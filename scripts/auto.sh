#!/bin/bash

wait_to_proceed() {
	while true; do
		sleep 0.1
	done &
	local while_pid=$!
	wait $while_pid
	kill $while_pid
}

wait_to_proceed() {
	sleep infinity &
	local sleep_pid=$!
	wait $sleep_pid
	kill $sleep_pid
	sleep 0.1
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
	local times=$1 size=$2 direction=$3
	[[ $times == [1-9]* ]] &&
		local repeat="--repeat-delay 100 --repeat $times $direction sleep 0.3 "
	xdotool key $size key --window $id $repeat key d
}

resize() {
	local size direction times key
	read size direction times
	[[ $size == '<' ]] && key=super || key=ctrl
	xdotool key --repeat-delay 200 --repeat $times alt+$key+$direction
}

run() {
	local command
	read command
	xdotool type --delay 100 "$command" && xdotool key Return
	sleep 0.5
	#xdotool type --window $id "$command" && xdotool key Return
	#eval "$command &> /dev/null &"
}

open() {
	local id command size direction times pid
	read size direction times command

	#eval "$command &> /dev/null &"
	xdotool sleep 0.1 key --clearmodifiers alt+a &
	press_keys

	echo $size, $direction, $times, $window_count
	((!window_count++)) || [[ $size == _ ]] && return

	[[ $size == '<' ]] && size=less || size=greater

	wait_to_proceed
	id=$(wmctrl -l | awk '$NF == "input" { print $1 }')
	echo ID $id

	sleep 0.3
	resize_window $times $size $direction
}

set() {
	local property value
	read property value
	~/.orw/scripts/wmctl.sh set_value $property $value > /dev/null
}

tile() {
	local scroll_{moves,directions} side{,_command} full{,_command} tile_{size,direction,moves} moves
	read scroll_{moves,directions} side full tile_{size,direction,moves} moves

	#~/.orw/scripts/signal_windows_event.sh tile

	[[ $side != l ]] &&
		case $side in
			r) side_rep=1;;
			t) side_rep=2;;
			b) side_rep=3;;
		esac && side_command="key --repeat $side_rep --repeat-delay 200 ctrl+j"

	((full)) && full_command="key ctrl+j"

	[[ $tile_size == '>' ]] && tile_size=greater || tile_size=less

	xdotool key alt+shift+w sleep 0.2 key ctrl+k sleep 0.2 key return
	xdotool sleep 0.5 key return
	xdotool sleep 0.5 key --repeat $scroll_moves --repeat-delay 200 ctrl+$scroll_directions key return

	echo $side: $full - $moves
	[[ $moves ]] &&
		select_window <<< "$moves " || xdotool sleep 0.5 key return

	eval xdotool sleep 0.5 $side_command key return
	eval xdotool sleep 0.5 $full_command key return

	wait_to_proceed
	id=$(wmctrl -l | awk '$NF == "input" { print $1 }')
	sleep 0.3

	resize_window $tile_moves $tile_size $tile_direction
}

tile() {
	local scroll_{moves,directions} side{,_command} full{,_command} tile_{size,direction,moves} moves
	read scroll_{moves,directions} side full tile_{size,direction,moves} moves
	local base_command='xdotool search --sync --onlyvisible --class "rofi" windowactivate --sync sleep 0.1 key'

	#~/.orw/scripts/signal_windows_event.sh tile

	[[ $side != l ]] &&
		case $side in
			r) side_rep=1;;
			t) side_rep=2;;
			b) side_rep=3;;
		esac && side_command="key --repeat $side_rep --repeat-delay 200 ctrl+j"

	((full)) && full_command="key ctrl+j"

	[[ $tile_size == '>' ]] && tile_size=greater || tile_size=less

	xdotool key alt+shift+w sleep 0.5 key ctrl+k sleep 0.2 key return

	wait_to_proceed
	xdotool sleep 0.2 key return

	wait_to_proceed
	xdotool sleep 0.2 key --repeat $scroll_moves --repeat-delay 200 ctrl+$scroll_directions sleep 0.2 key return

	wait_to_proceed
	[[ $moves ]] &&
		select_window <<< "$moves " || xdotool sleep 0.2 key return
	exit

	wait_to_proceed
	eval xdotool sleep 0.2 $side_command sleep 0.2 key return

	wait_to_proceed
	eval xdotool sleep 0.2 $full_command sleep 0.2 key return

	wait_to_proceed
	id=$(wmctrl -l | awk '$NF == "input" { print $1 }')
	sleep 0.3

	resize_window $tile_moves $tile_size $tile_direction
}

press_keys() {
	local delay=${delay:-2}
	[[ $@ ]] && local key="key --clearmodifiers $@ "
	local rofi_id=$(xdotool search --sync --onlyvisible --class "rofi")
	eval xdotool sleep 0.$delay $key sleep 0.$delay key return
}

scroll_windows() {
	local scroll_{moves,directions} 
	read scroll_{moves,direction}

	sleep 0.5

	~/.orw/scripts/signal_windows_event.sh test

	if [[ $scroll_direction == [JK] ]]; then
		[[ $scroll_direction == J ]] &&
			local opposite_direction=k || local opposite_direction=j
		[[ $scroll_moves == [1-9] ]] &&
			local opposite_moves="sleep 0.3 key --repeat $scroll_moves --repeat-delay $delay ctrl+$opposite_direction"
		press_keys alt+${scroll_direction,} $opposite_moves
	elif [[ $scroll_moves == [1-9] ]]; then
		press_keys --repeat $scroll_moves --repeat-delay $delay ctrl+$scroll_direction
	fi
}

tile() {
	local delay=250
	local scroll_{moves,directions} side{,_command} full{,_command} tile_{size,direction,moves} moves
	read scroll_{moves,direction} side full tile_{size,direction,moves} moves

	#~/.orw/scripts/signal_windows_event.sh tile

	[[ $side != l ]] &&
		case $side in
			r) side_rep=1;;
			t) side_rep=2;;
			b) side_rep=3;;
		esac && side_command="--repeat $side_rep --repeat-delay $delay ctrl+j"

	((full)) && full_command="ctrl+j"

	[[ $tile_size == '>' ]] && tile_size=greater || tile_size=less

	xdotool sleep 0.1 key --clearmodifiers alt+shift+w &
	press_keys ctrl+k
	sleep 0.5
	press_keys

	sleep 0.5

	if [[ $scroll_direction == [JK] ]]; then
		[[ $scroll_direction == J ]] &&
			local opposite_direction=k || local opposite_direction=j
		[[ $scroll_moves == [1-9] ]] &&
			local opposite_moves="sleep 0.3 key --repeat $scroll_moves --repeat-delay $delay ctrl+$opposite_direction"
		press_keys alt+${scroll_direction,} $opposite_moves
	elif [[ $scroll_moves == [1-9] ]]; then
		press_keys --repeat $scroll_moves --repeat-delay $delay ctrl+$scroll_direction
	fi

	sleep 0.5

	[[ $moves ]] &&
		select_window <<< "$moves " || xdotool key return

	press_keys $side_command
	press_keys $full_command

	wait_to_proceed
	id=$(wmctrl -l | awk '$NF == "input" { print $1 }')
	sleep 0.5

	resize_window $tile_moves $tile_size $tile_direction
}

get_command() {
	local command
	while read -d $' ' key; do
		command+="sleep 0.3 key $key "
	done
	echo $command
}

select_window() {
	#local command
	#while read -d $' ' key; do
	#	command+="sleep 0.5 key $key "
	#done
	command=$(get_command)

	#virtual_keyboard_id=$(xinput list |
	#	awk 'match($0, "Virtual.*XTEST keyboard.*id=") { print substr($0, RSTART + RLENGTH, 2) }')

	~/.orw/scripts/select_window.sh &
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

move_window() {
	local command=$(get_command)
	xdotool keydown super $command keyup alt
}

swap_window() {
	local command=$(get_command)
	xdotool keydown ctrl+super $command keyup ctrl+super
}

pause() {
	local time
	read time
	sleep $time
}

if [[ -t 0 ]]; then
	open <<< "$@"
else
	window_count=$(get_workspace_window_count)

	while read action args; do
		sleep 0.5
		$action <<< "$args "
	done
fi
