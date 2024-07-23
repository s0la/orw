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
	local force=$1
	[[ $style =~ ^((vertical_)?icons|dmenu)$ || $force ]] && ((tiling_workspace)) &&
		~/.orw/scripts/signal_windows_event.sh rofi_toggle
}

get_rofi_width() {
	local width font_size=9 force=$1

	if [[ ! ${widths[$item_count]} || $force ]]; then
		width=$(awk '
			BEGINFILE {
				ic = '${item_count:-5}'
				i = (FILENAME ~ "icons")
				p = "font|element-padding|window-width"
				p = "font|element-padding|window-(padding|width)"
				p = p "|" ((i) ? "list-spacing" : "entry-width")
			}

			$1 ~ "(" p ")" {
				v = $NF
				gsub(".* |(\"|px).*", "", v)

				switch ($1) {
					case /font/:
						if (!i) v = '$font_size'
						f = v * 1.34
						break
					case /window-padding/: wp = v * 2; break
					case /padding/: ep = v * ((i) ? 2 : 5); break
					case /spacing/: ls = v; break
					case /entry/: ew = v; break
					case /window-width/:
						w = wp + (ep + f) * ic
						if (i) w += ls * (ic - 1)
						print int(w)
						exit
				}
			}' ~/.config/rofi/$style.rasi)

			((sourced)) || widths[$item_count]=$width
		else
			width=${widths[$item_count]}
		fi

		theme_str="window { width: ${width}px; } "
		[[ $style == *icons ]] &&
			extra="listview { columns: $item_count; }" ||
			extra="horibox { children: [ listview ]; } * { font: \"material $font_size\"; }"
		theme_str+="$extra"
}

set_theme_str() {
	local force=$1
	[[ $style =~ horizontal|dmenu ]] &&
		get_rofi_width $force || unset theme_str
}

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

	source $script
fi
