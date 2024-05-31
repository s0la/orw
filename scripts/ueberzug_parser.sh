#!/bin/bash

close_cover_art() {
	rm $fifo
	killall ueberzug
}

#fifo=~/.config/ncmpcpp/cover_art_fifo.fifo
fifo=/tmp/cover_art_fifo.fifo
[[ ! -p $fifo ]] && mkfifo $fifo
	#echo making $fifo && mkfifo $fifo

trap close_cover_art EXIT

#tail -f $fifo | ueberzugpp layer --silent --parser bash &> /dev/null
tail -f $fifo | ueberzug layer --silent --parser bash &> /dev/null
