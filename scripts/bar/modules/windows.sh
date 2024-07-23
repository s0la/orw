#!/bin/bash

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
		p) window_padding="%{O$value}";;
	esac
}

make_windows_content() {
	listen_windows='_NET_CLIENT_LIST_STACKING _NET_ACTIVE_WINDOW'
	windows_content='$windows'
	windows_action='ia'

	if [[ $frame_type ]]; then
		windows_frame_type=$frame_type
		windows_frame_start=$module_frame_start
		windows_active_frame_start=$module_active_frame_start
		windows_frame_end=$module_frame_end
	fi

	local signal=~/.orw/scripts/signal_windows_event.sh
	local left_action="%{A:[[ \${list[index]} == \$current_window ]] "
	left_action+="&& $signal min || wmctrl -ia \${list[index]}:}"
	local middle_action="%{A2:wmctrl -ic \${list[index]}:}"

	windows_actions_start="$left_action$middle_action"
	windows_actions_end="%{A}%{A}"

	assign_args windows

	if [[ $window_buttons ]]; then
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
		window_buttons="%{F$pfc}$min_button$Abfg$max_button$Acbfg$close_button"
		cwc=$(~/.orw/scripts/convert_colors.sh -hV +11 ${jpfg:3:7})
		cwfg="%{F$cwc}"
	fi
}
