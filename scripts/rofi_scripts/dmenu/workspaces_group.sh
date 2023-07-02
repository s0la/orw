#!/bin/bash

get_workspaces() {
	awk '
		/<\/?names>/ { wn = (wn + 1) % 2 }

		wn && /<name>/ {
			gsub("\\s*<[^>]*>", "")
			printf "[%s]=%d ", $0, wsc++
		}' ~/.config/openbox/rc.xml
}

declare -A workspaces
eval workspaces=( $(get_workspaces) )

if [[ -z $@ ]]; then
	rofi -format 'i' -modi ":$0 switch,:$0 wall,:$0 move,:$0 tiling" -show  -theme sidebar
else
	case $# in
		1)
			for ws in ${!workspaces[*]}; do
				echo ${workspaces[$ws]}, $ws
			done | sort -nk 1,1 | cut -d ' ' -f 2
			;;
		*)
			read action workspace <<< "$@"

			if [[ $action == move ]]; then
				id=$(xdotool getactivewindow)
				~/.orw/scripts/signal_windows_event.sh mv
				wmctrl -ir $id -t ${workspaces[$workspace]}
			fi

			wmctrl -s ${workspaces[$workspace]}
			[[ $action == wall ]] && ~/.orw/scripts/wallctl.sh -r &
	esac
fi

exit

path=~/.orw/scripts/rofi_scripts
theme=$(awk -F '[".]' 'END { print $(NF - 2) }' ~/.config/rofi/main.rasi)
#[[ $theme =~ icons|dmenu ]] && ${path%/*}/set_rofi_geometry.sh workspaces
#${path%/*}/set_rofi_width.sh workspaces
#${path%/*}/set_rofi_margins.sh

modis+="wall:$path/workspaces.sh wall,"
modis+="workspaces:$path/workspaces.sh,"
modis+="move_to:$path/workspaces.sh move"
rofi -modi "$modis" -show $1 -theme main
