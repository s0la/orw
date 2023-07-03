#!/bin/bash

get_vanter() {
	vanter=$(cat ${0%/*}/vanter.txt)
	#sleep 3
	#~/.orw/scripts/notify.sh "gotten vanter.."
}

check_vanter() {
	local actions_start="%{A:~/.orw/scripts/notify.sh 'Hello from vanter':}"
	local actions_end='%{A}'

	label='VNT' icon="$(get_icon "vanter_icon")"

	while true; do
		get_vanter
		print_module vanter
		sleep 13
	done
}
