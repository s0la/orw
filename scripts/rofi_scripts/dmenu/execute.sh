#!/bin/bash

#toggle
#trap toggle EXIT

[[ $style =~ horizontal|dmenu ]] &&
	theme=dmenu || theme=list
theme=list

if [[ -z $@ ]]; then
	for script in ~/.orw/scripts/*.sh; do
		script=${script##*/}
		echo ${script%.*}
	done | rofi -dmenu -theme $theme
else
	killall rofi

	command="$@"
	script=${command%% *}
	~/.orw/scripts/$script.sh ${@/$script/} &
fi
