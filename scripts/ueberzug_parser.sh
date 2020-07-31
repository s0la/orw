#!/bin/bash

close_cover_art() {
	rm $fifo
	killall ueberzug
}

fifo=~/.config/ncmpcpp/cover_art_fifo.fifo
[[ -p $fifo ]] || mkfifo $fifo

trap close_cover_art EXIT

tail -f $fifo | ueberzug layer --silent --parse bash &> /dev/null
