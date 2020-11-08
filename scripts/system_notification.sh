#!/bin/bash

#[[ $1 == brightness ]] &&
#	icon=  command='echo 455030%' ||
#	#icon=  command='~/.orw/scripts/brightnessctl.sh -g 2> /dev/null' ||
#	icon=  command=$([[ $1 =~ mpd ]] && echo mpc volume || echo amixer -D pulse get Master)

theme=default
[[ $1 =~ mpd ]] && theme=vertical

[[ $1 == brightness ]] &&
	command='echo 50%' replace_id=104 theme=osd ||
	command=$([[ $1 =~ mpd ]] && echo mpc volume || echo amixer -D pulse get Master) replace_id=102

	#awk '"'$2'" == "mpd" || /^ *Front/ {

read value level_value empty_value icon <<< $($command | \
	awk '\
		BEGIN { s = "'$theme'" }
			("'$1'" ~ "system" && /^ *Front/) || "'$1'" !~ "system" {
			v = gensub(/.*[ \[]([0-9]+)%.*/, "\\1", 1)
			m = (!v || $NF ~ "off")

			if(s == "vertical") st = 10
			else st = ("'$theme'" == "default") ? 6 : 5
			t = int(100 / st)
			l = int(v / st)

			b = "'$1'" == "brightness"
			if(!v || $NF ~ "off") i = ""
			else if(v < 35) i = (b) ? "" : ""
			else if(v < 65) i = (b) ? "" : ""
			else i = (b) ? "" : ""

			printf "%d %.0f %.0f %s", v, l, t - l, i
			exit
		}')

#[[ $1 =~ mpd ]] && icon=
[[ $1 =~ mpd ]] && icon= replace_id=103

[[ $theme == mini ]] && value="-v $value%" || bar="-b $level_value/$empty_value"
~/.orw/scripts/notify.sh -r $replace_id -s $theme -i $icon "${bar:-$value}"
