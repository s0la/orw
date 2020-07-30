#!/bin/bash

theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)

if [[ $theme != icons ]]; then
	x_up='x up' x_down='x down' y_up='y up' y_down='y down' sep=' '
fi

icon_x_down=
icon_x_up=
icon_y_up=
icon_y_down=

list_options() {
	cat <<- EOF
		$icon_x_down$sep$x_down
		$icon_x_up$sep$x_up
		$icon_y_up$sep$y_up
		$icon_y_down$sep$y_down
	EOF
}

if [[ -z $@ ]]; then
	list_options
else
	[[ $@ =~ [0-9]+ ]] && value=${@##* }

	[[ $@ =~ ^($icon_x_up|$icon_y_up) ]] && direction=+ || direction=-
	[[ $@ =~ ^($icon_x_up|$icon_x_down) ]] && orientation=x || orientation=y

	default_value=$(awk '/^offset/ { print ($NF == "true") ? 50 : 10 }' ~/.config/orw/config)
	~/.orw/scripts/borderctl.sh w$orientation $direction${value-$default_value}

	list_options
fi
