#!/bin/bash

awk -F '[_ ]' '{ if(/^orientation/) {
		cd = 1
		bmin = 0
		#d = '${display:-0}'
		i = '$1'; mi = i + 2
		#wx = '${properties[1]}'
		#wy = '${properties[2]}'

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

				#if((d && d == cd) || !d) {
					dx = $4
					dy = $5
					minp = $(mi + 1)
				#}
			} else {
				#if((d && d == cd) || !d) {
					dw = $3
					dh = $4
					maxp = minp + $mi
				#}

				max += $i

				#if((d && p < max && (cd >= d)) || (!d && p < max)) {
				if(p < max) {
					#print (d) ? d : cd, dx, dy, dw, dh, minp, maxp, bmin, bmin + dw, dx + wx, dy + wy
					print cd, dx, dy, dw, dh, minp, maxp, bmin, bmin + dw, dx + wx, dy + wy
					exit
				} else {
					#if(d && cd < d || !d) bmin += $3
					bmin += $3
					if(p > max) if(i == 3) wx -= $i
					else wy -= $i
				}
			}
		}
	}
}' ~/.config/orw/config
