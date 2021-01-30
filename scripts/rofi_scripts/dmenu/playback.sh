#!/bin/bash

theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)

[[ $theme =~ dmenu|icons ]] && ~/.orw/scripts/set_rofi_geometry.sh playback
[[ $theme != icons ]] &&
	toggle=play stop=stop next=next prev=prev rand=random up=volume_up down=volume_down controls=controls pl=playlist sep=' '

icon_prev=
icon_prev=
icon_toggle=$(mpc | awk -F '[][]' 'NR == 2 { s = $2 } END { print (s == "playing") ? "" : "" }')
icon_stop=
icon_next=
icon_next=
icon_rand=
icon_up=
icon_up=
icon_down=
icon_down=
icon_controls=
icon_pl=
icon_pl=
icon_pl=

#icon_prev=
#icon_prev=
#icon_toggle=$(mpc | awk -F '[][]' 'NR == 2 { s = $2 } END { print (s == "playing") ? "" : "" }')
#icon_stop=
#icon_next=
#icon_next=
#icon_rand=
#icon_up=
#icon_down=
#icon_controls=
#icon_pl=
#icon_pl=
#icon_pl= 

handle_volume() {
	volume="$action"
	[[ ${volume##* } =~ [0-9] ]] && local multiplier="${volume##* }" volume="${volume% *}"
	[[ ${volume%% *} == $icon_up ]] && direction=+ || direction=-

	mpc -q volume $direction$((${multiplier:-1} * 5))
	~/.orw/scripts/system_notification.sh mpd_volume &
}

while
	active=$(mpc | awk 'END { if($6 == "on") print "-a 4" }')

	read row action <<< $(cat <<- EOF | rofi -dmenu -format 'i s' -selected-row ${row:-1} $active -theme main
		$icon_prev$sep$prev
		$icon_toggle$sep$toggle
		$icon_stop$sep$stop
		$icon_next$sep$next
		$icon_rand$sep$rand
		$icon_up$sep$up
		$icon_down$sep$down
		$icon_pl$sep$pl
	EOF
	)

	if [[ $action ]]; then
		case "$action" in
			$icon_toggle*) mpc -q toggle;;
			$icon_up*|$icon_down*) handle_volume;;

				#while
				#	list_actions $row
				#	[[ $action =~ $icon_up|$icon_down ]]
				#do
				#	handle_volume
				#done;;
			$icon_pl*)
				#indicator=''
				#indicator='●'

				#song_index=$(mpc current -f %position%)
				#current_song="$(mpc current -f "%artist% - %title%")"
				#[[ $current_song ]] && empty='  '
				#song=$(mpc playlist | awk '{
				#	p = ($0 == "'"$current_song"'") ? "'$indicator' " : "'"$empty"'"
				#	print p $0 }' | rofi -dmenu -selected-row $((song_index - 1)) -theme large_list)

				#[[ $song ]] && ~/.orw/scripts/play_song_from_playlist.sh "${song:${#empty}}";;
				#~/.orw/scripts/rofi_scripts/dmenu/mpd_playlist.sh;;
				
				~/.orw/scripts/rofi_scripts/mpd_songs_group.sh play;;
			#$icon_pl*)
			#	indicator='●'
			#	mpc playlist | awk '{ p = ($0 == "'"$current_song"'") ? "'$indicator' " : "'"$empty"'"; print p $0 }';;
			#*-*)
			#	song="$@"
			#	~/.orw/scripts/play_song_from_playlist.sh "${song:${#empty}}";;
			$icon_stop*) mpc -q stop;;
			$icon_next*) mpc -q next;;
			$icon_prev*) mpc -q prev;;
			$icon_rand*) mpc -q random;;
			*)
				mpc -q ${action#* }
		esac
	fi

	[[ $action =~ $icon_prev|$icon_next|$icon_up|$icon_down|$icon_rand ]]
do
	continue
done
