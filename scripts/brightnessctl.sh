#!/bin/bash

value=${1:-+5}

read value percent <<< $(awk '{
		if (NR == FNR) m = $1;
		else {
			p = (m / 100)
			nv = '$value' * p
			if ("'$value'" ~ "^[+-]") nv += $1
			$1 = (nv <= m && nv > 0) ? nv : $1
			printf "%.0f %.0f", $1, nv / p
		}
	}' /sys/class/backlight/intel_backlight/{max_,}brightness)

sudo tee /sys/class/backlight/intel_backlight/brightness <<< $value

~/.orw/scripts/system_notification.sh brightness $percent
