#!/bin/bash

while getopts :f:d: flag; do
	case $flag in
		f) fps=$OPTARG;;
		d) display=$OPTARG;;
	esac
done

[[ ! -f ~/.config/orw/config ]] && ~/.orw/scripts/generate_orw_config.sh
resolution=$(awk '/'${display-full}'/ {print $2 "x" $3}' ~/.config/orw/config)
ffmpeg -y -f x11grab -r 15 -s 1880x25 -i $DISPLAY+20,10 -f pulse -async 1 -i default "${@: -1}"
