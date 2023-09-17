#!/bin/bash

while
	#prompt=$(mpc current -f '%title%\n%artist%\n%album%' |
	#	awk '{ print (length($0) > 20) ? substr($0, 0, 20) ".." : $0 }')
	read index album <<< \
		$(mpc current -f '%position% %album%' | sed 's/[()]//g')
	cover="$HOME/Music/covers/${album// /_}.jpg"

	if [[ ! -f $cover ]]; then
		root=$(sed -n "/music_directory/ s/[^\"]*\"\(.*\)\/\?\".*/\1/p" ~/.config/mpd/mpd.conf)
		file=$(mpc current -f %file%)
		full_path="$root/$file"
		eval ffmpeg -loglevel quiet -i \"$full_path\" -vf scale=300:300 \"$cover\"
	fi

	[[ -f $cover ]] && ln -sf $cover /tmp/rofi_cover_art.png

	if ((index)); then
		((index--))
		active="-a $index"
	fi

	read index <<< \
		$(mpc playlist |
		rofi -dmenu -format d -p '' -i $active -selected-row ${index:-0} -theme art)
		#rofi -dmenu -format d -i $active -selected-row ${index:-0} -theme art)
		#rofi -dmenu -format d -p "$prompt" $active -selected-row ${index:-0} -theme art)

	[[ $index ]]
do
	mpc -q play $index
done
