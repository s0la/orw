#!/bin/bash

get_rss() {
	label='RSS'
	icon="$(get_icon "rss")"
	rss=$(newsboat -x reload print-unread 2> /dev/null |
		awk '$2 == "unread" { if ($1) print $1 }')
}

set_rss_actions() {
	actions_start='%{A:alacritty -t newsboat -e newsboat &> /dev/null &:}'
	actions_end='%{A}'
}

check_rss() {
	local content label icon old_rss actions_{start,end}

	set_rss_actions

	while true; do
		pid=$(pidof newsboat)
		if ((!pid)); then
			[[ $rss == [0-9]* ]] && old_rss=$rss

			get_rss
		fi

		((rss && old_rss < rss)) &&
			~/.orw/scripts/notify.sh -r 501 -s osd -i ${icon//[[:ascii:]]} \
			"New feeds: $rss" &> /dev/null

		print_module rss
		sleep 60
	done
}
