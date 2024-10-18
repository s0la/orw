#!/bin/bash

xrandr | awk -F '[ x+]' '
	NR == 1 {
		h = $9
		v = $12
		sub("[^0-9]", "", v)
		si = (h > 2 * v) ? 2 : 3
	}

	$2 == "connected" {
		p = $3 == "primary"
		i = 3 + p
		ad[$(i + si)] = ++di " " $1 " " p " " $i " " $(i + 1) " " $(i + 2) " " $(i + 3)
	} END { for (d in ad) print ad[d] }'
