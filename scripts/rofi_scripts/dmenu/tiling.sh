#!/bin/bash

theme=$(awk -F '[".]' 'END { print $(NF - 2) }' ~/.config/rofi/main.rasi)
orw_conf=~/.config/orw/config

[[ $theme != icons ]] &&
	wm_mode=wm_mode full=full use_ratio=use_ratio move=move interactive=interactive \
	offset=offset margin=margin reverse=reverse direction=direction sep=' '

get_state() {
	read wm_icon wm_active \
		{full,offset,margin,reverse,direction,interactive}_icon active{_direction,} <<< \
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
					case "h": d = ""; ad = 0; break
					case "v": d = ""; ad = 1; break
					default: d = ""; ad = 2
				}
			} else if(/^full/) {
				if (dir == "v") f = (rev) ? "" : ""
				else f = (rev) ? "" : ""
				if($NF == "true") a = a ",1"
			} else if(/^offset/) o = ""
			else if(/^margin/) m = ""
			else if(/^reverse/) {
				r = ""
				r = ""
				rev = ($NF == "true")
				if(rev) a = a ",7"
			} else if (/^interactive/) {
				i = ""
				i = ""
				i = ""
				if ($NF == "true") a = a ",4"
			}
		} END {
			o = ""; m = ""
			print wm, wma, f, o, m, r, d, i, ad, a
		}' ~/.config/orw/config)

	[[ $active && $active != -a* ]] && active="-a ${active#,}"
	#tile_icon=      
	tile_icon=''
	tile_icon=''
	move_icon=''
	move_icon=''
	untile_icon='' #
	rotate_icon=''
	rotate_icon=''
	rotate_icon=''
	rotate_icon=''
	rotate_icon=''
}

id=$(printf '0x%.8x' $(xdotool getactivewindow))

#toggle_rofi() {
#	~/.orw/scripts/signal_windows_event.sh rofi_toggle
#}

toggle_rofi
#trap toggle_rofi EXIT

update_value() {
	local property=$1 value=$2
	~/.orw/scripts/borderctl.sh w_$property $direction$value
}

set_margin() {
	local index

	while
		read index margin_direction <<< $(echo -e '\n' |
			rofi -dmenu -format 'i s' -selected-row ${index:-1} -theme main)
		[[ $margin_direction ]]
	do
		[[ $margin_direction ==  ]] && direction=+ || direction=-
		update_value m 5
	done
}

icon_x_down=
icon_x_up=
icon_y_up=
icon_y_down=

wait_to_proceed() {
	while true; do
		sleep 0.1
	done &
	local while_pid=$!
	wait $while_pid
	kill $while_pid
}

trap : USR1
#trap "~/.orw/scripts/notify.sh 'EXITING'" INT KILL EXIT

set_offset() {
	local index interactive=$(awk '$1 == "interactive" { print $NF == "true" }' $orw_conf)
	#~/.orw/scripts/notify.sh -t 11 "INT: $interactive"

	if ((interactive)); then
		~/.orw/scripts/signal_windows_event.sh offset_int
		exit
	else
		while
			read index option <<< $(cat <<- EOF | rofi -dmenu -format 'i s' -selected-row ${index:-0} -theme main
				$icon_x_down$sep$x_down
				$icon_x_up$sep$x_up
				$icon_y_up$sep$y_up
				$icon_y_down$sep$y_down
			EOF
			)

			[[ $option ]]
		do
			[[ $option =~ [0-9]+ ]] && value=${@##* }
			[[ $option =~ ^($icon_x_up|$icon_y_up) ]] && direction=+ || direction=-
			[[ $option =~ ^($icon_x_up|$icon_x_down) ]] && orientation=x || orientation=y
			update_value $orientation 20
			wait_to_proceed
		done
	fi
}

set_direction() {
	read new_{active_direction,direction_icon} <<< \
		$(echo -e '\n\n' | rofi -dmenu -a $active_direction -format 'i s' -theme main)

	if [[ $new_direction_icon ]]; then
		case $new_direction_icon in
			) direction=auto;; 
			) direction=h;;
			) direction=v;;
		esac

		active_direction=$new_active_direction
		direction_icon=$new_direction_icon
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
	local property=$1 index=$2 value=$3 icon=${1}_icon state
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

while
	get_state
		#$wm_icon$sep$wm_mode
	read index action <<< \
		$(cat <<- EOF | rofi -dmenu -format 'i s' -selected-row $index $active -theme main
		$direction_icon$sep$direction
		$full_icon$sep$full
		$offset_icon$sep$offset
		$margin_icon$sep$margin
		$interactive_icon$sep$interactive
		$tile_icon$sep$move
		$untile_icon$sep$untile
		$move_icon$sep$move
		$reverse_icon$sep$reverse
		$rotate_icon$sep$rotate
	EOF
	)

	[[ $action ]]
do
	case $action in
		*$full_icon*) set_value full;;
		*$offset_icon*) set_offset;;
		*$margin_icon*) set_margin;;
		*$move_icon*|*$tile_icon*|*$untile_icon*|*$rotate_icon*)
			case $action in
				*$move_icon*) action=mv;;
				*$tile_icon*) action=tile;;
				*$untile_icon*) action=untile;;
				*$rotate_icon*) action=rotate;;
			esac

			~/.orw/scripts/signal_windows_event.sh $action
			exit
			;;
		*$interactive_icon) set_value interactive;;
		*$reverse_icon*) set_value reverse;;
		*$direction_icon*) set_direction;;
		*$wm_icon*)
			[[ $theme == icons ]] &&
				wm_mode_icons=(           ) &&
				wm_mode_icons=(   $twm_icon       ) &&
				wm_mode_icons=(   $twm_icon       ) &&

			wm_modes=( floating tiling auto stack selection )

			[[ $theme == icons ]] && rep=wm_mode_icons || rep=wm_modes
			eval modes=( \${$rep[*]} )

			mode_index=$(for mode in ${modes[*]}; do
				echo "$mode"
			done | rofi -dmenu -a $wm_active -format i -theme main)

			[[ $mode_index ]] && mode=${wm_modes[mode_index]}
			~/.orw/scripts/toggle.sh wm $option $mode
	esac
done

toggle_rofi
exit

~/.orw/scripts/signal_windows_event.sh update

[[ $option || $mode ]] && ~/.orw/scripts/toggle.sh wm $option $mode
