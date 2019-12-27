#!/bin/bash

lines=${@: -1}
offset='${padding}'

if [[ $# -gt 1 ]]; then
	for argument in ${1//,/ }; do
		value=${argument:1}
		property=${argument:0:1}

		[[ $2 == true ]] && separator_color='${Lfc:-$fc}'

		if [[ $property == s ]]; then
			separator="%{B${separator_color:-\$bg}}%{O$value}"
		else
			if [[ $value =~ [0-9] ]]; then
				offset="%{O$value}"
			else
				[[ $value == p ]] && offset='${padding}' || offset='${inner}'
			fi
		fi
	done
fi

function set_line() {
	fc="\${Lfc:-\$fc}"
	frame_width="%{O\${Lfw:-\${frame_width-0}}\}"

	frame="%{B$fc\}$frame_width"
	left_frame="%{+u\}%{+o\}$frame"
	right_frame="$frame%{-o\}%{-u\}"
}

function add_line() {
	eval "$1=%{U$fc}\${start_line:-$left_frame}${!1}\${end_line:-$right_frame}"
}

[[ $lines != false ]] && set_line

current_desktop=$(xdotool get_desktop)
current_id=$(printf "0x%.8x" $(xdotool getactivewindow 2> /dev/null))

make_launcher() {
	local count position ids commands closing

	read count position ids <<< $(wmctrl -l | awk '\
		BEGIN { c = 0 }
		/'"$name"'/ {
			if($1 == "'$current_id'") p = c
			ids = ids " " $1
			c++
		} END { print c, p, ids }')

	if [[ $command_up && $command_down ]]; then
		local current=s
		local up="$command_up"
		local down="$command_down"
	else
		if ((count)); then
			ids=( $ids )
			local current=p

			[[ ${ids[position]} == $current_id ]] &&
				local toggle="xdotool getactivewindow windowminimize" ||
				local focus="wmctrl -a $name"

			if ((count > 1)); then
				local next_index=$(((position + 1) % count))
				local previous_index=$(((position + count - 1) % count))

				local down="wmctrl -ia ${ids[next_index]}"
				local up="wmctrl -ia ${ids[previous_index]}"
			fi
		else
			local current=s
		fi
	fi

	error='\&\> \/dev\/null \&'
	local left="${toggle:-${focus:-$command $error}}"
	local middle="wmctrl -ic ${ids[position]}"
	local right="$command $error"

	[[ $left ]] && commands+="%{A1:$left:}" && closing+="%{A}"
	[[ $middle ]] && commands+="%{A2:$middle:}" && closing+="%{A}"
	[[ $right ]] && commands+="%{A3:$right:}" && closing+="%{A}"
	[[ $up ]] && commands+="%{A4:$up:}" && closing+="%{A}"
	[[ $down ]] && commands+="%{A5:$down:}" && closing+="%{A}"

	bg="\${L${current}bg:-\${Lsbg:-\$${current}bg}}"
	fg="\${L${current}fg:-\${Lsfg:-\$${current}fg}}"

	launcher="$commands$bg$fg$offset$icon$offset$closing"

	if [[ $current == p && $lines == single ]]; then
		launcher="%{U$fc}\${start_line:-$left_frame}$launcher\${end_line:-$right_frame}"
	fi
}

while IFS='"' read _ icon _ name _ command _ command_up _ command_down; do
		make_launcher
		launchers+="$launcher$separator"
done < <(grep -v ^\# ~/.orw/scripts/bar/launchers)

[[ $separator ]] && launchers=${launchers%\%*}
[[ $launchers && $lines == true ]] && launchers="%{U$fc}\${start_line:-$left_frame}$launchers\${end_line:-$right_frame}"

[[ $launchers ]] && echo -e "$launchers%{B\$bg}\$separator"
