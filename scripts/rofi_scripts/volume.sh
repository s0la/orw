#!/bin/bash

theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)

if [[ $theme != icons ]]; then
	mute=mute up='volume up' down='volume down' sep=' '
fi

if [[ -z $@ ]]; then
	cat <<- EOF
		$sep$mute
		$sep$up
		$sep$down
	EOF
else
	case $@ in
		*) amixer -q -D pulse set Master toggle;;
		*)
			volume="$@"
			[[ ${volume##* } =~ [0-9] ]] && multiplier="${volume##* }" volume="${volume% *}"
			[[ ${volume%% *} ==  ]] && direction=+ || direction=-
			amixer -q -D pulse set Master $((${multiplier:-1} * 10))%$direction;;
	esac

	killall rofi
	~/.orw/scripts/system_notification.sh system_volume
fi
