#!/bin/bash

awk -F '[_ ]' '{
	if (/^orientation/) {
		cd = 1
		bmin = 0
		#i = '$1'; mi = i + 2

		wx = '${1:-0}'
		wy = '${2:-0}'

		if ($NF ~ /^h/) {
			i = 4
			p = wx
		} else {
			i = 5
			p = wy
		}
	}

	if (/^primary/ && !(wx + wy)) {
		cd = $NF
		e = 1
	}

	{
		if ($1 == "display") {
			if ($3 == "xy") {
				cd = $2

				dx = $4
				dy = $5
				minp = $(mi + 1)
			} else if ($3 == "size") {
				dw = $4
				dh = $5
				maxp = minp + $(mi + 1)

				max += $i

				#if (p < max) {
				#	print cd, dx, dy, dw, dh, minp, maxp, bmin, bmin + dw, dx + wx, dy + wy
				#	exit
				#} else {

				if (p > max) {
					bmin += $4
					if(p > max) if(i == 4) wx -= $i
					else wy -= $i
				}
			} else if ($3 == "offset") {
				if (p < max || e) {
					print cd, dx, dy, dw, dh, $4, $5, minp, maxp, bmin, bmin + dw, dx + wx, dy + wy
					exit
				}
			}
		}
	}
}' ~/.config/orw/config
