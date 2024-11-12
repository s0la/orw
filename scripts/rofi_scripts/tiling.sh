#!/bin/bash

options=(
	direction
	full
	offset
	margin
	reverse
	move
	interactive
)

direction_options=(
	direction_auto
	direction_horizontal
	direction_vertical
)

offset_options=(
	offset_horizontal_increase
	offset_horizontal_decrease
	offset_vertical_decrease
	offset_vertical_increase
)

margin_options=(
	margin_increase
	margin_decrease
)

#style=list
orw_conf=~/.config/orw/config
read direction full <<< $(awk '
	$1 == "reverse" { r = ($NF == "true") }
	$1 == "direction" {
		if ($NF == "h") f = (r) ? "left" : "right"
		else f = (r) ? "top" : "bottom"
		print $NF ".*_direction", f "_side"
	}' ~/.config/orw/config)

for option in ${options[*]} ${direction_options[*]} ${margin_options[*]} ${offset_options[*]}; do
	if [[ $style != *icons* ]]; then
		[[ $option =~ ^(direction|margin|offset)_.* ]] &&
			label=${option#*_} || label=$option
	else
		[[ $option == full ]] && label=$full
		[[ $option == direction ]] && label=$direction
		[[ $option == direction_* ]] && label="${option#*_}_direction"

		if [[ $option == offset_* ]]; then
			if [[ $option == *horizontal* ]]; then
				[[ $option == *increase* ]] &&
					label=right || label=left
			else
				[[ $option == *increase* ]] &&
					label=down || label=up
			fi
			label="arrow_${label}_circle_empty"
		fi

		label=$(sed -n "s/^${label:-$option}=//p" $icons)
	fi

	eval $option=$label
	unset label
done

declare -A submenus=(
	[$direction]="$direction_auto $direction_horizontal $direction_vertical"
	[$margin]="$margin_decrease $margin_increase"
	[$offset]="$offset_horizontal_decrease $offset_horizontal_increase $offset_vertical_decrease $offset_vertical_increase"
	)

base_count=${#options[*]}
item_count=$base_count

wait_to_proceed() {
	while true; do
		sleep 0.1
	done &
	local while_pid=$!
	wait $while_pid
	kill $while_pid
}

trap : USR1
toggle

set_value() {
	local property=$1 value=$2 icon=${1}_icon state
	read state active <<< $(awk -i inplace '
			/^'$property'/ {
				v = "'"$value"'"
				i = "'"$index"'"
				a = "'"${active#* }"'"

				$NF = (v) ? (v ~ "[-+][0-9]*") ? $NF + v : v \
					: ($NF == "true") ? "false" : "true"

				if ($NF == "false") gsub(",?" i "|" i ",?", "", a)
				else if ($NF == "true") a = (a) ? a "," i : i

				s = (v) ? v : ($NF == "true") ? "enabled" : "disabled"
			} { print }

			END { print s, (a) ? "-a " a : "" }
		' $orw_conf)

	~/.orw/scripts/notify.sh -r 22 -t 1200m -s osd -i $option "$property: ${state^^}" &> /dev/null
	~/.orw/scripts/signal_windows_event.sh update

	#toggle-able features, they call this function directly (not from other/nested function)
	#thus then call depth is 3
	#if [[ ${BASH_LINENO[*]} -eq 3 && ${active#* } == *$selected_index* ]]; then
	if [[ ${#BASH_LINENO[*]} -eq 3 ]]; then
		#echo here ${active} - $selected_index, $selected_option, ${active_indices[$selected_option]}
		[[ ${active#* } == *$selected_index* &&
			${active_indices[*]} != *$selected_option* ]] &&
			active_indices[$selected_option]=$selected_index
		[[ ${active#* } != *$selected_index* &&
			${active_indices[$selected_option]} ]] &&
			unset active_indices[$selected_option]
	fi
}

set_direction() {
	case $option in
		$direction_auto) direction=auto;; 
		$direction_vertical) direction=v;;
		$direction_horizontal) direction=h;;
	esac

	active_direction=$option
	direction_icon=$new_direction
	set_value direction $direction
	restore_active

	submenus[$option]="${submenus[$selected_option]}"
	unset submenus[$selected_option]
	direction=$option
}

update_value() {
	local property=$1 value=$2
	~/.orw/scripts/borderctl.sh w_$property $offset_direction$value
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

set_offset() {
	local index offset_direction
	#for a in ${!active_indices[*]}; do
	#	echo $a: ${active_indices[$a]}
	#done
	#echo "${active} == -a*${active_indices[$interactive]}*"
	#exit
	##local interactive=$(awk '$1 == "interactive" { print $NF == "true" }' $orw_conf)

	##if ((interactive)); then
	#if [[ ${active} == -a*${active_indices[$interactive]}* ]]; then
	#	echo ~/.orw/scripts/signal_windows_event.sh offset_int
	#	exit
	#else
		[[ $option =~ [0-9]+ ]] && value=${@##* }
		[[ $option =~ ^($offset_horizontal_increase|$offset_vertical_increase) ]] &&
			offset_direction=+ || offset_direction=-
		[[ $option =~ ^($offset_horizontal_increase|$offset_horizontal_decrease) ]] &&
			orientation=x || orientation=y
		update_value $orientation 20
		[[ $style =~ vertical_icons|dmenu ]] && wait_to_proceed
	#fi
}

shift_active() {
	if [[ $active ]]; then
		local existing_active=${active#* } new_active
		for ex_active in ${existing_active//,/ }; do
			#echo $ex_active: $subactive, $selected_index
			((ex_active < selected_index)) &&
				new_active+=",$ex_active" ||
				new_active+=",$((ex_active + ${#submenu[*]}))"
		done

		[[ $new_active ]] &&
			active="-a ${new_active#,}$subactive"
	else
		[[ $subactive ]] && active="-a ${subactive#,}"
	fi
}

restore_active() {
	local existing_active="${active#* }" current_subactive="${1:-$subactive}" new_active
	for ex_active in ${existing_active//,/ }; do
		#ex_subactive="$(grep -oE "(^|,)$ex_active(,|$)" <<< $subactive)"
		#[[ $ex_subactive == ,*, ]] &&
		#	substitute=',' || substitute=''

		if [[ ! $current_subactive =~ (^|,)$ex_active(,|$) ]]; then
			((ex_active < selected_index)) &&
				new_active+=",$ex_active" ||
				new_active+=",$((ex_active - ${#submenu[*]}))"
		fi

		[[ $new_active ]] && active="-a ${new_active#,}"
	done

	[[ $hilight ]] && ((item_count -= ${#submenu[*]}))
	unset submenu subactive hilight
}

#active="$(awk '
#	BEGIN {
#		split("'"${options[*]}"'", ao)
#		for (oi in ao) o[ao[oi]] = i++
#	}
#
#	/reverse|interactive/ { if ($NF == "true") a = a "," o[$1] }
#	END { if (a) print "-a", substr(a, 2) }' $orw_conf)"

declare -A active_indices
while read option index; do
	if [[ $option ]]; then
		active_indices["${!option}"]=$index
		active+=",$index"
	fi
done <<< $(awk '
	BEGIN {
		split("'"${options[*]}"'", ao)
		for (oi in ao) o[ao[oi]] = i++
	}

	/full|reverse|interactive/ { if ($NF == "true") a[$1] = o[$1] }
	END { if (length(a)) for (ai in a) print ai, a[ai] }' $orw_conf)

[[ $active ]] && active="-a $active"

while
	set_theme_str
	read index option < <(
		for option in ${options[*]}; do
			echo ${!option}
			[[ ${!option} == $selected_option ]] && ((item_count > base_count)) &&
				tr ' ' '\n' <<< ${submenu[*]}
		done | rofi -dmenu -format 'i s' -selected-row ${index:-0} \
			$active $hilight -theme-str "$theme_str" -theme $style)

	[[ $option ]]
do
	if [[ ${submenus[$option]} ]]; then
		selected_index=$index
		selected_option=$option
		submenu=( ${submenus[$option]} )
		submenu_options="${submenu[*]}"

		if ((item_count > base_count)); then
			restore_active
		else
			#if [[ $option == $offset ]]; then
			#	echo "${active} == -a*${active_indices[$interactive]}*, $interactive, ${active_indices[*]}", ${active_indices[$interactive]}
			#fi
			#if [[ $option == $offset && ${active} == -a*${active_indices[$interactive]}* ]]; then
			if [[ $option == $offset && ${active_indices[$interactive]} ]]; then
				~/.orw/scripts/signal_windows_event.sh offset_int
				exit
			else
				((item_count += ${#submenu[*]}))
				#[[ $option == $direction ]] &&
				#	for dir in ${!submenu[*]}; do
				#		((dir)) && hilight+=','
				#		hilight+="$((dir + index))"
				#		if [[ ${submenu[$dir]} == $option ]]; then
				#			((dir += index))
				#			[[ $active ]] &&
				#				active+=",$dir" || active="-a $dir"
				#		fi
				#	done ||
				#		case $option in
				#			$direction_auto|$direction_horizontal|$direction_vertical) set_direction;;
				#		esac

				for suboption in ${!submenu[*]}; do
					((suboption)) && hilight+=','
					hilight+="$((index + 1 + suboption))"

					if [[ $option == $direction ]]; then
						[[ ${submenu[$suboption]} == $option ]] &&
							subactive+=",$((index + 1 + suboption))"
						#if [[ ${submenu[$suboption]} == $option ]]; then
						#	((suboption += index))
						#	[[ $active ]] &&
						#		active+=",$suboption" || active="-a $suboption"
						#fi
					fi
				done

				#if [[ $subactive ]]; then
				#	if [[ $active ]]; then
				#		existing_active=${active#* }
				#		for ex_active in ${existing_active//,/ }; do
				#			#echo $ex_active: $subactive, $selected_index
				#			((ex_active < selected_index)) &&
				#				new_active+=",$ex_active" ||
				#				new_active+=",$((ex_active + ${#submenu[*]}))"
				#		done

				#		[[ $new_active ]] &&
				#			active="-a ${new_active#,}$subactive"
				#		unset {existing,new}_active
				#	else
				#		active="-a ${sub_active#,}"
				#	fi
				#fi

				shift_active
				hilight="-u $hilight"
			fi
		fi
	else
		if [[ ${submenu[*]} == *$option* ]]; then
			case $option in
				$offset_horizontal_increase|$offset_horizontal_decrease| \
					$offset_vertical_decrease|$offset_vertical_increase) set_offset;;
				$direction_auto|$direction_horizontal|$direction_vertical) set_direction;;
			esac
		else
			selected_option=$option
			selected_index=$((index - ${#submenu[*]}))

			[[ ${active#* } =~ (^|,)$index(,|$) ]] &&
				toggle_index=$index || toggle_index=''

			case $option in
				$full) set_value full;;
				$margin) set_margin;;
				$move) ~/.orw/scripts/signal_windows_event.sh mv;;
				$interactive) set_value interactive;;
				$reverse) set_value reverse;;
			esac

			#if ((item_count > base_count)); then

			#if [[ $option =~ $reverse|$interactive ]]; then
			#	if [[ ${active#* } =~ (^|,)$index(,|$) ]]; then
			#		restore_active "${subactive:-$index}"
			#	else
			#		[[ $active ]] &&
			#			active+=",$index" || active="-a $index"
			#	fi
			#else
			#	restore_active
			#fi

			restore_active "${subactive:-$toggle_index}"


			#[[ $item_count -gt $base_count ||
			#	${active#* } =~ (^|,)$index(,|$) ]] && restore_active "${subactive:-$index}"
			#if [[ ${active#* } =~ (^|,)$index(,|$) ]]; then
			#	restore_active "${subactive:-$index}"
			#fi
		fi
	fi
done

toggle
exit

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
