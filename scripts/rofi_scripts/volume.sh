#!/bin/bash

if [[ -z $@ ]]; then
	echo -e '  mute\n  volume up\n  volume down'
else
	case $@ in
		*volume*)
			volume="$@"
			[[ ${volume##* } =~ [0-9] ]] && multiplier="${volume##* }" volume="${volume% *}"
			[[ ${volume##* } == up ]] && direction=+ || direction=-
			amixer -q -D pulse set Master $((${multiplier:-1} * 10))%$direction;;
		*mute*) amixer -q -D pulse set Master toggle;;
	esac

	~/.orw/scripts/volume_notification.sh
fi
