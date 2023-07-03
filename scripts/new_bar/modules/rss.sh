#!/bin/bash

get_rss() {
	label='RSS'
	icon="$(get_icon "rss_icon")"
	#~/.orw/scripts/notify.sh "$(newsboat -x reload print-unread 2> /dev/null | awk '{ print $1 }')"
	rss=$(newsboat -x reload print-unread 2> /dev/null |
		awk '$2 == "unread" { if ($1) print $1 }')
	#~/.orw/scripts/notify.sh "RSS"
}

set_rss_actions() {
	actions_start='%{A:termite -t newsboat -e newsboat &> /dev/null &:}'
	actions_end='%{A}'
}

check_rss() {
	local content label icon old_rss actions_{start,end}

	set_rss_actions

	#rss_icon="$(get_icon "rss_icon")"

	while true; do
		pid=$(pidof newsboat)
		#((pid)) || get_rss
		if ((!pid)); then
			[[ $rss == [0-9]* ]] && old_rss=$rss

			#icon=$waiting_icon rss=0
			#print_module rss
			#rss=$loading_icon
			#print_module rss
			get_rss
		fi

		((old_rss && old_rss < rss)) &&
			~/.orw/scripts/notify.sh -r 501 -s osd -i ${icon//[[:ascii:]]} \
			"New feeds: $rss" &> /dev/null

		#~/.orw/scripts/notify.sh "RSS"
		print_module rss
		sleep 60
	done
}
