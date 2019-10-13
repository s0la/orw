#!/bin/bash

if [[ -z $@ ]]; then
	mpc playlist
else
	~/.orw/scripts/play_song_from_playlist.sh "$@"
fi
