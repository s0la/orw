#!/bin/bash

color_bar() {
	for p in $(seq $2); do
		eval $1+='▀'
	done
}

step=4
icon_size=11
distance=$(((100 / step) / 2))

read level_value empty_value <<< $(amixer -D pulse get Master | \
	awk -F '[[%]' '\
		/^ *Front/ {
			s = '$step'
			t = int(100 / s)
			l = int($2 / s)
			printf "%.0f %.0f", l, t - l
			exit
		}')

color_bar level $level_value
color_bar empty $empty_value

icon="$(printf "%*.s%s\\\n%s" $distance " " \
	"<span font='Roboto Mono $icon_size' foreground='\$epbfg'> </span>" \
	"<span font='Roboto Mono $icon_size'> </span>")"

volume_bar="<span font='Roboto 8' foreground='\$pbfg'>$level<span foreground='\$epbfg'>$empty</span></span>"

~/.orw/scripts/notify.sh -r 100 -P 4 -p "$icon$volume_bar"
