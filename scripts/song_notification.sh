#!/bin/bash

artist=$(mpc current -f %artist%)
title=$(mpc current -f %title%)
album=$(mpc current -f %album%)

cover=~/Music/covers/${album// /_}.jpg
cover="${cover//[()]/}"

font='Iosevka Orw'
info="$artist  <span font='$font 9'></span>  <b>$title</b>"

[[ -f $cover ]] && icon="-i $cover"
[[ $artist && $title ]] &&
	~/.orw/scripts/notify.sh $icon -r 101 -F 'Iosevka Orw' -f 8 -po 8 "$info" &> /dev/null
