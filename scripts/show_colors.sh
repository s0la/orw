#!/bin/bash

while getopts :b:d:l:f: flag; do
	case $flag in
		l) length=$OPTARG;;
		f) filter=$OPTARG;;
		d) hex_dark=$OPTARG;;
		b) hex_bright=$OPTARG;;
	esac
done

colorctl=~/.orw/scripts/colorctl.sh
colors=~/.config/orw/colorschemes/colors

clean="$(tput sgr0)"
dark=$($colorctl -cs ';' -h ${hex_bright-'#bbbbbb'})
bright=$($colorctl -cs ';' -h ${hex_dark-'#444444'})

while read index name value; do
	read br rgb <<< $($colorctl -bcs ';' -h $value | xargs)
	color=$(printf '   %*s%s%*s   ' ${length:=5} ' ' $value $length ' ')
	echo -e "$index $name\n\033[48;2;${rgb}38;2;${!br}2m${color}\033[0m\n"
done <<< $(awk '/'$filter'/ { print NR, $0 }' $colors)
