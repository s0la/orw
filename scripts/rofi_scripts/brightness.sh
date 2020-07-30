#!/bin/bash

theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)

if [[ $theme != icons ]]; then
	default='default' up='brightness up' down='brightness down' sep=' '
fi

icon_up=
icon_down=
icon_default=

if [[ -z $@ ]]; then
	cat <<- EOF
		$icon_up$sep$up
		$icon_default$sep$default
		$icon_down$sep$down
	EOF
else
	case $@ in
		$icon_default*) default_value=50;;
		*)
			[[ $1 == $icon_up ]] && direction=+ || direction=-
			[[ $@ =~ [0-9]+ ]] && mulitplier=${@: -1}
			[[ $mulitplier ]] && value=$((mulitplier * 10))
	esac

	killall rofi
	#~/.orw/scripts/brightnessctl.sh -s $direction${default_value:-${value:-10}}
	~/Desktop/set_brightness.sh $direction ${default_value:-10}
fi
