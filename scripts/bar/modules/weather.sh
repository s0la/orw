#!/bin/bash

make_weather_content() {
	for arg in ${args//,/ }; do
		value=${arg#*:}
		arg=${arg%%:*}

		case $arg in 
			w) weather_components+='$wind';;
			t) weather_components+='$temperature';;
			o) weather_components+="%{O$value}";;
			*) location=$value;;
		esac
	done
}

get_weather() {
	IFS=$'\n' read -d '' weather temperature wind <<< \
		$(curl -s wttr.in/$location | awk 'NR < 6 {
			switch (NR) {
				case 1:
					sub(":\\s.*", "")
					p = length($0) + 3
					break
				default:
					if (NR > 2) {
						gsub("\\x1B\\[[^m]*m|\\s*$", "")
						if (NR == 4) gsub("\\([0-9]+\\)|\\+", "")
						print substr($0, p)
					}
			}
		}')

	case "${weather,,}" in
		*sunny*) label='SUNNY';;
		#*cloud*)
		#	[[ ${weather,,} == *partly* ]] &&
		#		label='LIGHT RAIN' || label='RAIN'
		#	;;
		*rain*)
			[[ ${weather,,} =~ ^(light|patchy) ]] &&
				label='LIGHT RAIN' || label='RAIN'
			;;
		*) label=${weather,,};;
	esac

	label_icon="${label/ /_}"
	icon=$(get_icon "^${label_icon,,}=")

	[[ $weather_components != *O* ]] &&
		weather_components=$(sed 's/\([^^]\)\$/\1$inner$/g' <<< $weather_components)

	eval weather=\""$weather_components"\"
	weather="${weather:-$temperature}"
}

check_weather() {
	while
		get_weather
		print_module weather
	do
		sleep 300
	done
}
