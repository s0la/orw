#!/bin/bash

indicator='●'
indicator=''

current_song="$(mpc current -f "%artist% - %title%")"
[[ $current_song ]] && empty='____'

while read -r song; do
	songs+=( "${song//&/&amp;}" )
	#songs+=( "${song// /_}:\"$song\"" )
	#songs+=( "${song//\&/\\&}:\"$song\"" )
done <<< "$( mpc playlist |\
	awk '{ p = ($0 == "'"$current_song"'") ? "'$indicator'" : "'"$empty"'"
	print p "__" gensub(" ", "_", "g") ":\"" $0 "\"" }')"

~/.config/openbox/pipe_menu/generate_menu.sh -c '~/.orw/scripts/play_song_from_playlist.sh' -i "${songs[@]}"
