#!/bin/bash

display=${1-0}

read bar_min bar_max <<< \
	$(awk -F '[_ ]' '{ if(/primary/) { bm = 0; d = '$display'; if(!d) d = $NF } \
		if(/^display/) { if(NF == 4) if(d > $2) bm += $3; else { print bm, bm + $3; exit } } }' ~/.config/orw/config)

ps aux | grep bar | sort -r | \
	awk -F '[- ]' '! /awk/ && /lemonbar/ \
	{ nr = NR; p = ($(NF - 6) == "b") ? 0 : 1; split($(NF - 3), g, "[x+]"); x = g[3]; y = g[4]; w = g[1]; h = g[2]; \
		ff = (p) ? 7 : 9; fw = ($(NF - ff) == "r") ? $(NF - (ff - 1)) * 2 : 0; bn = $NF } \
		{ if(nr && NR == nr + 1 && x >= '$bar_min' && x + w <= '$bar_max') \
			{ aw = (/-w [a-z]/) ? 1 : 0; print bn, p, x, y, w, h, aw, fw } }'
