#!/bin/bash

make_list() {
	local module=$1 short=$2 current
	local $module content=${module}_content
	local current_item=current_${module%s} separator=${module%s}_separator
	local actions_start=${module}_actions_start actions_end=${module}_actions_end
	local padding=${module%s}_padding offset=${module%s}_offset icons=${module%s}_icons
	local padding=${!padding} offset=${!offset:-10} icons=${!icons}
	local module_frame_type=${module}_frame_type
	local module_frame_start=${module}_frame_start module_frame_end=${module}_frame_end
	local module_active_frame_start=${module}_active_frame_start

	for index in ${!list[*]}; do
		item=${list[index]}

		if [[ $item == ${!current_item} ]]; then
			current=p current_icon=p
		else
			[[ ${workspaces_windows[$item]} ]] &&
				current_icon=c || current_icon=s
			current=s
		fi

		if [[ $module == windows ]]; then
			label="$cwfg${windows_titles[$item]:-$item}"
		else
			[[ $workspace_icons == [iln] ]] &&
				label="${workspaces_icons[index]}" ||
				label="\${workspace_${current_icon}_icon:-$item}"
		fi

		if [[ $module == workspaces ||
			($module == windows && ! $only_current_window) ]]; then
				if [[ ${joiner_modules[$short]} &&
					($index -eq 0 || $index -eq $((${#list[*]} - 1))) ]]; then
						((index)) &&
							left_offset="%{O$offset}" right_offset='' ||
							left_offset='' right_offset="%{O$offset}"
				else
					left_offset="%{O$offset}" right_offset="%{O$offset}"
				fi
		fi

		[[ $module == windows && $window_buttons ]] &&
			label+="$inner$window_buttons"

		action="${!actions_start}$left_offset$label$right_offset${!actions_end}"

		item="\\\${cj${current}fg:-\\\$$short${current}fg}$action"

		if [[ ! ${joiner_modules[$short]} ]]; then
			item="\$$short${current}bg$item"

			if [[ ${!module_frame_type} == single || ${!separator} ]]; then
				local frame_mode=${!module_frame_start}
				[[ $current_icon == p && ${!module_frame_type} == single ]] && 
					frame_mode=${!module_active_frame_start}
									[[ $current_icon == s && $module == workspaces ]] && unset frame_mode
			fi

			if [[ $padding ]]; then
				((index)) || local padding_start_frame="\$$short${current}bg$frame_mode"
			fi

			if ((index == ${#list[*]} - 1)); then
				[[ $padding ]] && unset frame_mode_end
			else
				local frame_mode_end=${!module_frame_end}
			fi

			[[ (${!module_frame_type} == all && ${!separator}) ||
				(($module == windows || ($workspace_icons == [iln] && $current_icon != s)) &&
				${!module_frame_type} == single) ]] &&
					item="$frame_mode$item$frame_mode_end"
		fi

		eval $module+=\"$item\"
		((index < ${#list[*]} - 1)) &&
			eval $module+="${!separator}"
	done

	if [[ ! ${joiner_modules[$short]} ]]; then
		[[ $workspace_icons && $workspace_icons == i ]] &&
			local module_start="\$${short}sbg$padding_start_frame" ||
			local module_start="${!module_frame_start}\$${short}sbg$padding_start_frame"
		local module_end="${!module_frame_end}"
	fi

	[[ ! ${!separator} &&
		((${!module_frame_type} == all || (${!module_frame_type} == single && $icons) ||
		(($workspace_icons == n || $icon_type) && $padding)) || ${joiner_groups[*]} =~ (^| )$short|$short( |$)) ]] &&
		echo "$module_start$padding${!module}$padding$module_end" || echo "${!module}"
}

get_all_windows() {
	if [[ $1 ]]; then
		[[ $1 == 0x* ]] &&
			local window_id=${1#0x} ||
			local workspace_id=$1
	fi

	wmctrl -l | awk '
		BEGIN {
			wc = '$workspace_count'
			wid = "'"$window_id"'"
			wsid = "'"$workspace_id"'"
			p = "0x0*" wid
		}

		$1 ~ p && $2 ~ wsid {
			id = $1; d = $2
			sub("0x0*", "0x", id)
			gsub(".*" $3 ".* ", "")

			if (wid) exit

			aw[d] = aw[d] " " id
			at[id] = (length($0) < 20) ? $0 : substr($0, 0, 20) ".."
		} END {
			if (wid) print $0
			else {
				for (w=0; w<wc; w++) printf "[%d]=\"%s\" ", w, substr(aw[w], 2)
				print ""
				for (t in at) printf "[%s]=\"%s\" ", t, at[t]
			}
		}'
}

get_workspaces() {
	print_tiling

	[[ ! $current_workspace ]] &&
		local current_workspace=$(xdotool get_desktop)

	((workspace_count)) ||
		local workspace_count=$(xdotool get_num_desktops)
	local list=( $(seq 0 $((workspace_count - 1))) )

	workspaces="$(make_list workspaces W)"
}

get_windows() {
	if [[ ! $current_workspace_windows ]]; then
		local current_workspace=$(xdotool get_desktop)
		local workspaces_windows windows_titles current_workspace_windows
		IFS=$'\n' read -d '' all_windows all_titles <<< $(get_all_windows $current_workspace)
		eval workspaces_windows=( $all_windows )
		eval windows_titles=( $all_titles )
		local current_workspace_windows=${workspaces_windows[$current_workspace]}
	fi

	[[ $only_current_window ]] &&
		local list=( $current_window ) ||
		local list=( ${current_workspace_windows} )
	windows="$(make_list windows A)"
}

make_tiling_content() {
	tiling_icon=$icons
	[[ ${joiner_modules[t]} ]] || local tiling_bg=$tsbg
	tiling_content="$tiling_bg\${cjsfg:-\$tsfg}\$tiling"
}

get_tiling() {
	if [[ -z $wm_label ]]; then
		wm_label=$(awk '/^(direction|reverse|full)/ {
							l = substr($NF, 1, 1)
							if (l == "a") exit
						} END { print l }' ~/.config/orw/config)
		wm_icon=$(sed "s/./_&[^_]*/g" <<< "${wm_label/f}")
	fi

	[[ "$tiling_workspaces" == *$current_workspace* ]] &&
		label="TILE:${wm_label^^}" icon="tiling${wm_icon%[*}" ||
		label='FLOAT' icon='floating'

	icon=$(get_icon "wm_mode_$icon")

	[[ $tiling_icon ]] &&
		tiling=$icon || tiling=$label
}

set_tiling_actions() {
	actions_start='%{A:~/.orw/scripts/signal_windows_event.sh toggle_ws:}'
	actions_end='%{A}'
}

print_tiling() {
	if [[ "${modules[*]}" == *tiling* ]]; then
		get_tiling
		set_tiling_actions
		print_module tiling
	fi
}

get_windows_and_titles() {
	local windows titles
	IFS=$'\n' read -d '' all_{windows,titles} <<< $(get_all_windows ${@:2})
	eval workspaces_windows=( $all_windows )
	eval windows_titles=( $all_titles )
}

check_workspaces() {
	local workspaces event
	local workspaces_fifo=/tmp/workspaces.fifo
	local workspace_count=$(xdotool get_num_desktops)
	declare -A all_{windows,titles} workspaces_windows
	get_windows_and_titles #all_windows all_titles 

	[[ -p $workspaces_fifo ]] || mkfifo $workspaces_fifo

	while true; do
		[[ $current_workspace ]] || ~/.orw/scripts/signal_windows_event.sh info

		read event value < $workspaces_fifo #&

		workspace_count=$(xdotool get_num_desktops)

		case $event in
			close)
				current_workspace=$value
				unset current_{workspace_,}window{s,}
				workspaces_windows[$current_workspace]="$current_workspace_windows"

				if [[ "${modules[*]}" == *windows* ]]; then
					get_windows
					print_module windows
				fi
				;;
			desktop)
				previous_workspace=$current_workspace
				read current_{workspace,window,workspace_windows} <<< $value
				workspaces_windows[$current_workspace]="$current_workspace_windows"

				get_workspaces
				print_module workspaces

				if [[ "${modules[*]}" == *windows* ]]; then
					if [[ ! $current_workspace_windows =~ 0x ]]; then
						unset current_window windows
						print_module windows
					elif ((${#current_workspace_windows} != ${#previous_windows} )); then
						get_windows
						print_module windows
					fi

					previous_windows="$current_workspace_windows"
				fi

				previous_workspace=$current_workspace
				;;
			new_window)
				read current_window title <<< "$value"
				windows_titles[$current_window]="$title"
				;;
			windows)
				read current_{workspace,window,workspace_windows} <<< $value
				[[ ! "$current_workspace_windows" =~ $current_window ]] &&
					current_workspace_windows+=" $current_window"

				workspaces_windows[$current_workspace]="$current_workspace_windows"

				if [[ $current_workspace != $previous_workspace ]]; then
					get_workspaces
					print_module workspaces
					previous_workspace=$current_workspace
				fi

				if [[ "${modules[*]}" == *windows* ]]; then
					get_windows
					print_module windows
				fi
				;;
			tiling)
				read wm_label tiling_workspaces <<< "$value"
				wm_icon=$(sed "s/./_&[^_]*/g" <<< "${wm_label/f}")
				print_tiling
				;;
		esac
	done
}

make_workspaces_content() {
	local ws_count
	workspaces_action='s'

	if [[ $frame_type ]]; then
		workspaces_frame_type=$frame_type
		workspaces_frame_start=$module_frame_start
		workspaces_active_frame_start=$module_active_frame_start
		workspaces_frame_end=$module_frame_end
	fi

	for arg in ${1//,/ }; do
		value=${arg#*:}
		arg=${arg%%:*}

		case $arg in
			o) workspace_offset="$value";;
			p) workspace_padding="%{O$value}";;
			s) workspace_separator="%{B\$bg}%{O$value}";;
			i)
				if ((${#value} > 1)); then
					icon_type=$(sed 's/\w/&\[^_]*_/g' <<< "W$value")
					read workspace_{p,c,s}_icon <<< $(get_icon "${icon_type}[pcs]" | xargs)
				else
					workspace_icons=$value
					while read ws_name; do
						case $workspace_icons in
							l) workspaces_icons+=( $ws_name );;
							n)
								((ws_count++))
								workspaces_icons+=( $(get_icon "number_${ws_count}") )
								#workspaces_icons+=( $ws_count )
								;;
							*) workspaces_icons+=( $(get_icon "Workspace_${ws_name}") );;
						esac
					done <<< $(awk -F '[<>]' '
						/<\/?desktops>/ { d = !d }
						d && /<name>/ { print $3 }' ~/.config/openbox/rc.xml)
				fi
		esac
	done

	workspaces_actions_start='%{A:wmctrl -s ${list[index]}:}'
	workspaces_actions_end='%{A}'
	workspaces_content='$workspaces'
}
