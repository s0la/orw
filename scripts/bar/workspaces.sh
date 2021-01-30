#!/bin/bash

workspace_count=$(xdotool get_num_desktops)
current_workspace=$(($(xdotool get_desktop) + 1))

offset=$3
padding=$1
separator="$2"
single_line=${@: -1}

function set_line() {
	fc="\${Wfc:-\$fc}"
	frame="%{B$fc\}$frame_width"
	left_frame="%{+u\}%{+o\}$frame"
	remove_frame="%{-o\}%{-u\}"
	right_frame="$frame$remove_frame"
}

[[ $single_line == false ]] && format_delimiter=' '

workspace_labels=( $(wmctrl -d | awk '{
	print ($NF ~ /^[0-9]+$/) ? ($NF > 1) ? "tmp_" $NF - 1 : "tmp" : $NF }') )

for workspace_index in $(seq $workspace_count); do
	[ $workspace_index -eq $current_workspace ] && current=p || current=s

	for arg in ${4//,/ }; do
		case $arg in
			o*)
				value=${arg:1}

				if [[ $value =~ [0-9] ]]; then
					offset="%{O$value}"
				else
					[[ $value == p ]] && offset=$padding || offset='$inner'
				fi;;
			[cr]) [[ ! $flags =~ $arg ]] && flags+=$arg;;
			s*) workspace_separator="\$jbg%{O${arg:1}}";;
			#l) label="${padding}$(wmctrl -d | awk '$1 == '$((workspace_index - 1))' \
			#	{ wn = $NF; if(wn ~ /^[0-9]+$/) { if(wn > 1) tc = wn - 1; wn = "tmp" tc }; print wn }')${padding}";;
			l) label="${padding}${workspace_labels[workspace_index - 1]}${padding}";;
			n) label="$offset$workspace_index$offset";;
			b*) ((${#arg} > 1)) && label=%{O${arg:1}} || label=$offset;;
			*)
				#case ${arg:1} in
				#	d) icon_type=dot;;
				#	h) icon_type=half;;
				#	e) icon_type=empty;;
				#	b) icon_type=block;;
				#	be) icon_type=block_empty;;
				#	*) icon_type=default;;
				#esac

				((${#arg} == 1)) &&
					icon_type="${workspace_labels[workspace_index - 1]}" ||
					icon_type=$(sed 's/\w/&\.\*_/g' <<< ${arg:1})$current
				#~/.orw/scripts/notify.sh "it: $icon_type"
				icon="$(sed -n "s/Workspace_${icon_type}_icon=//p" ${0%/*}/icons)"
				[[ ${arg:1:1} == s ]] && icon=%{T4}$icon%{T-}

				#if [[ $icon_type ]]; then
				#	#icon="$(sed -n "s/Workspace_${icon_type}_${current}_icon=//p" ${0%/*}/icons)"
				#	icon="$(sed -n "s/Workspace_${icon_type}${current}_icon=//p" ${0%/*}/icons)"
				#	[[ ${arg:1:1} == s ]] && icon=%{T4}$icon%{T-}
				#else
				#	icon=${workspace_icons[workspace_index]}
				#fi
				#icon=${workspace_icons[workspace_index - 1]}

				label="$offset$icon$offset";;
		esac
	done

	bg="\${W${current}bg:-\${Wsbg:-\$${current}bg}}"
	fg="\${W${current}fg:-\${Wsfg:-\$${current}fg}}"
	[[ $fbg ]] || fbg=$bg

	command="wmctrl -s $((workspace_index - 1)) \&\& ~/.orw/scripts/barctl.sh -b wss -k \&"
	[[ $flags ]] && command+=" ~/.orw/scripts/xwallctl.sh -$flags \&"
	workspace="%{A:$command:}$bg$fg$label%{A}"

	if [[ $single_line == true && $separator =~ ^% && $current == p ]]; then
		set_line
		workspace="%{U$fc}\${start_line:-$left_frame}$workspace\${end_line:-$right_frame}"
	fi

	((workspace_index < workspace_count)) && workspace+="$workspace_separator"
	workspaces+="$workspace"
done

[[ $4 =~ i ]] && workspaces="$fbg${padding}$workspaces${padding}"
#[[ $4 =~ i[^b] ]] && workspaces="$fbg${padding}$workspaces${padding}"
#[[ $separator =~ ^% ]] && workspaces="$remove_frame$workspaces"

workspaces="%{A2:~/.orw/scripts/barctl.sh -b wss:}\
%{A4:wmctrl -s $((((current_workspace + workspace_count - 2) % workspace_count))):}\
%{A5:wmctrl -s $((current_workspace % workspace_count)):}$workspaces%{A}%{A}%{A}"

if [[ $single_line == true ]]; then
	#~/.orw/scripts/notify.sh "s: $separator"
	case $separator in
		[ej]*)
			[[ $separator =~ j ]] &&
				workspaces+='$start_line'
			workspaces+="${separator:1}";;
		s*) workspaces="%{U$fc}\${start_line:-$left_frame}$workspaces\$start_line${separator:2}";;
		#e*) launchers+="\${end_line:-$right_frame}%{B\$bg}${separator:1}";;
		#e*) launchers+="${separator:1}";;
		*) [[ $start_line == false ]] &&
			workspaces="%{U$fc}\${start_line:-$left_frame}$workspaces\${end_line:-$right_frame}%{B\$bg}$separator";;
	esac

	#launchers="%{U$fc}\${start_line:-$left_frame}$launchers\${end_line:-$right_frame}"
else
	workspaces+="$format_delimiter%{B\$bg}$separator"
fi

echo -e "$workspaces"

#case $separator in
#	s*) separator="${separator:2}";;
#	[ej]*) separator="${separator:1}";;
#esac

#echo -e "%{A2:~/.orw/scripts/barctl.sh -b wss:}\
#%{A4:wmctrl -s $((((current_workspace + workspace_count - 2) % workspace_count))):}\
#%{A5:wmctrl -s $((current_workspace % workspace_count)):}\
#$workspaces%{A}%{A}%{A}%{B\$bg}$format_delimiter$separator"
