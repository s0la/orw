#!/bin/bash

#[[ $1 == brightness ]] &&
#	icon=  command='echo 65%' ||
#	#icon=  command='~/.orw/scripts/brightnessctl.sh -g 2> /dev/null' ||
#	icon=  command=$([[ $1 =~ mpd ]] && echo mpc volume || echo amixer -D pulse get Master)

[[ $1 == brightness ]] &&
	command='echo 65%' ||
	command=$([[ $1 =~ mpd ]] && echo mpc volume || echo amixer -D pulse get Master)

	#awk '"'$2'" == "mpd" || /^ *Front/ {
read value level_value empty_value icon <<< $($command | \
	awk '("'$1'" ~ "system" && /^ *Front/) || "'$1'" !~ "system" {
			v = gensub(/.*[ \[]([0-9]+)%.*/, "\\1", 1)
			m = (!v || $NF ~ "off")
			t = int(100 / 5)
			l = int(v / 5)

			b = "'$1'" == "brightness"
			if(!v || $NF ~ "off") i = ""
			else if(v < 30) i = (b) ? "" : ""
			else if(v < 60) i = (b) ? "" : ""
			else i = (b) ? "" : ""

			printf "%d %.0f %.0f %s", v, l, t - l, i
			exit
		}')

#[[ $1 =~ mpd ]] && icon=
[[ $1 =~ mpd ]] && icon=

style=osd
[[ $style == mini ]] && info="$value%" || info="$level_value/$empty_value"
~/.orw/scripts/notify.sh $style $icon "$info" 
