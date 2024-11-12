#!/bin/bash

item_count=8

read icon_size window_width <<< \
	$(awk '
		function get_value() {
			gsub("[^0-9]", "", $NF)
			return $NF
		}

		NR == FNR && $1 == "primary" { d = get_value() }
		NR == FNR && $1 == "display_" d "_size" { h = $NF }
		NR > FNR {
			if (/font/) { f = get_value() }
			if (/element-padding/) { ep = get_value() }
			if (/window-padding/) { wp = get_value() }
			if (/input-padding/) { ip = get_value() }
			if (/window-width/) { exit }
		} END {
			ww = int((h - (2 * (wp + ip) + f)) / '$item_count')
			is = ww - 3 * ep - 1
			print is
		 }' ~/.config/{orw/config,rofi/image_preview.rasi})

theme_str="listview { lines: $item_count; } "
theme_str+="element-icon { size: ${icon_size}px; } "
theme_str+="window { width: ${window_width:-130}px; }"
IFS=$'\n' read -d '' command active content
[[ $active == *[0-9]* ]] && active="-a $active"

toggle force
trap "toggle force" EXIT

while
	read index element <<< $(while read -r element; do
			echo -en "$element\0icon\x1f$element\n"
		done <<< $(echo -e "$content") |
			rofi -dmenu -show-icons -format 'i s' \
			$active -selected-row ${index:-0} -theme-str "$theme_str" -theme image_preview 2> /dev/null)
	[[ $element ]]
do
	[[ $command ]] &&
		eval "$command" &&
		active="-a $index" ||
		exit
done
exit

ISF=$'\n' read -d '' active wallpapers <<< $(~/.orw/scripts/rofi_scripts/select_wallpaper.sh)
[[ $active ]] && active="-a $active"

while
	read index wallpaper <<< $(while read -r wall; do
			echo -en "$wall\0icon\x1f$wall\n"
		done <<< $(echo -e "$wallpapers") |
			rofi -dmenu -show-icons -format 'i s' \
			$active -selected-row ${index:-0} -theme-str "$theme_str" -theme img)
	[[ $wallpaper ]]
do
	eval ~/.orw/scripts/wallctl.sh -s "'$wallpaper'"
	active="-a $index"
done
