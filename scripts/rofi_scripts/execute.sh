#!/bin/bash

[[ $style =~ horizontal|dmenu ]] &&
	theme=dmenu || theme=list
theme=list

command="$(
	for script in ~/.orw/scripts/*.sh; do
		script=${script##*/}
		echo ${script%.*}
	done | rofi -dmenu -theme $theme
)"

killall rofi

script=${command%% *}
~/.orw/scripts/$script.sh ${@/$script/} &
