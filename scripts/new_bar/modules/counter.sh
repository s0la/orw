#!/bin/bash

get_counter() {
	counter=$(cat ${0%/*}/counter.txt)
	sleep 2
}

check_counter() {
	local actions_start="%{A:~/.orw/scripts/notify.sh 'Hello from counter':}"
	local actions_end='%{A}'

	label='CNT' icon="$(get_icon "counter_icon")"

	while true; do
		get_counter
		print_module counter
		sleep 5
	done
}
