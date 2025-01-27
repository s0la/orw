#!/bin/bash

[[ $1 ]] || id=$(wmctrl -l | awk '$2 >= 0 { print $1; exit }')

toggle_decor_state() {
	awk -F '[<>]' '
			/class=.*custom_size/ { aw = 1 }

			aw && /<decor>/ {
				cds = $3
				nds = ("'"$1"'") ? "'"$1"'" : ($3 == "no") ? "yes" : "no"
				sub($3, nds)
				aw = 0
			}

			{ wo = wo "\n" $0 }

			END {
				print cds wo
			}' ~/.config/openbox/rc.xml |
				{ read cd; { echo $cd >&1; cat > ~/.config/openbox/rc.xml; } }

	openbox --reconfigure
}

current_decor_state=$(toggle_decor_state yes)

#current_workspace=$(xdotool get_desktop)
#
#tiling_workspaces=$(sed -n '/^tiling/ s/.*(\s*\|\s*)//gp' \
#	~/.orw/scripts/spy_windows.sh | tr ' ' '\n')
#
#floating_workspace=$(comm -3 \
#	<(wmctrl -d | cut -d ' ' -f 1) \
#	<(echo -e "$tiling_workspaces") | head -1)
#
#wmctrl -s $floating_workspace

fifo=/tmp/borders.fifo
mkfifo $fifo

~/.orw/scripts/set_geometry.sh -c size -w 120 -h 120
alacritty -t get_borders --class=custom_size -e \
	/bin/bash -c "~/.orw/scripts/get_borders.sh > $fifo" &> /dev/null &

read x_border y_border < $fifo
rm $fifo

#wmctrl -s $current_workspace
echo $x_border $y_border

toggle_decor_state ${current_decor_state} &> /dev/null
