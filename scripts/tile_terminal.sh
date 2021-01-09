#!/bin/bash

replace() {
	#sed -i "/<application name.*\*.*>/,/\/position/ { /<[xy]>/ s/>.*</>${1:-center}</ }" ~/.config/openbox/rc.xml
	~/.orw/scripts/set_geometry.sh -n "\\\*" -y $1 -x $1
	~/.orw/scripts/toggle.sh wm $2 no_notify
	#openbox --reconfigure
}

set_offsets() {
	#[[ -f $offsets_file ]] && eval "$(cat $offsets_file | xargs)"
	[[ -f $offsets_file ]] && eval "$(awk -F '=' '{ print $1 "=" ++$2 }' $offsets_file | xargs)"
}

all_arguments="$@"
win_args="${all_arguments#*-t * }"
#~/.orw/scripts/notify.sh "wa: $win_args"

#current_mode=$(awk '/class.*tiling/ { cm = "tiling" } END { print (cm) ? cm : "\\\*" }' ~/.config/openbox/rc.xml)
#current_mode=$(awk '/class.*(tiling|\*)/ { print (/\*/) ? "tiling" : "\\\*" }' ~/.orw/dotfiles/.config/openbox/rc.xml)

read mode offset <<< $(awk '/^(mode|offset) / { print $NF }' ~/.config/orw/config | xargs)
#offset=$(awk '/^offset/ { print $NF }' ~/.config/orw/config)
#current_mode=$(awk '/^mode/ { print $NF }' 

while getopts :t:d:x:y:m:o flag; do
	[[ $flag == t ]] && title=$OPTARG || eval "$flag=$OPTARG"
	#[[ $flag == t ]] && title=$OPTARG
	#[[ $flag == o ]] && set_offsets || eval "$flag=$OPTARG"
done

#[[ $win_args =~ ^- ]] &&
command="$(sed 's/^\(\(\(-. \w*\|-b\) \?\)*\)\(.*\)/\4/' <<< $win_args)"
[[ $command ]] && win_args=${win_args%*$command}

#~/.orw/scripts/notify.sh "wa: ^$win_args$"
#~/.orw/scripts/notify.sh "c: $command"
#exit

#[[ $arguments =~ -[tdxym] ]] && command="${arguments##*-[tdxym] * }"
#[[ $command ]] && command="&& $command"

offsets_file=~/.config/orw/offsets
#[[ $offset == true ]] && set_offsets
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
