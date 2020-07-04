#!/bin/bash

read bg fg <<< $(awk -F '"' '/urgency_normal/ { nr = NR } \
	{ if(nr && NR > nr && NR <= nr + 2) print $2 }' ~/.config/dunst/dunstrc | xargs)

pbfg='#a58479'
epbfg=$(~/.orw/scripts/colorctl.sh -o +30 -h $bg)

type=$(ps -C dunst -o args=)

if [[ $1 == osd ]]; then
	set_pid() {
		sed -i "/^restore_default_config_pid/ s/[0-9]*$/$1/" $0
	}

	restore_default_config() {
		((restore_default_config_pid)) && kill $restore_default_config_pid

		(sleep 10
		killall dunst
		dunst &> /dev/null &
		set_pid) &

		set_pid $!
	}

	color_bar() {
		for p in $(seq $2); do
			#eval $1+='▀'
			#eval $1+='▊'
			eval $1+='▖'
		done
	}

	[[ "$type" =~ dunst$ ]] && killall dunst

	restore_default_config_pid=
	restore_default_config

	pid=$(pidof dunst)
	((pid)) || dunst -conf ~/.config/dunst/osd_dunstrc &> /dev/null &

	#icon=$2
	icon_size=48
	icon="<span font='Iosevka Orw $icon_size' foreground='$epbfg'>$2</span>"

	if [[ $3 =~ ^[0-9]+/[0-9]+$ ]]; then
		bar_size=8

		color_bar level ${3%/*}
		color_bar empty ${3#*/}

		#info="<span font='Iosevka Orw $bar_size' foreground='\$pbfg'>$level<span foreground='\$epbfg'>$empty</span></span>"
		info="<span font='Iosevka Orw $bar_size' foreground='$pbfg'>$level<span foreground='$epbfg'>$empty</span></span>"
		#info="<span font='Iosevka Orw $bar_size' foreground='$fg'>$2</span>"
	else
		info_offset=$(awk '{
				m = $0
				l = length(m)
				d = (20 - l) / 2
				printf("%*.s%s%*.s", d, " ", m, d, " ") }' <<< "$3")
		info="<span foreground='$fg'>$info_offset</span>"
	fi

	dunstify -r 292 '' "<span>\n$icon\n\n\n$info</span>"
	exit
else
	pid=$(pidof dunst)

	if ((pid)); then
		if [[ ! "$type" =~ dunst$ ]]; then
			killall dunst
			dunst &> /dev/null &
		fi
	else
		read x_offset y_offset <<< \
			$(awk '/^[xy]_offset/ { print $NF * 2 }' ~/.config/orw/config | xargs)

		while read -r bar_name position bar_x bar_y bar_width bar_height adjustable_width frame; do
			if ((position)); then
				current_bar_height=$((bar_y + bar_height + frame))
				((current_bar_height > max_bar_height)) && max_bar_height=$current_bar_height
			fi
		done <<< $(~/.orw/scripts/get_bar_info.sh)

		dmenu_height=$(~/.orw/scripts/get_dmenu_height.sh)
		(( y_offset += max_bar_height + dmenu_height ))

		sed -i "s/\(^\s*geometry.*x[0-9]*\)[^\"]*/\1-$x_offset+$y_offset/" ~/.config/dunst/dunstrc

		dunst &> /dev/null &
	fi
fi

#if ((pid)); then
#	if [[ $1 == osd ]]; then
#		if [[ "$type" == dunst ]]; then
#			killall dunst
#			dunst -conf ~/.config/dunst/osd_dunstrc &> /dev/null &
#		fi
#
#		shift
#	else
#		if [[ "$type" != dunst ]]; then
#			killall dunst
#			dunst &> /dev/null &
#		fi
#	fi
#else
#	if [[ $1 == osd ]]; then
#		conf='-conf ~/.config/dunst/osd_dunstrc'
#		shift
#	else
#		read x_offset y_offset <<< $(awk '/^[xy]_offset/ { print $NF * 2 }' ~/.config/orw/config | xargs)
#
#		while read -r bar_name position bar_x bar_y bar_width bar_height adjustable_width frame; do
#			if ((position)); then
#				current_bar_height=$((bar_y + bar_height + frame))
#				((current_bar_height > max_bar_height)) && max_bar_height=$current_bar_height
#			fi
#		done <<< $(~/.orw/scripts/get_bar_info.sh)
#
#		dmenu_height=$(~/.orw/scripts/get_dmenu_height.sh)
#		(( y_offset += max_bar_height + dmenu_height ))
#
#		sed -i "s/\(^\s*geometry.*x[0-9]*\)[^\"]*/\1-$x_offset+$y_offset/" ~/.config/dunst/dunstrc
#	fi
#
#	dunst "$conf" &> /dev/null &
#fi

while getopts :i:F:f:o:r:c:t:P:p flag; do
	case $flag in
		p) padding='\n';;
		i) icon=$OPTARG;;
		F) font="$OPTARG";;
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

dunstify -i ${icon-none} $time $replace 'summery' "<span font='${font:-Roboto Mono} ${padding_height-6}'>\n\
	<span font='Roboto Mono ${font_size:-8}'>$padding$offset${message//\\n/$offset\\n$offset}$offset$padding</span>\n</span>"
