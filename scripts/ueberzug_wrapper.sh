#!/usr/bin/env bash

#fifo=~/.config/ncmpcpp/cover_art_fifo.fifo
fifo=/tmp/cover_art_fifo.fifo

if [ -p $fifo ]; then
    if [[ "$1" == "draw" ]]; then
        declare -p -A cmd=([action]=add [identifier]="cover_art"
		   [x]="$2" [y]="$3" [width]="$4" [height]="$5" [path]="$6") > $fifo
	else
        declare -p -A cmd=([action]=remove [identifier]="cover_art") > $fifo
	fi
else
	mkfifo $fifo
fi
