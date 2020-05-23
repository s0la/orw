#!/bin/bash

replace() {
	#sed -i "/<application name.*\*.*>/,/\/position/ { /<[xy]>/ s/>.*</>${1:-center}</ }" ~/.config/openbox/rc.xml
	~/.orw/scripts/set_geometry.sh -n "\\\*" -y $1 -x $1
	~/.orw/scripts/toggle.sh wm $2 no_notify
	#openbox --reconfigure
}

set_offsets() {
	[[ -f $offsets_file ]] && eval "$(cat $offsets_file | xargs)"
	[[ -f $offsets_file ]] && eval "$(awk -F '=' '{ print $1 "=" ++$2 }' ~/.config/orw/offsets | xargs)"
}

arguments="$@"
#current_mode=$(awk '/class.*tiling/ { cm = "tiling" } END { print (cm) ? cm : "\\\*" }' ~/.config/openbox/rc.xml)
#current_mode=$(awk '/class.*(tiling|\*)/ { print (/\*/) ? "tiling" : "\\\*" }' ~/.orw/dotfiles/.config/openbox/rc.xml)

offsets_file=~/.config/orw/offsets
offset=$(awk '/^offset/ { print $NF }' ~/.config/orw/config)
current_mode=$(awk '/class.*\*/ { print "tiling" }' ~/.orw/dotfiles/.config/openbox/rc.xml)

while getopts :d:x:y:m:o flag; do
	[[ $flag == o ]] && set_offsets || eval "$flag=$OPTARG"
done

[[ $offset == true ]] && set_offsets

while read -r name position bar_x bar_y width height adjustile_width border; do
		current_width=$((bar_y + height + border))
		((current_width > max_width)) && max_width=$current_width
done <<< $(~/.orw/scripts/get_bar_info.sh)

replace default floating

~/.orw/scripts/set_geometry.sh -c custom_size -w ${x:-${x_offset-100}} -h $((${y:-${y_offset-100}} + max_width))
termite --class=custom_size -t termite -e "bash -c '~/.orw/scripts/windowctl.sh $arguments tile;bash'" &> /dev/null &

sleep 1
replace center "${current_mode:-floating}"
