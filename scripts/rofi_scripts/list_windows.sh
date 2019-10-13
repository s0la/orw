#!/bin/bash

desktops=( $(wmctrl -d | awk '{print $NF}') )

while read -r window; do
	windows+=( "$window" )
done <<< $(wmctrl -l | awk '$2 >= 0 {$3=""; print}')

if [[ -z $@ ]]; then
	for window_index in ${!windows[*]}; do
		window=${windows[window_index]#* }
		desktop_id=${window%% *}
		desktop=${desktops[$desktop_id]}

		separation_length=15
		optimised_separation=$((separation_length - ${#desktop}))
		separation=''

		for space in $(seq $optimised_separation); do separation+=' '; done
		echo "$window_index  $desktop $separation ${window#* }"
	done
else
	wmctrl -ia ${windows[${@%% *}]%% *}
fi
