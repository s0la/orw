#!/bin/bash

mode=$(awk '/^mode/ { print $NF }' ~/.config/orw/config)

if [[ $mode != tiling ]]; then
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
		*$*) amixer -q -D pulse set Master toggle;;
		*)
			volume="$@"
			[[ ${volume##* } =~ [0-9] ]] && multiplier="${volume##* }" volume="${volume% *}"
			[[ ${volume%% *} ==  ]] && direction=+ || direction=-
			amixer -q -D pulse set Master $((${multiplier:-1} * 10))%$direction;;
	esac

	~/.orw/scripts/volume_notification.sh
fi
