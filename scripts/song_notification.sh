#!/bin/bash

artist=$(mpc current -f %artist%)
title=$(mpc current -f %title%)
album=$(mpc current -f %album%)

cover=~/Music/covers/${album// /_}.jpg
cover="${cover//[()]/}"

font='Iosevka Orw'
#info="$artist    ››    <b>$title</b>"
#info="<span font='$font 8'>$artist</span>    <span font='$font 8'> </span>   <span font='$font 8'><b>$title</b></span>"
info="$artist        <b>$title</b>"

#info="<b>artist:</b>  $artist\n"
#info+="<b>title:</b>   $title\n"
#info+="<b>album:</b>   $album"

[[ -f $cover ]] && icon="-i $cover"
[[ $artist && $title ]] && ~/.orw/scripts/notify.sh $icon -r 101 -F 'Iosevka Orw' -f 8 -po 8 "$info"
