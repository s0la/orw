#!/bin/bash

set_position() {
	window_border=$(awk '/^border.width/ { print $NF * 2 }' ~/.orw/themes/theme/openbox-3/themerc)

	read x y width height <<< $(sed -n '/dropdown/,/^$/ s/[^0-9]*\([0-9]\+\).*/\1/p' .config/openbox/rc.xml | xargs)

	read display display_x display_y display_width display_height bar_min bar_max x y <<< \
		$(awk -F '[_ ]' '{ if(/^orientation/) \
		{ d = '${display:-0}'; cd = 1; wx = '$x'; wy = '$y'; bmin = 0; \
			if($NF ~ /^h/) { i = 3; p = wx } else { i = 4; p = wy } }; \
				if($1 == "display") \
					if($3 == "xy") { cd = $2; if((d && d == cd) || !d) { dx = $4; dy = $5 } } \
					else { if((d && d == cd) || !d) { dw = $3; dh = $4 }; max += $i; \
						if(((d && (cd >= d)) || (!d)) && p < max) \
							{ print (d) ? d : cd, dx, dy, dw, dh, bmin, bmin + $3, wx, wy; exit } else \
								{ if(d && cd < d || !d) bmin += $3; \
									if(p > max) if(i == 3) wx -= $i; else wy -= $i } } }' ~/.config/orw/config)

	if [[ $x_position ]]; then
		case $x_position in
			l) sort_criteria='2,2';;
			r) sort_criteria='1,1';;
		esac
	fi

	read x y width height <<< \
		$(while read -r bar_name position bar_x bar_y bar_width bar_height adjustable_width frame; do
			if ((position)); then
				if ((adjustable_width)); then
					read bar_width bar_height bar_x bar_y < ~/.config/orw/bar/geometries/$bar_name
					(( bar_y -= display_y ))
				else
					(( bar_x -= bar_min ))
				fi

				echo $bar_x $((display_width - (bar_x + bar_width + frame))) $((bar_width + frame)) $((bar_y + bar_height + frame + 1))
			fi
		done <<< $(~/.orw/scripts/get_bar_info.sh $display) | \
			sort -nk ${sort_criteria:-4} | awk 'END { xo = $1; rxo = $2; bw = $3; yo = $4; \
			dx = '$display_x'; dy = '$display_y'; dw = '$display_width'; dh = '$display_height'; \
			wb = '$window_border'; wx = '$x'; wy = '$y'; ww = '$width'; wh = '$height';  rwx = dw - (wx + ww + wb); \
			nw = "'$new_width'"; if(nw) { ww = int((dw / 100) * nw); if(nw == 100) ww -= bw } \
			nh = "'$new_height'"; if(nh) wh = int(((dh - yo) / 100) * nh); \
			nx = "'$x_position'"; \
			if(nx == "r" || (!nx && rwx < wx + 10)) wx = dw - (rxo + ww + wb); \
			else if(nx == "l" || (!nx && wx < rwx + 10)) wx = xo; \
			else wx = int(dw / 2 - ww / 2); \
				print dx + wx, dy + yo, ww, wh }')

		~/.orw/scripts/set_class_geometry.sh -c dropdown -x $x -y $y -w $width -h $height
}

x_position=r
	
current_desktop=$(xdotool get_desktop)
focused_window=$(xdotool getwindowfocus getwindowname)

if [[ $focused_window == DROPDOWN ]]; then
	xdotool getactivewindow windowminimize
else
	if ! wmctrl -a DROPDOWN; then
		while getopts :x:y:w:h:d: flag; do
			case $flag in
				y) new_y=$OPTARG;;
				w) new_width=$OPTARG;;
				h) new_height=$OPTARG;;
				x)
					x_position=$OPTARG
					sed -i "/^x_position/ s/=./=$x_position/" $0;;
				d) display=$OPTARG;;
			esac
		done

		set_position

		termite -t DROPDOWN --class=dropdown &> /dev/null &
	fi
fi
