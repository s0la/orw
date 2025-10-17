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

get_workspace_window_count() {
	awk '
		NR == FNR && $2 == "*" { w = $1 }
		NR > FNR && $2 == w { wc++ }
		END { print wc }
	' <(wmctrl -d) <(wmctrl -l)
}

resize_window() {
	[[ $times == [1-9]* ]] &&
		local repeat="--repeat-delay 100 --repeat $times $direction "
	xdotool key $size key --window $id $repeat sleep 0.3 key d
}

resize() {
	local size direction times key
	read size direction times
	[[ $size == '<' ]] && key=super || key=ctrl
	xdotool key --repeat-delay 100 --repeat $times alt+$key+$direction
}

run() {
	local command
	read command
	xdotool type "$command" && xdotool key Return
	#xdotool type --window $id "$command" && xdotool key Return
	#eval "$command &> /dev/null &"
}

open() {
	local id command size direction times pid
	read size direction times command

	eval "$command &> /dev/null &"

	echo $size, $direction, $times, $window_count
	#([[ $size == _ ]] || ((!(window_count++)))) && return
	((!window_count++)) || [[ $size == _ ]] && return

	[[ $size == '<' ]] && size=less || size=greater

	#if [[ $size == _ ]]; then
	#	return
	#else
	#	[[ $size == '<' ]] && size=less || size=greater
	#fi

	echo before wait: $command
	wait_to_proceed
	id=$(wmctrl -l | awk '$NF == "input" { print $1 }')
	echo ID $id

	sleep 0.3
	resize_window
}

set() {
	local property value
	read property value
	~/.orw/scripts/wmctl.sh set_value $property $value > /dev/null
}

select_window() {
	local command
	while read -d $' ' key; do
		command+="sleep 0.3 key $key "
	done

	#virtual_keyboard_id=$(xinput list |
	#	awk 'match($0, "Virtual.*XTEST keyboard.*id=") { print substr($0, RSTART + RLENGTH, 2) }')

	~/.orw/scripts/select_window.sh virtual &
	xdotool $command sleep 0.5 key return
	return

	local command
	read key_sequence
	for key in $key_sequence; do
		command+="sleep 0.3 key $key "
	done
	~/.orw/scripts/select_window.sh &
	xdotool $command sleep 0.3 key return
}

if [[ -t 0 ]]; then
	open <<< "$@"
else
	window_count=$(get_workspace_window_count)

	while read action args; do
		sleep 0.3
		$action <<< "$args "
	done
fi
