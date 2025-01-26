#!/bin/bash

make_battery_content() {
	for arg in ${args//,/ }; do
		value=${arg#*:}
		arg=${arg%%:*}

		case $arg in 
			p) battery_components+='$battery_percentage';;
			t) battery_components+='${battery_time%:*}';;
			o) battery_components+="%{O$value}";;
		esac
	done
}

get_battery() {
	read battery_{state,percentage,time} <<< $(acpi |
		awk -F ',' '{
			gsub("[^0-9:]", "", $3)
			sub(".*\\s+", "", $1)
			print $1, $2, $3
		}')

	((${#battery_percentage} == 4)) &&
		icon_level=full ||
		icon_level="${battery_percentage:: -2}"
	[[ ${battery_state,} == charging ]] &&
		label=CHR || label=BAT
	icon=$(get_icon "^${label,,}?.*_?${icon_level:-empty}")

	[[ $battery_components != *O* ]] &&
		battery_components=$(sed 's/\([^^]\)\$/\1$inner$/g' <<< $battery_components)

	eval battery=\""$battery_components"\"
	((${battery_percentage:: -1} >= 95)) &&
		unset battery || battery="${battery:-$battery_percentage}"
	print_module battery
}

check_battery() {
	while
		get_battery
	do
		sleep 100
	done
}
