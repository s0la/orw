#!/bin/bash

artist=$(mpc current -f %artist%)
album=$(mpc current -f %album% | sed 's/[()]//g')
cover="$HOME/Music/covers/${album// /_}.jpg"

[[ ! -d ~/Music/covers/ ]] && mkdir ~/Music/covers

if [[ ! -f "${cover//[()]/}" ]]; then
	file=$(mpc current -f %file%)
	root=$(sed -n "/music_directory/ s/[^\"]*\"\(.*\)\".*/\1/p" ~/.mpd/mpd.conf)

	[[ ${root: -1} == '/' ]] && root=${root%*/}

	if ! eval "ffmpeg -loglevel quiet -i \"$root/$file\" $cover"; then
		[[ ! $(grep "$album" ~/Music/missing_cover_arts.txt) ]] && echo "$artist - $album" >> ~/Music/missing_cover_arts.txt
	fi
fi

echo "$cover"
