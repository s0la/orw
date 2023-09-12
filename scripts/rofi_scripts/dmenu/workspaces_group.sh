#!/bin/bash

proceed_changing_workspace() {
	return
}

trap proceed_changing_workspace USR1

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
	#rofi -format 'i' -modi ":$0 switch,:$0 wall,:$0 move,:$0 tiling" -show  -theme sidebar
	#rofi -format 'i' -modi ":$0 switch,:$0 wall,:$0 move" -show  -theme sidebar
	#rofi -format 'i' -modi ":$0 switch,:$0 wall,:$0 move" -show  -theme sidebar
	#rofi -format 'i' -modi ":$0 switch,:$0 wall,:$0 move" -show  -theme sidebar

	#rofi -format 'i' -modi ":$0 switch,:$0 wall,:$0 move" -show  -theme sidebar
	#rofi -format 'i' -modi ":$0 switch,:$0 wall,:$0 move" -show  -theme sidebar

	#rofi -format 'i' -show drun -modes "drun,:$0 switch,:$0 wall,:$0 move" -selected-row 2 -theme sidebar
	rofi -format 'i' -modi ":$0 switch,:$0 wall,:$0 move" -show  -theme sidebar
else
	case $# in
		1)
			workspace=$(xdotool get_desktop)
			#printf "\0active\x1f$workspace\0keep-selection\x1ftrue\0new-selection\x1fmedia\n"
			#printf "\0keep-selection\x1ftrue\0new-selection\x1f2\n"

			printf "\0active\x1f$workspace\n"
			#printf "\0keep-selection\x1ftrue\n"
			#printf "\0new-selection\x1fmedia\n"
			#printf "\0keep-selection\x1ftrue\0new-selection\x1f2\n"
			printf "\0new-selection\x1f2\0keep-selection\x1ftrue\n"

			for ws in ${!workspaces[*]}; do
				echo ${workspaces[$ws]}, $ws
			done | sort -nk 1,1 | cut -d ' ' -f 2
			;;
		*)
			read action workspace <<< "$@"

			if [[ $action == move ]]; then
				id=$(xdotool getactivewindow)
				~/.orw/scripts/signal_windows_event.sh mv

				#while true; do
				#	#echo waiting
				#	#sleep 0.1
				#	continue
				#done &
				#wait

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
