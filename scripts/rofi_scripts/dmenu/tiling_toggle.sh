#!/bin/bash

theme=$(awk -F '[".]' 'END { print $(NF - 2) }' ~/.config/rofi/main.rasi)
orw_conf=~/.config/orw/config

[[ $theme != icons ]] &&
	wm_mode=wm_mode full=full use_ratio=use_ratio move=move interactive=interactive \
	offset=offset margin=margin reverse=reverse direction=direction sep=' '
#[[ $theme =~ dmenu|icons ]] && ~/.orw/scripts/set_rofi_geometry.sh tiling_toggle

get_state() {
	read {,t}wm_icon wm_active \
		{full,use_ratio,offset,margin,reverse,direction,interactive}_icon active{_direction,} <<< \
		$(awk '{
			if(/^mode/) {
				m = $NF

				if(m == "tiling") { wm = ""; wma = 1 }
				else if(m == "stack") { wm = ""; wma = 3 }
				else if(m == "floating") { wm = ""; wma = 0 }
				else { wm = ""; wma = 4 }
			}
			else if(/^part/) { p = $NF }
			else if(/^ratio/) { r = 100 / $NF * p }
			else if(/^direction/) {
				dir = $NF
				d = (dir == "h") ? "" : ""
				d = (dir == "h") ? "" : ""
				twm = (dir == "h") ? "" : ""
				#if(m == "tiling") wm = twm

				switch ($NF) {
					case "h": d = ""; ad = 0; break
					case "v": d = ""; ad = 1; break
					default: d = ""; ad = 2
				}
			} else if(/^full/) {
				#if(dir == "h") f = (rev) ? "" : ""
				if (dir == "v") f = (rev) ? "" : ""
				else f = (rev) ? "" : ""
				#f = ""
				#f = ""

				if($NF == "true") a = a ",2"
			} else if(/^use_ratio/) {
				if(r < 13) ur = ""
				else if(r <= 25) ur = ""
				else if(r < 38) ur = ""
				else if(r <= 50) ur = ""
				else if(r < 63) ur = ""
				else if(r <= 75) ur = ""
				else ur = ""
				if($NF == "true") a = a ",3"
			} else if(/^offset/) {
				o = ""
				#if($NF == "true") a = a ",4"
			} else if(/^margin/) m = ""
			else if(/^reverse/) {
				r = ""
				r = ""
				rev = ($NF == "true")
				if(rev) a = a ",8"
			} else if (/^interactive/) {
				i = ""
				i = ""
				i = ""
				if ($NF == "true") a = a ",5"
			}
		} END {
			print wm, twm, wma, f, ur, o, m, r, d, i, ad, a
		}' ~/.config/orw/config)

	[[ $active && $active != -a* ]] && active="-a ${active#,}"
	#tile_icon=      
	tile_icon=''
	tile_icon=''
	move_icon=''
	move_icon=''
	rotate_icon=''
	rotate_icon=''
	rotate_icon=''
	rotate_icon=''
	rotate_icon=''
}

id=$(printf '0x%.8x' $(xdotool getactivewindow))

#get_state
#action=$(cat <<- EOF | rofi -dmenu $active -theme main
#	$wm_icon$sep$wm_mode
#	$full_icon$sep$full
#	$use_ratio_icon$sep$use_ratio
#	$offset_icon$sep$offset
#	$margin_icon$sep$margin
#	$reverse_icon$sep$reverse
#	$direction_icon$sep$direction
#EOF
#)

toggle_rofi() {
	#~/.orw/scripts/notify.sh "SIG" &
	~/.orw/scripts/signal_windows_event.sh rofi_toggle
}

toggle_rofi
trap toggle_rofi EXIT

update_value() {
	local property=$1 value=$2
	#local value=${2#[+-]}
	#local direction=${2%$value}

	#local direction=${2//[0-9]}
	#local value=${2#$direction}

	#awk -i inplace '
	#	/^'$property'/ { $NF '${direction:-+}'= '$value' }
	#	{ print }' ~/.config/orw/config
	~/.orw/scripts/borderctl.sh w_$property $direction$value
	#~/.orw/scripts/signal_windows_event.sh update
}

set_margin() {
	local index

	while
		#read index margin_direction <<< $(echo -e '\n' |
		read index margin_direction <<< $(echo -e '\n' |
			rofi -dmenu -format 'i s' -selected-row ${index:-1} -theme main)
		[[ $margin_direction ]]
	do
		#[[ $margin_direction ==  ]] && direction=+ || direction=-
		[[ $margin_direction ==  ]] && direction=+ || direction=-

		update_value m 5
		#awk -i inplace '/^margin/ { $NF '$direction'= 5 } { print }' ~/.config/orw/config
		#~/.orw/scripts/signal_windows_event.sh update
	done
}

icon_x_down=
icon_x_up=
icon_y_up=
icon_y_down=

set_offset() {
	local index interactive=$(awk '$1 == "interactive" { print $NF == "true" }' $orw_conf)

	if [[ $interactive ]]; then
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
			#awk -i inplace '/^'$orientation'_offset/ {
			#		$NF '$direction'= '${value:-20}'
			#	} { print }' ~/.config/orw/config
			#~/.orw/scripts/signal_windows_event.sh update
		done
	fi
}

set_direction() {
#	~/.orw/scripts/set_rofi_geometry.sh tiling_toggle 3
	read new_{active_direction,direction_icon} <<< \
		$(cat <<- EOF | rofi -dmenu -a $active_direction -format 'i s' -theme main
			
			
			
			EOF
		)

	#direction=$(cat <<- EOF | rofi -dmenu -theme main
	#		
	#		
	#		
	#		EOF
	#	)

	#direction=$(cat <<- EOF | rofi -dmenu -theme main
	#		
	#		
	#		
	#	EOF
	#	)

	#direction=$(cat <<- EOF | rofi -dmenu -theme main
	#		
	#		
	#		
	#	EOF
	#	)

	if [[ $new_direction_icon ]]; then
		case $new_direction_icon in
			) direction=h;;
			) direction=v;;
			) direction=auto;; 
		esac

		#echo $direction
		#~/.orw/scripts/toggle.sh wm direction $direction
		#~/.orw/scripts/signal_windows_event.sh update

		active_direction=$new_active_direction
		direction_icon=$new_direction_icon
		set_value direction $direction

		#echo HERE $new_direction_icon, $direction_icon
	fi

	echo DIR: ^$direction_icon^
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

	#echo $active, $index

	~/.orw/scripts/notify.sh -r 22 -s osd -i ${!icon} "$property: ${state^^}"
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
	#~/.orw/scripts/signal_windows_event.sh update
}

#get_state

while
	get_state
	#echo $direction_icon=
	read index action <<< \
		$(cat <<- EOF | rofi -dmenu -format 'i s' -selected-row $index $active -theme main
		$wm_icon$sep$wm_mode
		$direction_icon$sep$direction
		$full_icon$sep$full
		$offset_icon$sep$offset
		$margin_icon$sep$margin
		$interactive_icon$sep$interactive
		$tile_icon$sep$move
		$move_icon$sep$move
		$reverse_icon$sep$reverse
		$rotate_icon$sep$rotate
	EOF
	)

	#echo dir: $direction_icon$sep$direction


	[[ $action ]]
do
	case $action in
		*$full_icon*) set_value full;;
		*$offset_icon*) set_offset;;
		*$offset_icon*) option=offset;;
		*$margin_icon*) set_margin;;
		*$move_icon*) ~/.orw/scripts/signal_windows_event.sh mv && close_rofi;;
		*$tile_icon*) ~/.orw/scripts/signal_windows_event.sh tile && exit;;
		*$rotate_icon*) ~/.orw/scripts/signal_windows_event.sh rotate && close_rofi;;
		*$interactive_icon) set_value interactive;;
		*$reverse_icon*) set_value reverse;;
		*$reverse_icon*) ~/.orw/scripts/toggle.sh wm reverse;;
		*$direction_icon*) set_direction;;
		*$direction_icon*) option=direction;;
		*$use_ratio_icon*) option=use_ratio;;
		*$wm_icon*)
			[[ $theme == icons ]] &&
				wm_mode_icons=(           ) &&
				wm_mode_icons=(   $twm_icon       ) &&
				wm_mode_icons=(   $twm_icon       ) &&
#				~/.orw/scripts/set_rofi_geometry.sh tiling_toggle 5

			wm_modes=( floating tiling auto stack selection )

			[[ $theme == icons ]] && rep=wm_mode_icons || rep=wm_modes
			eval modes=( \${$rep[*]} )

			mode_index=$(for mode in ${modes[*]}; do
				echo "$mode"
			done | rofi -dmenu -a $wm_active -format i -theme main)

			[[ $mode_index ]] && mode=${wm_modes[mode_index]}
	esac
done

~/.orw/scripts/signal_windows_event.sh update

[[ $option || $mode ]] && ~/.orw/scripts/toggle.sh wm $option $mode
