#!/bin/bash

ocs_root=$HOME/.config/orw/colorschemes

while read preview; do
	echo -en "${preview##*/}\x00icon\x1f${preview}\n"
done <<< $(ls $ocs_root/previews/*) |
	rofi -dmenu -show-icons -l 5 -theme list \
	-theme-str 'element-icon { size: 100px; } element { padding: 0; margin: 10px; }' |
	sed "s/.png$//" | xargs echo ~/.orw/scripts/rice_and_shine.sh -tC
