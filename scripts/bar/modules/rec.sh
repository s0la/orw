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
	#actions_start="%{A:kill $rec_pid:}" actions_end="%{A}"
	actions_start="%{A:killall ffmpeg:}" actions_end="%{A}"
}

check_rec() {
	rec_color=$(awk '$1 == "red" { gsub("\"", "", $NF); r = $NF } END { print "%{F" r "}" }' \
		~/.config/alacritty/alacritty.toml)
	[[ $Xpfg == $pfg ]] &&
		local rec_fg=$rec_color || local rec_fg=$Xpfg
	#rec_fg=$rec_color
	rec_icon="$rec_fg$(get_icon '^rec')"

	while true; do
		get_rec
		print_module rec
		sleep 3
	done
}
