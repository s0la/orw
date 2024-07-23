#!/bin/bash

display=${1-0}

read bar_min bar_max display <<< \
	$(awk -F '[_ ]' '{
		if(/primary/) {
			bm = 0
			d = '$display'
			if(!d) d = $NF
		}
		if(/^display/) {
			if($3 == "size") {
				if(d > $2) bm += $4
				else {
					print bm, bm + $4, d
					exit
				}
			}
		}
	}' ~/.config/orw/config)

ps aux | grep bar | sort -r | \
	awk -F '[- ]' '\
	!/awk/ && /lemonbar\s*-d/ {
		nr = NR
		p = ($(NF - 6) == "b") ? 0 : 1
		split($(NF - 3), g, "[x+]")
		x = g[3]; y = g[4]; w = g[1]; h = g[2]
		ff = (p) ? 7 : 9
		fw = ($(NF - ff) == "r") ? $(NF - (ff - 1)) * 2 : 0
		bn = $NF
	} {
		if(nr && NR == nr + 1 && x >= '$bar_min' && x + w <= '$bar_max') {
			aw = (/-w [a-z]/) ? 1 : 0
			print bn, p, x, y, w, h, aw, fw
		}
	}'
