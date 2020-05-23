#!/bin/bash

getopts t: title
[[ $title ]] && title=$OPTARG arguments="${@:3}"

desktop=$(xdotool get_desktop)
window_count=$(wmctrl -l | awk '$2 == '$desktop' { wc++ } END { print wc }')

if ((window_count)); then
	#read mode ratio <<< $(awk '/^(mode|part|ratio)/ {
	#		if(/mode/) m = $NF
	#		else if(/part/ && $NF) p = $NF
	#		else if(/ratio/) r = p "/" $NF
	#	} END { print m, r }' ~/.config/orw/config | xargs)

	#ratio=$(awk '/^(part|ratio)/ { if(!p) p = $NF; else { print p "/" $NF; exit } }' ~/.config/orw/config)

	read monitor x y width height <<< $(~/.orw/scripts/windowctl.sh resize -H a)
	#echo $x $y $width $height
	#~/.orw/scripts/windowctl.sh resize -h $width -v $height move -h $x -v $y
	~/.orw/scripts/set_geometry.sh -c '\\*' -m $monitor -x $x -y $y -w $width -h $height
fi
