#!/bin/bash

get_date() {
	read seconds date <<< "$(date +"%S $date_format")"

	[[ "$date_format" == *\|* ]] &&
		#date="${dsfg}${date/\|/┃${dpfg}}"
		date="${dsfg}${date/\|/|${dpfg}}"
		#date="${dpfg}${date/\|/${dsfg}┃}"

	#if [[ ! ${joiner_modules[$opt]} ]]; then
	#	local tpbg='$tpbg' tpfg='$tpfg'
	#	[[ "$date_format" == *\|* ]] &&
	#		date_format="${tsfg}${date_format%\|*}|${tpfg}${date_format#*\|}"
	#	~/.orw/scripts/notify.sh -t 11 "$date_format"
	#else
	#	local tpbg='${cjsbg:-$tsbg}' tpfg='${cjsfg:-$tsfg}'
	#	local time_frame_start=$module_frame_start time_frame_end=$module_frame_end
	#fi
}

check_date() {
	local actions_{start,end}
	set_date_actions

	while true; do
		get_date
		print_module date
		sleep $((60 - ${seconds#0}))
	done
}

set_date_actions() {
	actions_start='%{A:~/.orw/scripts/show_calendar.sh:}' actions_end='%{A}'
}

make_date_content() {
	[[ ! $args ]] &&
		date_format='%I:%M' ||
		date_format="$(sed 's/[[:alpha:]]/%&/g' <<< "${args//_/ }")"

	[[ ${joiner_modules[$opt]} ]] &&
		local dpbg='' dpfg='$dpfg' ||
		local dpbg='${cjsbg:-$dsbg}' dpfg='${cjsfg:-$dsfg}' \
		date_frame_start=$module_frame_start date_frame_end=$module_frame_end

	date_content="$dpbg\$date_padding\${cjpfg:-\$dpfg}\$date\$date_padding"
	date_content="$date_frame_start$date_content$date_frame_end"
}
