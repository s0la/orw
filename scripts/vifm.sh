#!/bin/bash

while getopts :w:h: flag; do
	case $flag in
		w) width=$OPTARG;;
		h) height=$OPTARG;;
	esac
done

~/.orw/scripts/set_class_geometry.sh -c size -w ${width:-450} -h ${height:-600}

#tmux="tmux -S /tmp/vifm -f ~/.tmux_hidden.conf new -s vifm ~/.config/vifm/scripts/run_with_image_preview $@"

termite -t ${title-vifm} --class=custom_size -e \
	"bash -c 'sleep 0.1 && $tmux ~/.config/vifm/scripts/run_with_image_preview'" &> /dev/null &
