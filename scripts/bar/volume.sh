#!/bin/bash

icon=
icon=
icon=
path=~/.orw/bar

file="${0%/*}/$1*.sh"
volume="current_${1}_volume_mode"

[[ $@ =~ icon ]] && icon_width=%{I-b}

function toggle_command() {
	echo -e "%{A:sed -i \\\"/$volume=[a-z]/ s/=.*/=$1/\\\" $file:}"
}

if [[ $1 == system ]]; then
	read icon vol <<< $(amixer -D pulse get Master toggle | awk -F '[][]' \
		'/Front.*Playback/ { print ($4 == "on") ? " " $2 : ("'$2'") ? " 0%" : " MUTE" }')

	command='amixer -q -D pulse set Master'
	notification=~/.orw/scripts/volume_notification.sh

	up="$command 5%+ && $notification"
	down="$command 5%- && $notification"
	mute_start="%{A2:$command toggle && $notification:}"
	mute_end='%{A}'
else
	vol=$(mpc volume | sed 's/.*: \([0-9]*\).*/\1/')
	up='mpc -q volume +5'
	down='mpc -q volume -5'
fi

if [[ $(sed -n "s/.*$volume=//p" $file) == mono ]]; then
	echo -ne "'\${vsfg:-\$sfg}%{A:$down:}%{I-n}%{I-}%{A}$(toggle_command duo)"
	echo -e "$mute_start\${vpfg:-\$pfg}\${inner}\${inner}$vol$mute_end\$inner\$inner%{A}\${vsfg:-\$sfg}%{A:$up:}%{I-n}${I-}%{A}'"
else
	echo -e "'%{A4:$up:}%{A5:$down:}$mute_start$(toggle_command mono)$icon_width${!2-VOL}%{I-}$mute_end%{A}%{A}%{A}'" "'$vol'"
fi
