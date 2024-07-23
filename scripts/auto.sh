#!/bin/bash

wait_to_proceed() {
	while true; do
		sleep 0.1
	done &
	local while_pid=$!
	wait $while_pid
	kill $while_pid
}

trap : SIGUSR1

resize() {
	xdotool \
		key $size \
		key --window $id --repeat-delay 100 --repeat $times $direction \
		sleep 0.3 key d
}

run() {
	local id app size direction times pid
	read size direction times app

	eval "$app &> /dev/null &"

	wait_to_proceed
	id=$(wmctrl -l | awk '$NF == "input" { print $1 }')

	sleep 0.3
	resize
}

if [[ -t 0 ]]; then
	run <<< "$@"
else
	while read app; do
		run <<< "$app"
	done
fi
