#!/bin/bash

while getopts :f:d: flag; do
	((arg_count++))

	case $flag in
		f) fps=$OPTARG;;
		d) display=$OPTARG;;
	esac
done

[[ ! -f ~/.config/orw/config ]] && ~/.orw/scripts/generate_orw_config.sh
resolution=$(awk '/'${display-full}'/ {print $2 "x" $3}' ~/.config/orw/config)

shift $((arg_count * 2))
[[ $@ ]] && filename="$@" || filename=$(date +"%Y-%m-%d-%H:%M")

~/.orw/scripts/notify.sh -p "<span font='Roboto Mono 10'>      </span>recording started"

ffmpeg -y -f x11grab -r ${fps-25} -s $resolution -draw_mouse 0 -i $DISPLAY \
	-f pulse -async 1 -i default -c:v libx264 -preset ultrafast -vsync 1 ~/Videos/$filename.mp4
