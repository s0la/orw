#!/bin/bash

if [[ $@ ]]; then
	if [[ $@ == [0-9] ]]; then
		desktop="$1"

		wmctrl -l | awk '
			$2 ~ "'"$desktop"'" {
				aw[$2] = aw[$2] " " $NF
			} END { for (w in aw) {
					gsub(" ", "\n", aw[w])
					print aw[w]
				}
			}'
	else
		window="$@"
		wmctrl -l | sed -n "s/\s.*${window##* }$//p" | xargs wmctrl -ia
		#echo WIN $window
	fi
else
	desktop_num=$(xdotool get_num_desktops)
	
	for desktop in $(seq 0 $((desktop_num - 1))); do
		modis+="$desktop:$0 $desktop,"
	done

	desktop=$(xdotool get_desktop)
	rofi -modi "${modis%,}" -show $desktop -theme sidebar_new
fi

exit

if [[ $1 ]]; then
	desktop=$(xdotool get_desktop)
else
	read workspace_lenght workspaces <<< $(wmctrl -d | awk '{
			wn = ($NF ~ "^[0-9]+$") ? ($NF > 1) ? "tmp_" $NF - 1 : "tmp" : $NF 
			wl = length(wn)
			if(wl > mwl) mwl = wl
			aw = aw " " wn
		} END {
			print mwl, aw
		}')

	workspaces=( $workspaces )
	workspace_format="%-$((workspace_lenght * 2))s  "
fi

id=$(printf '0x%.8x' $(xdotool getactivewindow))

read current_window_index x y windows <<< \
	$(wmctrl -lG | awk '
		$2 ~ "'$desktop'" {
			gsub("\"", "\\\\\"")
			#if(!ti) ti = index($0, $8)
			if($1 == "'$id'") { cwi = NR; x = $3; y = $4 }
			#aw = aw " \"" $2 " " sprintf("0x%x", $1) " " substr($0, ti) "\"" 
			aw = aw " \"" $2 " " sprintf("0x%x", $1) " " $NF "\"" 
		} END {
			if(!cwi) cwi = x = y = 0
			print cwi, x, y, aw
		}')

eval "windows=( $windows )"

((current_window_index)) &&
	display_width=$(~/.orw/scripts/get_display.sh $x $y | cut -d ' ' -f 4)
((display_width)) ||
	display_width=$(awk ' /^primary/ { p = $NF } p && $1 == p "_size" { print $2 }' ~/.config/orw/config)

rofi_width=$(awk '
		function get_value() {
			return gensub(".* ([0-9]+).*", "\\1", 1)
		}

		/^\s*font/ { f = get_value() }
		/^\s*window-width/ { ww = get_value() }
		/^\s*window-padding/ { wp = get_value() }
		/^\s*element-padding/ { ep = get_value() }
		END {
			rw = int('$display_width' * ww / 100)
			iw = rw - 2 * (wp + ep)
			print int(iw / (f - 1))
		}' ~/.config/rofi/list.rasi)

window_title_lenght=$((rofi_width - workspace_lenght))
max_title_lenght=$((window_title_lenght - 20))
title_format="%-${workspace_lenght}s%${window_title_lenght}s\n"

list_workspaces() {
	[[ $done ]] && echo -e $done
	window_index=$(\
		for window in "${windows[@]}"; do
			workspace=${window%% *}
			window_title="${window#* * }"
			((${#window_title} > max_title_lenght)) &&
				window_title="${window_title:0:$max_title_lenght}.."
			printf "$title_format" ${workspaces[workspace]} "$window_title"
		done | rofi -dmenu -a $((current_window_index - 1)) -format 'i' -theme list)
}

if [[ $1 ]]; then
	done='done\n━━━━━━━'

	until
		list_workspaces
		((window_index))
	do
		window_id=${windows[window_index - 2]:2:10}
	done
else
	list_workspaces

	if [[ $window_index ]]; then
		#window_id=${windows[window_index]:2:10}
		read _ window_id _ <<< ${windows[window_index]}
		#~/.orw/scripts/minimize_window.sh $window_id
		wmctrl -ia $window_id
	fi
fi
