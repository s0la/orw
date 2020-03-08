#!/bin/bash

while getopts :w:h: flag; do
	case $flag in
		w) width=$OPTARG;;
		h) height=$OPTARG;;
	esac
done

all="$@"
[[ ! ${all##* } =~ ^[0-9]+$ ]] && args="${all##*[0-9] }"

~/.orw/scripts/set_class_geometry.sh -c size -w ${width:-400} -h ${height:-500}

termite -t ${title-vifm} --class=custom_size -e \
	"bash -c 'sleep 0.1 && $tmux ~/.config/vifm/scripts/run_with_image_preview $args'" &> /dev/null &
