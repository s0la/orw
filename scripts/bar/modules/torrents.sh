#!/bin/bash

get_torrents_stats() {
	transmission-remote -l |
		awk '
			function make_progressbar(percent) {
				if (percent) {
					pb = sprintf("%*s", percent, " ")
					gsub(" ", pbi "%{O0}", pb)
					return fg pb
				}
			}

			NR == 1 {
				ns = index($0, "Name")
				ss = index($0, "Status")

				pbs = "'"${torrents_progressbar_step:-10}"'"
				pbi = "'"$torrents_progressbar_icon"'"
				spbs = int(100 / pbs)
			}

			{
				if ($2 ~ "^[0-9]{1,2}\\.[0-9]{1,2}%") {
					tp += $2
					tc++

					i = i "," $1
					ts = substr($0, ss)
					ns = (ts ~ "^Stopped") ? "s" : "S"
				}
			}

			END {
				ap = tp / tc
				pd = sprintf("%.0f", ap / spbs)
				pr = 100 / spbs - pd

				pb = "%{T3}${tbefg:-${pbefg:-${pfg}}}" make_progressbar(pd) 
				pb = pb "${tbfg:-${sfg}}" make_progressbar(pr) "%{T-}"

				if (tc) print substr(i, 2), ns, tc, ap "%", pb
			}' 2> /dev/null
}

#get_torrents_stats
#exit

set_torrents_actions() {
	local action1="transmission-remote -t $ids -$status &> /dev/null"
	local action3="~/.orw/scripts/show_torrents_info_old.sh"
	actions_start="%{A:$action1:}%{A3:$action3:}"
	actions_end="%{A}%{A}"
}

get_torrents() {
	unset torrents
	label=TOR icon="$(get_icon "torrents")"
	read ids status count percentage torrents_progressbar <<< $(get_torrents_stats)

	set_torrents_actions

	((count)) && eval torrents=\""$torrents_components"\"

	print_module torrents
}

check_torrents() {
	local pid actions_{start,end} quit

	while true; do
		pid=$(pidof transmission-daemon 2> /dev/null)

		if ((pid)); then
			unset quit
			get_torrents
		elif [[ ! $quit ]]; then
			quit=true
			unset torrents
			print_module torrents
		fi

		#((count)) && sleep_interval=10 || sleep_interval=60
		if ((!count)); then
			sleep_interval=60
			((pid)) && kill $pid
		else
			sleep_interval=10
		fi

		#~/.orw/scripts/notify.sh "$pid: $count, $sleep_interval"

		sleep $sleep_interval
	done
}

make_torrents_content() {
	for arg in ${args//,/ }; do
		value=${arg#*:}
		arg=${arg%%:*}

		case $arg in 
			c) torrents_components+='$count';;
			p) torrents_components+='$percentage';;
			o) torrents_components+="%{O$value}";;
			P)
				torrents_progressbar_step=${value//[^0-9]}
				[[ ${value/$torrents_progressbar_step} == *d* ]] &&
					torrents_progressbar_icon="■" || torrents_progressbar_icon="━"
				torrents_components+='$torrents_progressbar'
				;;
		esac
	done
}
