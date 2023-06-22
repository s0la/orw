#!/bin/bash

#id=$(printf "0x%.8x" $(xdotool getactivewindow))
#
#read border_x border_y <<< $(xwininfo -id $id | awk '/Relative/ {print $NF}' | xargs)
#[[ -f ~/.config/orw/config ]] && read width height <<< $(awk '/[hv]_base/ {print $NF}' ~/.config/orw/config | xargs)
#
#read wx wy <<< $(wmctrl -lG | awk '$1 == "'$id'" \
#	{ print int($3 + $5 / 2 - '${width:-0}' / 2 - '$border_x'), int($4 + $6 / 2 - '${height:-0}' / 2 - '$border_y') }')

read wx wy <<< $(~/.orw/scripts/windowctl.sh -p | cut -d ' ' -f 3,4)

#if [[ $@ ]]; then
	awk '{
		if(/^orientation/) {
			if($2 ~ /^h/) { p = '$wx'; op = '$wy'; f = 2 }
			else { p = '$wy'; op = '$wx'; f = 3 }
		} else if(/^display.*size/) {
			if(p > $f) p -= $f
			else {
				print p, op
				exit
			}
		}
	}' ~/.config/orw/config
#else
#	echo $wx $wy
#fi
