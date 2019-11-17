#!/bin/bash

replace() {
	sed -i "/<application name.*\*.*>/,/\/position/ { /<[xy]>/ s/>.*</>${1:-center}</ }" ~/.config/openbox/rc.xml
	openbox --reconfigure
}

arguments="$@"

while getopts :d:x:y:m:o flag; do
	if [[ $flag == o ]]; then
		offsets_file=~/.config/orw/offsets
		[[ -f $offsets_file ]] && eval "$(cat $offsets_file | xargs)"
	else
		eval "$flag=$OPTARG"
	fi
done

while read -r name position bar_x bar_y width height adjustile_width border; do
		current_width=$((bar_y + height + border))
		((current_width > max_width)) && max_width=$current_width
done <<< $(~/.orw/scripts/get_bar_info.sh)

replace default

~/.orw/scripts/set_class_geometry.sh -c custom_size -w ${x:-${x_offset-70}} -h $((${y:-${y_offset-70}} + max_width))
termite --class=custom_size -t termite -e "bash -c '~/.orw/scripts/windowctl.sh $arguments tile;bash'" &> /dev/null &

sleep 1
replace
