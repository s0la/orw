#!/bin/bash

padding=$1
separator="$2"
lines=${@: -1}
offset=$padding
window_name_lenght=20

mode=$(awk '/class.*\*/ { print "tiling" }' ~/.config/openbox/rc.xml)
current_window_id=$(printf "0x%.8x" $(xdotool getactivewindow 2> /dev/null))

if [[ $# -gt 3 ]]; then
	for argument in ${3//,/ }; do
		case $argument in
			a) active=$current_window_id;;
			c) current_desktop=$(xdotool get_desktop);;
			*)
				value=${argument:1}
				property=${argument:0:1}

				[[ $4 == true ]] && separator_color='${Afc:-$fc}'

				case $property in
					l) window_name_lenght=$value;;
					s) app_separator="%{B${separator_color:-\$bg}}%{O$value}";;
					*)
						if [[ $value =~ [0-9] ]]; then
							offset="%{O$value}"
						else
							[[ $value == p ]] && offset=$padding || offset='${inner}'
						fi;;
				esac
		esac
	done
fi

function set_line() {
	fc="\${Afc:-\$fc}"
	frame_width="%{O\${Afw:-\${frame_width-0}}\}"

	if [[ $lines == [ou] ]]; then
		left_frame="%{+$lines\}" right_frame="%{-$lines\}"
	else
		frame="%{B$fc\}$frame_width"
		#left_frame="\${start_line:-%{+u\}%{+o\}$frame}"
		#right_frame="\${end_line:-$frame%{-o\}%{-u\}}"
		left_frame="%{+u\}%{+o\}$frame"
		right_frame="$frame%{-o\}%{-u\}"
	fi

	#frame="%{B$fc\}$frame_width"
	#left_frame="%{+u\}%{+o\}$frame"
	#right_frame="$frame%{-o\}%{-u\}"
}

[[ $lines != false ]] && set_line

current_window_id=$(printf "0x%.8x" $(xdotool getactivewindow 2> /dev/null))

get_window() {
	#[[ $window_id -eq $current_window_id ]] && current='p' current_index=$window_index || current='s'
	[[ $window_id -ne $current_window_id ]] && current='s' ||
		current='p' current_index=$window_index previous_index=$(((current_index + count - 1) % count))

	if [[ ${#window_name} -gt $window_name_lenght ]]; then
		window_name="${window_name:0:$window_name_lenght}"
		window_name+='..'
	fi

	window_name="${offset}${window_name}${offset}"

	if [[ $window_id ]]; then
		bg="\${A${current}bg:-\${Asbg:-\$${current}bg}}"
		fg="\${A${current}fg:-\${Asfg:-\$${current}fg}}"

		#[[ $current == s ]] &&
		#	left_command="wmctrl -ia $window_id" ||
		#	left_command="xdotool getactivewindow windowminimize"
		left_command="~/.orw/scripts/minimize_window.sh $window_id"
		[[ $mode != tiling ]] &&
			middle_command="wmctrl -ic $window_id" ||
			middle_command="~/.orw/scripts/get_window_neighbours.sh"
		right_command="~/.orw/scripts/windowctl.sh -i $window_id -C -M x,y,w,h"
		commands="%{A:$left_command:}%{A2:$middle_command:}%{A3:$right_command:}"

		window="$commands$bg$fg${padding}${window_name//\"/\\\"}${padding}%{A}%{A}%{A}"

		[[ $app_separator || ($lines == [ou] && $separator =~ ^% && $current == p) ]] &&
			window="%{U$fc}$left_frame$window$right_frame"
		#[[ $app_separator ]] &&
			#window="%{U$fc}\${start_line:-$left_frame}$window\${end_line:-$right_frame}"

		#[[ $lines == [ou] && $separator =~ ^% && $current == p ]] &&
		#		window="%{U$fc}\${start_line:-$left_frame}$window\${end_line:-$right_frame}"
				#window="%{U$fc}$left_frame$window$right_frame"
	fi
}

blacklisted_windows='input|image_preview|cover_art_widget'

eval windows=( $(wmctrl -l | awk '\
	$1 ~ /'$active'/ && !/ ('$blacklisted_windows')/ && $2 ~ /^'${current_desktop:--?[0-9]}'/ {
		wn = (NF > 3) ? substr($0, index($0, $4)) : "no name"
		gsub("\"", "\\", wn)
		print "\"" $1, wn "\"" }') )
count=${#windows[*]}

for window_index in "${!windows[@]}"; do
	window_id="${windows[window_index]%% *}"
	window_name="${windows[window_index]#* }"

	get_window
	apps+="$window$app_separator"
done

[[ $app_separator ]] && apps=${apps%\%*}

[[ $apps ]] && apps="%{A4:wmctrl -ia ${windows[previous_index]%% *}:}\
%{A5:wmctrl -ia ${windows[$(((current_index + 1) % count))]%% *}:}\
$apps%{A}%{A}"

#~/.orw/scripts/notify.sh "apps: $separator"

if [[ $lines != false ]]; then
	#~/.orw/scripts/notify.sh "s: $separator"
	case $separator in
		[ej]*)
			[[ $separator =~ j ]] &&
				apps+='$start_line'
			apps+="${separator:1}";;
		s*)
			joiner_start="%{U$fc}\${start_line:-$left_frame}"
			[[ $apps ]] && apps="$joiner_start$apps\$start_line${separator:2}" || apps=$joiner_start;;
			#[[ $apps ]] && apps="%{U$fc}\${start_line:-$left_frame}$apps\$start_line${separator:2}";;
		#e*) launchers+="\${end_line:-$right_frame}%{B\$bg}${separator:1}";;
		#e*) launchers+="${separator:1}";;
		*) [[ $app_separator ]] ||
				apps="%{U$fc}\${start_line:-$left_frame}$apps\${end_line:-$right_frame}%{B\$bg}$separator";;

			#[[ $lines == true ]] &&
			#[[ $lines == a ]] &&
			#apps="%{U$fc}\${start_line:-$left_frame}$apps\${end_line:-$right_frame}%{B\$bg}$separator";;
			#apps="%{U$fc}$left_frame$apps$right_frame%{B\$bg}$separator";;
	esac

	#launchers="%{U$fc}\${start_line:-$left_frame}$launchers\${end_line:-$right_frame}"
else
	apps+="%{B\$bg}$separator"
fi

#case $separator in
#	s*) separator="${separator:2}";;
#	[ej]*) separator="${separator:1}";;
#esac

#[[ $app_separator ]] && windows=${windows%\%*}
#[[ $windows && $lines == true ]] && windows="%{U$fc}\${start_line:-$left_frame}$windows\${end_line:-$right_frame}"
#~/.orw/scripts/notify.sh "W: $windows"

#[[ $windows ]] && echo -e "$windows%{B\$bg}\$separator"
echo -e "$apps"
