#!/bin/bash

get_time() {
	read seconds time <<< "$(date +"%S $time_format")"
}

check_time() {
	local actions_{start,end}
	set_time_actions

	while true; do
		get_time
		print_module time
		sleep $((60 - ${seconds#0}))
	done
}

set_time_actions() {
	actions_start='%{A:~/.orw/scripts/show_calendar.sh:}' actions_end='%{A}'
}

make_time_content() {
	[[ ! $args ]] &&
		time_format='%I:%M' ||
		time_format="$(sed 's/[[:alpha:]]/%&/g' <<< "${args//_/ }")"

	if [[ ${joiner_modules[$opt]} ]]; then
		local tpbg='$tpbg' tpfg='$tpfg'
		[[ "$time_format" == *|* ]] &&
			time_format="${tsfg}${time_format%|*}|${tpfg}${time_format#*|}"
	else
		local tpbg='${cjsbg:-$tsbg}' tpfg='${cjsfg:-$tsfg}'
		local time_frame_start=$module_frame_start time_frame_end=$module_frame_end
	fi

	time_content="\${cjpbg:-\$tpbg}\$time_padding\${cjpfg:-\$tpfg}\$time\$time_padding"
	time_content="$time_frame_start$time_content$time_frame_end"
}
