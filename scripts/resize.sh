#!/bin/bash

property=$1
sign=${2//[0-9]}
value=${2#$sign}
[[ $3 ]] &&
	event=$3 || event=resize

[[ ${sign:=+} == - ]] &&
	opposite_sign=+ || opposite_sign=-

id=$(printf '0x%.8x' $(xdotool getactivewindow))

workspace=$(xdotool get_desktop)
is_tiling=$(awk \
	'/^tiling_workspace/ { if (/'$workspace'/) print 1 }' ~/.orw/scripts/spy_windows.sh)

if ((is_tiling)); then
	[[ $event == edge ]] && event=swap
else
	[[ $event == edge ]] &&
		~/.orw/scripts/windowctl.sh move -${property^} && exit
fi

echo $is_tiling, $value

parse_properties() {
	xwininfo -id $id | awk '
		/Absolute/ { p[++pi] = $NF; if(/X/) x = $NF; else y = $NF }
		/Relative/ { if(/X/) xb = $NF; else yb = $NF }
		/Width/ { p[++pi] = $NF; w = $NF }
		/Height/ { p[++pi] = $NF; h = $NF }
		/Corners/ { ax = $NF; gsub("^.|.[0-9]*$", "", ax) }
		/geometry/ { ay = $NF; sub("^.*[^0-9]", "", ay) }

		END {
			t = '${is_tiling:-0}'
			m = ("'"$event"'" == "move")
			pi = ("'"$property"'" ~ "[tb]") ? 4 : 3

			if ("'"$property"'" ~ "[lt]" || (!t && m))
				p[pi - 2] '$opposite_sign'= '$value'
			if (!m) p[pi] '$sign'= '$value'

			if (p[1] != ax) p[1] -= xb
			if (p[2] != ay) p[2] -= yb

			printf "0,%d,%d,%d,%d\n", \
				p[1] - 0, p[2] - 0, p[3], p[4]
		}'
}

wmctrl -ir $id -e $(parse_properties)
~/.orw/scripts/signal_windows_event.sh $event
