#!/bin/bash

get_all_window_ids() {
	previous_windows=$current_windows
	read current_window_properties current_windows windows_per_desktop <<< \
		$(wmctrl -lG | awk '\
			$1 == "'$current_window_id'" { p = $3 - '$x_border' "_" $4 - '$y_border' "_" $5 "_" $6 }
			$NF !~ "^(DROPDOWN|input)" {
				wpda[$2]++
				awi = awi "|" $1
			} END {
				for(di in wpda) wpd = wpd " [" di "]=" wpda[di]
				print p, substr(awi,2), wpd
			}')

	eval desktops=( "$windows_per_desktop" )
}

running_pid=$(pidof -o %PPID -x $0)
[[ $running_pid ]] &&
	echo "Script is already running ($running_pid), exiting" && exit

current_desktop=$(xdotool get_desktop)
current_window_id=$(printf '0x%.8x' $(xdotool getactivewindow))

read {x,y}_border <<< \
	$(awk '/^[xy]_border/ { if(/^x/) x = $NF; else { print x, ($NF - x / 2) * 2 } }' ~/.config/orw/config)

new_window_size=150
#read {x,y}_border <<< $(awk '/^[xy]_border/ { print $NF }' ~/.config/orw/config | xargs)
#y_border=$(((y_border - x_border / 2) * 2))

declare -A desktops
get_all_window_ids

blacklist='input,get_borders,rec_file_name_input,DROPDOWN,image_preview,cover_art_widget'

xprop -spy -root _NET_ACTIVE_WINDOW | \
	awk '/window id/ {
			id = sprintf("0x%0*d%s", 10 - length($NF), 0, substr($NF, 3))
			if(id !~ "^0x0+$") print id
			fflush()
		}' | while read -r new_window_id; do
				#~/.orw/scripts/notify.sh "NEW $new_window_id $current_window_id $all_window_ids"

				if [[ $new_window_id != $current_window_id ]]; then
					previous_window_title=$current_window_title
					#current_window_title=$(xdotool getactivewindow getwindowtitle)
					read current_window_type current_window_title <<< \
						$(xprop -id $new_window_id _OB_APP_TYPE _OB_APP_TITLE | \
						awk -F '"' '{ print $(NF - 1) }' | xargs)

					#~/.orw/scripts/notify.sh "nw: $new_window_id $current_window_title"

					if [[ ! $current_window_title =~ ^(${blacklist//,/|})$ ]]; then
						previous_window_properties="$current_window_properties"
						previous_window_id=$current_window_id
						current_window_id=$new_window_id

						#sleep 0.1

						get_all_window_ids

						#echo $new_window_id "^($current_windows)$"
						#echo pw $previous_windows
						#echo cw $current_windows

						#if [[ ! $previous_window_id =~ ^($current_windows)$ ]]; then
						if [[ ${#current_windows} -lt ${#previous_windows} ]]; then
							#echo pid $previous_window_id
							#echo pwp $previous_window_properties
							#echo $previous_window_id $previous_window_properties
							#~/.orw/scripts/notify.sh -t 11 "closing $previous_window_id $previous_window_properties"
							~/.orw/scripts/windowctl.sh -i $previous_window_id -P "${previous_window_properties//_/ }" -A c
							#~/.orw/scripts/windowctl.sh -R

							get_all_window_ids
							#echo ~/.orw/scripts/windowctl.sh -i $previous_window_id -P "${previous_window_properties//_/ }" -A c
						fi

						#if [[ ! $new_window_id =~ ^($current_windows)$ ]]; then
						if [[ ! $new_window_id =~ ^($previous_windows)$ ]]; then
						#if [[ ${#current_windows} -gt ${#previous_windows} ]]; then
							#mode=$(awk '/^mode/ { print $NF }' ~/.config/orw/config)

							#if [[ $mode != floating ]]; then
								if [[ $current_window_type != dialog ]]; then
									current_desktop=$(xdotool get_desktop)
									((${desktops[$current_desktop]} == 1)) && id=none || id=$previous_window_id
									read x y w h d <<< $(~/.orw/scripts/windowctl.sh -i ${id:-none} -A)
									echo "$new_window_id: $d" >> ~/.config/orw/window_alignment

									current_window_properties="$x $y $w $h"

									wmctrl -ir $new_window_id -e 0,$x,$y,$w,$h
								fi

								wmctrl -ir $new_window_id -b add,above

								~/.orw/scripts/set_window_opacity.sh $new_window_id 100

								~/.orw/scripts/set_geometry.sh -c '\\\*' \
									-x $(((x + w - new_window_size) / 2)) -y $(((y + h - new_window_size) / 2))
							#fi
						fi
					#else
					elif [[ $current_window_title =~ ^(input|rec_file_name_input|DROPDOWN)$ ]]; then
						#[[ $current_window_title == input ]] && opacity=0 || opacity=90

						case $current_window_title in
							input) opacity=0;;
							DROPDOWN) opacity=90;;
							*)
								opacity=100
								wmctrl -ir $new_window_id -b add,above;;
						esac

						#case $current_window_title in
						#	*input) opacity=0;;
						#	DROPDOWN) opacity=90;;
						#	*)
						#		opacity=100
						#		#wmctrl -ir $new_window_id -b add,above
						#esac

						#~/.orw/scripts/notify.sh "$opacity"
						~/.orw/scripts/set_window_opacity.sh $new_window_id $opacity
					fi
				fi

				#get_all_window_ids

				#~/.orw/scripts/notify.sh "cdwc: ${desktops[$curent_desktop]}, $current_desktop_window_count"
				#[[ $current_desktop_window_count && ! ${desktops[$curent_desktop]} ]] && ~/.orw/scripts/notify.sh "KILL"
				#[[ $current_desktop_window_count && ! ${desktops[$curent_desktop]} ]] && unset current_window_id
				#echo desk $curent_desktop ${desktops[$current_desktop]} ${desktops[*]}
				#((${desktops[$current_desktop]})) && echo Y || echo N
				((${desktops[$current_desktop]})) || unset current_window_id
				#[[ ${desktops[$current_desktop]} -gt 0 ]] || unset current_window_id
			done
