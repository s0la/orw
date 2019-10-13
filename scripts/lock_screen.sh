#!/bin/bash

source ~/.orw/dotfiles/.config/i3lockrc

blank=33000000

khl="$(~/.orw/scripts/colorctl.sh -o -$delta -h ${rc:0:6})${rc: -2}"
bshl="$(~/.orw/scripts/colorctl.sh -o +$delta -h ${rc:0:6})${rc: -2}"

i3lock --blur $blur \
	   --verifsize=16 \
	   --veriftext="..." \
	   --radius $radius \
	   --ring-width $width \
	   --indicator --clock --timestr="%H:%M" \
	   --linecolor=$blank \
	   --insidecolor=$ic --ringcolor=$rc \
	   --datecolor=$tc --timecolor=$tc \
	   --separatorcolor=$rc --keyhlcolor=${khl#\#} \
	   --bshlcolor=${bshl#\#} \
	   --verifcolor=$tc --wrongcolor=$tc \
	   --ringvercolor=${rvc:-$rc} --ringwrongcolor=$wc \
	   --insidevercolor=$ic --insidewrongcolor=$ic \
