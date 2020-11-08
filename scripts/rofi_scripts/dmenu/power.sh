#!/bin/bash

theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)
[[ $theme =~ dmenu|icons ]] && ~/.orw/scripts/set_rofi_geometry.sh power
[[ $theme != icons ]] && lock=lock loggout=loggout reboot=reboot off=poweroff sep=' '

icon_lock=
icon_logout=
icon_reboot=
icon_off=

icon_lock=
icon_lock=
icon_logout=
icon_reboot=
icon_off=

action=$(cat <<- EOF | rofi -dmenu -theme main
	$icon_lock$sep$lock
	$icon_logout$sep$loggout
	$icon_reboot$sep$reboot
	$icon_off$sep$off
EOF
)

if [[ $action ]]; then
	yes_icon=
	no_icon=

	[[ $theme != icons ]] &&
		yes_label=yes no_label=no ||
		~/.orw/scripts/set_rofi_geometry.sh power 2

	if [[ $action =~ $icon_lock ]]; then
		sleep 0.1
		~/.orw/scripts/lock_screen.sh
	else
		confirmation=$(echo -e "$yes_icon$yes_label\n$no_icon$no_label" | rofi -dmenu -theme main)

		[[ $confirmation == "$yes_icon$yes_label" ]] && case "$action" in
				$icon_logout*) openbox --exit;;
				$icon_reboot*) systemctl reboot;;
				$icon_suspend) systemctl suspend;;
				$icon_off*) systemctl poweroff ;;
			esac
	fi
fi
