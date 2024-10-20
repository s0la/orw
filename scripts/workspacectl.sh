#!/bin/bash

#[[ $1 == add ]] && sign=+ || sign=-
action="$1"
workspace_name="$2"
workspace_to_restore="$3"
[[ $action == add ]] && direction=1 || direction=-1

if [[ $1 == add ]]; then
	if [[ ! $workspace_name ]]; then
		fifo=/tmp/workspace_name.fifo
		[[ -p $fifo ]] && rm $fifo
		mkfifo $fifo

		command="read -p 'Enter workspace name: ' workspace_name && echo \"\$workspace_name\" > $fifo"

		width=300
		height=100

		window_id=$(xdotool getactivewindow)
		read window_x window_y <<< $(xwininfo -int -id $window_id |
			awk '/Absolute/ { print $NF }' | xargs)
		read x y <<< $(~/.orw/scripts/get_display.sh $window_x $window_y |
			awk '{ print int(($4 - '$width') / 2), int(($5 - '$height') / 2) }')

		~/.orw/scripts/set_geometry.sh -t input -x $x -y $y -w 300 -h 100
		alacritty -t workspace_name_input -e bash -c "$command" &> /dev/null &

		read workspace_name < $fifo
		rm $fifo
	fi
else
	if ((!(${#workspace_name} > 1))); then
		[[ $workspace_name ]] &&
			workspace_icon=$workspace_name ||
			read workspace_{index,icon} <<< $(~/.orw/scripts/rofi_scripts/dmenu.sh workspaces move)
		workspace_name=$(sed -n "/Workspace.*$workspace_icon$/ s/Workspace_\|=.*//gp" ~/.orw/scripts/icons)
	fi
fi

current_workspace=$(xdotool get_desktop)

read workspace_{count,index} <<< $(awk -i inplace '
	BEGIN { d = '$direction' }

	function get_value() {
		#return gensub("[^>]*>([^<]*).*", "\\1", 1)
		value = $0
		gsub("\\s*<[^>]*.", "", value)
		return value
	}

	/<number>/ {
		n = get_value()
		sub(n, n + d)
	}

	/<\/?names>/ { wn = !wn }

	wn && /<name>/ {
		cwn = get_value()
		if (cwn ~ "^tmp(_[0-9])?$") tw++
		if (d < 0 && cwn == "'$workspace_name'") { r = s = 1; wi = wc }
		if (d > 0 && '$current_workspace' == wc) {
			s = 1
			nw = $0
			wi = wc
			#nwn = ("'$workspace_name'") ? "'$workspace_name'" : (tw) ? "tmp_" tw : "tmp"
			sub(cwn, "new_workspace_name", nw)
			wo = wo "\n" $0 "\n" nw
		}
		wc++
	} {
		if (s) s = 0
		else wo = wo "\n" $0
	} END {
		print n + d, (wi) ? wi : 0
		sub("new_workspace_name", ("'$workspace_name'") ? "'$workspace_name'" : \
			(tw) ? "tmp_" tw : "tmp", wo)
		print substr(wo, 2)
	}' ~/.config/openbox/rc.xml |
		{ read -r wo; { echo "$wo" >&1; cat > ~/.config/openbox/rc.xml; } })
openbox --reconfigure

if [[ $action == add ]]; then
	wmctrl -n $workspace_count
else
	if [[ ! $workspace_to_restore ]]; then
		workspace_to_restore=$((current_workspace - (current_workspace >= workspace_index)))
		window_id="$(xdotool getactivewindow 2> /dev/null)"
	fi

	wmctrl -s $workspace_to_restore
fi

while read new_workspace id; do
	wmctrl -ir $id -t $new_workspace
	[[ $action == remove && ! $window_id && $new_workspace == $workspace_to_restore ]] && window_id=$id
done <<< $(wmctrl -lG | awk '$2 > '$workspace_index' { print $2 + '$direction', $1 }' | sort -nk 1,1)

if [[ $action == remove ]]; then
	wmctrl -n $workspace_count
	[[ $window_id ]] && sleep 0.1 && wmctrl -ia $window_id
	~/.orw/scripts/notify.sh -s osd -i '*' "REMOVED: $workspace_name"
else
	wmctrl -s $((current_workspace + 1))
	echo -n ' 1'
fi
