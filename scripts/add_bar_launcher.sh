#!/bin/bash

launchers=~/.orw/scripts/bar/launchers

while getopts :i:n:c:u:d: flag; do
	case $flag in
		i) icon="\"$OPTARG\"";;
		n) name="\"$OPTARG\"";;
		c) command="\"$OPTARG\"";;
		u) up_command="\"$OPTARG\"";;
		d) down_command="\"$OPTARG\"";;
	esac
done

[[ $name ]] || name=$(xwininfo | awk -F ' - |"' '/id:/ { print $(NF - 1) }')

offset=$(awk 'NR == 1 { print gensub(/"%{I(.[0-9]+).*/, "\\1", 1); exit }' $launchers)
echo "%{I$offset}$icon%{I-} $name $command $up_command $down_command" >> $launchers
