#!/bin/bash

workspace_count=$(xdotool get_num_desktops)
current_workspace=$(($(xdotool get_desktop) + 1))

offset=$3
separator="$1"
single_line=${@: -1}

function set_line() {
	fc="\${Wfc:-\$fc}"
	frame="%{B$fc\}$frame_width"
	left_frame="%{+u\}%{+o\}$frame"
	right_frame="$frame%{-o\}%{-u\}"
}

[[ $single_line == false ]] && format_delimiter=' '

for workspace_index in $(seq $workspace_count); do
	[ $workspace_index -eq $current_workspace ] && current=p || current=s

	for arg in ${2//,/ }; do
		case $arg in
			o*)
				value=${arg:1}

				if [[ $value =~ [0-9] ]]; then
					offset="%{O$value}"
				else
					[[ $value == p ]] && offset='$padding' || offset='$inner'
				fi;;
			[cr]) [[ ! $flags =~ $arg ]] && flags+=$arg;;
			s*) workspace_separator="\$bsbg%{O${arg:1}}";;
			l) label="\${padding}$(wmctrl -d | awk '$1 == '$((workspace_index - 1))' \
				{ wn = $NF; if(wn ~ /^[0-9]+$/) { if(wn > 1) tc = wn - 1; wn = "tmp" tc }; print wn }')\${padding}";;
			n) label="$offset$workspace_index$offset";;
			b*) ((${#arg} > 1)) && label=%{O${arg:1}} || label=$offset;;
			*)
				case ${arg: -1} in
					d) icon_type=dot;;
					h) icon_type=half;;
					e) icon_type=empty;;
					*) icon_type=default;;
				esac

				icon="$(sed -n "s/Workspace_${icon_type}_${current}_icon=//p" ${0%/*}/icons)"
				#~/.orw/scripts/notify.sh "Workspace_${icon_type}_${current}_icon"
				#:icon="${current}_icon"
				label="$offset$icon$offset";;
		esac
	done

	bg="\${W${current}bg:-\${Wsbg:-\$${current}bg}}"
	fg="\${W${current}fg:-\${Wsfg:-\$${current}fg}}"

	[[ $fbg ]] || fbg=$bg

	command="wmctrl -s $((workspace_index - 1)) \&\& ~/.orw/scripts/barctl.sh -b wss -k \&"
	[[ $flags ]] && command+=" ~/.orw/scripts/wallctl.sh -$flags \&"
	#~/.orw/scripts/notify.sh "$command"
	workspace="%{A:$command:}$bg$fg$label%{A}"

	if [[ $single_line == true && $current == p ]]; then
		set_line
		workspace="%{U$fc}\${start_line:-$left_frame}$workspace\${end_line:-$right_frame}"
	fi

	((workspace_index < workspace_count)) && workspace+="$workspace_separator"

	workspaces+="$workspace"
done

[[ $2 =~ i ]] && workspaces="$fbg\${padding}${workspaces%\%*}\${padding}"

echo -e "%{A2:~/.orw/scripts/barctl.sh -b wss:}\
%{A4:wmctrl -s $((((current_workspace + workspace_count - 2) % workspace_count))):}\
%{A5:wmctrl -s $((current_workspace % workspace_count)):}\
$workspaces%{A}%{A}%{A}%{B\$bg}$format_delimiter$separator"
