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
				#rgb_value=$((rgb_value ${sign:-+} offset))
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
	for rgb_value_index in ${!rgb_values[*]}; do
		rgb_value=${rgb_values[rgb_value_index]}

		if ((${section-$rgb_value_index} == rgb_value_index)); then
			((rgb_value ${sign:-+}= offset))
			((offset -= degradation))
		fi

		[[ $convert ]] && hex+=$(printf "%.2x" $rgb_value)
		full_rgb+="$rgb_value${separator-,}"
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
			color=$OPTARG
			[[ $color =~ ^# ]] && get_rgb ${color:1}

			rgb=${rgb-$color}
			rgb_values=( ${rgb//${separator:=,}/ } )

			((${#rgb_values[*]} > 3)) && transparency=${rgb_values[0]}$separator
			rgb="${rgb_values[*]: -3}"

			while
				clear

				for property in hue saturation value; do
					((property_index++))
					echo "$property_index) $property"
				done

				read -rsn 1 -p $'\n#?\n' property_index
				read -p $'\nOffset: ' offset

				rgb="$(~/.orw/scripts/hsv.py "$rgb" $((property_index - 1)) $offset)"
				fifo=/tmp/color_preview.fifo
				echo $rgb > $fifo
				unset property_index hex full_rgb

				read -rsn 1 -p $'Continue: [y/N]\n' cont
				[[ $cont == y ]]
			do
				continue
			done

			echo $transparency${rgb// /$separator}
	esac
done
