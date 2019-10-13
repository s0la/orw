#!/bin/bash

workspaces=( $(wmctrl -d | awk '{ wn = $NF; if(wn ~ /^[0-9]+$/) { if(wn > 1) tc = wn - 1; wn = "tmp" tc }; print wn }') )
workspace_count=${#workspaces[*]}

[[ $@ =~ move ]] && move=true

if [[ -z $@ || $@ =~ (move|wall)$ ]]; then
	for workspace in ${workspaces[*]}; do
		echo $workspace
	done

	#[[ $move ]] && echo  
	[[ $move ]] && echo +tmp
else
	killall rofi

	window_id=$(printf "0x%.8x" $(xdotool getactivewindow))

	#if [[ "$@" =~   ]]; then
	if [[ "$@" =~ \+tmp  ]]; then
		new_workspace_name='tmp'
		new_workspace_index=$workspace_count

		((workspace_count++))
		wmctrl -n $workspace_count
	else
		new_workspace_name="${desktop:-${@: -1}}"

		for new_workspace_index in ${!workspaces[*]}; do
			[[ ${workspaces[new_workspace_index]} == $new_workspace_name ]] && break
		done
	fi

	if [[ $move ]]; then
		windowctl=~/.orw/scripts/windowctl.sh

		current_workspace_index=$(wmctrl -l | awk '$1 == "'$window_id'" { print $2 }')
		current_workspace_name=${workspaces[current_workspace_index]}

		#[[ ! $current_workspace_name =~ ^tmp && $new_workspace_name =~ ^tmp[0-9]+?$ ]] && $windowctl -S
		wmctrl -i -r $window_id -t $new_workspace_index

		if [[ $new_workspace_name =~ ^tmp[0-9]+?$ ]]; then
			[[ $current_workspace_name =~ ^tmp[0-9]+?$ ]] || save=-s
			$windowctl -D $new_workspace_index -i $window_id $save -g
			#$windowctl -g
			#sleep 0.4
			sleep 0.08
		fi

		if [[ $current_workspace_name =~ ^tmp[0-9]+?$ ]]; then
			#[[ $new_workspace_name =~ ^tmp ]] || $windowctl -D $new_workspace_index -i $window_id -r
			#[[ $new_workspace_name =~ ^tmp ]] || $windowctl -D $new_workspace_index -i $window_id -g
			[[ $new_workspace_name =~ ^tmp ]] || $windowctl -D $new_workspace_index -i $window_id -r

			window_count=$(wmctrl -l | awk '$2 == '$current_workspace_index' { wc++ } END { print wc }')

			if ((window_count)); then
				current_workspace_window=$(wmctrl -l | awk '$2 == '$current_workspace_index' { print $1; exit }')
				$windowctl -D $current_workspace_index -i $current_workspace_window -g
				sleep 0.3
			else
				sleep 0.07
				wmctrl -n $((workspace_count - 1))
				~/.orw/scripts/notify.sh -p "Temporary workspace ${current_workspace_name^^} has been removed."
			fi
		fi
	fi

	wmctrl -s $new_workspace_index

	[[ $(wmctrl -l | awk '$NF == "ncmpcpp_with_cover_art" && $2 == '$new_workspace_index'') ]] && ~/.orw/scripts/ncmpcpp.sh -R
	[[ $@ =~ wall ]] && ~/.orw/scripts/wallctl.sh -c -r
fi
