#!/bin/bash

workspace_count=$(xdotool get_num_desktops)
current_workspace=$(($(xdotool get_desktop) + 1))

offset="\${$2}"
space="\${padding}"
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

	case $1 in
		l) label="\${padding}$(wmctrl -d | awk '$1 == '$((workspace_index - 1))' \
			{ wn = $NF; if(wn ~ /^[0-9]+$/) { if(wn > 1) tc = wn - 1; wn = "tmp" tc }; print wn }')\${padding}";;
		n) label="$offset$workspace_index$offset";;
		*)
			p_icon=""
			[[ $2 == inner ]] && s_icon="" || s_icon=""
			s_icon=""
			icon="${current}_icon"
			label="$offset%{I-3}${!icon}%{I-}$offset";;
	esac

	bg="\${W${current}bg:-\${Wsbg:-\$${current}bg}}"
	fg="\${W${current}fg:-\${Wsfg:-\$${current}fg}}"

	workspace="%{A:wmctrl -s $((workspace_index - 1)):}$bg$fg$label%{A}"

	if [[ $single_line == true && $current == p ]]; then
		set_line
		workspace="%{U$fc}\${start_line:-$left_frame}$workspace\${end_line:-$right_frame}"
	fi

	workspaces+="$workspace"
done

[[ $1 == i ]] && workspaces="$bg\$inner${workspaces%\%*}\$inner"

echo -e "%{A4:wmctrl -s $((current_workspace % workspace_count)):}\
%{A5:wmctrl -s $((((current_workspace + workspace_count - 2) % workspace_count))):}\
$workspaces%{A}%{A}%{B\$bg}$format_delimiter\$separator"
