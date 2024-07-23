#!/bin/bash

theme=$(awk -F '[".]' 'END { print $(NF - 2) }' ~/.config/rofi/main.rasi)
orw_conf=~/.config/orw/config

[[ ! $style =~ icons|dmenu ]] &&
	wm_mode=wm_mode full=full use_ratio=use_ratio move=move interactive=interactive \
	offset=offset margin=margin reverse=reverse direction=direction sep=' '

get_state() {
	read wm wm_active \
		{full,offset,margin,reverse,direction,interactive} active{_direction,} <<< \
		$(awk '{
			if(/^mode/) {
				m = $NF

				if(m == "tiling") { wm = ""; wma = 1 }
				else if(m == "stack") { wm = ""; wma = 3 }
				else if(m == "floating") { wm = ""; wma = 0 }
				else { wm = ""; wma = 4 }
			}
			else if(/^direction/) {
				switch ($NF) {
					case "h": d = ""; ad = 2; break
					case "v": d = ""; ad = 1; break
					default: d = ""; ad = 0
				}
			} else if(/^full/) {
				if (dir == "v") f = (rev) ? "" : ""
				else f = (rev) ? "" : ""
				if($NF == "true") a = a ",1"
			} else if(/^offset/) o = ""
			else if(/^margin/) m = ""
			else if(/^reverse/) {
				r = ""
				rev = ($NF == "true")
				if(rev) a = a ",4"
			} else if (/^interactive/) {
				i = ""
				if ($NF == "true") a = a ",5"
			}
		} END {
			o = ""; m = ""
			print wm, wma, f, o, m, r, d, i, ad, a
		}' ~/.config/orw/config)

	[[ $active && $active != -a* ]] && active="-a ${active#,}"
	read rotate move {,un_}tile <<< \
		$(sed -n 's/^\(.*tile\|move\|rotate\)//p' ~/.orw/scripts/icons | xargs)
}

id=$(printf '0x%.8x' $(xdotool getactivewindow))

toggle

update_value() {
	local property=$1 value=$2
	~/.orw/scripts/borderctl.sh w_$property $direction$value
}

set_margin() {
	local index direction theme_str item_count=2
	set_theme_str

	while
		read index margin_direction <<< $(echo -e '\n' |
			rofi -dmenu -format 'i s' -theme-str "$theme_str" \
			-selected-row ${index:-1} -theme main)
		[[ $margin_direction ]]
	do
		[[ $margin_direction ==  ]] && direction=+ || direction=-
		update_value m 5
	done
}

read up down left right <<< $(sed -n 's/arrow.*empty=//p' ~/.orw/scripts/icons | xargs)

wait_to_proceed() {
	while true; do
		sleep 0.1
	done &
	local while_pid=$!
	wait $while_pid
	kill $while_pid
}

trap : USR1

set_offset() {
	local index direction theme_str item_count=4
	local interactive=$(awk '$1 == "interactive" { print $NF == "true" }' $orw_conf)
	set_theme_str

	if ((interactive)); then
		~/.orw/scripts/signal_windows_event.sh offset_int
		exit
	else
		while
			read index option <<< $(cat <<- EOF | rofi -dmenu -format 'i s' -theme-str "$theme_str" -selected-row ${index:-0} -theme main
				$x_down
				$x_up
				$y_up
				$y_down
			EOF
			)

			[[ $index ]]
		do
			[[ $option =~ [0-9]+ ]] && value=${@##* }
			[[ $option =~ ^($x_up|$y_up) ]] && direction=+ || direction=-
			[[ $option =~ ^($x_up|$x_down) ]] && orientation=x || orientation=y
			update_value $orientation 20
			[[ $style =~ vertical_icons|dmenu ]] && wait_to_proceed
		done
	fi
}

set_direction() {
	local direction theme_str item_count=3
	set_theme_str

	read new_{active_direction,direction} <<< \
		$(sed -n 's/^.*direction=//p' ~/.orw/scripts/icons |
		rofi -dmenu -format 'i s' -theme-str "$theme_str" -a $active_direction -theme main)

	if [[ $new_active_direction ]]; then
		case $new_active_direction in
			0) direction=auto;; 
			1) direction=v;;
			2) direction=h;;
		esac

		active_direction=$new_active_direction
		direction_icon=$new_direction
		set_value direction $direction
	fi
}

set_value() {
	local property=$1 value=$2 icon=${1}_icon state
	read state active <<< $(awk -i inplace '
			/^'$property'/ {
				v = "'"$value"'"
				i = "'"$index"'"
				a = "'"$active"'"

				$NF = (v) ? (v ~ "[-+][0-9]*") ? $NF + v : v \
					: ($NF == "true") ? "false" : "true"

				if ($NF == "false") gsub(",?" i "|" i ",?", "", a)
				else if ($NF == "true") a = a "," i

				s = (v) ? v : ($NF == "true") ? "enabled" : "disabled"
			} { print }

			END { print s, a }
		' $orw_conf)

	~/.orw/scripts/notify.sh -r 22 -t 1200m -s osd -i ${!icon} "$property: ${state^^}"
	~/.orw/scripts/signal_windows_event.sh update
}

close_rofi() {
	trap - EXIT
	exit
}

set_interactive() {
	local property=$1 index=$2 icon=${1}_icon value=$3 state
	read state active <<< $(awk -i inplace '
			/^'$property'/ {
				v = "'"$value"'"
				i = "'"$index"'"
				a = "'"$active"'"

				if ($NF == "true") {
					$NF = "false"
					gsub(",?" i "|" i ",?", "", a)
				} else {
					$NF = "true"
					a = a "," i
				}

				s = $NF
			} { print }

			END { print s, a }
		' ~/.config/orw/config)

	~/.orw/scripts/notify.sh -s osd -i ${!icon} "$property: ${state^^}"
}

item_count=6
set_theme_str

while
	get_state
	read index action <<< \
		$(cat <<- EOF | rofi -dmenu -format 'i s' -theme-str "$theme_str" -selected-row $index $active -theme main
		$direction
		$full
		$offset
		$margin
		$reverse
		$interactive
	EOF
	)

	[[ $action ]]
do
	case $action in
		*$full*) set_value full;;
		*$offset*) set_offset;;
		*$margin*) set_margin;;
		*$move*|*$tile*|*$untile*|*$rotate*)
			case $action in
				*$move*) action=mv;;
				*$tile*) action=tile;;
				*$untile*) action=untile;;
				*$rotate*) action=rotate;;
			esac

			~/.orw/scripts/signal_windows_event.sh $action
			exit
			;;
		*$interactive) set_value interactive;;
		*$reverse*) set_value reverse;;
		*$direction*) set_direction;;
	esac
done

toggle
