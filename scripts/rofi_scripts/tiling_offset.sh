#!/bin/bash

theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)

if [[ $theme != icons ]]; then
	x_up='x up' x_down='x down' y_up='y up' y_down='y down' sep=' '
fi

list_options() {
	cat <<- EOF
		$sep$x_down
		$sep$x_up
		$sep$y_up
		$sep$y_down
	EOF
}

if [[ -z $@ ]]; then
	list_options
else
	[[ $@ =~ [0-9]+ ]] && value=${@##* }

	[[ $@ =~ ^(|) ]] && direction=+ || direction=-
	[[ $@ =~ ^(|) ]] && orientation=x || orientation=y

	default_value=$(awk '/^offset/ { print ($NF == "true") ? 50 : 10 }' ~/.config/orw/config)
	~/.orw/scripts/borderctl.sh w$orientation $direction${value-$default_value}

	list_options
fi


