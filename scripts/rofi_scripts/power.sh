#!/bin/bash

theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)
[[ $theme != icons ]] && loggout=loggout reboot=reboot off=poweroff sep=' '

icon_logout=
icon_reboot=
icon_off=

icon_logout=
icon_reboot=
icon_off=

if [[ -z $@ ]]; then
	cat <<- EOF
		$icon_logout$sep$loggout
		$icon_reboot$sep$reboot
		$icon_off$sep$off
	EOF
else
	case "$@" in
		$icon_logout*) openbox --exit;;
		$icon_reboot*) systemctl reboot;;
		suspend) systemctl suspend;;
		$icon_off*) systemctl poweroff ;;
	esac
fi
