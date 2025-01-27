#!/bin/bash

time=3

while getopts :i:F:f:o:r:c:t:P:ps:b:v:TC: flag; do
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
		t)
			[[ $OPTARG =~ m$ ]] &&
				miliseconds=true sleep_time=2
			time=${OPTARG%m};;
		s)
			style=$OPTARG
			[[ $style == default ]] &&
				style_config=dunstrc || style_config=${style}_dunstrc;;
		i) [[ -f "$OPTARG" ]] && image="-i $OPTARG" || font_icon=$OPTARG;;
		C) font_color=$OPTARG;;
	esac
done

read bg fg <<< $(awk -F '"' '/urgency_normal/ { nr = NR } \
	{ if(nr && NR > nr && NR <= nr + 2) print $2 }' ~/.config/dunst/dunstrc | xargs)

sbg="#8899a5"
pbfg="#608e9a"

type=$(ps -C dunst -o args=)
[[ $style_config ]] || style_config=dunstrc

color_bar() {
	printf "$1%.0s$3" $(seq 1 $2)
}

set_pid() {
	sed -i "/^\s*restore_default_config_pid/ s/[0-9]*$/$1/" $0
}

restore_default_config() {
	(
		sleep $((${sleep_time:-$time} + 1))
		pidof dunst | xargs kill -9 &> /dev/null
		dunst &> /dev/null &
	) &> /dev/null &
}

restore_default_config() {
	{
		sleep ${sleep_time:-$time}

		while
			displayed=$(dunstctl count displayed)
			((displayed))
		do
			sleep 1
		done

		pidof dunst | xargs -r kill -9 #&> /dev/null
		dunst & #&> /dev/null &
	} &> /dev/null &
}

running_pids=( $(pidof -o %PPID -x $0) )
running_count=${#running_pids[*]}
((running_count)) && kill -9 ${running_pids[*]} &> /dev/null

if [[ $style =~ ^(osd|vert) ]]; then
	restore_default_config_pid=

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
					} else {
						bs = sprintf("%.0f", s * 0.05)
						w = int(bs * 20)
					}

					is = int(s * 0.3)
					x = int((dw - w) / 2)
					y = int(dh / 3 * 2)

					o = "+"
				} else {
					bs = 15
					is = bs - 2

					h = 10 * bs + 4 * is
					w = 3 * bs
					y = int((dh - h) / 2)

					x = (x > w) ? int((x - w) / 2) : int(x / 2)

					o = "-"
				}

				print bs, is, w "x" h o x "+" y
			}' ~/.config/orw/config)

	if ((!running_count)); then
		awk -i inplace '/^\s*geometry/ {
				sub(/".*"/, "\"" "'$geometry'" "\"")
			} { print }' ~/.config/dunst/${style}_dunstrc

		if [[ $style == osd ]]; then
			#sed -i "/info_size=[0-9]\+$/ s/[0-9]\+/$info_size/" $0
			sed -i "/icon_size=[0-9]\+$/ s/[0-9]\+/$icon_size/" $0
		fi
	fi
else
	pid=( $(pidof dunst) )

	((${#pid[*]})) && [[ ! "$type" =~ (dunst|/$style_config)$ ]] &&
		kill -9 ${pid[*]} &> /dev/null

	read {x,y}_offset <<< \
		$(awk '/^[xy]_offset/ { print $NF * 2 }' ~/.config/orw/config | xargs)

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

	(( y_offset += max_bar_height + dmenu_height ))

	dunst &> /dev/null &

	[[ $style != *osd* ]] && bottom_padding=true
fi

if [[ $style ]]; then
	offset_count=0
	padding_height=0

	case $style in
		osd)
			((icon_size)) || icon_size=
			#((info_size)) || info_size=5
			[[ $bar ]] && info_size=5

			[[ $font_color && $font_color != '#'* ]] &&
				icon_fg="${!font_color}" || icon_fg="$font_color"
			icon="<span font='Iosevka Orw $icon_size' foreground='${icon_fg:-$fg}'>$font_icon</span>"

			if [[ $bar ]]; then
				level=$(color_bar '▖' $level_value)
				empty=$(color_bar '▖' $empty_value)

				level=$(color_bar '➖' $level_value)
				empty=$(color_bar '➖' $empty_value)

				level=$(color_bar '' $level_value)
				empty=$(color_bar '' $empty_value)

				bar="<span font='Iosevka Orw $info_size' foreground='$pbfg'>$level<span foreground='$sbg'>$empty</span></span>"
			else
				info_offset=$(awk '{
					m = ("'"$no_top"'") ? $0 : "<b>" toupper($0) "</b>"
					l = length(m)
					d = (20 - l) / 2
					printf("%*.s%s%*.s", d, " ", m, d, " ") }' <<< "${value:-${@: -1}}")
				info="<span font='Iosevka Orw $info_size' foreground='$fg'>$info_offset</span>"
			fi

			padding_height=3
			message="<span>\n$icon\n\n\n${bar:-$info}</span>";;
		vertical)
			font='SFMono'
			font='DejaVu Sans Mono'

			bar_icon="<span font='$font 15'>┃</span>"
			vert_padding="<span font='$font 12'> </span>"
			bar_row="$vert_padding$vert_padding$bar_icon$vert_padding$vert_padding"
			level=$(color_bar "$bar_row" $level_value '\n')
			empty=$(color_bar "$bar_row" $empty_value '\n')
			icon_padding="<span font='$font 11'> </span><span font='$font 9'> </span>"
			font_icon="$icon_padding$font_icon$icon_padding"

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
			level_bar="<span font='$font 15' foreground='$pbfg'>$slider_icon$level</span>"

			message="<span foreground='$fg' font='$font 13'>\n"$empty_bar\\n$level_bar"\n\n$font_icon\n</span>"
			;;
		mini)
			if [[ $bar ]]; then
				bar_icon=━
				level=$(color_bar $bar_icon $level_value)
				empty=$(color_bar $bar_icon $empty_value)

				empty_bar="<span font='$font 11' foreground='$sbg'>$empty</span>"
				level_bar="<span font='$font 11' foreground='$pbfg'>$level</span>"
			fi

			#icon="<span foreground='$pbfg' font='Iosevka Orw 11'> $font_icon </span>"
			#info="<span foreground='$fg' font='Iosevka Orw 12'> ${value :-${@: -1}}</span>"
			#message="$icon$info"

			side_font=7
			icon_font=15
			icon_padding=2
			padding_in_icon_row="$(color_bar " " $icon_padding)"
			#padding_in_side_row="$(color_bar " " $((icon_font / side_font * (4 * icon_padding + 0) + 0)))"
			padding_in_side_row="$(color_bar " " $((icon_font / side_font * (2 * icon_padding + 1) + 0)))"

			ibg="$(~/.orw/scripts/convert_colors.sh -hV -10 $sbg)"
			ibg=$sbg
			icon_area="$padding_in_icon_row$font_icon$padding_in_icon_row"
			icon="<span font='SFMono $icon_font' background='$ibg' foreground='$fg'>$icon_area</span>"
			side_row_icon_area="<span background='$ibg'>$padding_in_side_row</span>"
			side_row="<span font='SFMono $side_font'>$side_row_icon_area</span>"
			info="<span foreground='$fg' font='SFMono $icon_font'><b>${value:-${@: -1}}</b></span>"
			f="<span font='SFMono 20'>   </span>"

			message="$side_row\n$icon    $level_bar$empty_bar     \n$side_row"

			#echo -e "$((icon_font / side_font * (2 * icon_padding + 1))), $icon_padding" > ~/not.log

			#[[ $style != default ]] && restore_default_config
			#[[ ($type =~ dunst$ && $style_config != dunstrc) ||
			#	(! $type =~ dunst$ && ! "$type" =~ /$style_config$) ]] &&
			#	pidof dunst | xargs kill -9 &> /dev/null

			#pid=$(pidof dunst)
			#[[ $pid ]] || dunst -conf ~/.config/dunst/$style_config &> /dev/null &

			#dunstify $image -t 5555 $replace 'summery' "$message"
			#exit

			#echo "$(xdotool get_desktop): $message" > ~/not.log
			unset bottom_padding
			;;
		default)
			font='DejaVu Sans Mono'
			font='Iosevka Orw'

			if [[ $bar ]]; then
				[[ $dashes ]] && bar_icon= || bar_icon=━

				level=$(color_bar $bar_icon $level_value)
				empty=$(color_bar $bar_icon $empty_value)

				empty_bar="<span font='$font 15' foreground='$sbg'>$empty</span>"
				level_bar="<span font='$font 15' foreground='$pbfg'>$level</span>"
			fi

			icon="<span font='$font ${font_size:-12}' foreground='$fg'>$font_icon</span>"
			message="$icon    $level_bar$empty_bar "

			padding='\n' padding_height=8 offset_count=6
			;;
		fullscreen)
			#read width height <<< $(awk '
			x=100 y=100
			message="$(awk '
				/[xy]_offset/ { if (/^x/) xo = $NF; else yo = $NF }
				/^display.*(xy|size)/ {
					if (/xy/) { dx = $2; dy = $3 }
					else {
						d = $1
						gsub("[^0-9]", "", d)

						if ('$x' >= dx + xo && '$x' <= dx + $2 - xo &&
							'$y' >= dy + yo && '$y' <= dy + $3 - yo) {
								s = 45
								f = int($3 / s - 4)
								f = 8
								p = sprintf("%*s", (s - 9) / 2, " ")
								gsub(" ", "|\\n", p)
								i = "<span font=\"SFMono " 8 * f "\">'"$font_icon"'</span>"
								printf "<span font=\"SFMono %d\">%s%s\n'"${@: -1}"'%s</span>", f, p, i, p
								exit
							}
					}
				}' ~/.config/orw/config)"


				#awk '
				#/[xy]_offset/ { if (/^x/) xo = $NF; else yo = $NF }
				#/^display.*(xy|size)/ {
				#	if (/xy/) { dx = $2; dy = $3 }
				#	else {
				#		d = $1
				#		gsub("[^0-9]", "", d)

				#		if ('$x' >= dx + xo && '$x' <= dx + $2 - xo &&
				#			'$y' >= dy + yo && '$y' <= dy + $3 - yo) {
				#				s = 5
				#				f = int($3 / s)
				#				p = sprintf("%*s", (s - 1) / 2, " ")
				#				m = "<span font=\"SFMono 20\">'"${@: -1}"'</span>"

				#				print f, "'$icon'", m
				#				exit
				#				gsub(" ", "\\n", p)
				#				printf "<span font=\"SFMono %d\">%s%s\n%s%s</span>", 13, p, "'$icon'", m, p
				#				exit
				#			}
				#	}
				#}' ~/.config/orw/config
				#exit



				#awk '
				#/[xy]_offset/ { if (/^x/) xo = $NF; else yo = $NF }
				#/^display.*(xy|size)/ {
				#	if (/xy/) { dx = $2; dy = $3 }
				#	else {
				#		d = $1
				#		gsub("[^0-9]", "", d)

				#		if ('$x' >= dx + xo && '$x' <= dx + $2 - xo &&
				#			'$y' >= dy + yo && '$y' <= dy + $3 - yo) {
				#				s = 45
				#				f = int($3 / s)
				#				print s, (s - 1) / 2, f
				#				exit
				#				p = sprintf("%*s", (s - 1) / 2, " ")
				#				gsub(" ", "\\n", p)
				#				printf "<span font=\"SFMono %d\">%sDISCONNECT%s</span>", f, p, p
				#				exit
				#			}
				#	}
				#}' ~/.config/orw/config
				#exit

				#awk '
				#	/[xy]_offset/ { if (/^x/) xo = $NF; else yo = $NF }
				#	/^display.*(xy|size)/ {
				#		if (/xy/) { dx = $2; dy = $3 }
				#		else {
				#			d = $1
				#			gsub("[^0-9]", "", d)

				#			print '$x', dx + xo, '$y', dy + yo
				#			if ('$x' >= dx + xo && '$x' <= dx + $2 - xo &&
				#				'$y' >= dy + yo && '$y' <= dy + $3 - yo) {
				#					p = sprintf("%*s", ($3 / 20 - 1) / 2, " ")
				#					gsub(" ", "\n", p)
				#					print "HERE", p
				#					exit
				#				}
				#		}
				#	}' ~/.config/orw/config
				#exit


			;;
	esac

	[[ $style != default ]] && restore_default_config
	[[ ($type =~ dunst$ && $style_config != dunstrc) ||
		(! $type =~ dunst$ && ! "$type" =~ /$style_config$) ]] &&
		pidof dunst | xargs kill -9 &> /dev/null

	pid=$(pidof dunst)
	[[ $pid ]] || dunst -conf ~/.config/dunst/$style_config &> /dev/null &
fi

[[ $message ]] || message="$(sed "s/\$fg/$fg/g; s/\$pbfg/$pbfg/g; s/\$sbg/$sbg/g" <<< "${@: -1}")"

if [[ ! $style =~ mini|fullscreen ]]; then
	padding_font="<span font='${font:-Roboto Mono} ${padding_height-6}'>\n</span>"
	[[ $bottom_padding ]] && bottom_padding="$padding_font"

	#font="Roboto Mono ${font_size:-8}"
	font="${font:-Iosevka Orw} ${font_size:-8}"
	offset="<span font='$font'>$(printf "%-${offset_count-10}s")</span>"
fi

#[[ $style == mini ]] &&
#	unset padding{,_font} offset
[[ $miliseconds ]] || ((time *= 1000))
dunstify $image -t $time $replace 'summery' \
	"$padding_font<span font='$font'>$padding$offset${message//\\n/$offset\\n$offset}$offset$padding</span>$bottom_padding"
	#"$padding_font<span font='$font'>$padding${message}$offset$padding</span>$bottom_padding"
