#!/bin/bash

#check_windows() {
#	xprop -spy -root _NET_ACTIVE_WINDOW |
#		while read window; do
#			window_id=${window##* }
#			[[ ! ${!all_windows[*]} =~ $window_id ]] &&
#				all_windows[$window_id]=$current_workspace
#			make_windows
#			eval echo \"WINDOWS:"$windows_content"\"
#		done
#}

assign_windows_args() {
	case $arg in
		o) window_offset="$value";;
		c)
			only_current_window=true
			window_buttons=$value
			[[ $value == b ]] &&
				show_buttons=true
			;;
		s) window_separator="%{O$value}";;
	esac
}

make_windows_content() {
	listen_windows='_NET_CLIENT_LIST_STACKING _NET_ACTIVE_WINDOW'
	windows_content='$windows'
	windows_action='ia'

	#if [[ ! ${joiner_modules[A]} ]]; then
	#	set_module_frame A
	if [[ $frame_type ]]; then
		windows_frame_type=$frame_type
		windows_frame_start=$module_frame_start
		windows_frame_end=$module_frame_end
	fi

	#~/.orw/scripts/notify.sh "wins: $frame_type, $module_frame_start"

	local signal=~/.orw/scripts/signal_windows_event.sh
	local left_action="%{A:[[ \${list[index]} == \$current_window ]] "
	left_action+="&& $signal min || wmctrl -ia \${list[index]}:}"
	local middle_action="%{A2:wmctrl -ic \${list[index]}:}"

	windows_actions_start="$left_action$middle_action"
	#windows_actions_start="%{A:wmctrl -ia \$item:}"
	windows_actions_end="%{A}%{A}"
	#windows_actions_end="%{A}"

	#for arg in ${1//,/ }; do
	#	value=${arg#*:}
	#	arg=${arg%%:*}

	assign_args windows

	#if [[ $show_buttons ]]; then
	if [[ $window_buttons ]]; then
		#local button=$(get_icon "window_button")
		#local mi_button='%{i}%{i}'
		#local ma_button='%{i}%{i}'
		#local c_button='%{i}%{i}'
		#local mi_button='%{i}%{i}'
		#local ma_button='%{i}%{i}'
		#local c_button='%{i}%{i}'
		#local mi_button='%{i}%{i}'
		#local ma_button='%{i}%{i}'
		#local c_button='%{i}%{i}'
		#local mi_button='%{i}%{i}'
		#local ma_button='%{i}%{i}'
		#local c_button='%{i}%{i}'
		#button='%{I}%{I}'

		#local button="$jpfg$button_icon"





		if [[ $window_buttons == b[cs] ]]; then
			local pattern="window_${window_buttons/*[cs]/${window_buttons:1:1}[^_]*_}button"
			local button=$(get_icon "$pattern")
		else
			read {min,max,close}_button <<< $(\
				sed -n "s/window_${window_buttons:1:1}[^_]*_[cm].*=//p" $icons_file | xargs)
		fi

		local min_button="%{A:$signal min:}${min_button:-$button}%{A}"
		local max_button="%{A:$signal max:}${max_button:-$button}%{A}"
		local close_button="%{A:wmctrl -ic \$current_window:}${close_button:-$button}%{A}"
		window_buttons="$jpfg$close_button$Abfg$max_button$jsfg$min_button"
		cwc=$(~/.orw/scripts/convert_colors.sh -hV +11 ${jpfg:3:7})
		cwfg="%{F$cwc}"
	fi
}
