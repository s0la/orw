#!/bin/bash

calculate_brightness_index() {
	brightness_index=$(awk -F ''${separator-,}'' '{ r = $1; g = $2; b = $3; \
		print (sprintf("%.2f\n", (0.3 * r + 0.6 * g + 0.1 * b) / 255) > 0.5) ? "bright" : "dark" }' <<< ${full_rgb:-$rgb})
}

balance_offset() {
	calculate_brightness_index
	[[ $brightness_index == bright ]] && sign=- || sign=+
}

get_rgb() {
	local rgb_values hex=$1

	while [[ $hex ]]; do
		rgb_values+=( $(printf "%.2d" 0x${hex:0:2}) )
		hex=${hex:2}
	done

	((section && ${#rgb_values[*]} < 4)) && ((section--))

	for rgb_value_index in ${!rgb_values[*]}; do
		rgb_value=${rgb_values[rgb_value_index]}

		if ((${section-$rgb_value_index} == rgb_value_index)); then
			if [[ ! $balance && $offset ]]; then
				((rgb_value ${sign:-+}= offset))
				((rgb_value > 255)) && rgb_value=255
				((rgb_value < 0)) && rgb_value=0
				((offset -= degradation))
			fi
		fi

		full_hex+="$(printf "%.2x" $rgb_value)"
		rgb+="$rgb_value${separator-,}" 
	done
}

get_hex() {
	for color in $rgb; do
		hex+=$(printf "%.2x" $color)
		full_rgb+="$((color ${sign:-+} offset))${separator-,}"

		((offset -= degradation))
	done
}

while getopts :o:pdcs:S:r:h:P:Bb flag; do
	case $flag in
		o)
			sign=${OPTARG%%[0-9]*}
			offset=${OPTARG#$sign};;
		p) offset=$((offset * 255 / 100));;
		O) opposite=true;;
		d) degradation=$((offset / 10 * 2));;
		c) convert=true;;
		B) balance=true;;
		b) brightness=true;;
		S) section=$OPTARG;;
		s) separator=$OPTARG;;
		r)
			rgb_values=( ${OPTARG//${separator-,}/ } )
			((section && ${#rgb_values[*]} < 4)) && ((section--))

			[[ $balance ]] && balance_offset

			rgb="${rgb_values[*]: -3}"
			get_hex

			[[ $brightness ]] && calculate_brightness_index
			[[ $convert ]] && echo "#$hex" || echo $full_rgb;;
		h)
			hex=${OPTARG#\#}

			get_rgb $hex

			if [[ $balance ]]; then
				balance_offset
				unset balance rgb{color,} full_hex
				get_rgb $hex
			fi

			[[ $brightness ]] && calculate_brightness_index
			[[ $convert ]] && echo $rgb || echo "#$full_hex";;
		P)
			display_preview() {
				preview_color="#$hex"
				convert -size 100x100 xc:$preview_color $preview
				feh -g 100x100 --title 'image_preview' $preview &
			}

			color=$OPTARG
			[[ $color =~ ^# ]] && get_rgb ${color:1}

			rgb=${rgb-$color}
			rgb_values=( ${rgb//${separator:=,}/ } )

			((${#rgb_values[*]} > 3)) && transparency=${rgb_values[0]}
			rgb="${rgb_values[*]: -3}"
			hsv=( $(~/.orw/scripts/rgb_to_hsv.py "$rgb") )

			read x y <<< $(~/.orw/scripts/windowctl.sh -p | awk '{ print $3 + ($5 - 100), $4 + ($2 - $1) }')
			~/.orw/scripts/set_geometry.sh -t image_preview -x $x -y $y

			preview=/tmp/color_preview.png
			get_hex
			display_preview

			while
				clear

				for property in hue saturation value done; do
					echo -n "${property:0:1}) $property "
					((hsv_index < 3)) && echo -e "(${hsv[hsv_index]})"
					((hsv_index++))
				done

				read -rsn 1 -p $'\n\n' choice

				[[ $choice != d ]]
			do
				read -p $'Offset: ' offset

				case $choice in
					h) property_index=0;;
					s) property_index=1;;
					v) property_index=2;;
				esac

				hsv_rgb="$(~/.orw/scripts/hsv_to_rgb.py "$rgb" $property_index $offset)"
				hsv=( ${hsv_rgb%-*} )
				rgb=${hsv_rgb#*-}

				[[ $preview_color ]] && kill $!

				unset property_index hex full_rgb hsv_index
				get_hex
				display_preview
			done

			kill $!

			if [[ $transparency ]]; then
				rgb="$transparency $rgb"
				unset hex
				get_hex
			fi

			fifo=/tmp/color_preview.fifo
			[[ ! -p $fifo ]] && mkfifo $fifo
			echo "#$hex" > /tmp/color_preview.fifo &
	esac
done
