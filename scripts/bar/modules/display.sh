#!/bin/bash

get_display() {
	#read {{prev,next}_,}display display_count <<< $(awk '
	#	NR == FNR && /class="\*"/ { c = 1 }
	#	c && /<[xy]>/ {
	#		v = $1
	#		gsub("\\s*<[^>]*>", "", v)
	#		if ($1 ~ "x") x = int(v); else y = int(v)
	#	}
	#	c && /\/position/ { c = 0 }

	#	NR > FNR {
	#		if (/[xy]_offset/) { if (/^x/) xo = $NF; else yo = $NF }
	#		if (/^display.*(xy|size)/) {
	#			if (/xy/) { dx = $2; dy = $3 }
	#			else {
	#				d = $1
	#				gsub("[^0-9]", "", d)

	#				if (x >= dx + xo && x <= dx + $2 - xo &&
	#					y >= dy + yo && y <= dy + $3 - yo) cd = d - 1
	#			}
	#		}
	#	} END { print (cd + d - 1) % d + 1, (cd + 1) % d + 1, cd + 1, d }' \
	#		~/.config/{openbox/rc.xml,orw/config})



	read {{prev,next}_,}display display_count <<< \
		$(awk -F '[ x+]' '
			NR == 1 {
				h = $9
				v = $12
				sub("[^0-9]", "", v)
				si = (h > 2 * v) ? 2 : 3
			}

			NR == FNR && $2 == "connected" {
				ad[$(3 + ($3 == "primary") + si)] = ++d
			}

			NR > FNR && /class="\*"/ { c = 1 }
			c && /<monitor>/ {
				gsub("[^0-9]", "")
				for (di in ad) {
					if (++dc == $0) d = ad[di]
				}
				exit
			}
			END { print (d + dc - 1) % d + 1, (d + 1) % dc + 1, d, dc }' \
				<(xrandr) ~/.config/openbox/rc.xml)





	#read {prev,next,current}_display display_count <<< $(awk '
	#	NR == FNR && /class="\*"/ { c = 1 }
	#	c && /<monitor>/ {
	#		c = 0
	#		d = $1
	#		gsub("\\s*<[^>]*>", "", v)
	#	}
	#	NR > FNR && /display.*name/ { dc++ }
	#	END { print (d + dc - 1) % dc + 1, (d + 1) % dc + 1, cd + 1, dc }' \
	#		~/.config/{openbox/rc.xml,orw/config})

	[[ $display_icons == only ]] &&
		icon=$(get_icon "number_$display") ||
		icon=$(get_icon "display_icon")
	label=DIS
}

set_display_actions() {
	local action1="~/.orw/scripts/notify.sh -s osd -i $icon \"DISPLAY: $display\""
	local action4="~/.orw/scripts/select_display.sh $prev_display"
	local action5="~/.orw/scripts/select_display.sh $next_display"
	actions_start="%{A:$action1:}%{A4:$action4:}%{A5:$action5:}"
	actions_end="%{A}%{A}%{A}"
	actions_start="%{A4:$action4:}%{A5:$action5:}"
	actions_end="%{A}%{A}"
}

make_display_content() {
	display_icons=$icons
	display_mapping=$(
		xrandr | awk -F '[ x+]' '
			NR == 1 {
				h = $9
				v = $12
				sub("[^0-9]", "", v)
				si = (h > 2 * v) ? 2 : 3
			}
			$2 == "connected" {
				ad[$(3 + ($3 == "primary") + si)] = ++d
			} END {
				for (d in ad) printf "[%d]=%d ", ++di, ad[d]
			}'
	)

	declare -A display_map
	eval display_map=( $display_mapping )
}

check_display() {
	local count

	get_display
	set_display_actions

	if ((display_count > 1)); then
		print_module display

		while read event file; do
			(( count = (count + 1) % 2))

			if ((!count)); then
				get_display
				set_display_actions
				((display_count > 1)) && print_module display
			fi
		done < <(inotifywait -me close_write --format '%e %w%f' ~/.config/openbox/ 2> /dev/null)
	fi
}
