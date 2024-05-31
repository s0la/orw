#!/bin/bash

time=3

while getopts :i:F:f:o:r:c:t:P:ps:b:v:T flag; do
	case $flag in
		p) padding='\n';;
		v) value=$OPTARG;;
		F) font="$OPTARG";;
		f) font_size=$OPTARG;;
		o) offset_count=$OPTARG;;
		r) replace="-r $OPTARG";;
		P) padding_height=$OPTARG;;
		c) config="-config $OPTARG";;
		T) no_top=true;;
		b)
			bar=true
			level_value=${OPTARG%/*}
			empty_value=${OPTARG#*/};;
		#t) time=$((OPTARG * 1000));;
		t)
			[[ $OPTARG =~ m$ ]] &&
				miliseconds=true sleep_time=2
			time=${OPTARG%m};;
		s)
			style=$OPTARG
			[[ $style == default ]] &&
				style_config=dunstrc || style_config=${style}_dunstrc;;
		i) [[ -f "$OPTARG" ]] && image="-i $OPTARG" || font_icon=$OPTARG;;
	esac
done

read bg fg <<< $(awk -F '"' '/urgency_normal/ { nr = NR } \
	{ if(nr && NR > nr && NR <= nr + 2) print $2 }' ~/.config/dunst/dunstrc | xargs)

sbg="#2c2c2c"
pbfg="#8aa5b4"

type=$(ps -C dunst -o args=)
[[ $style_config ]] || style_config=dunstrc

color_bar() {
	printf "$1%.0s$3" $(seq 1 $2)
}

set_pid() {
	sed -i "/^\s*restore_default_config_pid/ s/[0-9]*$/$1/" $0
}

restore_default_config() {
	#running_pids=( $(pidof -o %PPID -x $0) )

	#(while
	#	running_pids=( $(pidof -o %PPID -x $0) )
	#	echo '' "running ${running_pids[*]}" >> ~/Desktop/not_log
	#	((${#running_pids[*]}))
	#do
	#	sleep $((time + 1))
	#done

	(
	#echo '' "running ${running_pids[*]}" >> ~/Desktop/not_log
	sleep $((${sleep_time:-$time} + 1))

	#killall dunst &> /dev/null
	pidof dunst | xargs kill -9 &> /dev/null
	#echo '' "closing ${running_pids[*]}" >> ~/Desktop/not_log
	dunst &> /dev/null &) &> /dev/null &
	#echo '' "closing ${running_pids[*]}" >> ~/Desktop/not_log) &
	#[[ $running_pid ]] && kill ${running_pid[*]}




	#((restore_default_config_pid)) &&
	#	[[ -d /proc/$restore_default_config_pid ]] && kill $restore_default_config_pid

	#(sleep 10
	#killall dunst
	#dunst &> /dev/null &
	#set_pid) &

	#set_pid $!
}

restore_default_config() {
	(
		#echo SLEEP ${sleep_time:-$time} $style >> ~/d.log
		#sleep $((${sleep_time:-$time} + 0))
		sleep ${sleep_time:-$time}

		while
			displayed=$(dunstctl count displayed)
			#echo "$displayed" >> ~/d.log
			((displayed))
		do
			sleep 1
		done

		#ps -C dunst -o args= >> ~/d.log

		pidof dunst | xargs -r kill -9 &> /dev/null
		#echo STARTING DEFAULT >> ~/d.log
		dunst &> /dev/null &
	) &
}

running_pids=( $(pidof -o %PPID -x $0) )
running_count=${#running_pids[*]}
#((running_count)) && echo "killing ${running_pids[*]}" >> ~/Desktop/not_log
((running_count)) && kill -9 ${running_pids[*]} &> /dev/null

if [[ $style =~ ^(osd|vert) ]]; then
	restore_default_config_pid=

	#read {x,y}_offset <<< $(grep offset ~/.config/orw/offsets | xargs eval)
	#read {x,y}_offset <<< $(grep offset ~/.config/orw/offsets | xargs eval)
	#eval $(grep offset ~/.config/orw/offsets | xargs)

	#if ((!restore_default_config_pid)); then
	if ((!running_count)); then
		read info_size icon_size geometry <<< \
			$(awk '\
				BEGIN { s = "'$style'" }
				/^mode/ { f = ($NF == "floating") }
				/^x_offset/ { x = $NF }
				/^primary/ { p = $NF }
				p && $1 == p "_size" {
					dw = $2
					dh = $3

					if(s == "osd") {
						h = s = int(dw * 0.1)

						if("'$bar'") {
							bs = sprintf("%.0f", s * 0.025)
							w = int(bs * 40)
							#bs = sprintf("%.0f", s * 0.03)
							#w = int(bs * 35)
						} else {
							bs = sprintf("%.0f", s * 0.05)
							w = int(bs * 20)
						}

						is = int(s * 0.3)
						x = int((dw - w) / 2)
						#y = int((dh + h) / 2)
						y = int(dh / 3 * 2)

						o = "+"
					} else {
						bs = 15
						is = bs - 2

						h = 10 * bs + 4 * is
						w = 3 * bs
						y = int((dh - h) / 2)

						#if(f) x = int(x / 2)
						##else if(x > w) x -= w
						#else if(x > w) x = int((x - w) / 2)
						x = (x > w) ? int((x - w) / 2) : int(x / 2)

						o = "-"
					}

					print bs, is, w "x" h o x "+" y
				}' ~/.config/orw/config)

		awk -i inplace '/^\s*geometry/ {
				sub(/".*"/, "\"" "'$geometry'" "\"")
			} { print }' ~/.config/dunst/${style}_dunstrc

		if [[ $style == osd ]]; then
			sed -i "/info_size=[0-9]\+$/ s/[0-9]\+/$info_size/" $0
			sed -i "/icon_size=[0-9]\+$/ s/[0-9]\+/$icon_size/" $0
		fi
	fi
else
	#pid=$(pidof dunst)
	pid=( $(pidof dunst) )

	#if ((pid)); then
	if ((${#pid[*]})); then
		[[ ! "$type" =~ (dunst|/$style_config)$ ]] && kill -9 ${pid[*]} &> /dev/null
		#if [[ ! "$type" =~ (dunst|/$style_config)$ ]]; then
		#	killall dunst
		#	dunst &> /dev/null &
		#fi
	fi
	#else
		read {x,y}_offset <<< \
			$(awk '/^[xy]_offset/ { print $NF * 2 }' ~/.config/orw/config | xargs)

		#while read -r bar_name position bar_x bar_y bar_width bar_height adjustable_width frame; do
		#	if ((position)); then
		#		current_bar_height=$((bar_y + bar_height + frame))
		#		((current_bar_height > max_bar_height)) && max_bar_height=$current_bar_height
		#	fi
		#done <<< $(~/.orw/scripts/get_bar_info.sh)


		max_bar_height=$(awk '
				/y_offset/ { yo = $NF }
				/primary/ { d = $NF }
				$1 ~ d "_xy" { y = $NF }
				d && $1 ~ d "_offset" { print y + yo + $2; exit }
			' ~/.config/orw/config)

		dmenu=$(awk -F '"' 'END { print $(NF - 1) == "dmenu" }' ~/.config/rofi/main.rasi)
		((dmenu)) &&
			dmenu_height=$(awk '
				function get_value(position) {
					pattern = (position == "f") ? "[^0-9]" : "."
					return gensub(pattern "*([0-9]+).*", "\\1", 1)
				}

				/padding/ && !p { p = get_value("f") }
				/border/ { b = get_value("l") }
				/font/ { print get_value("f") + 2 * (p + b + 1); exit }' ~/.config/rofi/{dmenu,theme}.rasi)

		#((dmenu)) && dmenu_height=$(~/.orw/scripts/get_dmenu_height.sh)
		(( y_offset += max_bar_height + dmenu_height ))

		#sed -i "s/\(^\s*geometry.*x[0-9]*\)[^\"]*/\1-$x_offset+$y_offset/" ~/.config/dunst/{mini_,}dunstrc

		dunst &> /dev/null &
	#fi

	[[ $style != *osd* ]] && bottom_padding=true
fi

if [[ $style ]]; then
	offset_count=0
	padding_height=0

	case $style in
		osd)
			((icon_size)) || icon_size=57
			((info_size)) || info_size=10
			icon="<span font='Iosevka Orw $icon_size' foreground='$fg'>$font_icon</span>"

			if [[ $bar ]]; then
				#remove for vertical bars
				#((level_value /= 2))
				#empty_value=$((10 - level_value))
				#((level_value -= 2))
				#empty_value=$((16 - level_value))

				level=$(color_bar '▖' $level_value)
				empty=$(color_bar '▖' $empty_value)

				level=$(color_bar '➖' $level_value)
				empty=$(color_bar '➖' $empty_value)

				level=$(color_bar '' $level_value)
				empty=$(color_bar '' $empty_value)

				#level=$(color_bar '▂' $level_value)
				#empty=$(color_bar '▂' $empty_value)

				bar="<span font='Iosevka Orw $info_size' foreground='$pbfg'>$level<span foreground='$sbg'>$empty</span></span>"
			else
				info_offset=$(awk '{
					m = ("'"$no_top"'") ? $0 : "<b>" toupper($0) "</b>"
					l = length(m)
					d = (20 - l) / 2
					printf("%*.s%s%*.s", d, " ", m, d, " ") }' <<< "${value:-${@: -1}}")
				#info="<span font='Iosevka Orw $info_size' foreground='$fg'><b>${info_offset^^}</b></span>"
				#info="<span font='Iosevka Orw $info_size' foreground='$fg'><b>$info_offset</b></span>"
				info="<span font='Iosevka Orw $info_size' foreground='$fg'>$info_offset</span>"
			fi

			padding_height=3
			message="<span>\n$icon\n\n\n${bar:-$info}</span>";;
		vertical)
			#level=$(color_bar "  ┃  " $level_value '\n')
			#empty=$(color_bar "  ┃  " $empty_value '\n')

			font='SFMono'
			font='DejaVu Sans Mono'

			bar_icon="<span font='$font 15'>┃</span>"
			vert_padding="<span font='$font 12'> </span>"
			bar_row="$vert_padding$vert_padding$bar_icon$vert_padding$vert_padding"
			level=$(color_bar "$bar_row" $level_value '\n')
			empty=$(color_bar "$bar_row" $empty_value '\n')
			icon_padding="<span font='$font 11'> </span><span font='$font 9'> </span>"
			font_icon="$icon_padding$font_icon$icon_padding"

			#slider=true

			if [[ $slider ]]; then
				slider_icon="<span font='$font 17'>  \\n</span>"
				slider_icon="<span font='$font 13'>  \\n</span>"
				slider_icon="<span font='$font 13'>  \\n</span>"
				slider_icon="<span font='$font 13'>  \\n</span>"
				slider_icon="<span font='$font 17'>  \\n</span>"
				slider_icon="<span font='$font 17'>  \\n</span>"
				sbg=$pbfg
			fi


						empty_bar="<span font='$font 15' foreground='$sbg'>$empty</span>"
			#empty_bar="<span font='$font 15' foreground='$pbfg'>$empty</span>"
			#level_bar="<span font='$font 15' foreground='$pbfg'>$level</span>"
			level_bar="<span font='$font 15' foreground='$pbfg'>$slider_icon$level</span>"

			message="<span foreground='$fg' font='$font 13'>\n"$empty_bar\\n$level_bar"\n\n$font_icon\n</span>"
			#echo -e "$empty_bar,      $level_bar"
			#echo -e "$message";;
			;;
		mini)
			icon="<span foreground='$pbfg' font='Iosevka Orw 11'> $font_icon </span>"
			info="<span foreground='$fg' font='Iosevka Orw 12'> ${value :-${@: -1}}</span>"
			message="$icon$info"

			unset bottom_padding;;
		default)
			font='Iosevka Orw'
			font='Roboto Mono'
			font='DejaVu Sans Mono'
			font='Iosevka Orw'

			#dashes=true

			if [[ $bar ]]; then
				#[[ $dashes ]] && bar_icon= || bar_icon=
				[[ $dashes ]] && bar_icon= || bar_icon=━

				level=$(color_bar $bar_icon $level_value)
				empty=$(color_bar $bar_icon $empty_value)

				empty_bar="<span font='$font 15' foreground='$sbg'>$empty</span>"
				level_bar="<span font='$font 15' foreground='$pbfg'>$level</span>"
			fi

			icon="<span font='$font ${font_size:-12}' foreground='$fg'>$font_icon</span>"
			message="$icon    $level_bar$empty_bar "

			padding='\n' padding_height=8 offset_count=6
	esac

	[[ $style != default ]] && restore_default_config

	#if [[ ! "$type" =~ /$style_config$ ]]; then
	#	echo "$type is not $style_config, thus killing all" >> ~/Desktop/dunst_log
	#	killed=killed
	#	#killall dunst
	#	kill -9 $(pidof dunst)
	#fi

	#[[ ! "$type" =~ /$style_config$ ]] && kill -9 $(pidof dunst)
	#echo "$type, /$style_config"
	#echo "$type, /$style_config"
	##[[ ($type =~ dunst$ && ! $style_config =~ /dunstrc$) ]] && echo def not #|| echo def yes
	#[[ ($type =~ dunst$ && $style_config == dunstrc) ]] && echo def yes || echo def no
	#[[ "$type" =~ /$style_config$ ]] && echo type yes || echo type no


	[[ ($type =~ dunst$ && $style_config != dunstrc) ||
		(! $type =~ dunst$ && ! "$type" =~ /$style_config$) ]] &&
		pidof dunst | xargs kill -9 &> /dev/null
		#echo killed &&

	#[[ !("$type" =~ /$style_config$) ||
	#	($type == dunst && (!$style_config ||
	#	($style_config && $style_config =~ /dunstrc$))) ]] &&
	#	pidof dunst | xargs kill -9

	pid=$(pidof dunst)
	#echo "$killed $pid: $type ~ $style_config" >> ~/Desktop/dunst_log
	#((pid)) && ps aux | awk '$2 == "'$pid'"' >> ~/Desktop/dunst_log
	#((pid)) || dunst -conf ~/.config/dunst/$style_config &> /dev/null &
	[[ $pid ]] || dunst -conf ~/.config/dunst/$style_config &> /dev/null &
fi

[[ $message ]] || message="$(sed "s/\$fg/$fg/g; s/\$pbfg/$pbfg/g; s/\$sbg/$sbg/g" <<< "${@: -1}")"

padding_font="<span font='${font:-Roboto Mono} ${padding_height-6}'>\n</span>"
[[ $bottom_padding ]] && bottom_padding="$padding_font"

font="Roboto Mono ${font_size:-8}"
offset="<span font='$font'>$(printf "%-${offset_count-10}s")</span>"

[[ $miliseconds ]] || ((time *= 1000))
dunstify $image -t $time $replace 'summery' \
	"$padding_font<span font='$font'>$padding$offset${message//\\n/$offset\\n$offset}$offset$padding</span>$bottom_padding"
