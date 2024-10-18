#!/bin/bash

#displays=( $(awk -F '[=_ ]' '
#	NR == FNR && /class="\*"/ { c = 1 }
#	c && /<[xy]>/ {
#		v = $0
#		gsub("[^0-9]", "", v)
#		if (/x/) x = int(v); else y = int(v)
#	}
#	c && /\/position/ { c = 0 }
#
#	ENDFILE { if (NR == FNR) nr = NR }
#
#	/^(display|number)_[0-9](_name)?/ {
#		if (FNR + nr == NR) ad[$2] = 1
#		else if ($2 in ad) adi[$2] = $NF
#	}
#
#	$1 == "display" && $3 ~ "xy|size" {
#		if ($3 == "size") { w = $(NF - 1); h = $NF }
#		else if (x < $(NF - 1) + w && y < $NF + h && !d) d = $2
#	}
#
#	END { print d - 1; for (di in adi) print adi[di] }
#	' ~/.config/{openbox/rc.xml,orw/config} ~/.orw/scripts/icons ) )

displays=( $(awk -F '[=_ ]' '
	NR == FNR && /class="\*"/ { c = 1 }
	c && /monitor/ {
		gsub("[^0-9]", "")
		m = $0
		c = 0
	}

	ENDFILE { if (NR == FNR) nr = NR }

	/^(display|number)_[0-9](_name)?/ {
		if (FNR + nr == NR) ad[$2] = 1
		else if ($2 in ad) adi[$2] = $NF
	}

	END {
		print m
		for (di in adi) print adi[di]
	}' ~/.config/{openbox/rc.xml,orw/config} ~/.orw/scripts/icons ) )

#display_mapping=$(
#	xrandr | awk -F '[ x+]' '
#		NR == 1 {
#			h = $9
#			v = $12
#			sub("[^0-9]", "", v)
#			si = (h > 2 * v) ? 2 : 3
#		}
#		$2 == "connected" {
#			ad[$(3 + ($3 == "primary") + si)] = ++d
#		} END {
#			for (d in ad) printf "[%d]=%d ", ++di, ad[d]
#		}'
#)

display_mapping=$(~/.orw/scripts/display_mapper.sh | awk '{ printf "[%d]=%d ", NR, $1 }')

declare -A display_map
eval display_map=( $display_mapping )
current_display=$((${display_map[${displays[0]}]} - 1))
unset displays[0]

item_count=${#displays[*]}
set_theme_str

new_display=$(tr ' ' '\n' <<< ${displays[*]} |
	rofi -dmenu -format 'd' -theme-str "$theme_str" -a $current_display -selected-row $current_display -theme main)
((new_display)) &&
	~/.orw/scripts/select_display.sh ${display_map[$new_display]} $new_display
exit

tr ' ' '\n' <<< ${displays[*]} |
	rofi -dmenu -format 'd' -theme-str "$theme_str" -a $current_display -selected-row $current_display -theme main |
	xargs -r ~/.orw/scripts/select_display.sh
