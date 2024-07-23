#!/bin/bash

if [[ $style =~ icons|dmenu ]]; then
	read max min close <<< \
		$(sed -n 's/^\(arrow_\(up\|down\)\|x\).*empty=//p' ~/.orw/scripts/icons | xargs)
else
	default='default' up='brightness up' down='brightness down' sep=' '
fi


config=~/.config/orw/config
offsets=~/.config/orw/offsets
properties=~/.config/orw/windows_properties

id=$(printf "0x%x" $(xdotool getactivewindow))
title=$(wmctrl -l | awk '$1 == "'$id'" { print $NF }')
maxed=$(awk '$1 == "'$id'" { m = ($NF == "maxed") } END { if(m) print "-a 1" }' $properties)

toggle

action=$(cat <<- EOF | rofi -dmenu $maxed -theme main
	$close
	$max
	$min
EOF
)

if [[ $action ]]; then
	case "$action" in
		$min*) ~/.orw/scripts/signal_windows_event.sh min;;
		$max*) ~/.orw/scripts/signal_windows_event.sh max;;
		$close*)
			wmctrl -c :ACTIVE:

			[[ $title =~ ^vifm ]] && vifm --remote -c quit

			tmux_command='tmux -S /tmp/tmux_hidden'
			tmux_session=$($tmux_command ls | awk -F ':' '$1 == "'$title'" { print $1 }')
			[[ $tmux_session ]] && $tmux_command kill-session -t $tmux_session
	esac
fi
