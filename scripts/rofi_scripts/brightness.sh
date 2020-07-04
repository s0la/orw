#!/bin/bash

theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)

if [[ $theme != icons ]]; then
	default='default' up='brightness up' down='brightness down' sep=' '
fi

if [[ -z $@ ]]; then
	cat <<- EOF
		$sep$default
		$sep$up
		$sep$down
	EOF
else
	case $@ in
		*) default_value=50;;
		*)
			[[ $1 ==  ]] && direction=+ || direction=-
			[[ $@ =~ [0-9]+ ]] && mulitplier=${@: -1}
			[[ $mulitplier ]] && value=$((mulitplier * 10))
	esac

	killall rofi
	~/.orw/scripts/brightnessctl.sh -s $direction${default_value:-${value:-10}}
	#~/Desktop/set_brightness.sh $direction ${default_value:-10}
fi
