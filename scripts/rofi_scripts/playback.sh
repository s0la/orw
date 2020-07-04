#!/bin/bash

theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)

current_song="$(mpc current -f "%artist% - %title%")"
[[ $current_song ]] && empty='  '

[[ $theme != icons ]] &&
	play=play stop=stop next=next prev=prev rand=random up=volume_up down=volume_down controls=controls pl=playlist sep=' '

if [[ -z $@ ]]; then
	cat <<- EOF
		$sep$play
		$sep$stop
		$sep$prev
		$sep$next
		$sep$rand
		$sep$up
		$sep$down
		$sep$controls
		$sep$pl
	EOF
else
	killall rofi

	case "$@" in
		*) mpc -q toggle;;
		*|*)
			volume="$@"
			[[ ${volume##* } =~ [0-9] ]] && multiplier="${volume##* }" volume="${volume% *}"
			[[ ${volume%% *} ==   ]] && direction=+ || direction=-

			mpc -q volume $direction$((${multiplier:-1} * 5))
			~/.orw/scripts/system_notification.sh mpd_volume;;
		*)
			indicator=''
			mpc playlist | awk '{ p = ($0 == "'"$current_song"'") ? "'$indicator' " : "'"$empty"'"; print p $0 }';;
		*)
			mpd=~/.orw/scripts/bar/mpd.sh
			mode=$(awk -F '=' '/^current_mode/ { if ($2 == "controls") print "song_info"; else print "controls"}' $mpd)
			sed -i "/^current_mode/ s/=.*/=$mode/" $mpd;;
		*-*)
			song="$@"
			~/.orw/scripts/play_song_from_playlist.sh "${song:${#empty}}";;
		*) mpc -q stop;;
		*) mpc -q next;;
		*) mpc -q prev;;
		*) mpc -q random;;
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
