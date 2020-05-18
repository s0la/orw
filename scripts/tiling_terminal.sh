#!/bin/bash

getopts t: title
[[ $title ]] && title=$OPTARG arguments="${@:3}"
#[[ $@ =~ ^-t ]] && title=$2 arguments="${@:3}"

desktop=$(xdotool get_desktop)
window_count=$(wmctrl -l | awk '$2 == '$desktop' { wc++ } END { print wc }')

if ((window_count)); then
	read mode ratio <<< $(awk '/^(mode|part|ratio)/ {
			if(/mode/) m = $NF
			else if(/part/ && $NF) p = $NF
			else if(/ratio/) r = p "/" $NF
		} END { print m, r }' ~/.config/orw/config | xargs)

	read monitor x y width height <<< $(~/.orw/scripts/windowctl.sh resize H a $ratio)
	~/.orw/scripts/set_class_geometry.sh -c tiling -m $monitor -x $x -y $y -w $width -h $height

	eval termite --class=tiling -t ${title:-termite$window_count} "${arguments:-$@}" &> /dev/null &
	#eval termite --class=tiling -t termite$window_count "${arguments#* }" &> /dev/null &
	#termite --class=tiling -t termite$window_count ${@:1} &> /dev/null &
else
	~/.orw/scripts/tile_terminal.sh ${@:1}
fi
