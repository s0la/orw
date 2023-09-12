#!/bin/bash

base_directory=~/Videos
sub_directory='release2'

while getopts :f:d:D: flag; do
	((arg_count++))

	case $flag in
		f) fps=$OPTARG;;
		d)
			sub_directory=$OPTARG
			sed -i "/^sub_directory/ s/'.*'/'$sub_directory'/" $0;;
		D) display=display_$OPTARG;;
	esac
done

full_path=$base_directory/$sub_directory
[[ ! -d $full_path ]] && mkdir -p $full_path
[[ $sub_directory && $# -eq 2 ]] && exit

[[ ! -f ~/.config/orw/config ]] && ~/.orw/scripts/generate_orw_config.sh

read resolution position <<< $(awk '\
	$1 == "primary" { d = ("'$display'") ? "'$display'" : $NF }
	$1 ~ d "_(xy|size)" {
		if(/size/) print $2 "x" $3, xy
		else xy = "+" $2 "," $3 }' ~/.config/orw/config)

shift $((arg_count * 2))
[[ $@ ]] && filename="$@" || filename=$(date +"%Y-%m-%d-%H:%M")

~/.orw/scripts/notify.sh -s osd -i   'recording started' &> /dev/null &

ffmpeg -y -f x11grab -r ${fps-60} -s $resolution -draw_mouse 1 -i $DISPLAY$position \
	-f pulse -async 1 -i default -c:v libx264 -preset ultrafast -vsync 1 $full_path/$filename.mp4
