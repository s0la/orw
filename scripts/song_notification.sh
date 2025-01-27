#!/bin/bash

artist=$(mpc current -f %artist%)
title=$(mpc current -f %title%)
album=$(mpc current -f %album%)

#cover=~/Music/covers/${album// /_}.jpg
cover="$(~/.orw/scripts/get_cover_art.sh)"
cover="${cover//[()]/}"

#song_position=$(mpc current -f '%position%')
#IFS=$'\n' read -d '' -a songs <<< $(mpc playlist |
#	awk 'NR >= '$song_position' - 1 && NR <= '$song_position' + 1')

font='Iosevka Orw'
#info+="<span font='$font 8'><b>$artist┃</b>$title</span>"
info="<b>$artist┃</b>$title"
info="<b>$artist</b>\n$title"
#song_fg="<span foreground='\$sbg'>"
#[[ ${songs[-3]} ]] && info="$song_fg${songs[-3]}</span>\n"
#info+="<span foreground='\$fg'>$artist  <span font='$font 9'></span>  <b>$title</b></span>\n"
#[[ ${songs[2]} ]] && info+="$song_fg${songs[2]}</span>"

[[ -f $cover ]] && icon="-i $cover"
[[ $artist && $title ]] &&
	#~/.orw/scripts/notify.sh $icon -r 101 -F 'Iosevka Orw' -f 8 -po 8 "$info" &> /dev/null
	~/.orw/scripts/notify.sh $icon -r 101 -F 'Iosevka Orw' -f 8 -o 8 "$info" &> /dev/null
