#!/bin/bash

artist=$(mpc current -f %artist%)
title=$(mpc current -f %title%)
album=$(mpc current -f %album%)

cover=~/Music/covers/${album// /_}.jpg

[[ $artist && $title ]] && ~/.orw/scripts/notify.sh -i ${cover//[()]/} -r 101 -f 8 -p "$artist  -  $title"
