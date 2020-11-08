#!/bin/bash

theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)
[[ $theme =~ dmenu|icons ]] && ~/.orw/scripts/set_rofi_geometry.sh volume

if [[ $theme != icons ]]; then
	mute=mute up='volume up' down='volume down' sep=' '
fi

icon_up=
icon_down=
icon_mute=

while
	active=$(amixer -D pulse get Master | awk '/Playback.*%/ { if($NF ~ "off") print "-a 1" }')

	read row volume <<< $(cat <<- EOF | rofi -dmenu -format 'i s' -selected-row ${row:-0} $active -theme main
		$icon_up$sep$up
		$icon_mute$sep$mute
		$icon_down$sep$down
	EOF
	)

	if [[ $volume ]]; then
		case $volume in
			$icon_mute*) amixer -q -D pulse set Master toggle;;
			*)
				[[ ${volume##* } =~ [0-9] ]] && multiplier="${volume##* }" volume="${volume% *}"
				[[ ${volume%% *} == $icon_up ]] && direction=+ || direction=-
				amixer -q -D pulse set Master $((${multiplier:-1} * 10))%$direction;;
		esac
	fi

	[[ $volume ]] && ~/.orw/scripts/system_notification.sh system_volume &

	[[ $volume =~ $icon_up|$icon_down ]]
do
	continue
done
