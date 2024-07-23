#!/bin/bash

read sbg pbfg <<< $(\
	sed -n 's/^\w*g=.\([^"]*\).*/\1/p' ~/.orw/scripts/notify.sh | xargs)

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

read x y display <<< \
	$(xdotool getmouselocation --shell | head -3 | cut -d '=' -f 2 | xargs)

((display++))

font_size=11

calendar_y=$(awk -F '[_ ]' '
	$1 == "display" && $2 == "'"$display"'" {
		if ($3 == "xy") ys = $NF
		else if ($3 == "offset")
			print (ys + $(NF - 1) > '$y') ? "+" $(NF - 1) + 5 : -($NF + 5)
	}' ~/.config/orw/config)

notification="<span font='Iosevka Orw $font_size'>\n  $cal  \n</span>" 
~/.orw/scripts/notify.sh -t 5 -r 222 -s windows_osd "$notification" &> /dev/null &
