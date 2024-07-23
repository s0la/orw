#!/bin/bash

color_bar() {
	printf "$1%.0s$3" $(seq 1 $2)
}

get_dimension() {
	awk '
		function get_portion(n) {
			return sprintf("%.1f", n)
		}

		function get_delta(r1, r2) {
			return sqrt((r1 - r2) ^ 2) <= 0.2
		}

		function get_final(b, a, t, w) {
			bp = b / s
			ap = a / s
			mp = m / s
			tp = t / s

			tm = 0
			if(cs > (w) ? bs : ds && ce < (w) ? be : de) {
				if (b) { bp -= mp; tm++ }
				if (a) { ap -=  mp; tm++ }
			} else tm = 1

			tm *= mp

			dp = (tp - tm) - (bp + ap)

			br = bp % 1; dr = dp % 1; ar = ap % 1
			dr = dp % 1; ar = ap % 1

			se = get_delta(br, ar)

			if(b && a && br + ar >= 0.6 && se) { bp++; ap++ }
			else {
				ibp = idp = iap = 0
				if(dr > 0.5) { idp++ }
				if(br > 0.5) { ibp++ }
				if(ar > 0.5) { iap++ }
			}

			fd = 0
			fb = int(bp + ibp)
			fa = int(ap + iap)

			if (b && a) {
				fd = int(tp - (fb + fa))
			} else if (b) {
				if (get_delta(dp, bp)) fd = fb
			} else if (a) {
				if (get_delta(dp, ap)) fd = fa
			}

			if (!fd) fd = int(tp - (fb + fa))
		}

		BEGIN {
			if(("'$orientation'" == "x" && "'$alignment_direction'" == "h") ||
				("'$orientation'" == "y" && "'$alignment_direction'" == "v")) {
				bs = '${block_start:-0}'
				bd = '${block_dimension:-0}' #+ '${!border}'
				be = bs + bd
			}

			ws = '${!orientation}'
			wd = '$dimension' + '${!border}'
			we = ws + wd
			ds = '${!start}'
			de = '${!end}'
			s = '${!step}'
			m = '$margin'

			if(bs) {
				get_final(bs - ds, de - be, de - ds)
				wb = fb; wa = fa

				get_final(ws - bs, be - we, be - bs, 1)
				fbb = fb; wd = fd; fba = fa
			} else {
				get_final(ws - ds, de - we, de - ds)
				wb = fb; wd = fd; wa = fa
			}

			print wb, wd, wa, fbb, fba
		}'
}

get_dimension_size() {
	local filled_{x,y}
	local orientation=$1
	[[ $orientation == x ]] &&
		dimension=$w total=$columns || dimension=$h total=$rows

	unset {x,y}_offset
	read border end start step <<< $(eval echo \${!${orientation}_*})
	read ${orientation}_{window_{before,size,after},block_{before,after}} <<< $(get_dimension)
}

font="Roboto Mono 8"
offset="<span font='$font'>$(printf "%-3s")</span>"

notify() {
	local notification="$1" time="$2" offset="   "
	dunstify -t ${time:-10000} -r 222 "summary" \
		"<span font='Iosevka Orw $font_size'>\n$notification\n</span>" &> /dev/null
}

display_notification() {
	local window_row empty_block_row table {h,v}_separator
	icon='██'
	
	[[ $evaluate_type != offset ]] &&
		v_separator="<span font='Iosevka Orw 6'>\n</span>" \
		h_separator="<span foreground='$empty_bg'>  </span>"

	empty_row=$(color_bar "$icon" $columns)
	((x_window_before)) && empty_block_row="$(color_bar "$icon" $x_window_before)"
	empty_block_row+="<span foreground='$sbg'>$(color_bar "$icon" $x_window_size)</span>"
	((x_window_after)) && empty_block_row+="$(color_bar "$icon" $x_window_after)"

	((x_window_before)) && window_row="$(color_bar "$icon" $x_window_before)"
	((x_block_before)) &&
		window_row+="<span foreground='$sbg'>$(color_bar "$icon" $x_block_before)</span>$h_separator" &&
		((separator_width++))
	window_row+="<span foreground='$pbfg'>$(color_bar "$icon" $x_window_size)</span>"
	((x_block_after)) &&
		window_row+="<span foreground='$sbg'>$h_separator$(color_bar "$icon" $x_block_after)</span>" &&
		((separator_width++))
	((x_window_after)) && window_row+="$(color_bar "$icon" $x_window_after)"

	((y_window_before)) && table="$(color_bar "$empty_row\n" $y_window_before)\n"
	((y_block_before)) && table+="$(color_bar "$empty_block_row\n" $y_block_before)\n$v_separator"
	table+="$(color_bar "$window_row\n" $y_window_size)"
	((y_block_after)) && table+="$v_separator\n$(color_bar "$empty_block_row\n" $y_block_after)"
	((y_window_after)) && table+="$v_separator\n$(color_bar "$empty_row\n" $y_window_after)"

	notification="<span foreground='$empty_bg'>$table</span>"
	notify "$notification"

	unset separator_width
}

evaluate() {
	input=$1

	if [[ $input == d ]]; then
		stop=true
		~/.orw/scripts/notify.sh -r 222 -t 1m -s windows_osd 
		unset {x,y}_{window,block}_{before,after,size}
	else
		[[ $input == [JKkj] ]] &&
			step=$y_step || step=$x_step

		case $input in
			m)
				moved=true
				option=move;;
			r) option=resize;;
			"<"|">")
				option=resize
				[[ $input == "<" ]] && sign=- || sign=+
				return
				;;
			[A-Z])
				local default_step=$step
				local step sign

				if [[ $option == resize && $source ]]; then
					get_max_value $input
					resize_to_edge $index $margin $input
					read x y w h <<< ${properties[*]:1:4}
				else
					case $input in
						K) step=$((y - y_start));;
						H) step=$((x - x_start));;
						J) step=$((y_end - (y + h + ${real_y_border:-$y_border})));;
						L) step=$((x_end - (x + w + x_border)));;
					esac
				fi

				sign=+
				input=${input,};;
		esac

		if [[ $option == move ]]; then
			case $input in
				k) ((y -= step));;
				l) ((x += step));;
				j) ((y += step));;
				h) ((x -= step));;
			esac
		else
			[[ $sign == - ]] &&
				opposite_sign=+ || opposite_sign=-

			case $input in
				j) ((h $sign= step));;
				l) ((w $sign= step));;
				[hk])
					[[ $input == h ]] &&
						properties='w x' ||
						properties='h y'

					((${properties% *} $sign= step))
					((${properties#* } $opposite_sign= step))

					local position=before
			esac

			[[ $position ]] || local position=after

			[[ $input == [jk] ]] && local direction=y vertical=true
			[[ $input == [hl] ]] && local direction=x horizontal=true

			((default_step)) && step=$default_step

			(( edges[$input] += $sign$step ))

			eval "((${direction}_window_size $sign= 1))"
			eval "((${direction}_block_$position $opposite_sign= 1))"
		fi

		display_notification
	fi
}

execute() {
	((x_border /= 2))
	((y_border -= x_border))

	[[ $source ]] ||
		echo wmctrl -ir $id -e 0,$((x - x_border)),$((y - y_border)),$w,$h
}

set_geometry() {
	osd_width=$(echo "((($columns + 2) * $font_size + 2 * 10) * 1.2) / 1" | bc)
	osd_x=$(((x_start + (x_end - x_start) - osd_width) / 2))
	osd_x=$(((x_end + x_start - osd_width) / 2))

	awk -i inplace '\
		function replace(position, value) {
			$0 = gensub("([0-9]+)", sprintf("%.0f", value), position)
		}

		/^\s*geometry/ {
			replace(3, '$osd_x')
			replace(1, '$osd_width' * 1.2)
		} { print }' ~/.config/dunst/windows_osd_dunstrc
}

step=120
font_size=6

[[ $1 == source ]] && source=true

declare -A edges

if [[ ! $source ]]; then
	id=$(printf '0x%.8x' $(xdotool getactivewindow))

	read {x,y}_offset offset <<< $(awk '/^([xy]_)?offset/ { print $NF }' ~/.config/orw/config | xargs)
	[[ $offset == true ]] && eval $(cat ~/.config/orw/offsets)

	read x y w h {x,y}_border <<< $(xwininfo -id $id | awk '
		/Absolute/ { if(/X/) x = $NF; else y = $NF }
		/Relative/ { if(/X/) xb = $NF; else yb = $NF }
		/Width/ { w = $NF }
		/Height/ { print x - xb, y - yb, w, $NF, 2 * xb, yb + xb }')

	read display display_x display_y width height rest <<< $(~/.orw/scripts/get_display.sh $x $y)

	read bar_{top,bottom}_offset <<< \
		$(awk '/^display_'${display:-1}'_offset/ { print $2, $3 }' ~/.config/orw/config)

	x_start=$((display_x + x_offset))
	x_end=$((display_x + width - x_offset))
	y_start=$((display_y + y_offset + bar_top_offset))
	y_end=$((display_y + height - (y_offset + bar_bottom_offset)))
fi

set_window_steps() {
	read columns rows <<< $(awk '
		function round(n) {
			return sprintf("%.0f", n)
		}

		BEGIN {
			c = 16
			r = ('$x_end' - '$x_start') / ('$y_end' - '$y_start')

			while(c % 2 + round(c / r) % 2) c++

			print c * 2, round(c / r) * 2
		}')

	x_step=$(((x_end - x_start) / columns))
	y_step=$(((y_end - y_start) / rows))

	((block_dimension)) &&
		empty_bg=$(sed -n '0,/^\s*background/ s/^\s*background[^"]*.\([^"]*\).*/\1/p' \
		~/.orw/dotfiles/.config/dunst/windows_osd_dunstrc) ||
		empty_bg="$sbg"
}

read sbg pbfg <<< $(\
	sed -n 's/^\w*g=.\([^"]*\).*/\1/p' ~/.orw/scripts/notify.sh | xargs)
