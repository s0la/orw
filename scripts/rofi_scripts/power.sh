#!/bin/bash

[[ ! $style =~ icons|dmenu ]] &&
	lock=lock loggout=loggout reboot=reboot suspend=suspend off=poweroff sep=' '

read {off,suspend,reboot,logout,,lock,yes,no}_icon <<< \
	$(sed -n 's/^\(power_bar\|yes\|no\).*=//p' ~/.orw/scripts/icons | xargs)

toggle
trap toggle EXIT

while
	item_count=5
	set_theme_str

	action=$(cat <<- EOF | rofi -dmenu -theme-str "$theme_str" -theme main
		$lock_icon$sep$lock
		$logout_icon$sep$loggout
		$reboot_icon$sep$reboot
		$suspend_icon$sep$suspend
		$off_icon$sep$off
	EOF
	)

	[[ $action ]]
do
	[[ $style != *icons ]] &&
		yes_label=yes no_label=no

	if [[ $action =~ $lock_icon ]]; then
		~/.orw/scripts/lock_screen.sh
		exit
	else
		item_count=2
		set_theme_str

		confirmation=$(echo -e "$yes_icon$yes_label\n$no_icon$no_label" |
			rofi -dmenu -theme-str "$theme_str" -theme main)

		[[ $confirmation == "$yes_icon$yes_label" ]] &&
			case "$action" in
				$logout_icon*) openbox --exit;;
				$reboot_icon*) systemctl reboot;;
				$suspend_icon) systemctl suspend;;
				$off_icon*) systemctl poweroff ;;
			esac && exit
	fi
done
