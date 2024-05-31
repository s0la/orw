#!/bin/bash

launchers_dir=~/.orw/dotfiles/.config/orw/bar/launchers

list_launchers() {
	awk '
		NR > FNR {
			i = $1
			sub("0x0*", "0x", i)
			gsub(".* |[0-9]*$", "")
			t = tolower($0)
			at[t] = at[t] " " i
		}

		NR == FNR {
			if (/^$/) {
				if (l) { al[++lc] = l; l = "" }
			} else {
				if (!/^#/) {
					if (/name/) {
						l = $0
						gsub("^[^\"]*.|\"$", "")
						ln = $0
						rl[ln] = 1
					} else l = l " " ln "_" $0
				}
			}
		}

		END {
			for (t in at) {
				if (t in rl) printf "[%s]=\"%s\" ", t, substr(at[t], 2)
			}
			print ""
			for (li in al) print al[li]
		}' <(cat $launchers_dir/$bar_name) <(wmctrl -lG | sort -nk 2,2 -k 3,3 -k 4,4)
}

#load_launchers
#exit

#IFS=$'\n' read -d '' launcher_{ids,properties} <<< $(load_launchers)
#echo $launcher_properties

#declare -A launcher_ids

load_launchers() {
	launcher_list=()

	#~/.orw/scripts/notify.sh -t 11 "$(list_launchers)"

	while read launcher; do
		if [[ $launcher == name* ]]; then
			eval $launcher
			launcher_list+=( $name )
		else
			#~/.orw/scripts/notify.sh -t 11 "Ls: $launcher"
			eval launcher_ids=( $launcher )
			#~/.orw/scripts/notify.sh -t 11 "Ls: ${launcher_ids[*]}"
			#echo -e "$launcher\n${launcher_ids[*]}" > l.log
		fi
	done <<< $(list_launchers)
}

get_launchers() {
	local properties="icon left middle right up down" {id,}s
	local signal_event=~/.orw/scripts/signal_windows_event.sh
	[[ $active_launcher ]] ||
		active_launcher=$(printf '0x%x' $(xdotool getactivewindow))

	launchers=''

	if ((!${#launcher_list[*]})); then
		declare -A launcher_ids
		load_launchers
	fi

	#if [[ $frame == ]]; then
	#fi

	for launcher_index in ${!launcher_list[*]}; do
		launcher=${launcher_list[launcher_index]}
		ids=( ${launcher_ids[$launcher]} )
		id_count=${#ids[*]}
		#read $properties <<< $(eval echo ${launcher}_{${properties// /,}})

		#left_action="%{A:${!left}:}"
		#closing_actions='%{A}'

		#[[ ${!middle} ]]

		icon=${launcher}_icon

		#for action in ${properties#* }; do
		#	action=${launcher}_$action

		for action in ${launcher}_{left,middle,right,up,down}; do
			#action=${launcher}_$action

			if [[ ${!action} ]]; then
				case ${action#*_} in
					left)
						[[ ${ids[*]} == *$active_launcher* ]] &&
							local left_action="$signal_event min" || 
							local left_action="wmctrl -a $launcher \\\|\\\| ${!action} \\\&"
						actions_start="%{A:$left_action &> /dev/null:}"
						actions_end="%{A}"
						continue
						;;
					middle) action_index=2;;
					right) action_index=3;;
					up) action_index=4;;
					down) action_index=5;;
				esac

				actions_start+="%{A${action_index}:${!action} &> /dev/null:}"
				actions_end+='%{A}'
			fi
		done

		color=s
		((launcher_index)) || local start_padding=$launchers_padding
		((launcher_index == ${#launcher_list[*]} - 1)) && local end_padding=$launchers_padding

		if ((id_count)); then
			color=p

			if [[ $actions_start != *A2* ]]; then
				[[ ${ids[*]} == *$active_launcher* ]] &&
					close_launcher=$active_launcher || close_launcher=${ids[0]}
				actions_start+="%{A2:wmctrl -ic $close_launcher:}" actions_end+="%{A}"
			fi

			[[ $actions_start != *A3* && ${ids[*]} == *$active_launcher* ]] &&
				actions_start+="%{A3:$signal_event max:}" actions_end+="%{A}"

			if [[ ${ids[*]} == *$active_launcher* ]]; then
				color=a

				if ((action_index < 4)); then
					for id in ${!ids[*]}; do
						[[ ${ids[$id]} == $active_launcher ]] && break
					done

					actions_start+="%{A4:wmctrl -ia ${ids[(id + id_count -1) % id_count]}:}"
					actions_start+="%{A5:wmctrl -ia ${ids[(id + 1) % id_count]}:}"
					actions_end+="%{A}%{A}"
				fi

				#actions_start="$launchers_frame_start$actions_start"
				#actions_end+="$launchers_frame_end"
			elif ((action_index < 4)); then
				actions_start+="%{A4:wmctrl -ia ${ids[-1]}:}%{A5:wmctrl -ia ${ids[0]}:}"
				actions_end+="%{A}%{A}"
			fi

			if [[ $launchers_frame_type == single && $color == [ap] ]]; then
				#actions_start="$launchers_frame_start$actions_start"
				#actions_end+="$launchers_frame_end"
				#actions_start="\${L${color}fc:-\$Lpfc}$actions_start"
				#actions_end+="$launchers_frame_end"
				[[ $color == a ]] &&
					frame_color=p || frame_color=s
				actions_start="${launchers_frame_start/L*fc/L${frame_color}fc}$start_padding$actions_start"
				actions_end+="$end_padding$launchers_frame_end"
				unset {start,end}_padding
				#~/.orw/scripts/notify.sh -t 11 "L: $actions_start"

				#echo "L: $actions_start,    $actions_end" >> l.log
			fi
		fi

		#case $color in
		#	a) local frame_mode=${!module_active_frame_start};;
		#	p) local frame_mode=${!module_frame_start};;
		#	s) unset frame_mode
		#esac

		#if [[ $padding ]]; then
		#	((launcher_index)) || local padding_start_frame=$frame_mode
		#	((launcher_index == ${#launcher_list[*]} - 1)) &&
		#		unset frame_mode_end || local frame_mode_end=$module_frame_end
		#fi

		((launcher_index)) && launchers+="$launcher_separator"
		launcher="$actions_start$launcher_offset${!icon}$launcher_offset$actions_end"
		launchers+="\$L${color}bg\$L${color}fg$start_padding$launcher$end_padding"

		unset launcher action_index actions_{start,end} start_padding
	done
}

#declare -A launcher_ids
#load_launchers
#echo ${launcher_ids[sxiv]}
#echo ${!launcher_ids[*]}, ${launcher_ids[*]}
#get_launchers
#echo $launchers
#exit

assign_launchers_args() {
	case $arg in
		s) launcher_separator="\$Lsbg%{O$value}";;
		p) launchers_padding="%{O$value}";;
		o) launcher_offset="%{O$value}";;
	esac
}

make_launchers_content() {
	if [[ $frame_type ]]; then
		launchers_frame_type=$frame_type
		launchers_frame_start=$module_frame_start
		launchers_active_frame_start=$module_active_frame_start
		launchers_frame_end=$module_frame_end

		[[ $frame_type == all ]] &&
			local frame_start=$module_frame_start frame_end=$module_frame_end
	fi

	[[ -f $launchers_dir/$bar_name ]] ||
		cp ~/.orw/scripts/new_bar/launchers $launchers_dir/$bar_name

	assign_args launchers

	#[[ ! $launcher_separator &&
	#	(($frame_type == all) || ${joiner_groups[*]} =~ (^| )L|L( |$)) ]] &&
	#	echo "$launchers_padding: $Lsbg$Lsfg$launchers_padding$launchers$launchers_padding" >> l.log

	[[ ! $launcher_separator &&
		(($frame_type == all) || ${joiner_groups[*]} =~ (^| )L|L( |$)) ]] &&
		#launchers_content='$Lsbg$Lsfg$launchers_padding$launchers$launchers_padding' ||
		launchers_content="$frame_start\$Lsbg\$Lsfg\$launchers$frame_end" ||
			launchers_content='$launchers'
}

find_launcher_by_id() {
	local id=$1

	for launcher in ${!launcher_ids[*]}; do
		[[ ${launcher_ids[$launcher]} == *$id* ]] &&
			echo $launcher && break
	done
}

swap_launchers() {
	local launcher=$(find_launcher_by_id $source_id)
	local ids=${launcher_ids[$launcher]}
	#~/.orw/scripts/notify.sh -t 11 "SPAW: $launcher, $ids"

	if [[ $target_id == *,* ]]; then
		target_ids=''

		for id in ${ids[*]}; do
			if [[ $id =~ ${target_id//,/\|} ]]; then
				[[ $target_ids ]] && target_ids+='*'
				target_ids+="$id"
			fi
		done

		target_id=$target_ids
	fi

	if [[ $ids == *$source_id* && $target_id && $ids == *$target_id* ]]; then
		#~/.orw/scripts/notify.sh -t 11 "PRE: $ids"
		ids="${ids/$source_id}"
		[[ $reverse ]] &&
			ordered_ids="$source_id $target_id" || ordered_ids="$target_id $source_id"
		ids="${ids/$target_id/$ordered_ids}"
		#~/.orw/scripts/notify.sh -t 11 "POST: $ids"
		launcher_ids[$launcher]="$ids"
	fi

	active=$source_id
}

check_launchers() {
	local launcher{,s} event {ordered_,}ids
	declare -A launcher_ids

	load_launchers
	get_launchers
	#~/.orw/scripts/notify.sh -t 11 "LNCH: $launchers"
	#exit
	print_module launchers

	local launchers_fifo=/tmp/launchers.fifo
	[[ -p $launchers_fifo ]] || mkfifo $launchers_fifo
	#[[ ${fifos_to_remove[*]} != *$workspaces_fifo* ]] &&
	#	fifos_to_remove+=( $workspaces_fifo )

	while true; do
		read event value < $launchers_fifo
		#~/.orw/scripts/notify.sh -t 11 "LNC: $event $value"
		#echo "LNC: $event - $value" >> ~/e.log

		case $event in
			reload) load_launchers;;
			active) active_launcher=$value;;
			close)
				#~/.orw/scripts/notify.sh -t 18 "$event: $value"
				launcher=$(find_launcher_by_id $value)
				[[ $launcher && ${launcher_ids[$launcher]} ]] &&
					launcher_ids[$launcher]="${launcher_ids[$launcher]/$value}" #||
					#~/.orw/scripts/notify.sh -t 18 "$event: $value"
				;;
			new_window)
				active_launcher="${value%% *}" launcher_name="${value#* }"
				#~/.orw/scripts/notify.sh -t 18 "LNC: $launcher_name: ${launcher_name%%[0-9]*} - $value"
				launcher_name="${launcher_name%%[0-9]*}"
				[[ ! ${launcher_ids[$launcher_name]} ]] &&
					launcher_ids[$launcher_name]="$active_launcher" ||
					launcher_ids[$launcher_name]+=" $active_launcher"
				;;
			swap)
				read {source,target}_id reverse <<< $value
				swap_launchers
				#launcher=$(find_launcher_by_id $source_id)
				#ids=${launcher_ids[$launcher]}

				#if [[ $ids == *$source_id* && $ids == *$dest_id* ]]; then
				#	#~/.orw/scripts/notify.sh -t 11 "PRE: $ids"
				#	ids="${ids/$source_id}"
				#	[[ $reverse ]] &&
				#		ordered_ids="$source_id $dest_id" || ordered_ids="$dest_id $source_id"
				#	ids="${ids/$dest_id/$ordered_ids}"
				#	#~/.orw/scripts/notify.sh -t 11 "POST: $ids"
				#	launcher_ids[$launcher]="$ids"
				#fi
		esac

		get_launchers
		print_module launchers
	done
}
