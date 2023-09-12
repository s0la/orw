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
	#[[ $event != edge ]] &&
	#	((value *= 50)) ||
	#	~/.orw/scripts/windowctl.sh move -${property^}

	[[ $event == edge ]] &&
		~/.orw/scripts/windowctl.sh move -${property^} && exit

	#if [[ $event != edge ]]; then
	#	((value *= 50))
	#else
	#	~/.orw/scripts/windowctl.sh move -${property^}
	#	exit
	#fi
fi

#((is_tiling)) || ((value *= 50))
echo $is_tiling, $value

parse_properties() {
	xwininfo -id $id | awk '
		/Absolute/ { p[++pi] = $NF; if(/X/) x = $NF; else y = $NF }
		/Relative/ { if(/X/) xb = $NF; else yb = $NF }
		/Width/ { p[++pi] = $NF; w = $NF }
		/Height/ { p[++pi] = $NF; h = $NF }
		END {
			t = '${is_tiling:-0}'
			m = ("'"$event"'" == "move")
			pi = ("'"$property"'" ~ "[tb]") ? 4 : 3

			#if (("'"$property"'" ~ "[lt]") || (!t && m))
			if ("'"$property"'" ~ "[lt]" || (!t && m))
				p[pi - 2] '$opposite_sign'= '$value'
			if (!m) p[pi] '$sign'= '$value'

			printf "0,%d,%d,%d,%d\n", \
				p[1] - xb, p[2] - yb, p[3], p[4]
		}'
}

#parse_properties() {
#	xwininfo -id $id | awk '
#		/Absolute/ { p[++pi] = $NF; if(/X/) x = $NF; else y = $NF }
#		/Relative/ { if(/X/) xb = $NF; else yb = $NF }
#		/Width/ { p[++pi] = $NF; w = $NF }
#		/Height/ { p[++pi] = $NF; h = $NF }
#		END {
#			t = '${is_tiling:-0}'
#			pi = ("'"$property"'" ~ "[tb]") ? 4 : 3
#			#if ("'"$property"'" ~ "[lt]") p[pi - 2] '$opposite_sign'= '$value'
#			if (t && "'"$property"'" ~ "[lt]")
#				p[pi - 2] '$opposite_sign'= '$value'
#			if ("'"$event"'" == "move" && !t) pi -= 2
#			p[pi] '$sign'= '$value'
#			printf "0,%d,%d,%d,%d\n", \
#				p[1] - xb, p[2] - yb, p[3], p[4]
#		}'
#}

#.orw/scripts/windowctl.sh -p

#if [[ ! -f /tmp/wmctrl_lock ]]; then
wmctrl -ir $id -e $(parse_properties)
#((is_tiling)) && ~/.orw/scripts/signal_windows_event.sh $event
~/.orw/scripts/signal_windows_event.sh $event
#fi
exit

spy_pid=$(ps aux | awk '/bash.*sws.sh$/ { if((pid && $2 < pid) || !pid) pid = $2 } END { print pid }')
((spy_pid)) && kill -USR2 $spy_pid
exit

resize() {
	wmctrl -lG | awk '
		$1 == "'"$id"'" {
			f = ("'"$property"'" ~ "[tb]") ? 6 : 5
			$f '$sign'= '$value'
			printf "wmctrl -ir %s -e 0,%d,%d,%d,%d", \
				$1, $3, $4, $5, $6
		}'
}

$(resize)

#echo $sign, $opposite_sign, $value
