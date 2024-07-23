#!/bin/bash

while getopts :w:h: flag; do
	case $flag in
		w) width=$OPTARG;;
		h) height=$OPTARG;;
		*) continue
	esac

	(( arg_count += 2 ))
done

((arg_count)) && shift $arg_count

desktop=$(xdotool get_desktop)
is_tiling=$(awk '/^tiling_workspaces/ { print (/\s'$desktop'\s/) }' \
	~/.orw/scripts/spy_windows.sh)

((is_tiling)) &&
	geometry='100x100' || geometry="${width:-450}x${height:-600}"

eval sxiv -tbg $geometry "$@" &
