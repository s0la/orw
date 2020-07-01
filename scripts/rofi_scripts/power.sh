#!/bin/bash

theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)
[[ $theme != icons ]] && loggout=loggout reboot=reboot off=poweroff sep=' '

if [[ -z $@ ]]; then
	cat <<- EOF
		$sep$loggout
		$sep$reboot
		$sep$off
	EOF
else
	case "$@" in
		*) openbox --exit;;
		*) systemctl reboot;;
		suspend) systemctl suspend;;
		*) systemctl poweroff ;;
	esac
fi
