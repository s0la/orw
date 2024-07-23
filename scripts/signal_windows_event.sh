#!/bin/bash

wait_to_proceed() {
	while true; do
		:
	done &
	wait
}

trap : USR1

spy_windows_pid=$(ps -o pid= -C spy_windows.sh | head -1)

[[ $spy_windows_pid ]] || exit

case $1 in
	min) sig=35;;
	max) sig=36;;
	mv) sig=37;;
	tile) sig=39;;
	info) sig=40;;
	align) sig=41;;
	update) sig=42;;
	rotate) sig=43;;
	stretch) sig=44;;
	resize) sig=46;;
	move) sig=45;;
	swap) sig=47;;
	ws) sig=48;;
	toggle_ws) sig=49;;
	mouse_move) sig=50;;
	mouse_split) sig=59;;
	mouse_split_reverse) sig=60;;
	mouse_resize) sig=51;;
	swap_resize) sig=38;;
	offset_int) sig=52;;
	resize_int) sig=53;;
	rofi_toggle) sig=54;;
	rofi_resize) sig=55;;
	untile) sig=56;;
	layout) sig=57;;
	test) sig=63;;
	kill)
		pidof -x spy_windows.sh | xargs kill -9
		exit
esac

kill -s $sig $spy_windows_pid

[[ $1 == mv ]] && wait_to_proceed
