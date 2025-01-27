#!/bin/bash

source ~/.orw/dotfiles/.config/i3lockrc

blank=33000000

khl="$(~/.orw/scripts/convert_colors.sh -hv -$delta ${rc:0:6})${rc: -2}"
bshl="$(~/.orw/scripts/convert_colors.sh -hv +$delta ${rc:0:6})${rc: -2}"

		#--blur $blur \
i3lock \
		--color "#00000028" \
		--verif-size=16 \
		--verif-text="..." \
		--radius $radius \
		--ring-width $width \
		--indicator --clock \
		--time-size=$timesize \
		--date-size=$datesize \
		--time-str="%I:%M" \
		--date-str="%B %d, %Y" \
		--line-color=$blank \
		--inside-color=$ic --ring-color=$rc \
		--date-color=$tc --time-color=$tc \
		--separator-color=$rc --keyhl-color=${khl#\#} \
		--bshl-color=${bshl#\#} \
		--verif-color=$tc --wrong-color=$tc \
		--ringver-color=${rvc:-$rc} --ringwrong-color=$wc \
		--insidever-color=$ic --insidewrong-color=$ic &
