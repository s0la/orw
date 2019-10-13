#!/bin/bash

pid=$(pidof dunst)

if [[ ! $pid ]]; then
	read x_offset y_offset <<< $(awk '/offset/ { print $NF * 2 }' ~/.config/orw/config | xargs)

	while read -r bar_name position bar_x bar_y bar_width bar_height adjustable_width frame; do
		if ((position)); then
			current_bar_height=$((bar_y + bar_height + frame + y_offset))
			((current_bar_height > y_offset)) && y_offset=$current_bar_height
		fi
	done <<< $(~/.orw/scripts/get_bar_info.sh)

	sed -i "s/\(^\s*geometry.*x[0-9]*\)[^\"]*/\1-$x_offset+$y_offset/" ~/.config/dunst/*

	dunst &> /dev/null &
fi

read bg fg <<< $(awk -F '"' '/urgency_normal/ { nr = NR }; { if(nr && NR > nr && NR <= nr + 2) print $2 }' \
	~/.config/dunst/dunstrc | xargs)

pbfg='#8fa398'
epbfg=$(~/.orw/scripts/colorctl.sh -o +20 -h $bg)

while getopts :i:f:o:r:c:t:P:p flag; do
	case $flag in
		p) padding='\n';;
		i) icon=$OPTARG;;
		f) font_size=$OPTARG;;
		o) offset_count=$OPTARG;;
		r) replace="-r $OPTARG";;
		P) padding_height=$OPTARG;;
		c) config="-config $OPTARG";;
		t) time="-t $((OPTARG * 1000))";;
	esac
done

offset=$(printf "%-${offset_count-10}s")

message="$(sed "s/\$fg/$fg/g; s/\$pbfg/$pbfg/g; s/\$epbfg/$epbfg/g" <<< "${@: -1}")"

dunstify -i ${icon-none} $time $replace 'summery' "<span font='Roboto Mono ${padding_height-6}'>\n\
	<span font='Roboto Mono ${font_size:-8}'>$padding$offset${message//\\n/$offset\\n$offset}$offset$padding</span>\n</span>"
