#!/bin/bash

read sbg pbfg <<< $(\
	sed -n 's/^\w*g=.\([^"]*\).*/\1/p' ~/.orw/scripts/notify.sh | xargs)

#echo $sbg, $pbfg

day=$(date +'%d')
cal=$(cal | awk '
	function bold(string) {
		return "<b>" string "</b>"
	}

	NR == 1 { $0 = bold($0) "\n" }
	/\<'$day'\>/ {
		bd = "<span foreground=\"'"$pbfg"'\">" bold("'$day'") "</span>"
		sub("\\<'$day'\\>", bd)
	}

	{ print }')

#echo -e "$cal"
#exit

#cal | sed "s/\b\($day\)\b/SOLA\1CAR/"
#dunstify -t 10000 -r 222 'summery' "<span font='Iosevka Orw 11'>\n  $cal  \n</span>"

read x y display <<< \
	$(xdotool getmouselocation --shell | head -3 | cut -d '=' -f 2 | xargs)

#echo $x, $y, $display, $window
((display++))

font_size=11

calendar_y=$(awk -F '[_ ]' '
	$1 == "display" && $2 == "'"$display"'" {
		if ($3 == "xy") ys = $NF
		else if ($3 == "offset")
			print (ys + $(NF - 1) > '$y') ? "+" $(NF - 1) + 5 : -($NF + 5)
	}' ~/.config/orw/config)

#awk -F '["x+-]' -i inplace '/^[^#]*geometry/ {
#			x = '$x' - int('$font_size' * 7 / 2 * 3)
#			sub($4, x)
#			sub("[+-]" $5, "'"$calendar_y"'")
#			#gsub(".[0-9]*.[0-9]*\"|\"", "", $NF)
#			#$NF = "\"" $NF "+" x "'$calendar_y'\""
#			#print $NF ", " $0
#		} { print }' ~/.config/dunst/windows_osd_dunstrc

notification="<span font='Iosevka Orw $font_size'>\n  $cal  \n</span>" 
~/.orw/scripts/notify.sh -t 5 -r 222 -s windows_osd "$notification" &> /dev/null &
