#!/bin/bash

separator="$2"
lines=${@: -1}
offset='${padding}'

launchers_directory=~/.config/orw/bar/launchers
launchers_file=$launchers_directory/$1

[[ ! -d $launchers_directory ]] && mkdir $launchers_directory
[[ ! -f $launchers_file ]] && cp ~/.orw/scripts/bar/launchers $launchers_file

if (($# > 3)); then
	for argument in ${3//,/ }; do
		value=${argument:1}
		property=${argument:0:1}

		[[ $4 == true ]] && separator_color='${Lfc:-$fc}'

		if [[ $property == s ]]; then
			launcher_separator="%{B${separator_color:-\$bg}}%{O$value}"
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
		$NF != "input" && /'"$name"'/ {
			if($1 == "'$current_id'") p = c
			ids = ids " " $1
			c++
		} END { print c, p, ids }')

	if [[ $name =~ ^bar ]]; then
		current=$(ps aux | awk '{ b = (/-n '${name#*_}'$/); if(b) exit } END { print b ? "p" : "s" }')
	else
		if [[ $up && $down ]]; then
			local current=s
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
	fi

	error='\&\> \/dev\/null \&'
	left="${toggle:-${focus:-$left $error}}"
	[[ $right ]] || right="$left $error"
	[[ $middle ]] || middle="wmctrl -ic ${ids[position]}"

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

	unset right middle up down
}

while read launcher_properties; do
		eval ${launcher_properties//\&/\\&}
		make_launcher
		launchers+="$launcher$launcher_separator"
done <<< $(awk '{ if(/^$/) {
						if(l) al[++i] = l; l = ""
					} else { if(!/^#/) l = l " " $0 }
					} END { for(li in al) print al[li]; print l }' $launchers_file)

[[ $launcher_separator ]] && launchers=${launchers%\%*}
[[ $launchers && $lines == true ]] && launchers="%{U$fc}\${start_line:-$left_frame}$launchers\${end_line:-$right_frame}"

[[ $launchers ]] && echo -e "$launchers%{B\$bg}$separator"
