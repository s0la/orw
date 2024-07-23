#!/bin/bash

current_workspace=$(xdotool get_desktop)

mode=$(awk '/^mode/ { print $NF }' ~/.config/orw/config)
style=$(awk -F '[".]' 'END { print $(NF - 2) }' ~/.config/rofi/main.rasi)

declare -A workspace_icons
workspace_icons=( [web]=  [development]=  [media]=  [upwork]=$ )

if [[ $style =~ icons|dmenu ]]; then
	icons=~/.orw/scripts/icons
	active="-a ${2:-$current_workspace}"
else
	indicator='●  '
	empty='   '
fi

active="-a ${2:-$current_workspace}"

workspaces=( $(awk '
		/<\/?names>/ { wn = (wn + 1) % 2 }

		wn && /<name>/ {
			cwn = gensub("[^>]*>([^<]*).*", "\\1", 1)
			awn = awn "|" cwn
		}

		FILENAME ~ ".*(icons|dmenu)$" && $0 ~ "Workspace_(" substr(awn, 2) ")" {
			awi = awi " " gensub(".*=", "", 1)
		} END { print (awi) ? awi : gensub("\\|", " ", "g", awn) }' ~/.config/openbox/rc.xml $icons) )

workspace_count=${#workspaces[*]}
window_id=$(printf "0x%.8x" $(xdotool getactivewindow))

[[ $1 == move ]] && move=true

manage=
if [[ $manage ]]; then
	#[[ $style =~ icons|dmenu ]] && workspaces+=(    ) || workspaces+=( add remove )
	[[ ! $style =~ icons|dmenu ]] &&
		workspaces+=( add remove ) ||
		workspaces+=( $(sed -n 's/^\(plus\|minus\).*=//p' $icons | xargs) )
fi

for workspace_index in ${!workspaces[*]}; do
	((workspace_index)) && all_workspaces+='\n'
	((workspace_index == ${#workspaces[*]} - 1)) && unset prefix
	all_workspaces+="$prefix${workspaces[workspace_index]}"
done

[[ $move ]] || toggle

item_count=${#workspaces[*]}
set_theme_str

read chosen_{index,workspace} <<< $(echo -e "$all_workspaces" |
	rofi -dmenu -format 'i s' -selected-row $current_workspace \
	-theme-str "$theme_str" $active -theme main)

if [[ -z $chosen_workspace || $chosen_index -eq $current_workspace ]]; then
	toggle
	exit 0
fi

[[ $1 == wall ]] && ~/.orw/scripts/wallctl.sh -c -r &

if [[ "$chosen_workspace" =~   ]]; then
	wmctrl -n $((workspace_count - 1))
else
	if [[ "$chosen_workspace" =~   ]]; then
		new_workspace_name='tmp'
		new_workspace_index=$workspace_count

		((workspace_count++))
		wmctrl -n $workspace_count
	else
		[[ $style =~ icons|dmenu ]] &&
			new_workspace_name="${chosen_workspace##* }" || new_workspace_name="${desktop:-${chosen_workspace##* }}"

		for new_workspace_index in ${!workspaces[*]}; do
			[[ ${workspaces[new_workspace_index]} == $new_workspace_name ]] && break
		done
	fi

	if [[ $move ]]; then
		windowctl=~/.orw/scripts/windowctl.sh
		current_workspace_index=$(wmctrl -l | awk '$1 == "'$window_id'" { print $2 }')
		current_workspace_name=${workspaces[current_workspace_index]}

		if [[ $mode != floating ]]; then
			echo $new_workspace_index
			exit
			$windowctl -D $new_workspace_index -t
		else
			wmctrl -i -r $window_id -t $new_workspace_index

			[[ $style =~ icons|dmenu && $chosen_workspace !=   ]] &&
				temp_workspace_regex='^(||||)$' || temp_workspace_regex='^tmp[0-9]+?$'

			if [[ "$new_workspace_name" =~ $temp_workspace_regex ]]; then
				[[ $current_workspace_name =~ $temp_workspace_regex ]] || save=-s

				[[ $mode != floating ]] && $windowctl -S
				$windowctl -D $new_workspace_index -i $window_id $save -g
				sleep 0.08
			fi

			if [[ $current_workspace_name =~ $temp_workspace_regex ]]; then
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
							print ("'$style'" =~ "icons|dmenu") ? "tmp" tn : "'$current_workspace_name'" }')
					wmctrl -n $((workspace_count - 1))
					~/.orw/scripts/notify.sh -p "Temporary workspace <b>$workspace_to_remove</b> has been removed."
				fi
			fi
		fi
	fi

	wmctrl -s $new_workspace_index
fi
