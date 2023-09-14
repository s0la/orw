#!/bin/bash

while getopts :t:w:h:i flag; do
	instance=true

	(( arg_count += 2 ))

	case $flag in
		t) title=$OPTARG;;
		w) width=$OPTARG;;
		h) height=$OPTARG;;
		i) (( arg_count-- ))
	esac
done

[[ ! $title ]] &&
	title=$(wmctrl -l | awk '$NF ~ "^vifm[0-9]+?" { print $NF }' | sort -n |
	awk '{
		ic = gensub("vifm", "", 1)
		if(mc + 1 < ic) exit; else mc = (ic) ? ic : 0
	} END { if(length(mc)) mc++; print "vifm" mc }')

args="${@:arg_count + 1}"
run_command="~/.config/vifm/scripts/run_with_image_preview --server-name $title"

if [[ $instance ]]; then
	~/.orw/scripts/set_geometry.sh -c size -w ${width:-400} -h ${height:-500}

	#[[ ! $title ]] && title=$(wmctrl -l | awk '$NF ~ "^vifm[0-9]+?" { c++ } END { print "vifm" c }')

	alacritty -t ${title-vifm} --class=${class-custom_size} -e \
		bash -c "sleep 0.5 && $run_command \\\"$args\\\"" &> /dev/null &
	exit

	alacritty -t ${title-vifm} --class=${class-custom_size} -e \
		bash -c "$run_command $args" &> /dev/null &
else
	eval $run_command $args
fi
