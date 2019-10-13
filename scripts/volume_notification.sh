#!/bin/bash

icon=~/Downloads/audio-volume-medium-symbolic.svg

color_bar() {
	for p in $(seq $2); do
		eval $1+='▀'
	done
}

read level_value empty_value <<< $(amixer -D pulse get Master | awk -F '[[%]' \
	'/^ *Front/ { s = 5; t = 100 / s; l = $2 / s; printf "%.0f %.0f", l, t - l; exit }')

color_bar level $level_value
color_bar empty $empty_value

icon=

volume_bar="<span font='Roboto 8' foreground='\$pbfg'>$level<span foreground='\$epbfg'>$empty</span></span>"

~/.orw/scripts/notify.sh -r 100 -P 4 -p "<span font='Roboto 13' foreground='\$epbfg'>$icon  $volume_bar</span>"
