#!/bin/bash

[[ ! $style =~ icons|dmenu ]] &&
	lock=lock loggout=loggout reboot=reboot suspend=suspend off=poweroff yes=yes no=no

read off suspend reboot logout _ lock yes no <<< \
	$(sed -n 's/^\(power_bar\|yes\|no\).*=//p' ~/.orw/scripts/icons | xargs)

options=(
	$lock
	$logout
	$reboot
	$suspend
	$off
)

base_count=${#options[*]}
item_count=$base_count

toggle
trap toggle EXIT

while
	set_theme_str

	read index option < <(
		for option in ${options[*]}; do
			echo $option
			[[ $option == $selected_option ]] &&
				echo -e "$yes\n$no"
		done | rofi -dmenu -format 'i s' -selected-row $index \
			$hilight -theme-str "$theme_str" -theme main)

	[[ $option ]]
do
	if [[ $option == $lock ]]; then
		~/.orw/scripts/lock_screen.sh
		exit
	elif [[ $option == $yes ]]; then
		case "$selected_option" in
			$logout*) openbox --exit;;
			$reboot*) systemctl reboot;;
			$suspend*) systemctl suspend;;
			$off*) systemctl poweroff ;;
		esac
		exit
	else
		if [[ $option =~ ^($selected_option|$no)$ ]]; then
			item_count=$base_count
			unset selected_option hilight
		else
			selected_option=$option
			item_count=$((base_count + 2))
			hilight="-u $((index + 1)),$((index + 2))"
		fi
	fi
done
