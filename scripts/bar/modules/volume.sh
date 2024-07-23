#!/bin/bash

get_volume() {
	#volume=$(pactl list sinks | awk '
	#	$1 == "Sink" { nr = NR + 2 }
	#	NR == nr { c = $NF !~ "hdmi" }
	#	c && /^\s*Volume/ { print $5; exit }')

	read icon volume <<< $(pactl list sinks |
		awk '
			$1 == "State:" && $NF == "RUNNING" { c = 1 }
			c && $1 == "Mute:" { print "volume" (($NF == "yes") ? "_mute" : "") }
			c && /^\s*Volume/ { print $5; exit }' | xargs)

	label='VOL'
	icon="$(get_icon "${icon}=")"

	set_volume_actions
	if ((show_volume_buttons)); then
		if [[ ! ${joiner_modules[v]} ]]; then
			volume="$volume_down_button$volume_toggle_button%{O5}$volume%{O5}%{A}$volume_up_button"
			unset icon
		else
			icon=$volume
		fi
	fi

	print_module volume
}

set_volume_actions() {
	local notify='~/.orw/scripts/system_notification.sh system'
	local toggle_volume_buttons="sed -i '/^volume_buttons/ y/01/10/' $bar_config"
	local action1="$toggle_volume_buttons && pactl set-sink-volume 0 +0.01%"
	local action4="pactl set-sink-volume 0 +5% && $notify"
	local action5="pactl set-sink-volume 0 -5% && $notify"
	local action2="amixer set Master toggle"

	show_volume_buttons=$(awk '$1 == "volume_buttons" { print $NF }' $bar_config)

	if ((show_volume_buttons)); then
		local inner='%{O5}' joiner_group=${joiner_modules[v]}
		volume_toggle_button="%{A:$action1:}"
		volume_up_button="%{A:$action4:}$volume_up_icon%{A}"
		volume_down_button="%{A:$action5:}$volume_down_icon%{A}"

		if ((joiner_group)); then
			read _ inner _ <<< ${joiners[joiner_group-1]}

			actions_start="$volume_down_button$volume_toggle_button$inner"
			actions_end="$inner%{A}$volume_up_button"
		fi
	else
		actions_start="%{A:$action1:}%{A2:$action2:}%{A4:$action4:}%{A5:$action5:}"
		actions_end="%{A}%{A}%{A}%{A}"
	fi
}

check_volume() {
	read volume_{up,down}_icon <<< $(get_icon 'arrow_(right|left).*full' | xargs)
	get_volume

	pactl subscribe | grep --line-buffered "sink" |
		while read volume_change; do
			get_volume
		done
}
