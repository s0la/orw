#!/bin/bash

get_directory() {
	#directory="$(sed -n 's/^directory //p' ~/.config/orw/config)"
	read recursion directory <<< $(awk '\
		/^directory|recursion/ { sub("[^ ]* ", ""); print }' ~/.config/orw/config | xargs -d '\n')
}

if [[ -z $@ ]]; then
	echo -e 'next\nprev\nrand\nindex\nrestore\nselect\ninterval\nautochange'
else
	wallctl=~/.orw/scripts/wallctl.sh

	if [[ $@ =~ select ]]; then
		get_directory
		#eval ls "$directory"
		eval find $directory/ -maxdepth $recursion -type f -iregex "'.*\(jpe?g\|png\)'" |\
			awk '{ print gensub(".*/(.*(/.*){" '$recursion' - 1 "})$", "\\1", 1) }'
	else
		killall rofi

		case "$@" in
			*interval*) $wallctl -I ${@#* };;
			*index*) $wallctl -i ${@##* };;
			*restore*) $wallctl -r;;
			*auto*) $wallctl -A;;
			*.*)
				get_directory
				[[ $directory =~ \{.*\} ]] && directory="${directory%/*}"
				#$wallctl -s "${directory:1: -1}/$@";;
				eval $wallctl -s "$directory/$@";;
				#~/.orw/scripts/notify.sh "$directory/$@"
				#$wallctl -s "$directory/$@";;
			*) $wallctl -o $@;;
		esac
	fi
fi
