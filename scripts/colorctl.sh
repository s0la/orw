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
	local hex=$1

	while [[ $hex ]]; do
		rgb_color=$(printf "%.2d" 0x${hex:0:2})

		if [[ ! $balance && $offset ]]; then
			rgb_color=$((rgb_color ${sign:-+} offset))
			((rgb_color > 255)) && rgb_color=255
			((rgb_color < 0)) && rgb_color=0
			((offset -= degradation))
		fi

		full_hex+="$(printf "%.2x" $rgb_color)"
		rgb+="$rgb_color${separator-,}" 

		hex=${hex:2}
	done
}

while getopts :o:pdcs:r:h:Bb flag; do
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
		s) separator=$OPTARG;;
		r)
			rgb=${OPTARG//${separator-,}/ }

			[[ $balance ]] && balance_offset

			for color in $rgb; do
				[[ $convert ]] && hex+=$(printf "%.2x" $color)
				full_rgb+="$((color ${sign:-+} offset))${separator-,}"

				((offset -= degradation))
			done

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
	esac
done
