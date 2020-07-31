#!/bin/bash

read bg fg <<< $(awk -F '"' '/urgency_normal/ { nr = NR } \
	{ if(nr && NR > nr && NR <= nr + 2) print $2 }' ~/.config/dunst/dunstrc | xargs)

sbg='#9d9d9d'
pbfg='#bdd9d5'
#sbg=$(~/.orw/scripts/colorctl.sh -o +30 -h $bg)
#epbfg=$(~/.orw/scripts/colorctl.sh -o +30 -h $bg)

type=$(ps -C dunst -o args=)

if [[ $1 =~ ^(osd|mini|vert) ]]; then
	set_pid() {
		sed -i "/^\s*restore_default_config_pid/ s/[0-9]*$/$1/" $0
	}

	restore_default_config() {
		#~/.orw/scripts/notify.sh "$restore_default_config_pid"
		#((restore_default_config_pid)) && kill $restore_default_config_pid &&
		#((restore_default_config_pid)) && kill $restore_default_config_pid
		#((restore_default_config_pid)) && kill $restore_default_config_pid &> /dev/null
		#echo "pid: $restore_default_config_pid" > ~/Desktop/pid
		((restore_default_config_pid)) &&
			[[ -d /proc/$restore_default_config_pid ]] && kill $restore_default_config_pid
		#[[ -d /proc/$restore_default_config_pid ]] && kill $restore_default_config_pid &> /dev/null

		(sleep 10
		killall dunst
		dunst &> /dev/null &
		#dunstify '' 'killed dunst'
		set_pid) &

		bkg_pid=$!
		#echo "$bkg_pid"
		set_pid $bkg_pid
	}

	#[[ "$type" =~ dunst$ ]] && killall dunst
	[[ "$type" =~ ${1}_dunstrc$ ]] || killall dunst

	restore_default_config_pid=
	restore_default_config

	pid=$(pidof dunst)
	((pid)) || dunst -conf ~/.config/dunst/${1}_dunstrc &> /dev/null &

	#icon=$2
	if [[ $1 == osd ]]; then
		color_bar() {
			for p in $(seq $2); do
				#eval $1+='▀'
				#eval $1+='▊'
				eval $1+='▖'
			done
		}

		icon_size=48
		info_size=10
		icon="<span font='Iosevka Orw $icon_size' foreground='$sbg'>$2</span>"

		if [[ $3 =~ ^[0-9]+/[0-9]+$ ]]; then
			color_bar level ${3%/*}
			color_bar empty ${3#*/}

			#info="<span font='Iosevka Orw $info_size' foreground='\$pbfg'>$level<span foreground='\$sbg'>$empty</span></span>"
			info="<span font='Iosevka Orw $info_size' foreground='$pbfg'>$level<span foreground='$sbg'>$empty</span></span>"
			#info="<span font='Iosevka Orw $info_size' foreground='$fg'>$2</span>"
		else
			info_offset=$(awk '{
				m = $0
				l = length(m)
				d = (20 - l) / 2
				printf("%*.s%s%*.s", d, " ", m, d, " ") }' <<< "$3")
			info="<span font='Iosevka Orw $info_size' foreground='$fg'>$info_offset</span>"
		fi

		dunstify -r 292 '' "<span>\n$icon\n\n\n$info</span>"
	elif [[ $1 == mini ]]; then
		icon="<span foreground='$pbfg' font='Iosevka Orw 11'> $2 </span>"
		info="<span foreground='$fg' font='Iosevka Orw 12'> $3 </span>"
		dunstify -r 292 '' "$icon$info"
	else
		color_vertical_bar() {
			printf ' ┃ %.0s\n' $(seq 1 $1)
		}

		level_value=${3%/*}
		level=$(color_vertical_bar $((level_value / 2)))
		empty=$(color_vertical_bar $((10 - level_value / 2)))

		font='DejaVu Sans Mono'
		empty_bar="<span font='$font 15' foreground='$sbg'>$empty</span>"
		level_bar="<span font='$font 15' foreground='$pbfg'>$level</span>"

		dunstify -r 292 '' "<span foreground='$sbg' font='$font 13'>\n$empty_bar\n$level_bar\n\n $2 \n</span>"
	fi

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

		sed -i "s/\(^\s*geometry.*x[0-9]*\)[^\"]*/\1-$x_offset+$y_offset/" ~/.config/dunst/{mini_,}dunstrc

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

message="$(sed "s/\$fg/$fg/g; s/\$pbfg/$pbfg/g; s/\$sbg/$sbg/g" <<< "${@: -1}")"

dunstify -i ${icon-none} $time $replace 'summery' "<span font='${font:-Roboto Mono} ${padding_height-6}'>\n\
	<span font='Roboto Mono ${font_size:-8}'>$padding$offset${message//\\n/$offset\\n$offset}$offset$padding</span>\n</span>"
