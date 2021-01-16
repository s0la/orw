#!/bin/bash

read_keyboard_input() {
	$(declare -F get_argument_count)

	read_command="read -rsn ${argument_count:-1} input && echo \$input > $named_pipe"
	termite -t input --class=input -e "bash -c '$read_command'" &> /dev/null &

	read input < $named_pipe
	evaluate $input

	[[ $stop ]] || read_keyboard_input
}

named_pipe=/tmp/keyboard_input
[[ -p $named_pipe ]] && rm $named_pipe
mkfifo $named_pipe

#read window_x window_y <<< $(~/.orw/scripts/get_window_position.sh)
input_size=60
padding=$(awk '/padding/ { print $NF * 2; exit }' ~/.config/gtk-3.0/gtk.css)

#[[ ! "${BASH_SOURCE[0]}" =~ "$0" ]] &&
#	read window_x window_y window_width window_height <<< $(~/.orw/scripts/windowctl.sh -p | cut -d ' ' -f 3-)

if [[ "${BASH_SOURCE[0]}" =~ "$0" ]]; then
	read window_x window_y window_width window_height <<< $(~/.orw/scripts/windowctl.sh -p | cut -d ' ' -f 3-)

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
	input_x=$((x - display_x + (w - size) / 2))
	input_y=$((y - display_y + (h - size) / 2))
fi

~/.orw/scripts/set_geometry.sh -c input -x $input_x -y $input_y -w $size -h $size

source ~/.orw/scripts/${1}_input_template.sh "${@:2}"

$(declare -F prepare)
read_keyboard_input
execute
