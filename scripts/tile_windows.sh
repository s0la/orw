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
current_window_id=$(printf '0x%.8x' $(xdotool getwindowfocus))
#current_window_id=$(printf '0x%.8x' $(xdotool getactivewindow))

read {x,y}_border <<< \
	$(awk '/^[xy]_border/ { if(/^x/) x = $NF; else { print x, ($NF - x / 2) * 2 } }' ~/.config/orw/config)

new_window_size=60
padding=$(awk '/padding/ { print $NF * 2; exit }' ~/.config/gtk-3.0/gtk.css)
((new_window_size += padding))
#read {x,y}_border <<< $(awk '/^[xy]_border/ { print $NF }' ~/.config/orw/config | xargs)
#y_border=$(((y_border - x_border / 2) * 2))

declare -A desktops
get_all_window_ids

#blacklist='input,get_borders,rec_file_name_input,DROPDOWN,image_preview,cover_art_widget'
blacklist='.*input,get_borders,DROPDOWN,image_preview,cover_art_widget'

#xprop -spy -root _NET_ACTIVE_WINDOW _NET_SHOWING_DESKTOP | \
#	awk '/window id/ {
#			id = sprintf("0x%0*d%s", 10 - length($NF), 0, substr($NF, 3))
#			if(id !~ "^0x0+$") print id
#			fflush()
#		}' | while read -r new_window_id; do
#				echo c $current_window_id n $new_window_id
#
#				if [[ $new_window_id != $current_window_id ]]; then
#					previous_window_id=$current_window_id
#					current_window_id=$new_window_id
#					killall xev &> /dev/null
#				fi
#
#				xev -id $current_window_id -1 -event structure | \
#					while read change; do
#						echo $current_window_id changed
#					done &
#			done
#exit

#trap "~/.orw/scripts/notify.sh 'resized'" SIGWINCH
#trap "echo killed && exit" SIGTERM

shm=/dev/shm/latest_window_properties

set_new_position() {
	#all="$@"
	#~/.orw/scripts/notify.sh "a: $all"
	awk -i inplace '/class="\*"/ { t = 1 } t && /<\/app/ { t = 0 }
		t && /<[xy]>/ { sub(">.*<", ">" ((/x/) ? "'$1'" : "'$2'") "<") }
		t && /<(width|height)>/ { sub("[0-9]+", (/width/) ? '$3' : '$4') }
		{ print }' ~/.config/openbox/rc.xml
	openbox --reconfigure
}

xprop -spy -root _NET_ACTIVE_WINDOW | \
	awk '/window id/ {
			id = sprintf("0x%0*d%s", 10 - length($NF), 0, substr($NF, 3))
			if(id !~ "^0x0+$") print id
			fflush()
		}' | while read -r new_window_id; do
				#~/.orw/scripts/notify.sh "NEW $new_window_id $current_window_id $all_window_ids"

				if [[ $new_window_id != $current_window_id ]]; then
					#previous_window_properties="$current_window_properties"
					previous_window_id=$current_window_id
					current_window_id=$new_window_id

					#~/.orw/scripts/notify.sh "n: $new_window_id, c: $current_window_id"
					#killall xev &> /dev/null
					#if ((size_listening_pid)); then
					#	kill $size_listening_pid
					#	read latest_id latest_window_properties < $shm
					#	[[ $latest_window_properties ]] && current_window_properties=$latest_window_properties && echo "lwp: $latest_window_properties"
					#	echo killing_pid $size_listening_pid
					#	#~/.orw/scripts/notify.sh "lwp: $latest_window_properties"
					#	#~/.orw/scripts/notify.sh "lwp: $(cat $shm)"
					#	#current_window_properties="$(cat $shm)"
					#	unset size_listening_pid latest_window_properties
					#	echo '' > $shm
					#fi

					#echo latest properties: $current_window_properties

					previous_window_title=$current_window_title
					#current_window_title=$(xdotool getactivewindow getwindowtitle)
					read current_window_type current_window_title <<< \
						$(xprop -id $new_window_id _OB_APP_TYPE _OB_APP_TITLE | \
						awk -F '"' '{ print $(NF - 1) }' | xargs)

					#~/.orw/scripts/notify.sh "nw: $new_window_id $current_window_title"

					previous_desktop=$current_desktop
					current_desktop=$(xdotool get_desktop)
					#is_web_workspace=$(wmctrl -d | awk '$2 == "*" { print $1 == 0 }')
					is_dev_workspace=$(wmctrl -d | awk '$2 == "*" { print $1 == 1 }')
					#~/.orw/scripts/notify.sh "c: $current_desktop, p: $previous_desktop"

					if ((is_dev_workspace)); then
						#~/.orw/scripts/notify.sh "c: $current_desktop, p: $previous_desktop"
						((current_desktop != previous_desktop)) &&
							set_new_position ${new_x:-center} ${new_y:-center} 150 150

						if [[ ! $current_window_title =~ ^(${blacklist//,/|})$ ]]; then
							#if ((size_listening_pid)); then
								#kill $size_listening_pid

							xev_pid=$(pidof xev 2> /dev/null)

							if [[ $xev_pid ]]; then
								kill "$xev_pid"

								if [[ -f $shm ]]; then
									read latest_window_properties < $shm
									[[ $latest_window_properties ]] && current_window_properties=$latest_window_properties
								fi

								unset size_listening_pid latest_window_properties
								echo '' > $shm
							fi

							#~/.orw/scripts/notify.sh -t 10 "cwp: $current_window_properties"

							previous_window_properties="$current_window_properties"
							#previous_window_id=$current_window_id
							#current_window_id=$new_window_id

							#~/.orw/scripts/notify.sh -t 10 "pwp: $previous_window_properties"

							#sleep 0.1

							#~/.orw/scripts/notify.sh "pwp pre: $previous_window_properties"
							#~/.orw/scripts/notify.sh "lwp pre: $current_window_properties"
							get_all_window_ids
							#~/.orw/scripts/notify.sh "lwp post: $current_window_properties"
							#~/.orw/scripts/notify.sh -t 10 "npwp: $previous_window_properties"

							#echo $new_window_id "^($current_windows)$"
							#echo pw $previous_windows
							#echo cw $current_windows

							#if [[ ! $previous_window_id =~ ^($current_windows)$ ]]; then
							if [[ ${#current_windows} -lt ${#previous_windows} ]]; then
								#echo pid $previous_window_id
								#echo pwp $previous_window_properties
								#echo $previous_window_id $previous_window_properties
								#~/.orw/scripts/notify.sh -t 11 "closing $previous_window_id $previous_window_properties"
								#~/.orw/scripts/notify.sh -t 10 "closing: $previous_window_properties"
								#~/.orw/scripts/notify.sh "closing: $previous_window_properties"
								~/Desktop/win_test.sh -i $previous_window_id -P "${previous_window_properties//_/ }" -A c
								#~/.orw/scripts/windowctl.sh -i $previous_window_id -P "${previous_window_properties//_/ }" -A c
								#~/.orw/scripts/windowctl.sh -R

								get_all_window_ids
								#((desktops[$current_desktop]--))
								#echo ~/.orw/scripts/windowctl.sh -i $previous_window_id -P "${previous_window_properties//_/ }" -A c
							fi

							#if [[ ! $new_window_id =~ ^($current_windows)$ ]]; then
							#~/.orw/scripts/notify.sh "desktop: $current_desktop"
							if [[ ! $new_window_id =~ ^($previous_windows)$ ]]; then
							#if [[ ${#current_windows} -gt ${#previous_windows} ]]; then
								#mode=$(awk '/^mode/ { print $NF }' ~/.config/orw/config)

								#if [[ $mode != floating ]]; then
									if [[ $current_window_type != dialog ]]; then
										#current_desktop=$(xdotool get_desktop)
										((${desktops[$current_desktop]} == 1)) && id=none || id=$previous_window_id
										read x y w h d <<< $(~/Desktop/win_test.sh -i ${id:-none} -A)
										#read x y w h d <<< $(~/.orw/scripts/windowctl.sh -i ${id:-none} -A)
										#~/.orw/scripts/windowctl.sh -i ${id:-none} -A
										echo "$new_window_id: $d" >> ~/.config/orw/windows_alignment

										current_window_properties="$x $y $w $h"

										wmctrl -ir $new_window_id -e 0,$x,$y,$w,$h
									fi

									wmctrl -ir $new_window_id -b add,above

									~/.orw/scripts/set_window_opacity.sh $new_window_id 100

									#~/.orw/scripts/set_geometry.sh -c '\\\*' \
									#	-x $(((x + w - new_window_size) / 2)) -y $(((y + h - new_window_size) / 2))

									new_x=$(((x + w - new_window_size) / 2))
									new_y=$(((y + h - new_window_size) / 2))
									set_new_position ${new_x:-center} ${new_y:-center} 150 150
								#fi
							fi

							#~/.orw/scripts/notify.sh "listening"
							xev -id $new_window_id -1 -event structure | \
								while read change; do
									#echo $new_window_id changed $current_window_properties
									#read x y w h <<< $(~/.orw/scripts/windowctl.sh -p | cut -d ' ' -f 3-)
									#~/.orw/scripts/windowctl.sh -p | cut -d ' ' -f 3- > $shm
									#latest_window_properties=$(~/.orw/scripts/windowctl.sh -p | cut -d ' ' -f 3-)

									#latest_window_properties=$(wmctrl -lG | \
									#	awk '$1 == "0x01400003" { print $3, $4, $5 - '$x_border', $6 - '$y_border' }')
									#latest_window_properties=$(~/.orw/scripts/windowctl.sh -p | cut -d ' ' -f 3-)
									#echo "$latest_window_properties" > $shm

									#wmctrl -lG | awk '$1 == "'$new_window_id'" {
									#	print $3, $4, $5 - '$x_border', $6 - '$y_border' }' > $shm

									#latest_window_properties=$(wmctrl -lG | awk '$1 == "'$new_window_id'" {
									#	print $3 - '$x_border', $4 - '$y_border', $5, $6 }')
									#echo "$latest_window_properties" > $shm

									#latest_window_properties=$(~/.orw/scripts/windowctl.sh -i $new_window_id -p | cut -d ' ' -f 3-)
									#echo "$latest_window_properties" > $shm

									#cwid=$(printf '0x%.8x' $(xdotool getwindowfocus))

									latest_window_properties="$(wmctrl -lG | awk '$1 == "'$new_window_id'" {
										print $3 - '$x_border', $4 - '$y_border', $5, $6 }')"
									[[ $latest_window_properties ]] && echo "$latest_window_properties" > $shm
								done &

							#size_listening_pid=$!
							#echo latest_pid: $size_listening_pid

								#while read change; do
								#	echo $new_window_id changed $current_window_properties
								#	read x y w h <<< $(~/.orw/scripts/windowctl.sh -p | cut -d ' ' -f 3-)
								#	current_window_properties="$x $y $w $h"
								#done <<< $(xev -id $new_window_id -1 -event structure) &
								#size_listening_pid=$!

							#xev -id $new_window_id -1 -event structure | \
							#	while read change; do
							#		echo $new_window_id changed $current_window_properties
							#		read x y w h <<< $(~/.orw/scripts/windowctl.sh -p | cut -d ' ' -f 3-)
							#		current_window_properties="$x $y $w $h"
							#	done &

						#else
						fi
					else
						get_all_window_ids
						((${#current_windows} < ${#previous_windows})) && ((desktops[$current_desktop]--))
						((current_desktop != previous_desktop)) && set_new_position center center 0 0
						wmctrl -ir $new_window_id -b add,above
						~/.orw/scripts/set_window_opacity.sh $new_window_id 100
					fi
				fi
				#elif [[ $current_window_title =~ ^(input|rec_file_name_input|DROPDOWN)$ ]]; then

				if [[ $current_window_title =~ ^(.*input|DROPDOWN)$ ]]; then
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

				#get_all_window_ids

				#~/.orw/scripts/notify.sh "cdwc: ${desktops[$curent_desktop]}, $current_desktop_window_count"
				#[[ $current_desktop_window_count && ! ${desktops[$curent_desktop]} ]] && ~/.orw/scripts/notify.sh "KILL"
				#[[ $current_desktop_window_count && ! ${desktops[$curent_desktop]} ]] && unset current_window_id
				#echo desk $curent_desktop ${desktops[$current_desktop]} ${desktops[*]}
				#((${desktops[$current_desktop]})) && echo Y || echo N
				((${desktops[$current_desktop]})) || unset current_window_id
				#[[ ${desktops[$current_desktop]} -gt 0 ]] || unset current_window_id
			done
