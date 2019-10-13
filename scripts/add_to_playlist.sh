#!/bin/bash

music_dir=$(sed -n '/music/ s/.*"\(.*\)"/\1/p' ~/.mpd/mpd.conf)

for song in "$@"; do
	eval "mpc add '${song#${music_dir//\//\\\/}}'"
done
