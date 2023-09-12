#!/bin/bash

color_bar() {
	printf "$1%.0s$3" $(seq 1 $2)
}

calculate() {
	#printf '%.0f' $(bc <<< "scale=2; $@")
	local value=$(($1 / ${2:-$step}))
	local reminder=$(($1 % step))
	#((step - reminder < (step * 30 / 100))) && ((value++))

	echo $value
}

get_dimension() {
	awk '
		function get_portion(n) {
			return sprintf("%.1f", n)
		}

		function get_delta(r1, r2) {
			#rd = (r1 > r2) ? r1 - r2 : r2 - r1
			#return rd <= 0.2
			return sqrt((r1 - r2) ^ 2) <= 0.2
		}

		#function get_final(cs, ce, w) {
			#b = cs - ds
			#a = de - ce

		function get_final(b, a, t, w) {
			#print cs, ds, de, ce
			#print b, a, t

			#if (a) a += m
			#if (b) a -= m

			#print a, s, a / s, get_portion(a / s)
			#bp = get_portion(b / s)
			#ap = get_portion(a / s)
			#mp = get_portion(m / s)
			#tp = get_portion(t / s)

			bp = b / s
			ap = a / s
			mp = m / s
			tp = t / s

			#print "'$y_step'", "'$block_start'", "'$block_dimension'"
			#print "'$x_step'", "'$block_start'", "'$block_dimension'"
			#print bp, ap, mp, tp

			tm = 0
			#if(cs > ds && ce < de) {
			if(cs > (w) ? bs : ds && ce < (w) ? be : de) {
				#print "IN", cs, ds, ce, de, bs, be
				if (b) { bp -= mp; tm++ }
				if (a) { ap -=  mp; tm++ }
				#tm = 2 * mp
			} else tm = 1

			tm *= mp
			#print "T", tp, tm, ap, mp

			dp = (tp - tm) - (bp + ap)
			#print dp, tp, tm, bp, ap
			#print b, bp, a, ap, mp, s, cs, ds, de, ce, '$total', dp, '$total' - tm - bp - (18 + 0.7) == 17, sprintf("%.1f", a / s) == 18.7

			br = bp % 1; dr = dp % 1; ar = ap % 1
			dr = dp % 1; ar = ap % 1

			#print '$total', dp, bp, ap
			#print b, bp, a, ap, '$total', dp, s, de, ce, cs, ds
			#print bp, br, dp, dp % 1, dr, ap, ar

			se = get_delta(br, ar)
			#be = get_delta(bp, dp)
			#ae = get_delta(dp, ap)

			#if(dr > 0.6) { dp++ }
			#else if(br + dr > 0.6 && be) { bp++ }
			#else if(ar + dr > 0.6 && ae) { ap++ }
			#else if(br + ar > 0.6 && se) { bp++; ap++ }
			#else {
			#	if(br > 0.6) bp++
			#	if(ar > 0.6) ap++
			#}

			#print bp, ap, dp
			#print bp, ap, dp
			#print br, ar, dr
			if(b && a && br + ar >= 0.6 && se) { bp++; ap++ }
			else {
				ibp = idp = iap = 0
				if(dr > 0.5) { idp++ }
				if(br > 0.5) { ibp++ }
				if(ar > 0.5) { iap++ }
			}

			#print br, ar, get_delta(br, ar)
			#print "END", se, br, ar, bp, ap, dp

			#print "P", bp, ap

			#fd = (b && a) ? int(tp - (fb + fa)) : \
			#	(get_delta(dp, bp)) ? bp : 

			fd = 0
			fb = int(bp + ibp)
			fa = int(ap + iap)

			#print "END", fb, fa

			if (b && a) {
				fd = int(tp - (fb + fa))
			} else if (b) {
				if (get_delta(dp, bp)) fd = fb
			} else if (a) {
				#print "HERE", dp, ap, get_delta(dp, ap), fd, fa
				if (get_delta(dp, ap)) fd = fa
			}

			#print bp, ibp, dp, ap, iap, fa, fd, !fd
			if (!fd) fd = int(tp - (fb + fa))

			#print fb, fa, fb + fa "      " tp, tp - (fb + fa)
			#print "F", fb, fa, fb + fa, fd, tp, tp - (fb + fa)

			#print fb, fa, fd

			#print fb, fd, fa
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

			#if(bs) {
			#	get_final(bs, be)
			#	bb = fb; ba = fa
			#}

			#get_final(ws, we, 1)
			#wb = fb; wd = fd; wa = fa

			#if(bs) {
			#	#print wb, bb, wa, ba, wd, ws, we, ds, de
			#	fbb = wb - bb; fba = wa - ba
			#	wb = bb; wa = ba
			#}

			if(bs) {
				get_final(bs - ds, de - be, de - ds)
				#fbb = fb; fba = fa
				wb = fb; wa = fa

				#print "W", bs , ds, de , be, de , ds

				get_final(ws - bs, be - we, be - bs, 1)
				#print fb, fd, fa, ws , bs, be , we, be , bs, 1
				#fbb = fb - bb; fba = fa - ba
				fbb = fb; wd = fd; fba = fa
			} else {
				get_final(ws - ds, de - we, de - ds)
				wb = fb; wd = fd; wa = fa
			}

			print wb, wd, wa, fbb, fba
		}'
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

			#print "'$y_step'", "'$block_start'", "'$block_dimension'"
			#print "'$x_step'", "'$block_start'", "'$block_dimension'"
			#print bp, ap, mp, tp

			tm = 0
			#if(cs > ds && ce < de) {
			if(cs > (w) ? bs : ds && ce < (w) ? be : de) {
				#print "IN", cs, ds, ce, de, bs, be
				if (b) { bp -= mp; tm++ }
				if (a) { ap -=  mp; tm++ }
				#tm = 2 * mp
			} else tm = 1

			tm *= mp
			#print "T", tp, tm, ap, mp

			dp = (tp - tm) - (bp + ap)
			#print dp, tp, tm, bp, ap
			#print b, bp, a, ap, mp, s, cs, ds, de, ce, '$total', dp, '$total' - tm - bp - (18 + 0.7) == 17, sprintf("%.1f", a / s) == 18.7

			br = bp % 1; dr = dp % 1; ar = ap % 1
			dr = dp % 1; ar = ap % 1

			#print '$total', dp, bp, ap
			#print b, bp, a, ap, '$total', dp, s, de, ce, cs, ds
			#print bp, br, dp, dp % 1, dr, ap, ar

			se = get_delta(br, ar)

			#print bp, ap, dp
			#print bp, ap, dp
			#print br, ar, dr
			if(b && a && br + ar >= 0.6 && se) { bp++; ap++ }
			else {
				ibp = idp = iap = 0
				if(dr > 0.5) { idp++ }
				if(br > 0.5) { ibp++ }
				if(ar > 0.5) { iap++ }
			}

			#print br, ar, get_delta(br, ar)
			#print "END", se, br, ar, bp, ap, dp

			#print "P", bp, ap

			fd = 0
			fb = int(bp + ibp)
			fa = int(ap + iap)

			#print "END", fb, fa

			if (b && a) {
				fd = int(tp - (fb + fa))
			} else if (b) {
				if (get_delta(dp, bp)) fd = fb
			} else if (a) {
				#print "HERE", dp, ap, get_delta(dp, ap), fd, fa
				if (get_delta(dp, ap)) fd = fa
			}

			#print bp, ibp, dp, ap, iap, fa, fd, !fd
			if (!fd) fd = int(tp - (fb + fa))

			#print fb, fa, fb + fa "      " tp, tp - (fb + fa)
			#print "F", fb, fa, fb + fa, fd, tp, tp - (fb + fa)

			#print fb, fa, fd

			#print fb, fd, fa
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

				#print "W", bs , ds, de , be, de , ds

				get_final(ws - bs, be - we, be - bs, 1)
				#print fb, fd, fa, ws , bs, be , we, be , bs, 1
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
		#dimension=$w total=16 || dimension=$h total=9

	unset {x,y}_offset
	read border end start step <<< $(eval echo \${!${orientation}_*})
	#echo V: $border, $end, $offset, $start, $step
	#echo V: ${!start}, ${!orientation}, $dimension, ${!end}, ${!step}, ${!border}, $margin, $total
	#killall xprop swb.sh
	#exit

	##echo step: $step, ${!step}, $dimension, $total
	#get_dimension $orientation
	#killall spy_windows.sh xprop
	#exit

	#read ${orientation}_window_{before,size,after} \
	#	${orientation}_block_{before,after} <<< $(get_dimension)

	read ${orientation}_{window_{before,size,after},block_{before,after}} <<< $(get_dimension)
	#echo $x_window_before, $x_window_size, $x_window_after
}

#alignment_direction=h
#block_dimension=1200

font="Roboto Mono 8"
offset="<span font='$font'>$(printf "%-3s")</span>"

notify() {
	#echo START
	#ps -C dunst -o args=
	#ps -C notify.sh -o args=
	local notification="$1" time="$2" offset="   "
	dunstify -t ${time:-10000} -r 222 "summary" \
		"<span font='Iosevka Orw $font_size'>\n$notification\n</span>" &> /dev/null
		#"\n${notification//\\n/$offset\\n$offset}\n" #&> /dev/null &
		#"$padding_font<span font='$font'>$padding$offset${message//\\n/$offset\\n$offset}$offset$padding</span>$bottom_padding"

	#echo END
	#ps -C dunst -o args=
	#ps -C notify.sh -o args=
}

display_notification() {
	local window_row empty_block_row table {h,v}_separator
	icon=' '
	icon='██'
	#separator="<span font='Iosevka Orw 10'> </span>"
	
	[[ $evaluate_type != offset ]] &&
		v_separator="<span font='Iosevka Orw 6'>\n</span>" \
		h_separator="<span foreground='$empty_bg'>  </span>"

	#echo OSD $y_step $x $y $w $h

	#block_start=$x_start
	#get_dimension_size x
	#get_dimension_size y
	#killall sws.sh xprop
	#exit

	#x_block_after=6

	#echo $block_start, $block_dimension
	#[[ $resize_window ]] &&
	#	x_block_before=$x_window_before x_block_after=$x_window_after
	#echo $x_block_before, $x_block_after
	#echo $x_window_before, $x_window_size, $x_window_after
	#echo $y_window_before, $y_window_size, $y_window_after
	#killall spy_windows.sh xprop
	#exit

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

	#[[ $no_restart ]] || window_row+="$h_separator"

	#window_row="sola <span foreground='\$pbfg'>CAR</span>!!!!"
	#echo $x_block_after, $window_row
	#exit
	#notification="<span foreground='$empty_bg'>$window_row</span>"
	#~/.orw/scripts/notify.sh -r 222 -s windows_osd \
	#	"<span font='Iosevka Orw $font_size'>\n$notification\n</span>" &
	#exit

	((y_window_before)) && table="$(color_bar "$empty_row\n" $y_window_before)\n"
	((y_block_before)) && table+="$(color_bar "$empty_block_row\n" $y_block_before)\n$v_separator"
	table+="$(color_bar "$window_row\n" $y_window_size)"
	((y_block_after)) && table+="$v_separator\n$(color_bar "$empty_block_row\n" $y_block_after)"
	((y_window_after)) && table+="$v_separator\n$(color_bar "$empty_row\n" $y_window_after)"

	#echo $block_start, $block_dimension
	#echo $x_window_before, $x_window_size, $x_window_after
	#echo $x_block_before, $x_block_after
	#echo $y_window_before, $y_window_after
	#echo $y_block_after, $y_window_after
	#echo -e "$table"
	#echo $window_row
	#echo -e "$empty_row\n$window_row"
	#killall swb.sh xprop
	#exit

	#echo $empty_block_row
	#echo $window_row
	#echo $x_step $y_step
	#killall sws.sh xprop
	#exit


	#table="$empty_row\n$empty_block_row\n$window_row\n$empty_block_row"
	notification="<span foreground='$empty_bg'>$table</span>"
	notify "$notification"
	#notify "<span font='Iosevka Orw $font_size'>\n$notification\n</span>"

	unset separator_width
	return

	#notification="$window_row"
	~/.orw/scripts/notify.sh -r 222 -t 10 -s windows_osd \
		"<span font='Iosevka Orw $font_size'>\n$notification\n</span>" #&> /dev/null &

	#killall swb.sh xprop
	#exit

	#notify_pid=$!

	#echo $alignmet_direction, $enforced_direction
	#killall swf.sh xprop

	#echo $y_window_before, $y_window_size, $y_window_after
	#echo $y_block_before, $y_block_after
	#killall sws.sh xprop
	#exit

	#echo $x_window_before, $x_block_before, $x_window_size, $x_block_after, $x_window_after
	#echo $window_row
	#echo $empty_block_row
	#table="$window_row\n$empty_block_row"
	#notification="<span foreground='\$sbg'>$table</span>"
	#~/.orw/scripts/notify.sh -r 222 -s windows_osd \
	#	"<span font='Iosevka Orw $font_size'>\n$notification\n</span>" &
	#killall sws.sh xprop
	#exit

	#unset {x,y}_{window,block}_{before,after,size}
	return






	block_before=8
	window_before=13
	block_after=0
	window_after=0

	empty_row="<span foreground='$empty_bg'>$(color_bar "$icon" 16)"
	#((before)) && window_row="<span foreground='\$sbg'>$(color_bar "$icon" $before)"
	#window_row+="<span foreground='\$pbfg'>$(color_bar "$icon" $size)</span>"
	#((after)) && window_row+="$(color_bar "$icon" $after)</span>"
	((before)) && window_row=$(color_bar "$icon" $before)
	window_row+="<span foreground='$pbfg'>$(color_bar "$icon" $size)</span>"
	((after)) && window_row+="$(color_bar "$icon" $after)"
	#echo $before, $size, $after

	get_dimension_size y
	((before)) && table="$(color_bar "$empty_row\n" $before)\n"
	table+="$(color_bar "$window_row\n" $size)"
	((after)) && table+="\n$(color_bar "$empty_row\n" $after)"
	#echo $before, $size, $after
	#exit

	notification="<span foreground='\$sbg'>$table</span>"
	#~/.orw/scripts/notify.sh -r 222 -s windows_osd \
	#	"<span font='Iosevka Orw $font_size'>\n$notification\n</span>" &
	~/.orw/scripts/notify.sh -r 222 -s windows_osd \
		"<span font='Iosevka Orw $font_size'>\n$notification\n</span>" &
}

#adjust_values() {
#	#x_start=$((display_x + x_offset))
#	#y_start=$((display_y + bar_top_offset + y_offset))
#	#x_end=$((display_x + width - x_offset))
#	#y_end=$((display_y + height - (bar_top_offset + y_offset)))
#
#	#x_start=$((display_x + x_offset))
#	#y_start=$((display_y + bar_top_offset + y_offset))
#	#x_end=$((display_x + width - x_offset))
#	#y_end=$((display_y + height - (bar_bottom_offset + y_offset)))
#
#	get_dimension_size y
#	echo $before, $size, $after
#	exit
#
#	#osd_window_x=$(calculate $x)
#	#osd_window_x_end=$(calculate $((x + w)))
#	#osd_window_y=$(calculate $y)
#	#osd_window_y_end=$(calculate $((y + h)))
#	#osd_window_w=$(calculate $w)
#	#osd_window_h=$(calculate $h)
#
#	#osd_x_start=$(calculate $x_start)
#	#osd_y_start=$(calculate $y_start)
#	#osd_x_end=$(calculate $x_end)
#	#osd_y_end=$(calculate $y_end)
#	##osd_y_end=$(calculate $((y_end - y_start)))
#
#
#	#x_before=$((osd_window_x - osd_x_start))
#	##x_size=$(calculate $w)
#	#x_size=$((osd_window_x_end - osd_window_x))
#	#x_after=$((osd_x_end - osd_window_x_end))
#	##x_after=$((osd_x_end - (osd_window_x + osd_window_w)))
#
#	x_before=$(calculate $((x - x_start)) $x_step)
#	x_size=$(calculate $w $x_step)
#	x_after=$(calculate $((x_end - (x + w))) $x_step)
#
#	#y_before=$((osd_window_y - osd_y_start))
#	##y_size=$(calculate $h)
#	#y_size=$((osd_window_y_end - osd_window_y))
#	#y_after=$((osd_y_end - osd_window_y_end))
#	##y_after=$((osd_y_end - (osd_window_y + osd_window_h)))
#
#	y_before=$(calculate $((y - y_start)) $y_step)
#	y_size=$(calculate $h $y_step)
#	y_after=$(calculate $((y_end - (y + h))) $y_step)
#
#	echo $x_start, $x_end, $y_start, $y_end
#	echo $x_size, $x_step, $y_size, $y_step
#	echo $display_y + $height - $((bar_top_offset + y_offset))
#	echo $x_before, $x_after, $y_size, $y_before, $y_after
#	echo $y_end, $y + $h, $y_step
#	#exit
#
#	#echo $y - $y_start
#
#	#echo $y_before $y_size $y_after $h
#	#echo $osd_window_y $osd_y_start $osd_y_end
#
#	#echo $x_start $x_end $x $w
#	#echo $x_before $x_size $x_after $h
#	#echo $osd_window_x $osd_x_start $osd_x_end
#
#	icon=' '
#	icon=''
#	icon='█▊'
#	icon=' '
#	icon='▆▆'
#	icon=' '
#	local filled_{x,y}
#	#empty_x=$(color_bar ' ' $((x_before + x_size + x_after)))
#	empty_x="<span foreground='\$sbg'>$(color_bar "$icon" $((x_before + x_size + x_after)))</span>"
#
#	((x_before)) && filled_x="<span foreground='\$sbg'>$(color_bar "$icon" $x_before)</span>"
#	filled_x+="<span foreground='\$pbfg'>$(color_bar "$icon" $x_size)</span>"
#	((x_after)) && filled_x+="<span foreground='\$sbg'>$(color_bar "$icon" $x_after)</span>"
#
#	((y_before)) && filled_y="$(color_bar "$empty_x\n" $y_before)\n"
#	filled_y+="$(color_bar "$filled_x\n" $y_size)"
#	((y_after)) && filled_y+="\n$(color_bar "$empty_x\n" $y_after)"
#
#	~/.orw/scripts/notify.sh -r 222 -s windows_osd \
#		"<span font='Iosevka Orw $font_size'>\n$filled_y\n</span>" &
#}

evaluate() {
	input=$1

	if [[ $input == d ]]; then
		stop=true
		~/.orw/scripts/notify.sh -r 222 -t 1m -s windows_osd 
		unset {x,y}_{window,block}_{before,after,size}
		#[[ $notify_pid ]] && kill $notify_pid
	else
		[[ $input == [JKkj] ]] &&
			step=$y_step || step=$x_step

		case $input in
			m)
				moved=true
				option=move;;
			r) option=resize;;
			#[<>])
			"<"|">")
				option=resize
				[[ $input == "<" ]] && sign=- || sign=+
				return
				;;
			[A-Z])
				local default_step=$step
				local step sign

				if [[ $option == resize && $source ]]; then
					#echo ${properties[*]}
					#[[ $input == [LR] ]] && index=1 || index=2
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
			#echo $id, $x, $y, $w, $h, ${properties[*]}
			[[ $sign == - ]] &&
				opposite_sign=+ || opposite_sign=-

			case $input in
				j) ((h $sign= step));;
				l) ((w $sign= step));;
				[hk])
					#[[ $input == h ]] &&
					#	sign=- properties='w x' ||
					#	sign=+ properties='h y'

					[[ $input == h ]] &&
						properties='w x' ||
						properties='h y'

					#echo $x, $w
					((${properties% *} $sign= step))
					((${properties#* } $opposite_sign= step))
					#echo $x, $w

					local position=before
			esac

			[[ $position ]] || local position=after

			[[ $input == [jk] ]] && local direction=y vertical=true
			[[ $input == [hl] ]] && local direction=x horizontal=true

			((default_step)) && step=$default_step

			#[[ $input == [hjkl] ]] && (( edges[$input] += $sign$step ))
			(( edges[$input] += $sign$step ))

			#[[ $sign == - ]] &&
			#echo $y_block_before, $y_window_size, $y_block_after
			eval "((${direction}_window_size $sign= 1))"
			eval "((${direction}_block_$position $opposite_sign= 1))"
			#echo $y_block_before, $y_window_size, $y_block_after
			#echo $id, $x, $y, $w, $h, ${properties[*]}
		fi

		#adjust_values
		display_notification
	fi
}

execute() {
	#[[ "${BASH_SOURCE[0]}" == "$0" ]] && wmctrl -ir $id -e 0,$x,$y,$w,$h
	#[[ "${BASH_SOURCE[0]}" =~ windowctl.sh ]] || wmctrl -ir $id -e 0,$x,$y,$w,$h
	#[[ ! $source ]] && wmctrl -ir $id -e 0,$x,$y,$w,$h
	((x_border /= 2))
	((y_border -= x_border))

	[[ $source ]] ||
		echo wmctrl -ir $id -e 0,$((x - x_border)),$((y - y_border)),$w,$h
}

set_geometry() {
	#total_width=$((x_end - x_start))
	##column_count=$((total_width / step))
	##osd_width=$((column_count * font_size))
	#osd_width=$((columns * font_size))
	#osd_x=$(((width - (osd_width + 2 * 10 * font_size)) / 2))

	#total_width=$((x_end - x_start))
	#osd_width=$((((columns * 1.3) + (separator_width * 2)) * font_size * 1))
	#echo "(($columns * 1.3) + ($separator_width * 2)) * $font_size" | bc
	#
	#osd_width=$(awk 'BEGIN {
	#		printf "%.0f", ('$columns' + '${separator_width:-0}') * '$font_size' * 1.3
	#	}')

	#total_width=$((x_end - x_start))
	#expr="(($columns + ${separator_width:-0} + $font_size) * $font_size * 1.3) / 1"
	#osd_width=$(echo "$expr" | bc)
	#osd_x=$((x_start + (total_width - osd_width) / 2))

	#osd_width=$((columns * font_size))
	#osd_x=$(((width - (osd_width + 2 * 10 * font_size)) / 2))

	#expr="(($columns + ${separator_width:-0} + $font_size) * $font_size * 1.3) / 1"
	#expr="((($columns + 2) * $font_size + 2 * 10) * 1.3) / 1"
	osd_width=$(echo "((($columns + 2) * $font_size + 2 * 10) * 1.2) / 1" | bc)
	#osd_x=$(((width - osd_width) / 2))
	osd_x=$(((x_start + (x_end - x_start) - osd_width) / 2))
	osd_x=$(((x_end + x_start - osd_width) / 2))
	echo $columns, $font_size, $osd_width, $osd_x

	#~/.orw/scripts/notify.sh -t 11 "$columns, $font_size, $osd_width, $osd_x"
	#~/.orw/scripts/notify.sh -t 11 "$total_width, $x_end, $x_start"

	awk -i inplace '\
		function replace(position, value) {
			$0 = gensub("([0-9]+)", sprintf("%.0f", value), position)
		}

		/^\s*geometry/ {
			replace(3, '$osd_x')
			replace(1, '$osd_width' * 1.2)
			#replace(1, '$osd_width' * 2.5)
		} { print }' ~/.config/dunst/windows_osd_dunstrc

	#adjust_values
	#display_notification
}

step=120
font_size=6

[[ $1 == source ]] && source=true

declare -A edges

#if [[ ! "${BASH_SOURCE[0]}" =~ windowctl.sh ]]; then
#if [[ $1 == apply ]]; then
if [[ ! $source ]]; then
	id=$(printf '0x%.8x' $(xdotool getactivewindow))

	read {x,y}_offset offset <<< $(awk '/^([xy]_)?offset/ { print $NF }' ~/.config/orw/config | xargs)
	[[ $offset == true ]] && eval $(cat ~/.config/orw/offsets)

	#read {x,y}_border {x,y}_offset offset <<< $(awk '/^([xy]_|offset)/ { print $NF }' ~/.config/orw/config | xargs)
	#real_y_border=$y_border
	#y_border=$(((y_border - x_border / 2) * 2))

	#[[ $offset == true ]] && eval $(cat ~/.config/orw/offsets)

	#read x y w h <<< $(wmctrl -lG | awk '$1 == "'$id'" {
	#	print $3 - '$x_border', $4 - '$y_border', $5, $6 }')

	read x y w h {x,y}_border <<< $(xwininfo -id $id | awk '
		/Absolute/ { if(/X/) x = $NF; else y = $NF }
		/Relative/ { if(/X/) xb = $NF; else yb = $NF }
		/Width/ { w = $NF }
		/Height/ { print x - xb, y - yb, w, $NF, 2 * xb, yb + xb }')
		#/Height/ { print x - 0, y - 0, w, $NF, 2 * xb, yb + xb }')

	#echo $y, $h
	#exit

	read display display_x display_y width height rest <<< $(~/.orw/scripts/get_display.sh $x $y)

	#while read name position bar_x bar_y bar_widht bar_height rest; do
	#	current_bar_height=$((bar_y + bar_height))

	#	if ((position)); then
	#		((current_bar_height > bar_top_offset)) && bar_top_offset=$current_bar_height
	#	else
	#		((current_bar_height > bar_bottom_offset)) && bar_bottom_offset=$current_bar_height
	#	fi

	while read -r bar_name position bar_x bar_y bar_width bar_height adjustable_width frame; do
		current_bar_height=$((bar_y + bar_height))
		((position)) && (( current_bar_height += frame ))

		if ((position)); then
			((current_bar_height > bar_top_offset)) && bar_top_offset=$current_bar_height
		else
			((current_bar_height > bar_bottom_offset)) && bar_bottom_offset=$current_bar_height
		fi
	done <<< $(~/.orw/scripts/get_bar_info.sh $display)

	#x_step=$(((width - 2 * x_offset) / 16))
	#y_step=$(((height - (bar_top_offset + bar_bottom_offset) - 2 * y_offset) / 9))
	#echo $width, $x_offset, $x_step
	#echo $height, $y_offset, $y_step
	#exit

	x_start=$((display_x + x_offset))
	x_end=$((display_x + width - x_offset))
	y_start=$((display_y + y_offset + bar_top_offset))
	y_end=$((display_y + height - (y_offset + bar_bottom_offset)))
fi

#echo START $x $y $w $h

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

#x_step=$(((width - 2 * x_offset) / $columns))
#y_step=$(((height - (bar_top_offset + bar_bottom_offset) - 2 * y_offset) / $rows))
#echo $((height - (bar_top_offset + bar_bottom_offset) - 2 * y_offset))
#echo $width, $height, $x_offset $y_offset
#echo $x_step $y_step
#killall sws.sh xprop
#exit

#echo $width, $height, $x_offset $y_offset $x_step $y_step > ~/osd.log
#echo $x_start, $y_start, $x_end, $y_end, $x_step $y_step > ~/osd.log
#exit

#echo $height, $bar_top_offset, $bar_bottom_offset, $y_offset
#killall sws.sh xprop

#block_dimension=860
#block_start=1160

#set_window_steps
#set_geometry
