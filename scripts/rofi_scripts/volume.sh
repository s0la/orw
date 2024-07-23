#!/bin/bash

if [[ $style =~ icons|dmenu ]]; then
	read up down mute <<< \
		$(sed -n 's/^\(arrow_\(up\|down\)\|x\).*empty=//p' ~/.orw/scripts/icons | xargs)
else
	default='default' up='brightness up' down='brightness down' sep=' '
fi

toggle
trap toggle EXIT

while
	active=$(amixer -D pulse get Master | awk '/Playback.*%/ { if($NF ~ "off") print "-a 1" }')

	read row volume <<< $(cat <<- EOF | rofi -dmenu -format 'i s' -selected-row ${row:-0} $active -theme main
		$up
		$mute
		$down
	EOF
	)

	if [[ $volume ]]; then
		case $volume in
			$mute*) amixer -q -D pulse set Master toggle;;
			*)
				[[ ${volume##* } =~ [0-9] ]] && multiplier="${volume##* }" volume="${volume% *}"
				[[ ${volume%% *} == $up ]] && direction=+ || direction=-
				amixer -q -D pulse set Master $((${multiplier:-1} * 10))%$direction;;
		esac
	fi

	[[ $volume ]] && ~/.orw/scripts/system_notification.sh system_volume &

	[[ $volume =~ $up|$down ]]
do
	continue
done
