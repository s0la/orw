#!/bin/bash

theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)

current_song="$(mpc current -f "%artist% - %title%")"
[[ $current_song ]] && empty='  '

[[ $theme != icons ]] &&
	toggle=toggle stop=stop next=next prev=prev rand=random up=volume_up down=volume_down controls=controls pl=playlist sep=' '

icon_prev=
icon_prev=
icon_toggle=$(mpc | awk -F '[][]' 'NR == 2 { s = $2 } END { print (s == "playing") ? "" : "" }')
icon_stop=
icon_next=
icon_next=
icon_rand=
icon_up=
icon_down=
icon_controls=
icon_pl=

if [[ -z $@ ]]; then
	cat <<- EOF
		$icon_prev$sep$prev
		$icon_toggle$sep$toggle
		$icon_stop$sep$stop
		$icon_next$sep$next
		$icon_rand$sep$rand
		$icon_up$sep$up
		$icon_down$sep$down
		$icon_controls$sep$controls
		$icon_pl$sep$pl
	EOF
else
	killall rofi

	case "$@" in
		$icon_toggle*) mpc -q toggle;;
		$icon_up*|$icon_down*)
			volume="$@"
			[[ ${volume##* } =~ [0-9] ]] && multiplier="${volume##* }" volume="${volume% *}"
			[[ ${volume%% *} == $icon_up ]] && direction=+ || direction=-

			mpc -q volume $direction$((${multiplier:-1} * 5))
			~/.orw/scripts/system_notification.sh mpd_volume;;
		$icon_pl*)
			indicator=''
			mpc playlist | awk '{ p = ($0 == "'"$current_song"'") ? "'$indicator' " : "'"$empty"'"; print p $0 }';;
		$icon_controls*)
			mpd=~/.orw/scripts/bar/mpd.sh
			mode=$(awk -F '=' '/^current_mode/ { if ($2 == "controls") print "song_info"; else print "controls"}' $mpd)
			sed -i "/^current_mode/ s/=.*/=$mode/" $mpd;;
		*-*)
			song="$@"
			~/.orw/scripts/play_song_from_playlist.sh "${song:${#empty}}";;
		$icon_stop*) mpc -q stop;;
		$icon_next*) mpc -q next;;
		$icon_prev*) mpc -q prev;;
		$icon_rand*) mpc -q random;;
		*)
			mpc -q ${@#* }

			#if [[ ${@##* } == stop ]]; then
			#	bar_name=$(ps aux | awk -F '[- ]' \
			#		'!/awk/ && /generate_bar.* -m/ { for(f = 9; f <= NF; f++) if($f == "n") { print $(f + 1); exit } }')

			#	[[ $bar_name ]] && cat <<- EOF > ~/.config/orw/bar/fifos/$bar_name.fifo
			#		PROGRESSBAR
			#		SONG_INFO not playing
			#		MPD_VOLUME
			#	EOF
			#fi
	esac
fi
