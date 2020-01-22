#!/bin/bash

indicator='●'
indicator=''

current_song="$(mpc current -f "%artist% - %title%")"
[[ $current_song ]] && empty='  '

if [[ -z $@ ]]; then
	#mpc playlist | awk '$0 == "'"$current_song"'" { $0 = "'$indicator' " $0 } { print }'
	mpc playlist | awk '{ p = ($0 == "'"$current_song"'") ? "'$indicator' " : "'"$empty"'"; print p $0 }'
else
	song="$@"
	~/.orw/scripts/play_song_from_playlist.sh "${song:${#empty}}"
	#~/.orw/scripts/play_song_from_playlist.sh "${@#$indicator }"
fi
