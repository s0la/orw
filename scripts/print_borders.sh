#!/bin/bash

tty=$(tty)

if [[ $tty =~ ^not || $1 ]]; then
	fifo=/tmp/borders.fifo
	mkfifo $fifo

	~/.orw/scripts/set_geometry.sh -c size -w 120 -h 120
	termite -t get_borders --class=custom_size -e \
		"/bin/bash -c '~/Desktop/get_borders.sh > $fifo'" &> /dev/null &

	read x_border y_border < $fifo
	rm $fifo
else
	read x_border y_border <<< $(~/Desktop/get_borders.sh)
fi

echo $x_border $y_border
