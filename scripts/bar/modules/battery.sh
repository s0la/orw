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
	#read battery{_state,,time} <<< $(acpi |
	#	awk '{ gsub("(.*:|,)\\s+|\\s+\\w*$", " "); print }')
	#read battery{_state,,_time} <<< $(acpi | awk -F '[:, ]' '{ print $4, $6, $8 ":" $9 }')
	#acpi | awk -F '[:, ]' '{ print $4, $6, $8 ":" $9 }'
	#echo 'battery 0: charging, 100%, 11:33:55 remaining' | awk '{ gsub("[^,]*\\s+", " "); print }'

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
	#[[ $battery_time ]] &&
	#	battery_time="\$inner

	#[[ $battery_components == \$*\$* && $battery_components != *O* ]] &&
	#	battery_components="${battery_components%\$*}\$inner\$${battery_components##*\$}"
	#eval battery=\""$battery_components"\"

	[[ $battery_components != *O* ]] &&
		battery_components=$(sed 's/\([^^]\)\$/\1$inner$/g' <<< $battery_components)

	eval battery=\""$battery_components"\"
	#[[ $label == CHR ]] && ((${battery_percentage:: -1} >= 95)) &&
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
