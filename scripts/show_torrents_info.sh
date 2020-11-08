#!/bin/bash

icon=
length=$1

read level empty ft <<< $(transmission-remote -l | awk '\
	NR == 1 {
		ml = '${lenght:-30}'
		ns = index($0, "Name")
		ss = index($0, "Status")
		us = index($0, "Up"); ds = index($0, "Down")
	} {
		ts = substr($0, ss, ns - ss)

		if($2 ~ "^[0-9]{1,2}%") {
			tc++
			tn = substr($0, ns)
			tnl = length(tn)

			if(tnl > ml) {
				tn = substr(tn, 0, ml - 1) ".."
				mtnl = ml
			} else {
				if(tnl > mtnl) mtnl = tnl
			}

			s = 10
			pd = sprintf("%.0f", $2 / s)
			pr = 100 / s - pd
			at[tc,1] = tn

			if($3 != "None") { at[tc,2] = $3 " " $4 "    " substr($0, us + 2, ds - us + 2) }
		}
	} END {
		for(i = 1; i <= tc; i++) {
			ft = ft sprintf("%-5s%-*s     %20s      ", "'$icon'", mtnl, at[i, 1], at[i, 2])
			if(i < tc) ft = ft "\\\\n"
		}
		print pd, pr, ft
	}' 2> /dev/null)

~/.orw/scripts/notify.sh -s default -b $level/$empty -i "$ft"
