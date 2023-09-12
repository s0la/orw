#!/bin/bash

toggle_rofi() {
	echo TOGGLING: $tiling_workspace
	((tiling_workspace)) &&
		~/.orw/scripts/signal_windows_event.sh rofi_toggle
}

script=${0%/*}/$1.sh
shift

current_workspace=$(xdotool get_desktop)
tiling_workspace=$(awk '
	/^tiling_workspace/ { print (/'$current_workspace'/) }' \
		~/.orw/scripts/spy_windows.sh)

source $script
