#!/bin/bash

theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)

if [[ $theme != icons ]]; then
	part_up='part up' part_down='part down' ratio_up='ratio up' ratio_down='ratio down' sep=' '
fi

list_options() {
	cat <<- EOF
		$sep$part_down
		$sep$part_up
		$sep$ratio_up
		$sep$ratio_down
	EOF
}

if [[ -z $@ ]]; then
	list_options
else
	[[ $@ =~ [0-9]+ ]] && value=${@##* }

	[[ $@ =~ ^(|) ]] && direction=+ || direction=-
	[[ $@ =~ ^(|) ]] && property=part || property=ratio

	~/.orw/scripts/borderctl.sh w${property:0:1} $direction${value-1}

	list_options
fi

