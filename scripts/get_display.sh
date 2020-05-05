#!/bin/bash

awk -F '[_ ]' '{ if(/^orientation/) {
		cd = 1
		bmin = 0
		i = '$1'; mi = i + 2

		wx = '$1'
		wy = '$2'

		if($NF ~ /^h/) {
			i = 3
			p = wx
		} else {
			i = 4
			p = wy
		}
	} {
		if($1 == "display") {
			if($3 == "xy") {
				cd = $2

				dx = $4
				dy = $5
				minp = $(mi + 1)
			} else {
				dw = $3
				dh = $4
				maxp = minp + $mi

				max += $i

				if(p < max) {
					print cd, dx, dy, dw, dh, minp, maxp, bmin, bmin + dw, dx + wx, dy + wy
					exit
				} else {
					bmin += $3
					if(p > max) if(i == 3) wx -= $i
					else wy -= $i
				}
			}
		}
	}
}' ~/.config/orw/config
