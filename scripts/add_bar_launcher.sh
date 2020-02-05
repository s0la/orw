#!/bin/bash

launchers=~/.orw/scripts/bar/launchers

while getopts :i:n:c:r:m:u:d: flag; do
	case $flag in
		i) icon=$OPTARG;;
		n) name="$OPTARG";;
		c) left="$OPTARG";;
		r) right="$OPTARG";;
		m) middle="$OPTARG";;
		u) up="$OPTARG";;
		d) down="$OPTARG";;
	esac
done

if [[ -z $@ ]]; then
	read -p 'Name: ' name
	read -p 'Icon: ' icon
	read -p 'Left click command: ' left
	read -p 'Right click command: ' right
	read -p 'Middle click command: ' middle
	read -p 'Scroll up command: ' up
	read -p 'Scroll down command: ' down
fi

[[ $name ]] || name=$(xwininfo | awk -F ' - |"' '/id:/ { print $(NF - 1) }')

offset=$(awk '/^#?icon/ { print gensub(/.*%{I(.[0-9]+).*/, "\\1", 1); exit }' $launchers)

lines=$(wc -l < $launchers)
((lines)) && echo >> $launchers

cat <<- EOF >> $launchers
	#$name
	icon="%{I$offset}${icon// /}%{I-}"
	name="$name"
	left="$left"
EOF

[[ $right ]] && echo "right=\"$right\"" >> $launchers
[[ $middle ]] && echo "middle=\"$middle\"" >> $launchers
[[ $up ]] && echo "up=\"$up\"" >> $launchers
[[ $down ]] && echo "down=\"$down\"" >> $launchers

exit 0
