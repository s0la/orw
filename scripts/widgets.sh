#!/bin/bash

music() {
	if [[ $1 == -k ]]; then
		~/.orw/scripts/barctl.sh -b mw* -k &
		tmux -S /tmp/ncmpcpp kill-session -t visualizer
	else
		~/.orw/scripts/barctl.sh -b mw*
		~/.orw/scripts/ncmpcpp.sh -w 100 -h 100 -Vv -L "-n visualizer -M mwi x,y,w move -t 300 resize -B" -i
	fi
}

weather() {
	~/.orw/scripts/barctl.sh -b ww* $1
}

$@
