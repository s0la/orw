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
	#local current module_frame_start=${module}_start_frame
	#local current #module_frame_{start,end} module_frame_type=${module}_frame_type

	#[[ $module == workspaces ]] &&
	#~/.orw/scripts/notify.sh "ws: $current_item, ${!current_item}"

	#~/.orw/scripts/notify.sh "ws: $module_frame_start"
	#~/.orw/scripts/notify.sh "ws: ${!module_frame_type}"

	#[[ ${joiner_modules[$short]} ]] ||
	#	set_module_frame $short ${!module_frame_type}

	for index in ${!list[*]}; do
		item=${list[index]}

		#[[ $item == ${!current_item} ]] &&
		#	current=p || current=s

		if [[ $item == ${!current_item} ]]; then
			current=p current_icon=p
		else
			[[ ${workspaces_windows[$item]} ]] &&
				current_icon=c || current_icon=s
			current=s
		fi

		[[ $module == windows ]] &&
			#~/.orw/scripts/notify.sh "WIN: $item, ${windows_titles[$item]}" &&
			label="$cwfg${windows_titles[$item]:-$item}" ||
			label="\${workspace_${current_icon}_icon:-$item}"

		#if [[ ${joiner_modules[$short]} ]]; then
		#	case $index in
		#		0) left_offset=0 right_offset=$offset;;
		#		$((${#list[*]} - 1))) left_offset=$offset right_offset=0;;
		#		*) left_offset=$offset right_offset=$offset;;
		#	esac
		#else
		#	left_offset=$offset right_offset=$offset
		#fi

		#if [[ ${joiner_modules[$short]} &&
		#	($index -eq 0 || $index -eq $((${#list[*]} - 1))) ]]; then
		#		((index)) &&
		#			left_offset=$offset right_offset=0 ||
		#			left_offset=0 right_offset=$offset
		#else
		#	left_offset=$offset right_offset=$offset
		#fi

		#action="%{A:wmctrl -${!wmctrl_action} $item:}%{O$left_offset}$label%{O$right_offset}%{A}"

		#echo $item, $actions_start, $actions_end
		#echo $item, ${!actions_start}, ${!actions_end}
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
			#local buttons="$padding$window_buttons"

		#action="%{A:wmctrl -${!wmctrl_action} $item:}$left_offset$label$right_offset%{A}"
		action="${!actions_start}$left_offset$label$right_offset${!actions_end}"

		#item="\$$short${current}fg$action"
		item="\\\${cj${current}fg:-\\\$$short${current}fg}$action"

		#[[ $module == workspaces ]] &&
		#	~/.orw/scripts/notify.sh -t 11 "$label, $item"
		if [[ ! ${joiner_modules[$short]} ]]; then
			item="\$$short${current}bg$item"
			[[ (${!module_frame_type} == single && $current == p && ! $icons) ||
				(${!module_frame_type} == all && ${!separator}) ]] &&
				item="${!module_frame_start}$item${!module_frame_end}"
			#~/.orw/scripts/notify.sh "$module: ${!module_frame_type}, ${!module_frame_start}"
		fi

		#[[ $module == windows ]] && ~/.orw/scripts/notify.sh -t 11 "$label, $wmctrl_action"
		#[[ $module == workspaces ]] && ~/.orw/scripts/notify.sh -t 11 "WS: $item"

		eval $module+=\"$item\"
		((index < ${#list[*]} - 1)) &&
			eval $module+="${!separator}"
		#[[ $module == windows ]] && echo "$windows" >> w.log
	done

	[[ ${joiner_modules[$short]} ]] ||
		local module_start="${!module_frame_start}\$${short}sbg" module_end="${!module_frame_end}"

	#[[ $module == windows ]] &&
	#	~/.orw/scripts/notify.sh "$module_start, $module_end"

	#[[ $module == windows && $only_current_window ]] &&
	#	windows+="$padding$window_buttons"

	#[[ ${!separator} ]] &&
	[[ ! ${!separator} &&
		((${!module_frame_type} == all || ${!module_frame_type} == single && $icons) ||
		${joiner_groups[*]} =~ (^| )$short|$short( |$)) ]] &&
		echo "$module_start$padding${!module}$padding$module_end" ||
		echo "${!module}"

	#echo "WS: ${!module}" >> ws.log

	#[[ $module == workspaces ]] &&
	#	~/.orw/scripts/notify.sh -t 11 "$module_frame_start${!content}$module_frame_end"

	#[[ ${!separator} ]] &&
	#	eval echo \"${!content}\" ||
	#	eval echo \"$module_frame_start${!content}$module_frame_end\"

	#[[ ${!separator} ]] &&
	#	eval echo \""${module}_content"\" ||
	#	eval echo \""$module_frame_start${module}_content$module_frame_end"\"
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
			#gsub(".*( -|" $3 ") ", "")
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
	#local current_workspace=${value:-$(xdotool get_desktop)}
	#local current_workspace_windows="${workspaces_windows[$current_workspace]}"

	#~/.orw/scripts/notify.sh "WS: $current_workspace, $current_workspace_windows"

	##list=( $(sort -n <<< "${!workspaces_windows[*]}" | xargs) )
	#if ((${#workspaces_windows[*]})); then
	#	local list=( $(sort -n <<< "${!workspaces_windows[*]}" | xargs) )
	#else
	#	local workspace_count=$(xdotool get_num_desktops)
	#	local list=( $(seq 0 $((workspace_count - 1))) )
	#fi

	print_tiling

	[[ ! $current_workspace ]] &&
		local current_workspace=$(xdotool get_desktop)

	((workspace_count)) ||
		local workspace_count=$(xdotool get_num_desktops)
	local list=( $(seq 0 $((workspace_count - 1))) )

	#~/.orw/scripts/notify.sh "GW: ${list[*]}"
	workspaces="$(make_list workspaces W)"
}

#workspaces_actions_start='%{A:wmctrl -s ${list[index]}:}'
#workspaces_actions_end='%{A}'
#get_workspaces
#echo $workspaces
#exit

get_windows() {
	if [[ ! $current_workspace_windows ]]; then
		local current_workspace=$(xdotool get_desktop)
		local workspaces_windows windows_titles current_workspace_windows
		IFS=$'\n' read -d '' all_windows all_titles <<< $(get_all_windows $current_workspace)
		eval workspaces_windows=( $all_windows )
		eval windows_titles=( $all_titles )
		local current_workspace_windows=${workspaces_windows[$current_workspace]}
	fi

	#~/.orw/scripts/notify.sh "$current_workspace_windows" &> /dev/null
	[[ $only_current_window ]] &&
		local list=( $current_window ) ||
		local list=( ${current_workspace_windows} )
	windows="$(make_list windows A)"
}

get_tiling() {
	#if [[ $icons ]]; then
	#	[[ ${tiling_workspaces[*]} == *$current_workspace ]] &&
	#		label='TIL' || label='FLO'
	#else
	#	[[ ${tiling_workspaces[*]} == *$current_workspace ]] &&
	#		label='' || label=''
	#		#label='' || label=''
	#fi

	#[[ ${tiling_workspaces[*]} == *$current_workspace* ]] &&
	#	label='TIL' || label='FLO'
	#icon=$(get_icon "wm_mode_${label,,}")

	[[ "$tiling_workspaces" == *$current_workspace* ]] &&
		label=${wm_label^^} icon="tiling${wm_icon%[*}" || label='FLO' icon='floating'
	icon=$(get_icon "wm_mode_$icon")

	#~/.orw/scripts/notify.sh -t 11 "$label wm_mode_$icon $current_workspace: $tiling_workspaces" &> /dev/null

	[[ $icons ]] &&
		tiling=$icon || tiling=$label
	
	#tiling="$tsfg$tiling"
	#tiling="${cjsbg:-$tsbg}${cjsfg:-$tsfg}$tiling"
}

set_tiling_actions() {
	actions_start='%{A:~/.orw/scripts/signal_windows_event.sh toggle_ws:}'
	actions_end='%{A}'
}

print_tiling() {
	#if [[ ${shorts[tiling]} ]]; then
	if [[ "${modules[*]}" == *tiling* ]]; then
		get_tiling
		set_tiling_actions
		print_module tiling
	fi
}

get_windows_and_titles() {
	#IFS=$'\n' read -d '' ${@::2} <<< $(get_all_windows ${@:2})
	local windows titles
	IFS=$'\n' read -d '' all_{windows,titles} <<< $(get_all_windows ${@:2})
	eval workspaces_windows=( $all_windows )
	eval windows_titles=( $all_titles )
	#eval "$1=( $windows )"
	#eval "$2=( $titles )"
}

check_workspaces() {
	local workspaces event
	local workspace_count=$(xdotool get_num_desktops)
	declare -A all_{windows,titles} workspaces_windows
	get_windows_and_titles #all_windows all_titles 

	#IFS=$'\n' read -d '' all_windows all_titles <<< $(get_all_windows)
	#eval workspaces_windows=( $all_windows )
	#eval windows_titles=( $all_titles )

	local workspaces_fifo=/tmp/workspaces.fifo
	[[ -p $workspaces_fifo ]] || mkfifo $workspaces_fifo
	#[[ ${fifos_to_remove[*]} != *$workspaces_fifo* ]] &&
	#	fifos_to_remove+=( $workspaces_fifo )

	while true; do
		##read event value < $workspaces_fifo
		##read event current_{workspace,window,workspace_windows} < $workspaces_fifo
		#read workspace_status < $workspaces_fifo

		#echo "$workspace_status" >> ws.log
		#
		#read event current_{workspace,window,workspace_windows} <<< "$workspace_status"

		[[ $current_workspace ]] || ~/sws_test.sh info

		read event value < $workspaces_fifo #&
		#read_pid=$!

		#~/.orw/scripts/notify.sh "$event: $value" &> /dev/null

		#[[ $current_workspace ]] || ~/sws_test.sh update

		#wait $read_pid

		#echo "$event: $value" >> ws.log
		#~/.orw/scripts/notify.sh "$event: $value" &> /dev/null

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
				#~/.orw/scripts/notify.sh "$current_workspace_windows" &> /dev/null
				#current_workspace="$value"
				#get_windows_and_titles
				workspaces_windows[$current_workspace]="$current_workspace_windows"
				#~/.orw/scripts/notify.sh "cw: $current_workspace" &> /dev/null

				#~/.orw/scripts/notify.sh "DESK: $current_workspace_windows" &> /dev/null

				get_workspaces
				print_module workspaces

				#echo cw: $current_workspace

				if [[ "${modules[*]}" == *windows* ]]; then
					if [[ ! $current_workspace_windows =~ 0x ]]; then
						unset current_window windows
						print_module windows
					elif ((${#current_workspace_windows} != ${#previous_windows} )); then
						#~/.orw/scripts/notify.sh "from desktop" &> /dev/null
						get_windows
						print_module windows
					fi

					previous_windows="$current_workspace_windows"
				fi

				#~/.orw/scripts/notify.sh "C: $current_workspace, P: $previous_workspace" &> /dev/null
				previous_workspace=$current_workspace
				;;
			new_window)
				#~/.orw/scripts/notify.sh "NEW: $value" &> /dev/null
				read current_window title <<< "$value"
				windows_titles[$current_window]="$title"
				;;
			windows)
				#if [[ $event == current_window ]]; then
				#	current_window="$value"
				#else
				#	[[ $current_workspaace_windows != $value ]] &&
				#		current_workspace_windows="$value"
				#fi

				#~/.orw/scripts/notify.sh -t 11 "$value" &> /dev/null

				read current_{workspace,window,workspace_windows} <<< $value
				#~/.orw/scripts/notify.sh "ncw: $current_workspace" &> /dev/null
				#~/.orw/scripts/notify.sh "from windows $current_workspace_windows" &> /dev/null
				[[ ! "$current_workspace_windows" =~ $current_window ]] &&
					current_workspace_windows+=" $current_window"
				#current_workspace_windows="${current_workspace_windows/$current_window} $current_window"

				workspaces_windows[$current_workspace]="$current_workspace_windows"

				#if [[ $current_workspace != $previous_workspace ]]; then
				#	get_workspaces
				#	print_module workspaces
				#	previous_workspace=$current_workspace
				#	~/.orw/scripts/notify.sh -t 11 "ws diff $current_workspace"
				#fi

				#~/.orw/scripts/notify.sh -t 11 "C: $current_workspace, P: $previous_workspace"

				if [[ $current_workspace != $previous_workspace ]]; then
					get_workspaces
					print_module workspaces
					previous_workspace=$current_workspace
				fi

				#~/.orw/scripts/notify.sh -t 11 "ws: $windows"

				#echo cww: $current_workspace_windows
				#echo cwd: $current_workspace, $current_window, ${windows_titles[$current_window]}

				#echo $current_workspace, $current_window, $current_workspace_windows
				if [[ "${modules[*]}" == *windows* ]]; then
					get_windows
					print_module windows
				fi
				;;
			tiling)
				#read -a tiling_workspaces <<< "${value//_/ }"
				read wm_label tiling_workspaces <<< "$value"
				wm_icon=$(sed "s/./_&[^_]*/g" <<< "${wm_label/f}")
				#~/.orw/scripts/notify.sh "$value: $wm_label, $wm_icon $tiling_workspaces" &> /dev/null &
				#tiling_workspaces=( ${tiling_workspaces//_/ } )
				#~/.orw/scripts/notify.sh "TIL: ${tiling_workspaces[*]}" &> /dev/null
				print_tiling
				;;
		esac

		#echo -e "$event: $value\nC: $current_workspace, P: $previous_workspace" >> ws.log

		#~/.orw/scripts/notify.sh -t 11 "$current_workspace - $previous_workspace" &> /dev/null

		#sleep 2
	done

	return

	#xprop -spy -root _NET_CURRENT_DESKTOP $listen_windows |
	while true; do
		#while read change; do
		read change value < $workspaces_fifo
			#change="${change##*[\#=] }"
			#~/.orw/scripts/notify.sh -t 11 "WINDOW $change, $value"

			if [[ $value == 0x* ]]; then
				if [[ $value == *\ * ]]; then
					#~/.orw/scripts/notify.sh -t 11 "WIN $value"
					value="${value//,}"

					if ((${#value} < ${#current_windows})); then
						changed_window=$(comm -3 \
							<(tr ' ' '\n' <<< $value | sort) \
							<(tr ' ' '\n' <<< $current_windows | sort) | grep -o '0x\w\+')

						current_workspace_windows="${current_workspace_windows/$changed_window}"
						workspaces_windows[$current_workspace]="$current_workspace_windows"

						if [[ ! $current_workspace_windows =~ 0x ]]; then
							#unset current_window
							#echo "WINDOWS:"
							unset current_window windows
							print_module windows
						fi
						#~/.orw/scripts/notify.sh "HERE $current_window ^$current_workspace_windows^"
					fi

					current_windows="$value"
				else
					if [[ ! $value =~ ^(0x0|$current_window)$ ]]; then
						#~/.orw/scripts/notify.sh -t 11 "OTHER $value"
					#if [[ ! $value =~ ^$current_window$ ||
					#	($value == 0x0 && ! $current_workspace_windows =~ 0x) ]]; then
						current_window="$value"
						#~/.orw/scripts/notify.sh "HERE $current_window"

						#[[ $current_workspace_windows =~ $current_window ]] ||
						#	current_workspace_windows+=" $current_window"
						if [[ ! $current_workspace_windows =~ $current_window ]]; then
							current_workspace_windows+=" $current_window"
							#windows_titles[$current_window]="$(get_all_windows ${current_window#0x})"
							windows_titles[$current_window]="$(get_all_windows $current_window)"
						fi

						#list=( $current_workspace_windows )
						#windows="$(make_list windows A)"
						get_windows
						#echo ${list[*]}
						#~/.orw/scripts/notify.sh "wsfg: $sfg"
						#~/.orw/scripts/notify.sh "w: $windows"

						#eval echo \"WINDOWS:"$windows_content"\"
						print_module windows

						#list=( $current_workspace_windows )
						#make_list windows A
						#echo "WINDOWS:$windows_content"

						workspaces_windows[$current_workspace]="$current_workspace_windows"
					fi
				fi
			else
				current_workspace=$value
				get_windows_and_titles #current_workspace_windows _ $current_workspace
				current_workspace_windows="${workspaces_windows[$current_workspace]}"
				#get_windows_and_titles current_workspace_windows _ $current_workspace
				#current_workspace_windows="$(get_all_windows $current_workspace)"
				#workspaces_windows[$current_workspace]="$current_workspace_windows"

				#echo HERE $value, $current_workspace_windows

				#~/.orw/scripts/notify.sh -t 11 "WS $current_workspace_windows"

				#list=( $(sort -n <<< "${!workspaces_windows[*]}" | xargs) )
				#workspaces="$(make_list workspaces W)"
				get_workspaces
				#make_list workspaces W

				if [[ ! $current_workspace_windows =~ 0x ]]; then
					#unset current_window
					#echo "WINDOWS:"
					unset current_window windows
					print_module windows
					#echo ${list[*]}
				fi

				#eval echo \"WORKSPACES:"$workspaces_content"\"
				print_module workspaces
				#echo "WORKSPACES:$workspaces_content"
			fi
		#done < $workspaces_fifo #| lemonbar -p -F'#cecece' -g 500x30
	done
}

make_workspaces_content() {
	workspaces_action='s'
	#workspace_padding="$padding"

	#if [[ ! ${joiner_modules[W]} ]]; then
		#set_module_frame W
	if [[ $frame_type ]]; then
		workspaces_frame_type=$frame_type
		workspaces_frame_start=$module_frame_start
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
				workspace_icons=$value
				icon_type=$(sed 's/\w/&\.\*_/g' <<< "W$workspace_icons")
				read workspace_{p,c,s}_icon <<< $(get_icon "${icon_type}[pcs]" | xargs)
		esac
	done

	workspaces_actions_start='%{A:wmctrl -s ${list[index]}:}'
	workspaces_actions_end='%{A}'

	#local padding="\${workspace_padding:-$padding}"
	#local padding='${workspace_padding:-$padding}'
	#workspaces_content="\$Wsbg$padding\$workspaces$padding"
	workspaces_content='$workspaces'
}

#check_workspaces

#listen_windows='_NET_CLIENT_LIST_STACKING _NET_ACTIVE_WINDOW'
#check_workspaces
#exit
#
#workspaces_fifo=/tmp/workspaces.fifo
#[[ -p $workspaces_fifo ]] && rm $workspaces_fifo
#mkfifo $workspaces_fifo
#
#while true; do
#	cat $workspaces_fifo
#done
#exit
