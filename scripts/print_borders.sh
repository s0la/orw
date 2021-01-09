#!/bin/bash

#tty=$(tty)
[[ $1 ]] || id=$(wmctrl -l | awk '$2 >= 0 { print $1; exit }')

#if [[ $tty =~ ^not || $1 ]]; then
if [[ -z $id ]]; then
	fifo=/tmp/borders.fifo
	mkfifo $fifo

	~/.orw/scripts/set_geometry.sh -c size -w 120 -h 120
	termite -t get_borders --class=custom_size -e \
		"/bin/bash -c '~/.orw/scripts/get_borders.sh > $fifo'" &> /dev/null &

	read x_border y_border < $fifo
	rm $fifo
else
	read x_border y_border <<< $(~/.orw/scripts/get_borders.sh)
fi

echo $x_border $y_border
