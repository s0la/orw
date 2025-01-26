#!/bin/bash

wait_to_proceed() {
	while true; do
		sleep 0.1
	done &
	local while_pid=$!
	wait $while_pid
	kill $while_pid
}

toggle() {
	local signal force=$1
	if [[ $style =~ ^((vertical_)?icons|dmenu)$ || $force ]] &&
		((tiling_workspace)); then
			[[ $script == *image_preview* ]] &&
				signal=image_preview || signal=rofi_toggle
			~/.orw/scripts/signal_windows_event.sh $signal
	fi
}

get_rofi_width() {
	local width font_size=9 force=$1

	if [[ ! ${widths[$item_count]} || $force ]]; then
		width=$(awk '
			BEGINFILE {
				ic = '${item_count:-5}'
				i = (FILENAME ~ "icons")
				p = "font|element-padding|window-width"
				p = "font|element-padding|window-(padding|width|border)"
				p = p "|" ((i) ? "list-spacing" : "entry-width")
			}

			$1 ~ "(" p ")" {
				v = $NF
				gsub(".* |(\"|px).*", "", v)

				switch ($1) {
					case /font/:
						#if (!i) v = '$font_size'
						#f = v * 1.10
						f = (i) ? v * 1.3 : '$font_size'
						break
					case /window-padding/: wp = v * 2; break
					case /window-border/: wb = v * 2; break
					case /padding/: ep = v * ((i) ? 2 : 5); break
					case /spacing/: ls = v; break
					case /entry/: ew = v; break
					case /window-width/:
						w = wp + wb + (ep + f) * ic
						if (i) w += ls * (ic - 1)
						print int(w)
						exit
				}
			}' ~/.config/rofi/$style.rasi)

			((sourced)) || widths[$item_count]=$width
		else
			width=${widths[$item_count]}
		fi

		theme_str="window { width: ${width}px; } listview { columns: $item_count; }"
		[[ $style == dmenu ]] &&
			theme_str+=" horibox { children: [ listview ]; } * { font: \"material $font_size\"; }"
		#theme_str="window { width: ${width}px; } "
		#[[ $style == *icons ]] &&
		#	extra="listview { columns: $item_count; }" ||
		#	extra="horibox { children: [ listview ]; } * { font: \"material $font_size\"; }"
		#theme_str+="$extra"
		#~/.orw/scripts/notify.sh "ic: $item_count, $style, $theme_str"
		return 0
}

set_theme_str() {
	local force=$1
	[[ $style =~ horizontal|dmenu ]] &&
		get_rofi_width $force || unset theme_str
}

icons=~/.orw/scripts/icons
sourced=$((${#BASH_SOURCE[*]} == 1))

if ((sourced)); then
	declare -A widths

	trap : USR1

	script=${0%/*}/$1.sh
	shift

	current_workspace=$(xdotool get_desktop)
	tiling_workspace=$(awk '
		/^tiling_workspace/ { print (/'$current_workspace'/) }' \
			~/.orw/scripts/spy_windows.sh)

	style=$(awk 'END { gsub("\"|\\..*", "", $NF); print $NF }' ~/.config/rofi/main.rasi)

	source $script $@
fi
