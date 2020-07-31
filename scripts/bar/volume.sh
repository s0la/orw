#!/bin/bash

icon=
icon=
icon=
path=~/.orw/bar

file="${0%/*}/$1*.sh"
volume="current_${1}_volume_mode"

#[[ $@ =~ icon ]] && icon_width=%{I-b}

function set_icon() {
	local icon="$(sed -n "s/volume_${1}_icon=//p" ${0%/*}/icons)"
	eval volume_${1}_icon=$icon
}

set_icon up
set_icon down
set_icon mute

[[ $2 ]] && set_icon default

#~/.orw/scripts/notify.sh "$volume_default_icon"

function toggle_command() {
	echo -e "%{A:sed -i \\\"/$volume=[a-z]/ s/=.*/=$1/\\\" $file:}"
}

if [[ $1 == system ]]; then
		#'/Front.*Playback/ {
	read label vol <<< $(amixer -D pulse get Master toggle | awk -F '[][]' \
		'/Playback.*%/ {
			if($4 == "on") o = ("'$2'") ? "'$volume_default_icon' " $2 : "VOL " $2
			else o = ("'$2'") ? "'$volume_mute_icon' 0%" : "VOL MUTE"
			print o }')
			#print ($4 == "on") ? "'$volume_default_icon' " $2 : ("'$2'") ? " 0%" : " MUTE" }')

	notification="~/.orw/scripts/system_notification.sh $1_volume"
	command='amixer -q -D pulse set Master'

	up="$command 5%+ && $notification"
	down="$command 5%- && $notification"
	mute_start="%{A2:$command toggle && $notification:}"
	mute_end='%{A}'
else
	label=${volume_default_icon:-VOL}

	vol=$(mpc volume | sed 's/.*: \([0-9]*\).*/\1/')
	up='mpc -q volume +5'
	down='mpc -q volume -5'
fi

if [[ $(sed -n "s/.*$volume=//p" $file) == mono ]]; then
	echo -ne "'\${vsfg:-\$sfg}%{A:$down:}$volume_down_icon%{A}$(toggle_command duo)"
	echo -ne "$mute_start\${vpfg:-\$pfg}\${inner}\${inner}$vol$mute_end\$inner\$inner%{A}"
	echo -e "\${vsfg:-\$sfg}%{A:$up:}$volume_up_icon%{A}'"
else
	echo -e "'%{A4:$up:}%{A5:$down:}$mute_start$(toggle_command mono)$label$mute_end%{A}%{A}%{A}'" "'$vol'"
fi
