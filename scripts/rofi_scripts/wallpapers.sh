#!/bin/bash

get_directory() {
	directory="$(sed -n 's/^directory //p' ~/.config/orw/config)"
}

if [[ -z $@ ]]; then
	echo -e 'next\nprev\nrand\nindex\nrestore\nselect\ninterval\nautochange'
else
	wallctl=~/.orw/scripts/wallctl.sh

	if [[ $@ =~ select ]]; then
		get_directory
		ls "$directory"
	else
		killall rofi

		case "$@" in
			*interval*) $wallctl -I ${@#* };;
			*index*) $wallctl -i ${@##* };;
			*restore*) $wallctl -r;;
			*auto*) $wallctl -A;;
			*.*)
				get_directory
				$wallctl -s "$directory/$@";;
			*) $wallctl -o $@;;
		esac
	fi
fi
