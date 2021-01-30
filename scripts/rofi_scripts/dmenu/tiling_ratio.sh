#!/bin/bash

theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)

if [[ $theme != icons ]]; then
	part_up='part up' part_down='part down' ratio_up='ratio up' ratio_down='ratio down' sep=' '
fi

icon_part_down=
icon_part_up=
icon_ratio_up=
icon_ratio_down=

icon_part_down=
icon_part_up=
icon_ratio_up=
icon_ratio_down=

icon_part_down=
icon_part_up=
icon_ratio_up=
icon_ratio_down=

list_options() {
	cat <<- EOF
		$icon_part_down$sep$part_down
		$icon_part_up$sep$part_up
		$icon_ratio_up$sep$ratio_up
		$icon_ratio_down$sep$ratio_down
	EOF
}

if [[ -z $@ ]]; then
	list_options
else
	[[ $@ =~ [0-9]+ ]] && value=${@##* }

	[[ $@ =~ ^($icon_ratio_up|$icon_part_up) ]] && direction=+ || direction=-
	[[ $@ =~ ^($icon_part_up|$icon_part_down) ]] && property=part || property=ratio

	~/.orw/scripts/borderctl.sh w${property:0:1} $direction${value-1}

	list_options
fi
