#!/bin/bash

icons='       '

[[ $1 == brightness ]] &&
	icon=  command='echo 65%' ||
	#icon=  command='~/.orw/scripts/brightnessctl.sh -g 2> /dev/null' ||
	icon=  command=$([[ $1 =~ mpd ]] && echo mpc volume || echo amixer -D pulse get Master)

	#awk '"'$2'" == "mpd" || /^ *Front/ {
read level_value empty_value icon <<< $($command | \
	awk '("'$1'" ~ "system" && /^ *Front/) || "'$1'" !~ "system" {
			v = gensub(/.*[ \[]([0-9]+)%.*/, "\\1", 1)
			m = (!v || $NF ~ "off")
			t = int(100 / 5)
			l = int(v / 5)

			#else if(v < 30) i = (b) ? "" : ""
			#else if(v < 60) i = (b) ? "" : ""
			#else i = (b) ? "" : ""

			b = "'$1'" == "brightness"
			if(!v || $NF ~ "off") i = ""
			else if(v < 30) i = (b) ? "" : ""
			else if(v < 60) i = (b) ? "" : ""
			else i = (b) ? "" : ""

			printf "%.0f %.0f %s", l, t - l, i
			exit
		}')

#[[ $1 =~ mpd ]] && icon=
[[ $1 =~ mpd ]] && icon=
#[[ $1 == brightness ]] && icon=
~/.orw/scripts/notify.sh osd $icon "$level_value/$empty_value" 
