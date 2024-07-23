#!/bin/bash

source ~/.orw/dotfiles/.config/i3lockrc

blank=33000000

khl="$(~/.orw/scripts/convert_colors.sh -hv -$delta ${rc:0:6})${rc: -2}"
bshl="$(~/.orw/scripts/convert_colors.sh -hv +$delta ${rc:0:6})${rc: -2}"

i3lock --blur $blur \
	   --verifsize=16 \
	   --veriftext="..." \
	   --radius $radius \
	   --ring-width $width \
	   --indicator --clock \
	   --timesize=$timesize \
	   --datesize=$datesize \
	   --timestr="%I:%M" \
	   --datestr="%B %d, %Y" \
	   --linecolor=$blank \
	   --insidecolor=$ic --ringcolor=$rc \
	   --datecolor=$tc --timecolor=$tc \
	   --separatorcolor=$rc --keyhlcolor=${khl#\#} \
	   --bshlcolor=${bshl#\#} \
	   --verifcolor=$tc --wrongcolor=$tc \
	   --ringvercolor=${rvc:-$rc} --ringwrongcolor=$wc \
	   --insidevercolor=$ic --insidewrongcolor=$ic &
