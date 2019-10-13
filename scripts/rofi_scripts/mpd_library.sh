#!/bin/bash

set_current() {
	current="$1"
	current_replacement=$(sed 's/[/&]/\\&/g' <<< "$1")
	sed -i "s/\(^current[^']*'\)[^']*/\1$current_replacement/" $0
}

back() {
	[[ $current =~ / ]] && current="${current%/*}" || current=''
	set_current "$current"
}

current=''

if [[ -z $@ ]]; then
	set_current ''
else
	case "$@" in
		back) back;;
		add_all)
			mpc add "$current"
			back;;
		*.mp3)
			[[ $current ]] && current+='/'
			mpc add "$current${@// /\ }";;
		*)
			file="${@// /\ }"
			[[ $current ]] && current+="/$file" || current="$file"
			set_current "$current";;
	esac
fi

[[ $current ]] && echo back
echo add_all

mpc ls "$current" | awk -F '/' '! /m3u$/ { print $NF }'
