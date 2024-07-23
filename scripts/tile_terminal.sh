#!/bin/bash

replace() {
	~/.orw/scripts/set_geometry.sh -n "\\\*" -y $1 -x $1
	~/.orw/scripts/toggle.sh wm $2 no_notify
}

set_offsets() {
	[[ -f $offsets_file ]] && eval "$(awk -F '=' '{ print $1 "=" ++$2 }' $offsets_file | xargs)"
}

all_arguments="$@"
win_args="${all_arguments#*-t * }"

read mode offset <<< $(awk '/^(mode|offset) / { print $NF }' ~/.config/orw/config | xargs)

while getopts :t:d:x:y:m:o flag; do
	[[ $flag == t ]] && title=$OPTARG || eval "$flag=$OPTARG"
done

command="$(sed 's/^\(\(\(-. \w*\|-b\) \?\)*\)\(.*\)/\4/' <<< $win_args)"
[[ $command ]] && win_args=${win_args%*$command}

offsets_file=~/.config/orw/offsets
[[ $offset == true && -f $offsets_file ]] &&
	eval "$(awk -F '=' '{ print $1 "=" ++$2 }' $offsets_file | xargs)"

while read -r name position bar_x bar_y width height adjustile_width border; do
		current_width=$((bar_y + height + border))
		((current_width > max_width)) && max_width=$current_width
done <<< $(~/.orw/scripts/get_bar_info.sh)

replace default floating

~/.orw/scripts/set_geometry.sh -c custom_size -w ${x:-${x_offset-100}} -h $((${y:-${y_offset-100}} + max_width))
termite --class=custom_size -t ${title:=termite} \
	-e "bash -c '~/.orw/scripts/windowctl.sh $win_args tile;${command:-bash}'" &> /dev/null &

sleep 1
replace center $mode
