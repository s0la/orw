#!/bin/bash

set_current() {
	current="$1"
	current_replacement=$(sed 's/[/&]/\\&/g' <<< "$1")
	sed -i "s/\(^current[^\"]*\"\)[^\"]*/\1$current_replacement/" $0
}

back() {
	[[ $current =~ / ]] && current="${current%/*}" || current=''
	set_current "$current"
}

notify_on_finish() {
	while kill -0 $pid 2> /dev/null; do
		sleep 1
	done && ~/.orw/scripts/notify.sh "Music library updated."
}

current=""

if [[ -z $@ ]]; then
	set_current ''
else
	case "$@" in
		back) back;;
		update)
			coproc (mpc -q update &)
			pid=$((COPROC_PID + 1))
			coproc (notify_on_finish &);;
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

[[ $current ]] && echo -e 'back'
echo -e 'update\nadd_all\n━━━━━━━'

mpc ls "$current" | awk -F '/' '! /m3u$/ { print $NF }'
