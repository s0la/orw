#!/bin/bash

[[ $1 == add ]] && sign=+ || sign=-

if [[ $2 ]]; then
	workspace_name=$2
else
	if [[ $1 == add ]]; then
		fifo=/tmp/workspace_name.fifo
		[[ -p $fifo ]] && rm $fifo
		mkfifo $fifo

		command="read -p 'Enter workspace name: ' workspace_name && echo \"\$workspace_name\" > $fifo"

		width=300
		height=100

		#read window_x window_y <<< $(~/.orw/scripts/windowctl.sh -p | cut -d " " -f 3,4)
		window_id=$(xdotool getactivewindow)
		read window_x window_y <<< $(xwininfo -int -id $window_id |
			awk '/Absolute/ { print $NF }' | xargs)
		read x y <<< $(~/.orw/scripts/get_display.sh $window_x $window_y |
			awk '{ print int(($4 - '$width') / 2), int(($5 - '$height') / 2) }')

		~/.orw/scripts/set_geometry.sh -t input -x $x -y $y -w 300 -h 100
		alacritty -t workspace_name_input -e bash -c "$command" &> /dev/null &

		read workspace_name < $fifo
		rm $fifo
	else
		workspace_name=$(wmctrl -d | awk '{ print $NF }' | rofi -dmenu -p 'remove workspace' -theme list)
	fi
fi

workspace_count=$(awk -i inplace '
	function get_value() {
		return gensub("[^>]*>([^<]*).*", "\\1", 1)
	}

	/<number>/ {
		n = get_value()
		sub(n, n '$sign' 1)
	}

	/<\/?names>/ { wn = (wn + 1) % 2 }

	wn && /<name>/ {
		wc++
		cwn = get_value()

		#if(cwn ~ "^[0-9]$") wnn++
		if(cwn ~ "^tmp(_[0-9])?$") tw++

		if("'$sign'" == "-" && cwn == "'$workspace_name'") r = s = 1

		if(n == wc) {
			if(!r) s = 1
			#if("'$sign'" == "+")
			#	wo = wo "\n" $0 "\n" gensub(cwn, ("'$workspace_name'") ? "'$workspace_name'" : wnn + 1, 1)
			if("'$sign'" == "+") {
				nwn = ("'$workspace_name'") ? "'$workspace_name'" : (tw) ? "tmp_" tw : "tmp"
				wo = wo "\n" $0 "\n" gensub(cwn, nwn, 1)
			}
		}
	} {
		if(s) s = 0
		else wo = wo "\n" $0
	} END {
		print n '$sign' 1
		print substr(wo, 2)
	}' ~/.config/openbox/rc.xml |
		{ read -r wo; { echo "$wo" >&1; cat > ~/.config/openbox/rc.xml; } })

openbox --reconfigure
wmctrl -n $workspace_count
