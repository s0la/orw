#!/bin/bash

#read current_display displays <<< $(awk -F '[=_]' '
displays=( $(awk -F '[=_ ]' '
	#NR == FNR && /display.*name/ {
	#/^(display|number)_[0-9]_(name|icon)/ {

	#/^primary/ { print $NF - 1 }

	NR == FNR && /class="\*"/ { c = 1 }
	c && /<[xy]>/ {
		v = $0
		gsub("[^0-9]", "", v)
		if (/x/) x = int(v); else y = int(v)
	}
	c && /\/position/ { c = 0 }

	ENDFILE { if (NR == FNR) nr = NR }

	/^(display|number)_[0-9]_(name|icon)/ {
		#gsub("[^0-9]", "", $1)
		if (FNR + nr == NR) ad[$2] = 1
		else if ($2 in ad) adi[$2] = $NF
	}

	$1 == "display" && $3 ~ "xy|size" {
		if ($3 == "size") { w = $(NF - 1); h = $NF }
		else if (x < $(NF - 1) + w && y < $NF + h && !d) d = $2
	}

	END { print d - 1; for (di in adi) print adi[di] }
	' ~/.config/{openbox/rc.xml,orw/config} ~/.orw/scripts/icons ) )

current_display=${displays[0]}
unset displays[0]
item_count=${#displays[*]}
set_theme_str

tr ' ' '\n' <<< ${displays[*]} |
	rofi -dmenu -format 'd' -theme-str "$theme_str" -a $current_display -selected-row $current_display -theme main |
	xargs -r ~/.orw/scripts/select_display.sh
exit

display=$(tr ' ' '\n' <<< ${displays[*]} |
	rofi -dmenu -format 'd' -theme-str "$theme_str" -selected-row $current_display -theme main)

~/.orw/scripts/select_display.sh $display
