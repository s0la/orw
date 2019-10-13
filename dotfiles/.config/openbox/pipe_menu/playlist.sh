#!/bin/bash

while read -r song; do
	songs+=( "${song// /_}:\"$song\"" )
done <<< $(mpc playlist)

~/.config/openbox/pipe_menu/generate_menu.sh -c '~/.orw/scripts/play_song_from_playlist.sh' -i "${songs[@]}"
