#!/bin/bash

theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)
[[ $theme =~ dmenu|icons ]] && ~/.orw/scripts/set_rofi_geometry.sh volume
[[ $theme != icons ]] && close=close min=min max=max sep=' '

icon_max=
icon_min=
icon_close=

id=$(printf "0x%.8x" $(xdotool getactivewindow))
title=$(wmctrl -l | awk '$1 == "'$id'" { print $NF }')
mode=$(awk '/^mode/ { print $NF }' ~/.config/orw/config)
maxed=$(awk '$1 == "'$id'" { print "-a 1" }' ~/.config/orw/windows_properties)

action=$(cat <<- EOF | rofi -dmenu $maxed -theme main
	$icon_close$sep$close
	$icon_max$sep$max
	$icon_min$sep$min
EOF
)

if [[ $action ]]; then
	case "$action" in
		$icon_min*) xdotool getactivewindow windowminimize;;
		$icon_max*)
			[[ $theme == icons ]] || args="${action#*$sep$max}"

			[[ $maxed ]] && state='-r' ||
				state='-s' geometry='move -h 1/1 -v 1/1 resize -h 1/1 -v 1/1'
			[[ $mode != floating ]] && state=${state^^} align='-A m'

			#echo ~/.orw/scripts/windowctl.sh $args $state $geometry $align
			#exit

			~/.orw/scripts/windowctl.sh $args $state $align $geometry;;

			#[[ $maxed ]] && command="-r" ||
			#	command="-s move -h 1/1 -v 1/1 resize -h 1/1 -v 1/1"
			#~/.orw/scripts/windowctl.sh $args $command;;
		$icon_close*)
			[[ $mode == floating ]] &&
				wmctrl -c :ACTIVE: ||
				~/.orw/scripts/windowctl.sh -A c

			[[ $title =~ ^vifm ]] && vifm --remote -c quit

			tmux_command='tmux -S /tmp/tmux_hidden'
			tmux_session=$($tmux_command ls | awk -F ':' '$1 == "'$title'" { print $1 }')
			[[ $tmux_session ]] && $tmux_command kill-session -t $tmux_session
	esac
fi
