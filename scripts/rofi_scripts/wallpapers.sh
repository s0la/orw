#!/bin/bash

config=~/.config/orw/config

get_directory() {
	read depth directory <<< $(awk '\
		/^directory|depth/ { sub("[^ ]* ", ""); print }' $config | xargs -d '\n')
}

if [[ -z $@ ]]; then
	echo -e 'next\nprev\nrand\nindex\nselect\nrestore\nview_all\ninterval\nautochange'
else
	wallctl=~/.orw/scripts/wallctl.sh

	if [[ $@ =~ select ]]; then
		indicator='●'
		indicator=''

		get_directory

		current_desktop=$(xdotool get_desktop)
		current_wallpaper=$(grep "^desktop_$current_desktop" $config | cut -d '"' -f 2)

		eval find $directory/ -maxdepth $depth -type f -iregex "'.*\(jpe?g\|png\)'" |\
			awk '{ i = (/'"${current_wallpaper##*/}"'$/) ? "'$indicator'" : " "
				print i, gensub(".*/(.*(/.*){" '$depth' - 1 "})$", "\\1", 1) }'
	else
		killall rofi

		case "$@" in
			*interval*) $wallctl -I ${@#* };;
			*index*) $wallctl -i ${@##* };;
			*restore*) $wallctl -r;;
			*auto*) $wallctl -A;;
			*view*) $wallctl -v;;
			*.*)
				wall="$@"
				get_directory
				[[ $directory =~ \{.*\} ]] && directory="${directory%/*}"
				eval $wallctl -s "$directory/${wall:2}";;
			*) $wallctl -o $@;;
		esac
	fi
fi
