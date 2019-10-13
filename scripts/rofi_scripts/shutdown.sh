#!/bin/bash

option=$(echo -e 'reboot\nloggout\nsuspend\nshut down' | rofi -dmenu -theme main)
confirmation=$(echo -e 'yes\nno' | rofi -dmenu -theme main)

[[ $confirmation == yes ]] && case "$option" in
	loggout) openbox --exit;;
	reboot) systemctl reboot;;
	suspend) systemctl suspend;;
	*) systemctl poweroff ;;
esac
