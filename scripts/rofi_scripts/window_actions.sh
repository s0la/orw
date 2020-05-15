#!/bin/bash

theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)
[[ $theme != icons ]] && close=close min=min max=max sep=' '

if [[ -z $@ ]]; then
	cat <<- EOF
		$sep$close
		$sep$max
		$sep$min
	EOF
else
	case "$@" in
		*) wmctrl -r :ACTIVE: -b toggle,maximized_vert,maximized_horz;;
		*) xdotool getactivewindow windowminimize;;
		*) wmctrl -c :ACTIVE:;;
	esac
fi
