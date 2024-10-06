#!/bin/bash

[[ $1 == h* ]] &&
	width='window' lines=8 orientation=horizontal ||
	width='art' lines=5 orientation=vertical

theme_str="prompt { margin: @${orientation}-prompt-margin; } "
theme_str+="mainbox { orientation: $orientation; } "
theme_str+="window { width: @${width}-width; } "
theme_str+="* { lines: $lines; }"

while
	prompt=$(mpc current -f '%title%\n%artist%\n%album%' |
		awk '{ print (length($0) > 20) ? substr($0, 0, 20) ".." : $0 }')
	read index album <<< \
		$(mpc current -f '%position% %album%' | sed 's/[()]//g')
	#cover="$HOME/Music/covers/${album// /_}.jpg"
	cover="$(~/.orw/scripts/get_cover_art.sh)"

	#if [[ ! -f $cover ]]; then
	#	root=$(sed -n "/music_directory/ s/[^\"]*\"\(.*\)\/\?\".*/\1/p" ~/.config/mpd/mpd.conf)
	#	file=$(mpc current -f %file%)
	#	full_path="$root/$file"
	#	eval ffmpeg -loglevel quiet -i \"$full_path\" -vf scale=300:300 \"$cover\"
	#fi

	[[ -f $cover ]] && ln -sf $cover /tmp/rofi_cover_art.png

	if ((index)); then
		((index--))
		active="-a $index"
	fi

	read index <<< \
		$(mpc playlist |
		rofi -dmenu -format d -p '' -i $active \
		-theme-str "$theme_str" -selected-row ${index:-0} -theme art)

	[[ $index ]]
do
	((${active//[^0-9]} == $index - 1)) &&
		mpc toggle && break || mpc -q play $index
done
