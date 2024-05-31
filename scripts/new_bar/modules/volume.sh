#!/bin/bash

#make_volume_content() {
#	read volume_{up,down}_icon <<< $(get_icon 'volume_\(up\|down\)_icon' 2 | xargs)
#	volume_down_button="%{A:pactl set-sink-volume 0 -5%:}$volume_down_icon%{A}%{O10}"
#	volume_up_button="%{O10}%{A:pactl set-sink-volume 0 +5%:}$volume_up_icon%{A}"
#	toggle_volume_buttons="sed -i '/volume_buttons/ y/01/10/' bar_config"
#	#volume_content="\$vpbg\$vpfg$padding\$volume$padding"
#	make_module '$volume' 'VOL'
#}

get_volume() {
	label='VOL'
	icon="$(get_icon "volume_icon")"
	#volume=$(pactl list sinks | sed -n 's/^\s\+Volume:[^%]* \(\w*\)%.*/\1%/p')

	volume=$(pactl list sinks | awk '
		$1 == "Sink" { nr = NR + 2 }
		NR == nr { c = $NF !~ "hdmi" }
		c && /^\s*Volume/ { print $5; exit }')
	#volume=$(pactl list sinks | awk ' /RUNNING/ { c = 1 } c && $1 == "Volume:" { print $5; exit }')

	#volume="%{A:$toggle_volume_buttons && pactl set-sink-volume 0 +0.01%:}$volume%{A}"
	#local volume_buttons="%{A:sed -i 'y/01/10/' bar_config:}"
	#local volume_down="%{A5:pactl set-sink-volume 0 -5%:}"
	#local volume_up="%{A4:pactl set-sink-volume 0 +5%:}"
	#volume="$volume_down$volume_up$volume%{A}%{A}"
	#~/.orw/scripts/notify.sh "v: $volume"

	local show_buttons=$(awk '$1 == "volume_buttons" { print $NF }' $bar_config)
	((show_buttons)) &&
		volume="$volume_down_button$volume$volume_up_button"

	print_module volume
	#volume_content="\$actions_start$volume_content\$actions_end"
	#eval echo \"VOLUME:"$actions_start$volume_content$actions_end"\"
}

set_volume_actions() {
	local volume_{up,down}_{icon,button}
	read volume_{up,down}_icon <<< $(get_icon 'volume_\(up\|down\)_icon' 2 | xargs)
	volume_down_button="%{A:pactl set-sink-volume 0 -5%:}$volume_down_icon%{A}%{O10}"
	volume_up_button="%{O10}%{A:pactl set-sink-volume 0 +5%:}$volume_up_icon%{A}"

	local notify='~/.orw/scripts/system_notification.sh system'
	local toggle_volume_buttons="sed -i '/volume_buttons/ y/01/10/' $bar_config && $notify"
	local action1="$toggle_volume_buttons && pactl set-sink-volume 0 +0.01% && $notify"
	local action4="pactl set-sink-volume 0 +5% && $notify"
	local action5="pactl set-sink-volume 0 -5% && $notify"
	local action2="amixer set Master toggle"
	actions_start="%{A:$action1:}%{A2:$action2:}%{A4:$action4:}%{A5:$action5:}"
	actions_end="%{A}%{A}%{A}%{A}"
}

check_volume() {
	#local actions_{start,end}
	#local icon="$(get_icon "volume_icon")"
	set_volume_actions
	get_volume

	pactl subscribe | grep --line-buffered "sink" |
		while read volume_change; do
			get_volume
		done
}
