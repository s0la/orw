#!/bin/bash

desktop=$(xdotool get_desktop)
window_count=$(wmctrl -l | awk '$2 == '$desktop' { wc++ } END { print wc }')

[[ $1 ]] && mode=$1 || mode=$(awk '/^mode/ { print $NF }' ~/.config/orw/config)
	#mode=$(awk '/class.*(selection|\*)/ { print (/\*/) ? "tiling" : "selection" }' ~/.config/openbox/rc.xml)

if [[ $mode ]]; then
	if [[ $mode != selection ]]; then
		#((window_count)) && read m x y w h <<< $(~/.orw/scripts/windowctl.sh resize -H a)
		((window_count)) && ~/.orw/scripts/windowctl.sh -A
		exit
		((window_count)) && read m x y w h <<< $(~/.orw/scripts/windowctl.sh -A)
	else
		class=selection
		#read m x y w h <<< $(~/.orw/scripts/windowctl.sh -C -p | cut -d ' ' -f 3-)
		read m x y w h <<< $(~/.orw/scripts/windowctl.sh -C -p | awk '{ print $3, $4, $5, $6 - $1, $7 - $2 }')
	fi

	((w && h)) && ~/.orw/scripts/set_geometry.sh -c "${class:-\\\*}" -m $m -x $x -y $y -w $w -h $h
fi
