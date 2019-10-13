#!/bin/bash

module=t
lines=${@: -1}
window_name_lenght=20

current_window_id=$(printf "0x%.8x" $(xdotool getactivewindow 2> /dev/null))

if [[ $# -gt 1 ]]; then
	for argument in ${1//,/ }; do
		case $argument in
			a) active=$current_window_id;;
			c) current_desktop=$(xdotool get_desktop);;
			*)
				property=${argument%%[0-9]}
				value=${argument#$property}

				[[ $2 == true ]] && separator_color='${tfc:-$fc}'

				[[ $property == l ]] && window_name_lenght=$value ||
					task_separator="%{B${separator_color:-\$bg}}%{O$value}";;
		esac
	done
fi

function set_line() {
	fc="\${tfc:-\$fc}"
	frame_width="%{O\${tfw:-\${frame_width-0}}\}"

	frame="%{B$fc\}$frame_width"
	left_frame="%{+u\}%{+o\}$frame"
	right_frame="$frame%{-o\}%{-u\}"
}

function add_line() {
	eval "$1=%{U$fc}\${start_line:-$left_frame}${!1}\${end_line:-$right_frame}"
}

[[ $lines != false ]] && set_line

current_window_id=$(printf "0x%.8x" $(xdotool getactivewindow 2> /dev/null))

while read -r window_id window_name; do
	[[ $window_id -eq $current_window_id ]] && current='p' || current='s'

	if [[ ${#window_name} -gt $window_name_lenght ]]; then
		window_name="${window_name:0:$window_name_lenght}"
		[[ $current == s ]] && window_name+='..'
	fi

	window_name="\${padding}${window_name}\${padding}"

	if [[ $window_id ]]; then
		bg="\${t${current}bg:-\${tsbg:-\$${current}bg}}"
		fg="\${t${current}fg:-\${tsfg:-\$${current}fg}}"

		window="%{A:wmctrl -ia $window_id:}$bg$fg\${padding}${window_name//\"/\\\"}\${padding}%{A}"

		if [[ $current == p && $lines == single ]]; then
			window="%{U$fc}\${start_line:-$left_frame}$window\${end_line:-$right_frame}"
		fi

		windows+="$window$task_separator"
	fi
done <<< $(wmctrl -l | awk '$1 ~ /'$active'/ && $2 ~ /^'${current_desktop-[0-9]}'/ \
	{ print $1, (NF > 3) ? substr($0, index($0, $4)) : "no name" }')

[[ $task_separator ]] && windows=${windows%\%*}
[[ $windows && $lines == true ]] && windows="%{U$fc}\${start_line:-$left_frame}$windows\${end_line:-$right_frame}"

[[ $windows ]] && echo -e "$windows%{B\$bg}\$separator"
