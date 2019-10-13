#!/bin/bash

set_margins() {
	[[ $@ ]] && ((index++))
	sed -i "/#window/,/^$/ {/margin/ s/[0-9]\+/${1:-0}/${index-g}}" .config/rofi/dmenu.rasi
}

if [[ $(sed -n '$s/.*"\(.*\)"/\1/p' .config/rofi/main.rasi) == dmenu ]]; then
	read x_offset y_offset <<< $(awk '/offset/ { print $NF }' ~/.config/orw/config | xargs)

	while read -r bar_name position bar_x bar_y bar_width bar_height adjustable_width frame; do
		if ((position)); then
			current_bar_height=$((bar_y + bar_height + frame + 1))
			((current_bar_height > y_offset)) && y_offset=$current_bar_height
		fi
	done <<< $(~/.orw/scripts/get_bar_info.sh)

	set_margins $y_offset
	set_margins $x_offset
fi
