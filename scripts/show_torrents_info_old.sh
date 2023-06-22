#!/bin/bash

icon=
icon=''
tn_span="<span foreground='\\\$fg'>"
pd_span="<span font='Roboto Mono 3' foreground='\\\$pbfg'>"
pr_span="<span foreground='\\\$sbg'>"
end_span='</span></span></span>'

#read level empty ft <<< $(transmission-remote -l | awk '\
torrent_info=$(transmission-remote -l | awk '
	function print_progress(percent) {
		#if(percent > 0) return gensub(/ /, "█", "g", sprintf("%*s", percent, " "))
		if(percent > 0) return gensub(/ /, "▀", "g", sprintf("%*s", percent, " "))
		#if(percent > 0) return gensub(/ /, "━", "g", sprintf("%*s", percent, " "))
		#if(percent > 0) return gensub(/ /, "▔", "g", sprintf("%*s", percent, " "))
	}

	NR == 1 {
		ns = index($0, "Name")
		ss = index($0, "Status")
		us = index($0, "Up"); ds = index($0, "Down")
	} {
		ts = substr($0, ss, ns - ss)
		if($2 ~ "^[0-9]{1,2}%") {
			tc++
			tn = substr($0, ns)
			tnl = length(tn)
			if(tnl > mtnl) mtnl = tnl
			s = 5
			pd = sprintf("%.0f", $2 / s)
			pr = 100 / s - pd
			at[tc,1] = tn

			if($3 != "None") { at[tc,2] = $3 " " $4 "    " substr($0, us + 2, ds - us + 2) }
			at[tc,3] = "'"$pd_span"'" print_progress(pd)
			at[tc,4] = "'"$pr_span"'" print_progress(pr) "'$end_span'"
		}
	} END {
		for(i = 1; i <= tc; i++) {
			#ft = ft sprintf("%s%-*s     %20s      %s%s", "'"$tn_span"'", mtnl, at[i, 1], at[i, 2], at[i, 3], at[i, 4])
			#ft = ft sprintf("%-5s%-*s     %20s      ", "'$icon'", mtnl, at[i, 1], at[i, 2])

			ft = ft sprintf("%-5s%s%-10s   %s %-*s     %20s      ", "'"$icon"'", \
				at[i, 3], at[i, 4], "'"$tn_span"'", mtnl, at[i, 1], at[i, 2]) #, at[i, 3], at[i, 4])

			if(i < tc) ft = ft "\\\\n\\\\n"
		}

		#print pd, pr, ft
		print ft
	}' 2> /dev/null)

#echo -e "$torrent_info"
#exit

~/.orw/scripts/notify.sh -p "$torrent_info"
#exit
#~/.orw/scripts/notify.sh default "$ft" $level/$empty
#exit
#~/.orw/scripts/notify.sh -p -t 10 -o 5 "$ft"
