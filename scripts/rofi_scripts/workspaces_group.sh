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
	read {switch,wall,move}_icon <<< \
		$(awk -F '=' '/Workspace_(switch|wallpaper|move)/ { print $NF }' ~/.orw/scripts/icons | xargs)
	rofi -format 'i' -modi "$switch_icon:$0 switch,$wall_icon:$0 wall,$move_icon:$0 move" -show  -theme sidebar
else
	case $# in
		1)
			workspace=$(xdotool get_desktop)
			printf "\0active\x1f$workspace\n"
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

				wmctrl -ir $id -t ${workspaces[$workspace]}
			fi

			wmctrl -s ${workspaces[$workspace]}
			[[ $action == wall ]] && ~/.orw/scripts/wallctl.sh -r &
	esac
fi
