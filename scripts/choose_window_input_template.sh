#!/bin/bash

prepare() {
	~/.orw/scripts/windowctl_top_bottom.sh -x 100 -y 100 -m 20 -S -g
}

evaluate() {
	window_index=$1
	stop=true
}

execute() {
	current_desktop=$(xdotool get_desktop)
	id=$(wmctrl -lG | awk '$2 == '$current_desktop'' | sort -nk 4,3 | awk 'NR == '$window_index' { print $1 }')

	~/.orw/scripts/windowctl_top_bottom.sh -x 100 -y 100 -i $id -s move -h 1/1 -v 1/1 resize -h 1/1 -v 1/1
}
