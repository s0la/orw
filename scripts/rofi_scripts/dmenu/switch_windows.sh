#!/bin/bash

if [[ $1 ]]; then
	desktop=$(xdotool get_desktop)
else
	read workspace_lenght workspaces <<< $(wmctrl -d | awk '{
			wn = ($NF ~ "^[0-9]+$") ? ($NF > 1) ? "tmp_" $NF : "tmp" : $NF 
			wl = length(wn)
			if(wl > mwl) mwl = wl
			aw = aw " " wn
		} END {
			print mwl, aw
		}')

	workspaces=( $workspaces )
	workspace_format="%-$((workspace_lenght * 2))s  "
fi

#wmctrl -l | awk '$2 ~ "'$desktop'" {
#if(!ti) ti = index($0, $4)
#	if($1 == "'$id'") cwi = NR
#		at = at " \"" $2 " " $1 " " substr($0, ti) "\"" 
#		print cwi, at }'
#		exit

id=$(printf '0x%.8x' $(xdotool getactivewindow))

read current_window_index x y windows <<< \
	$(wmctrl -lG | awk '$2 ~ "'$desktop'" {
			if(!ti) ti = index($0, $8)
			if($1 == "'$id'") { cwi = NR; x = $3; y = $4 }
			at = at " \"" $2 " " $1 " " substr($0, ti) "\"" 
		} END { print cwi, x, y, at }')

eval "windows=( $windows )"

((current_window_index)) &&
	display_width=$(~/.orw/scripts/get_display.sh $x $y | cut -d ' ' -f 4)
((display_width)) || display_width=$(awk ' /^primary/ { p = $NF }
							p && $1 == p "_size" { print $2 }' ~/.config/orw/config)

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
			print int(iw / (f - 2))
		}' ~/.config/rofi/list.rasi)

window_title_lenght=$((rofi_width - workspace_lenght))
max_title_lenght=$((window_title_lenght - 10))
title_format="%-${workspace_lenght}s%${window_title_lenght}s\n"

	#str=$(python -c "print('s ' * 33)")
	#echo $rofi_width
	#echo $current_window_index
	#win=${windows[current_window_index - 1]}
	#python -c "print('s' * 92)" | rofi -dmenu -theme list
	#printf "%-*s%*s" $workspace_lenght "web" $((rofi_width - workspace_lenght)) "$win" | rofi -dmenu -theme list
	#exit

		#print "\"" $2, $1, t "\"" }')

#eval windows=( $(wmctrl -l | awk '$2 ~ "'$desktop'" {
#			if(!ti) ti = index($0, $4)
#			t = substr($0, ti)
#		print "\"" $2, $1, t "\"" }') )
#		#print "\"" $1 "  " $2 "  " t "\"" }') )
#		#print "\"" $1 ":" $2 ":" t "\"" }') )

#declare -A workspaces
#eval $(wmctrl -d | awk '{ print "workspaces[" $1 "]=" $NF }')

window_index=$(for window in "${windows[@]}"; do
	workspace=${window%% *}
	window_title="${window#* * }"
	((${#window_title} > max_title_lenght)) &&
		window_title="${window_title:0:$max_title_lenght}.."
	printf "$title_format" ${workspaces[workspace]} "$window_title"
	#printf "$workspace_format%s\n" ${workspaces[workspace]}  "${window#* * }"
done | rofi -dmenu -a $((current_window_index - 1)) -format 'i' -theme list)


if [[ $window_index ]]; then
	window_id=${windows[window_index]:2:10}
	~/.orw/scripts/minimize_window.sh $window_id
fi

exit

#is_viewable=$(xwininfo -id $window_id | awk '/Map/ { print $NF == "IsViewable" }')

#~/.orw/scripts/minimize_tiled_window.sh
#~/.orw/scripts/notify.sh "${properties[window_index]}"
~/.orw/scripts/minimize_window.sh $window_id
exit

minimize=~/.orw/scripts/minimize_tiled_window.sh

if ((is_viewable)); then
	current_window_id=$(printf '0x%.8x' $(xdotool getactivewindow))
	[[ $window_id == $current_window_id ]] && $minimize
	#wmctrl -ia $window_id
else
	$minimize $window_id
fi
