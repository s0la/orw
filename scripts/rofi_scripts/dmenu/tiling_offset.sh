#!/bin/bash

#mode=$(awk '/^mode/ { print $NF }' ~/.config/orw/config)
theme=$(awk -F '[".]' 'END { print $(NF - 2) }' ~/.config/rofi/main.rasi)

if [[ $theme != icons ]]; then
	x_up='x up' x_down='x down' y_up='y up' y_down='y down' sep=' '
fi

icon_x_down=
icon_x_up=
icon_y_up=
icon_y_down=

icon_x_down=
icon_x_up=
icon_y_up=
icon_y_down=

icon_x_down=
icon_x_up=
icon_y_up=
icon_y_down=

list_options() {
	cat <<- EOF
		$icon_x_down$sep$x_down
		$icon_x_up$sep$x_up
		$icon_y_up$sep$y_up
		$icon_y_down$sep$y_down
	EOF
}

#list_options() {
#	cat <<- EOF | rofi -dmenu -format 'i s' -selected-row ${row:-0} -theme main
#		$icon_x_down$sep$x_down
#		$icon_x_up$sep$x_up
#		$icon_y_up$sep$y_up
#		$icon_y_down$sep$y_down
#	EOF
#}
#
#while
#	read row option <<< $(list_options)
#	[[ $option ]]
#do
#	[[ $option =~ [0-9]+ ]] && value=${@##* }
#
#	[[ $option =~ ^($icon_x_up|$icon_y_up) ]] && direction=+ || direction=-
#	[[ $option =~ ^($icon_x_up|$icon_x_down) ]] && orientation=x || orientation=y
#
#	awk -i inplace '/^'$orientation'_offset/ {
#			$NF '$direction'= '${value:-20}'
#		} { print }' ~/.config/orw/config
#	~/.orw/scripts/signal_windows_event.sh update
#	#message=$(awk '/^'$orientation'_offset/ { $NF '$direction'= '${value:-20}'; print }' \
#	#	~/.config/orw/config)
#	#~/.orw/scripts/notify.sh "MSG: $message"
#done
#exit

if [[ -z $@ ]]; then
	#~/.orw/scripts/notify.sh -r 303 -s osd -i   OFFSET &

	list_options
else
	[[ $@ =~ [0-9]+ ]] && value=${@##* }

	[[ $@ =~ ^($icon_x_up|$icon_y_up) ]] && direction=+ || direction=-
	[[ $@ =~ ^($icon_x_up|$icon_x_down) ]] && orientation=x || orientation=y

	default_value=$(awk '/^offset/ { print ($NF == "true") ? 50 : 10 }' ~/.config/orw/config)
	~/.orw/scripts/borderctl.sh w$orientation $direction${value:-$default_value}
	#[[ $mode != floating ]] && ~/.orw/scripts/offset_tiled_windows.sh $orientation $direction ${value:-$default_value}

	list_options
fi
