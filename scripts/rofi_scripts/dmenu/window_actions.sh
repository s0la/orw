#!/bin/bash

theme=$(awk -F '[".]' 'END { print $(NF - 2) }' ~/.config/rofi/main.rasi)
#[[ $theme =~ dmenu|icons ]] && ~/.orw/scripts/set_rofi_geometry.sh volume
[[ $theme != icons ]] && close=close min=min max=max sep=' '

icon_max=
icon_min=
icon_close=

icon_max=
icon_min=
icon_close=

#id=$(printf "0x%.8x" $(xdotool getactivewindow))
config=~/.config/orw/config
offsets=~/.config/orw/offsets
properties=~/.config/orw/windows_properties

id=$(printf "0x%x" $(xdotool getactivewindow))
title=$(wmctrl -l | awk '$1 == "'$id'" { print $NF }')
maxed=$(awk '$1 == "'$id'" { m = ($NF == "maxed") } END { if(m) print "-a 1" }' $properties)

#toggle_rofi() {
#	~/.orw/scripts/signal_windows_event.sh rofi_toggle
#}

toggle_rofi
#trap toggle_rofi EXIT

action=$(cat <<- EOF | rofi -dmenu $maxed -theme main
	$icon_close$sep$close
	$icon_max$sep$max
	$icon_min$sep$min
EOF
)

if [[ $action ]]; then
	case "$action" in
		#$icon_min*) xdotool getactivewindow windowminimize;;
		$icon_min*) ~/.orw/scripts/signal_windows_event.sh min;;
		$icon_max*) ~/.orw/scripts/signal_windows_event.sh max;;
		$icon_min*) ~/.orw/scripts/minimize_window.sh $id;;
		$icon_max*)
			[[ $theme == icons ]] || args="${action#*$sep$max}"

			if [[ $maxed ]]; then
				~/.orw/scripts/minimize_window.sh $id restore
				sed -i '${ /^'$id'/d }' $properties

				#read line_number properties <<< $(awk '/^'$id'/ {
				#		nr = NR; p = gensub($1 " (.*) ?" $6, "\\1", 1)
				#	} END { print nr, p }' $properties)
				#sed -i "${line_number}d" $properties
			else
				[[ $mode != floating ]] && align='-A m'
				~/.orw/scripts/windowctl.sh -s $align move -h 1/1 -v 1/1 resize -h 1/1 -v 1/1
				awk -i inplace '$1 == "'$id'" { $6 = "maxed" } { print }' $properties
			fi;;

		#$icon_max*)
		#	[[ $theme == icons ]] || args="${action#*$sep$max}"

		#	[[ $maxed ]] && state='-r' || state='-s' geometry='move -h 1/1 -v 1/1 resize -h 1/1 -v 1/1'
		#	[[ $mode != floating && ! $maxed ]] && align='-A m'
		#	[[ $mode != floating ]] && state=${state^^}

		#	#echo ~/.orw/scripts/windowctl.sh $args $state $geometry $align
		#	#exit

		#	~/.orw/scripts/windowctl.sh $args $state $align $geometry
		#	((maxed)) || awk -i inplace '$1 == "'$id'" { $6 = "maxed" } { print }' $properties

		#	#[[ $maxed ]] && command="-r" ||
		#	#	command="-s move -h 1/1 -v 1/1 resize -h 1/1 -v 1/1"
		#	#~/.orw/scripts/windowctl.sh $args $command;;
		$icon_close*)
			#[[ $mode == floating ]] &&
			#	wmctrl -c :ACTIVE: ||
			#	~/.orw/scripts/windowctl.sh -A c
			wmctrl -c :ACTIVE:

			[[ $title =~ ^vifm ]] && vifm --remote -c quit

			tmux_command='tmux -S /tmp/tmux_hidden'
			tmux_session=$($tmux_command ls | awk -F ':' '$1 == "'$title'" { print $1 }')
			[[ $tmux_session ]] && $tmux_command kill-session -t $tmux_session
	esac
fi
