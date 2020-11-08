#!/bin/bash

indicator=''
indicator='●'

song_index=$(mpc current -f %position%)
current_song="$(mpc current -f "%artist% - %title%")"
[[ $current_song ]] && empty='  '

song=$(mpc playlist | awk '{
	p = ($0 == "'"$current_song"'") ? "'$indicator' " : "'"$empty"'"
	print p $0 }' | rofi -dmenu -i -selected-row $((song_index - 1)) -theme large_list)

[[ $song ]] && ~/.orw/scripts/play_song_from_playlist.sh "${song:${#empty}}"

#if [[ -z $@ ]]; then
#	mpc playlist | awk '{
#		p = ($0 == "'"$current_song"'") ? "'$indicator' " : "'"$empty"'"
#		print p $0 }'
#else
#	~/.orw/scripts/play_song_from_playlist.sh "${song:${#empty}}"
#fi
