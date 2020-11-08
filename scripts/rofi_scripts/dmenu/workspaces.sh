#!/bin/bash

theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)
[[ $theme =~ dmenu|icons ]] && ~/.orw/scripts/set_rofi_geometry.sh workspaces

current_workspace=$(xdotool get_desktop)
mode=$(awk '/^mode/ { print $NF }' ~/.config/orw/config)

if [[ $theme == icons ]]; then
	workspaces=( '' '' '' )
	workspaces+=( $(wmctrl -d | awk '$NF ~ "^[0-9]$" {
		if($NF == 1) i = " "
		else if($1 - 2 == 2) i = " "
		else if($1 - 2 == 3) i = " "
		else if($1 - 2 == 4) i = " "
		else if($1 - 2 == 5) i = " "

		tw = tw " " i
	} END { print tw }') )

	active="-a $current_workspace"
else
	workspaces=( $(wmctrl -d | awk '\
		{
			wn = $NF

			if(wn ~ /^[0-9]+$/) {
				if(wn > 1) tc = wn - 1
				wn = "tmp" tc
			}

			print wn
		}') )

	indicator=''
	indicator='●  '
	empty='   '
fi

workspace_count=${#workspaces[*]}

[[ $1 == move ]] && move=true

if [[ ! $@ =~ wall ]]; then
	[[ $theme == icons ]] && workspaces+=( '' ) || workspaces+=( " tmp" )
fi

for workspace_index in ${!workspaces[*]}; do
	((workspace_index)) && all_workspaces+='\n'
	((workspace_index == current_workspace)) && prefix="$indicator" || prefix="$empty"
	((workspace_index == ${#workspaces[*]} - 1)) && unset prefix
	all_workspaces+="$prefix${workspaces[workspace_index]}"
done

chosen_workspace=$(echo -e "$all_workspaces" | rofi -dmenu $active -theme main)
	#rofi -dmenu -selected-row $current_workspace $active -theme main)

window_id=$(printf "0x%.8x" $(xdotool getactivewindow))

if [[ "$chosen_workspace" =~   ]]; then
	new_workspace_name='tmp'
	new_workspace_index=$workspace_count

	((workspace_count++))
	wmctrl -n $workspace_count
else
	[[ $theme == icons ]] &&
		new_workspace_name="${chosen_workspace##* }" || new_workspace_name="${desktop:-${chosen_workspace##* }}"

	for new_workspace_index in ${!workspaces[*]}; do
		[[ ${workspaces[new_workspace_index]} == $new_workspace_name ]] && break
	done
fi

if [[ $move ]]; then
	windowctl=~/.orw/scripts/windowctl.sh
	current_workspace_index=$(wmctrl -l | awk '$1 == "'$window_id'" { print $2 }')
	current_workspace_name=${workspaces[current_workspace_index]}

	#tile=$(awk '/^mode/ { if($NF != "floating") print "true" }' ~/.config/orw/config)
	#[[ $tile ]] && $windowctl -D $new_workspace_index -t ||

	if [[ $mode != floating ]]; then
		$windowctl -D $new_workspace_index -t
	else
		#echo $current_workspace_index $current_workspace_name
		#echo $new_workspace_index $new_workspace_name
		#exit

		wmctrl -i -r $window_id -t $new_workspace_index
		#exit

		[[ $theme == icons && $chosen_workspace !=   ]] &&
			temp_workspace_regex='^(||||)$' || temp_workspace_regex='^tmp[0-9]+?$'

		if [[ "$new_workspace_name" =~ $temp_workspace_regex ]]; then
			[[ $current_workspace_name =~ $temp_workspace_regex ]] || save=-s

			[[ $mode != floating ]] && $windowctl -S
			$windowctl -D $new_workspace_index -i $window_id $save -g
			sleep 0.08
		fi

		if [[ $current_workspace_name =~ $temp_workspace_regex ]]; then
			#[[ $new_workspace_name =~ $temp_workspace_regex ]] || $windowctl -D $new_workspace_index -i $window_id -r
			if [[ ! $new_workspace_name =~ $temp_workspace_regex ]]; then
				[[ $mode == floating ]] && restore=-r || restore=-R
				$windowctl -D $new_workspace_index -i $window_id $restore
			fi

			window_count=$(wmctrl -l | awk '$2 == '$current_workspace_index' { wc++ } END { print wc }')

			if ((window_count)); then
				current_workspace_window=$(wmctrl -l | awk '$2 == '$current_workspace_index' { print $1; exit }')
				$windowctl -D $current_workspace_index -i $current_workspace_window -g
				sleep 0.3
			else
				sleep 0.07

				workspace_to_remove=$(wmctrl -d | \
					awk '$1 == "'$current_workspace_index'" {
						if ($NF - 1) tn = $NF - 1
						print ("'$theme'" == "icons") ? "tmp" tn : "'$current_workspace_name'" }')
				wmctrl -n $((workspace_count - 1))
				~/.orw/scripts/notify.sh -p "Temporary workspace <b>$workspace_to_remove</b> has been removed."
			fi
		#else
		#	[[ ! $new_workspace_name =~ $temp_workspace_regex ]] && $windowctl -D $new_workspace_index -t
		fi
	fi
fi

wmctrl -s $new_workspace_index

[[ $1 == wall ]] && ~/.orw/scripts/wallctl.sh -c -r
