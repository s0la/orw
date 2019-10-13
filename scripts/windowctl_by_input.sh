#!/bin/bash

read_named_pipe() {
	read input < $named_pipe
	echo $input
}

read_keyboard_input() {
	exec 3< <(read_named_pipe)

	$(declare -F get_argument_count)

	read_command="read -rsn ${argument_count:-1} input && echo \$input > $named_pipe"
	termite -t input --class=input -e "bash -c '$read_command'" &> /dev/null

	read <&3 input

	evaluate $input

	[[ $stop ]] && return || read_keyboard_input
}

named_pipe=/tmp/keyboard_input
[[ -p $named_pipe ]] && rm $named_pipe
mkfifo $named_pipe

read window_x window_y <<< $(~/.orw/scripts/get_window_position.sh)

read input_x input_y <<< $(awk '/^display/ { \
	if(!(x && y)) {
		x = '$window_x' - 30
		y = '$window_y' - 30
	}
	if($1 ~ /xy/) {
		dx = $2
		dy = $3
	} else {
		if(dx + $2 > x && dy + $3 > y) {
			print x - dx, y - dy
			exit
		}
	}
}' ~/.config/orw/config)

~/.orw/scripts/termite_geometry.sh -x $input_x -y $input_y -w 60 -h 60

source ~/.orw/scripts/${1}_input_template.sh "${@:2}"

$(declare -F prepare)

read_keyboard_input

execute
