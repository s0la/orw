#!/bin/bash

artist=$(mpc current -f %artist%)
album=$(mpc current -f %album% | sed 's/[()]//g')
cover="$HOME/Music/covers/${album// /_}.jpg"

[[ ! -d ~/Music/covers/ ]] && mkdir ~/Music/covers

if [[ ! -f "${cover//[()]/}" ]]; then
	root=$(sed -n "/music_directory/ s/[^\"]*\"\(.*\)\/\?\".*/\1/p" ~/.config/mpd/mpd.conf)
	file=$(mpc current -f %file%)
	full_path="$root/$file"

	if ! eval ffmpeg -loglevel quiet -i \"$full_path\" -vf scale=300:300 \"$cover\"; then
		[[ ! $(grep "$album" ~/Music/covers/missing_cover_arts.txt) ]] &&
			echo "$artist - $album" >> ~/Music/covers/missing_cover_arts.txt
	fi
fi

echo "$cover"
