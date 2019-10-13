#!/bin/bash

set_size_hints() {
	sed -i "s/\(.*size_hints.*\) .*/\1 $1/" .config/termite/config
}

read x y <<< $(~/.orw/scripts/get_window_position.sh)

~/.orw/scripts/termite_geometry.sh -x $x -y $y -w 10 -h 10

set_size_hints true

termite -t calibrate --class=input \
	-e "bash -c '~/.orw/scripts/execute_on_terminal_startup.sh calibrate ~/.orw/scripts/calibrate_steps.sh'"

set_size_hints false
