#!/bin/bash

sw_bg="#4c4e4f"
sw_main_bg="%{B$sw_bg}"

ws_width="%{O250}"
ws_fg="%{B#abaeb2}"
ws_dark_fg="%{B#7b7e82}"

geometry=$(wmctrl -lG | awk '/main_bar/ {print $5 "x" $6 "+" $3 "+" $4}')

killall main.sh lemonbar && sleep 0.2 2> /dev/null
command="sleep 0.35 && killall ${0##*\/} lemonbar && sleep 0.2 && ~/.orw/scripts/bar.sh"

while true; do
		workspace_count=$(xdotool get_num_desktops)
		current_workspace=$(($(xdotool get_desktop) + 1))

		workspaces=''
		for workspace in $(seq $workspace_count); do
		    [[ $workspace -lt $workspace_count ]] && offset="%{O5}" || offset=''
			[[ $workspace -eq $current_workspace ]] && ws_bg=$ws_fg || ws_bg=$ws_dark_fg
			workspaces+="%{A:wmctrl -s $((workspace - 1)) && $command:}$ws_bg$ws_width%{A}$sw_main_bg$offset"
		done

		echo -e "$sw_main_bg%{U$sw_bg}%{+u}%{+o}%{c}$ws_dark_fg$sw_main_bg%{O20}$workspaces%{O20}$sw_main_bg"
		sleep 0.1
done | lemonbar -B$sw_bg -g $geometry -u 5 -n workspace_switcher | bash
