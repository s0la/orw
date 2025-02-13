#!/bin/bash

set_position() {
	window_border=$(awk '/^border.width/ { print $NF * 2 }' ~/.orw/themes/theme/openbox-3/themerc)

	read primary_{w,h,x,y} <<< \
		$(xrandr -q | awk '$3 == "primary" { gsub("[^0-9]", " ", $4); print $4 }')

	read current_display x y width height <<< \
		$(sed -n '/dropdown/,/^$/ { s/[^0-9]*\([0-9]\+\).*/\1/p }' \
		~/.config/openbox/rc.xml | xargs)

	id=$(xdotool getactivewindow)
	read x y <<< $(xwininfo -id $id | awk '/Absolute/ { print $NF }' | xargs)
	#mapped_display=$(~/.orw/scripts/display_mapper.sh |
	#	awk '$1 == '$current_display' { print $1 }')
	#	#awk 'NR == '$current_display' { print $1 }')

	read primary addition mapped_display{,_{w,h}_ratio} <<< \
		$(~/.orw/scripts/display_mapper.sh | awk '
			$1 == '$current_display' { wr = $4 / '$primary_w'; hr = $5 / '$primary_h' }
			$3 { a = ("'"$display"'") ? '${display:-0}' == NR : '$current_display' == $1; p = NR }
			NR == '$current_display' { md = $1 }
			END { print p, !a, md, wr, hr }')

	#echo $primary_w $primary_h, $mapped_display: $mapped_display_w_ratio, $mapped_display_h_ratio
	#unset mapped_display_{w,h}_ratio
	#exit

	#echo $display
	#echo $x, $y, $width, $height

	read d x y w h <<< $(awk -F '[_ ]' '
		BEGIN {
			wb = '$window_border'; wx = '${x:-0}'; wy = '${y:-0}'
			ww = '$width'; wh = '$height';  rwx = dw - (wx + ww + wb);
			nx = "'$x_position'"; ny = "'$y_position'"; nw = "'$new_width'"; nh = "'$new_height'"
		} {
			if (/^[xy]_offset/) { if (/x/) xo = $NF; else yo = $NF }
			if (/^orientation/) {
				d = '${display:-0}'
				if ($NF ~ /^h/) { i = 4; p = wx } else { i = 5; p = wy }
			}

			if ($1 == "display") {
				if ($3 == "size") {
					cd = $2
					if (cd == '$mapped_display') { cdw = $4; cdh = $5 }
					if (!e && ((d && d == cd) || !d)) { dw = $4; dh = $5 }; max += $i
				} else if ($3 == "xy") {
					if (!e && ((d && d == cd) || !d)) { dx = $4; dy = $5 }
				} else if ($3 == "offset") {
					#if (((d && (cd >= d)) || (!d)) && p < max) {
					if (cd == '$mapped_display') { cdh -= $5 + $6 }
					if (!e && ((d && cd >= d) || (!d && p < max))) {
						e = cd
						bto = $4; bbo = $5
					} else {
						if(d && cd < d || !d) bmin += $3;
						if(p > max) if(i == 3) wx -= $i; else wy -= $i
					}
				}
			}
		} END {
			if (nw) { ww = int((dw / 100) * nw); if (nw == 100) ww -= bw }
			else { ww = int(dw / 100 * (ww / (cdw / 100))) }
			if (nh) wh = int(((dh - $4 - $5 - yo) / 100) * nh);
			else { wh = int((dh - $4 - $5 - yo) / 100 * (wh / (cdh / 100))) }

			if (nx == "r" || (!nx && rwx < wx + 10)) wx = dw - ww - int((xo + wb) / 2)
			else if (nx == "l" || (!nx && wx < rwx + 10)) wx = int(xo / 2)
			else wx = int((dw - ww) / 2)

			if (ny == "t" || (!ny && rwx < wx + 10)) wy = ((bto) ? bto + 1 : int(yo / 2))
			else if (ny == "b" || (!ny && wx < rwx + 10)) wx = dh - wh - int(xo / 2)
			else wy = int((dh - wh - bto - bbo) / 2)

			#print e, int(wx * '${mapped_display_w_ratio:-1}'), int(wy * '${mapped_display_h_ratio:-1}'), ww + 80, wh
			#print e, int(wx * '${mapped_display_w_ratio:-1}'), int(wy * '${mapped_display_h_ratio:-1}'), ww, wh
			#print e, wx, wy, int(ww * '${mapped_display_w_ratio:-1}'), int(wh * '${mapped_display_h_ratio:-1}')
			print e, int(wx), int(wy), ww + '${additional_width:-0}', wh + '${additional_height:-0}'
		}' ~/.config/orw/config)

	additional_width=80 additional_height=30
	if ((addition || (!display && d != primary))); then 
		#echo $addition, $d, $primary, $display, $((!display && d != primary)), $additional_width, $additional_height
		((w+=additional_width))
		((h+=additional_height))
	fi
	display=$(~/.orw/scripts/display_mapper.sh | awk 'NR == '$d' { print $1 }')

	#~/.orw/scripts/set_geometry.sh -c dropdown -m $display -x $x -y $y -w $w -h $h
	~/.orw/scripts/set_geometry.sh -c dropdown -m $display -x $x -y $y -w $w -h $h
	return

	read display display_x display_y display_width display_height bar_min bar_max x y <<< \
		$(awk -F '[_ ]' '{
			if(/^orientation/) {
				d = '${display:-0}'; cd = 1; wx = '$x'; wy = '$y'; bmin = 0;
				if($NF ~ /^h/) { i = 4; p = wx } else { i = 5; p = wy }
			}

			if($1 == "display") {
				if ($3 == "size") {
					if ((d && d == cd) || !d) { dw = $4; dh = $5 }; max += $i
				} else if ($3 == "xy") {
					cd = $2
					if ((d && d == cd) || !d) { dx = $4; dy = $5 }
					if (((d && (cd >= d)) || (!d)) && p < max) {
						print (d) ? d : cd, dx, dy, dw, dh, bmin, bmin + $3, wx, wy
						exit
					} else {
						if(d && cd < d || !d) bmin += $3;
						if(p > max) if(i == 3) wx -= $i; else wy -= $i
					}
				}
			}
		}' ~/.config/orw/config)

		#$(awk -F '[_ ]' '{
		#	if(/^orientation/) {
		#		d = '${display:-0}'; cd = 1; wx = '$x'; wy = '$y'; bmin = 0;
		#		if($NF ~ /^h/) { i = 4; p = wx } else { i = 5; p = wy } };
		#		if($1 == "display") {
		#			if($3 == "xy") { cd = $2; if((d && d == cd) || !d) { dx = $4; dy = $5 } }
		#			else if($3 == "size") {
		#				if((d && d == cd) || !d) { dw = $4; dh = $5 }; max += $i;
		#				if(((d && (cd >= d)) || (!d)) && p < max) {
		#					print (d) ? d : cd, dx, dy, dw, dh, bmin, bmin + $3, wx, wy
		#					exit
		#				} else {
		#					if(d && cd < d || !d) bmin += $3;
		#					if(p > max) if(i == 3) wx -= $i; else wy -= $i
		#					}
		#				}
		#			}
		#		}' ~/.config/orw/config)

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

				bar_y_end=$((2 * bar_y + bar_height + frame))
				((bar_y)) || (( bar_y_end+=5 ))
				echo $bar_x $((display_width - (bar_x + bar_width + frame))) $((bar_width + frame)) $bar_y_end
			fi
		done <<< $(~/.orw/scripts/get_bar_info.sh $display) | \
			sort -nk ${sort_criteria:-4} | awk 'END {
					xo = $1; rxo = $2; bw = $3; yo = $4;
					dx = '$display_x'; dy = '$display_y'; dw = '$display_width'; dh = '$display_height';
					wb = '$window_border'; wx = '$x'; wy = '$y'; ww = '$width'; wh = '$height';  rwx = dw - (wx + ww + wb);
					nw = "'$new_width'"; if(nw) { ww = int((dw / 100) * nw); if(nw == 100) ww -= bw }
					nh = "'$new_height'"; if(nh) wh = int(((dh - yo) / 100) * nh);
					nx = "'$x_position'";
					#if(nx == "r" || (!nx && rwx < wx + 10)) wx = dw - (rxo + ww + wb);
					if (nx == "r" || (!nx && rwx < wx + 10)) wx = dw - (rxo + ww + wb);
					else if(nx == "l" || (!nx && wx < rwx + 10)) wx = xo;
					else wx = int((dw - ww) / 2);
						print dx + wx, dy + yo, ww, wh }')

		y=$(awk '
				$1 == "display_'${display:-1}'_offset" { print $(NF - 1) + 1 }
			' ~/.config/orw/config)

		~/.orw/scripts/set_geometry.sh -c dropdown -x $x -y $y -w $width -h $height
}

x_position=r
y_position=c
	
current_desktop=$(xdotool get_desktop)
focused_window=$(xdotool getwindowfocus getwindowname)

if [[ $focused_window == DROPDOWN ]]; then
	xdotool getactivewindow windowminimize
else
	if ! wmctrl -a DROPDOWN; then
		while getopts :x:y:w:h:d: flag; do
			case $flag in
				#y) new_y=$OPTARG;;
				w) new_width=$OPTARG;;
				h) new_height=$OPTARG;;
				[xy])
					var=${flag}_position
					eval $var=$OPTARG
					sed -i "/^$var/ s/=./=${!var}/" $0;;
				d) display=$OPTARG;;
			esac
		done

		set_position

		alacritty -t DROPDOWN --class=dropdown &> /dev/null &
	fi
fi
