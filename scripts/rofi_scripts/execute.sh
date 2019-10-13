#!/bin/bash

if [[ -z $@ ]]; then
	for script in ~/.orw/scripts/*.sh; do
		script=${script##*/}
		echo ${script%.*}
	done
else
	killall rofi

	command="$@"
	script=${command%% *}
	~/.orw/scripts/$script.sh ${@/$script/}
fi
