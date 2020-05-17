#!/bin/bash

while getopts :t:c:w:h: flag; do
	case $flag in
		t) title=$OPTARG;;
		c) class=$OPTARG;;
		w) width=$OPTARG;;
		h) height=$OPTARG;;
		#c) command="$OPTARG &&";;
	esac
done

all="$@"
[[ ! ${all##* } =~ ^[0-9]+$ ]] && args="${all##*[0-9] }"

[[ $class ]] || ~/.orw/scripts/set_class_geometry.sh -c size -w ${width:-400} -h ${height:-500}

termite -t ${title-vifm} --class=${class-custom_size} -e \
	"bash -c 'sleep 0.1 && $tmux ~/.config/vifm/scripts/run_with_image_preview $args'" &> /dev/null &
#termite -t ${title-vifm} --class=custom_size -e \
#	"bash -c '~/.orw/scripts/execute_on_terminal_startup.sh ${title-vifm} \"$command $tmux ~/.config/vifm/scripts/run_with_image_preview $args\"'" &> /dev/null &
