#!/bin/bash

theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)

if [[ $theme != icons ]]; then
	mute=mute up='volume up' down='volume down' sep=' '
fi

icon_up=
icon_down=
icon_mute=

if [[ -z $@ ]]; then
	cat <<- EOF
		$icon_up$sep$up
		$icon_mute$sep$mute
		$icon_down$sep$down
	EOF
else
	case $@ in
		$icon_mute*) amixer -q -D pulse set Master toggle;;
		*)
			volume="$@"
			[[ ${volume##* } =~ [0-9] ]] && multiplier="${volume##* }" volume="${volume% *}"
			[[ ${volume%% *} == $icon_up ]] && direction=+ || direction=-
			amixer -q -D pulse set Master $((${multiplier:-1} * 10))%$direction;;
	esac

	killall rofi
	~/.orw/scripts/system_notification.sh system_volume
fi
