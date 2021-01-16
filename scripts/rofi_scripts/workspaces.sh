#!/bin/bash

theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)

if [[ $theme != icons ]]; then
	workspaces=( $(wmctrl -d | awk '\
		{
			wn = $NF

			if(wn ~ /^[0-9]+$/) {
				if(wn > 1) tc = wn - 1
				wn = "tmp" tc
			}

			print wn
		}') )

	current_workspace=$(xdotool get_desktop)
	indicator=''
	indicator='●'
	empty=' '
else
	workspaces=( '' '' '' )

	workspaces+=( $(wmctrl -d | awk '$NF ~ "^[0-9]$" {
		#if($NF == 1) i = " "
		#else if($NF == 2) i = " "
		#else if($NF == 3) i = " "
		#else if($NF == 4) i = " "
		#else if($NF == 5) i = " "

		if($NF == 1) i = " "
		else if($NF == 2) i = " "
		else if($NF == 3) i = " "
		else if($NF == 4) i = " "
		else if($NF == 5) i = " "

		tw = tw " " i
	} END { print tw }') )
fi

workspace_count=${#workspaces[*]}

[[ $@ =~ move ]] && move=true

if [[ ! $@ =~ wall ]]; then
	[[ $theme == icons ]] && workspaces+=( '' ) || workspaces+=( " tmp" )
fi

if [[ -z $@ || $@ =~ (move|wall)$ ]]; then
	for workspace_index in ${!workspaces[*]}; do
		((workspace_index == current_workspace)) && echo -n "$indicator" || echo -n "$empty"
		echo "$empty${workspaces[workspace_index]}"
	done

	#[[ $move ]] && echo  
	#[[ $move ]] && echo " +tmp"
	#[[ $move ]] && echo "   tmp"
else
	killall rofi
	[[ $@ =~ wall ]] && ~/.orw/scripts/xwallctl.sh -c -r &

	window_id=$(printf "0x%.8x" $(xdotool getactivewindow))

	#if [[ "$@" =~   ]]; then
	#if [[ "$@" =~ \+tmp ]]; then
	if [[ "$@" =~   ]]; then
		new_workspace_name='tmp'
		new_workspace_index=$workspace_count

		((workspace_count++))
		wmctrl -n $workspace_count
	else
		#if [[ $theme == icons ]]; then
		#	new_workspace_name="$@"
		#else
		#	new_workspace_name="${desktop:-${@: -1}}"
		#	new_workspace_name="${new_workspace_name:2}"
		#fi

		[[ $theme == icons ]] &&
			new_workspace_name="$@" || new_workspace_name="${desktop:-${@: -1}}"
		new_workspace_name="${new_workspace_name##* }"

		#new_workspace_regex='^(||||)$'
		#~/.orw/scripts/notify.sh "^$new_workspace_name^ ^$new_workspace_regex^"
		#[[ "$new_workspace_name" =~ $new_workspace_regex ]] &&
		#	~/.orw/scripts/notify.sh here

		for new_workspace_index in ${!workspaces[*]}; do
			#~/.orw/scripts/notify.sh "^${workspaces[new_workspace_index]}$\n^$new_workspace_name$"
			#~/.orw/scripts/notify.sh "^${workspaces[new_workspace_index]}^ ^$new_workspace_name^"
			[[ ${workspaces[new_workspace_index]} == $new_workspace_name ]] && break
			#[[ ${workspaces[new_workspace_index]} == ${new_workspace_name#$indicator } ]] && break
		done
		#~/.orw/scripts/notify.sh "wi: $new_workspace_index $new_workspace_name"
	fi

	if [[ $move ]]; then
		windowctl=~/.orw/scripts/windowctl.sh

		current_workspace_index=$(wmctrl -l | awk '$1 == "'$window_id'" { print $2 }')
		#~/.orw/scripts/notify.sh "cw: ${workspaces[current_workspace_index]}"
		#current_workspace_name=${workspaces[current_workspace_index]:2}
		current_workspace_name=${workspaces[current_workspace_index]}

		#[[ ! $current_workspace_name =~ ^tmp && $new_workspace_name =~ ^tmp[0-9]+?$ ]] && $windowctl -S
		wmctrl -i -r $window_id -t $new_workspace_index

		[[ $theme == icons && ! $@ =~   ]] &&
			new_workspace_regex='^(||||)$' || new_workspace_regex='^tmp[0-9]+?$'

		#~/.orw/scripts/notify.sh "nw: $new_workspace_name"

		if [[ "$new_workspace_name" =~ $new_workspace_regex ]]; then
			[[ $current_workspace_name =~ $new_workspace_regex ]] || save=-s
			$windowctl -D $new_workspace_index -i $window_id $save -g
			#$windowctl -g
			#sleep 0.4
			sleep 0.08
		fi

		#~/.orw/scripts/notify.sh "^$current_workspace_name$"

		if [[ $current_workspace_name =~ $new_workspace_regex ]]; then
			#~/.orw/scripts/notify.sh $current_workspace_name
			#~/.orw/scripts/notify.sh "$new_workspace_index $new_workspace_name"
			#[[ $new_workspace_name =~ ^tmp ]] || $windowctl -D $new_workspace_index -i $window_id -r
			#[[ $new_workspace_name =~ ^tmp ]] || $windowctl -D $new_workspace_index -i $window_id -g
			[[ $new_workspace_name =~ $new_workspace_regex ]] || $windowctl -D $new_workspace_index -i $window_id -r

			window_count=$(wmctrl -l | awk '$2 == '$current_workspace_index' { wc++ } END { print wc }')

			if ((window_count)); then
				#~/.orw/scripts/notify.sh here
				current_workspace_window=$(wmctrl -l | awk '$2 == '$current_workspace_index' { print $1; exit }')
				$windowctl -D $current_workspace_index -i $current_workspace_window -g
				sleep 0.3
			else
				#~/.orw/scripts/notify.sh after
				sleep 0.07
				workspace_to_remove=$(wmctrl -d | \
					awk '$1 == "'$current_workspace_index'" {
						if ($NF - 1) tn = $NF - 1
						print ("'$theme'" == "icons") ? "tmp" tn : "'$current_workspace_name'" }')
				#~/.orw/scripts/notify.sh "^$current_workspace_index^ $workspace_to_remove"
				wmctrl -n $((workspace_count - 1))
				~/.orw/scripts/notify.sh -p "Temporary workspace <b>$workspace_to_remove</b> has been removed."
				#~/.orw/scripts/notify.sh -p "Temporary workspace ${current_workspace_name^^} has been removed."
			fi
		fi
	fi

	wmctrl -s $new_workspace_index

	#[[ $(wmctrl -l | awk '$NF == "ncmpcpp_with_cover_art" && $2 == '$new_workspace_index'') ]] && ~/.orw/scripts/ncmpcpp.sh -R
fi
