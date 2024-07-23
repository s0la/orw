#!/bin/bash

read_keyboard_input() {
	$(declare -F get_argument_count)

	read_command="read -rsn ${argument_count:-1} input && echo \$input > $named_pipe"
	alacritty -t input --class=input -e bash -c "$read_command" &> /dev/null &

	read input < $named_pipe
	evaluate $input

	[[ $stop ]] || read_keyboard_input
}

named_pipe=/tmp/keyboard_input
[[ -p $named_pipe ]] && rm $named_pipe
mkfifo $named_pipe

input_size=60
padding=$(awk '/padding/ { print $NF * 2; exit }' ~/.config/gtk-3.0/gtk.css)

get_window_properties() {
	xwininfo -int -id $(xdotool getactivewindow) | awk '
			/Absolute/ { if(/X/) x = $NF; else y = $NF }
			/Relative/ { if(/X/) xb = $NF; else yb = $NF }
			/Width/ { w = $NF }
			/Height/ { print x - xb, y - yb, w, $NF }'
}

if [[ "${BASH_SOURCE[0]}" =~ "$0" ]]; then
	read window_x window_y window_width window_height <<< $(get_window_properties)

	read size input_x input_y <<< $(awk '\
		BEGIN {
			x = '$window_x'
			y = '$window_y'
			w = '$window_width'
			h = '$window_height'
			s = '$input_size' + '$padding'
		}

		/^display/ { 
			if($1 ~ /xy$/) {
				dx = $2
				dy = $3
			} else if($1 ~ /size$/) {
				if(dx + $2 > x && dy + $3 > y) {
					print s, x - dx + int((w - s) / 2), y - dy + int((h - s) / 2)
					exit
				}
			}
		}' ~/.config/orw/config)
else
	size=$((input_size + padding))
	input_x=$((x - display_x))
	input_y=$((y - display_y))
fi

source ~/.orw/scripts/${1}_input_template.sh "${@:2}"

$(declare -F prepare)

read_keyboard_input() {
	while [[ ! $stop ]]; do
		$(declare -F get_argument_count)

		read_command="read -rsn ${argument_count:-1} input && echo \$input > $named_pipe"
		alacritty -t input --class=input -e bash -c "$read_command" &> /dev/null &

		read input < $named_pipe
		evaluate $input

		((input_count+=2))
	done

	unset stop
}

if [[ ${@: -1} != source ]]; then
	~/.orw/scripts/set_geometry.sh -c input \
		-x $input_x -y $input_y -w $size -h $size
	read_keyboard_input
	execute
fi
