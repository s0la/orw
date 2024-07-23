#!/bin/bash

path=${0%/*}

[[ $2 ]] &&
	theme=$2 ||
	theme=$(awk -F '"' 'END {
			t = $(NF - 1)
			sub("\\..*", "", t)
			print t
		}' ~/.config/rofi/main.rasi)
[[ $theme == icons && $1 =~ bar|execute|files|library|playlist|torrent ]] && theme=list

rofi -modi "$1:$path/$1.sh" -show $1 -theme $theme
