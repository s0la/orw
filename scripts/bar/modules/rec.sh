#!/bin/bash

get_rec() {
	#local rec_color='#e34e68'
	label="%{F$rec_color}REC"
	icon="$rec_icon"

	rec_pid=$(pidof -x record_screen.sh)
	((rec_pid)) &&
		rec=$icon || unset rec

	set_rec_actions
}

set_rec_actions() {
	actions_start="%{A:kill $rec_pid:}" actions_end="%{A}"
}

check_rec() {
	rec_color=$(awk '$1 == "red" { gsub("\"", "", $NF); r = $NF } END { print r }' \
		~/.config/alacritty/alacritty.toml)
	rec_icon="%{F$rec_color}$(get_icon '^rec')"

	while true; do
		get_rec
		print_module rec
		sleep 3
	done
}
