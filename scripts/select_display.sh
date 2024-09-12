#!/bin/bash

icon=
icon=
display=$1
new_display=${2:-$display}

#read x y <<< $(awk '
#	/[xy]_offset/ { if (/^x/) xo = $NF; else yo = $NF }
#	/display_'"$display"'/ {
#		if ($1 ~ "xy") { x = $2; y = $3 }
#		if ($1 ~ "offset") { print x + xo, y + yo + $2 }
#	}' ~/.config/orw/config)

read x y <<< $(awk '
	/[xy]_offset/ { o[++oi] = $NF }
	/display_'"$new_display"'_offset/ { print o[1], o[2] + $2 }' ~/.config/orw/config)

~/.orw/scripts/notify.sh -s osd -i $icon "DISPLAY: $new_display" 2> /dev/null &
~/.orw/scripts/set_geometry.sh -c '\\\*' -x $x -y $y -m $display
openbox --reconfigure
