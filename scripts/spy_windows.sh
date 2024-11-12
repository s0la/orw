#!/bin/bash

parse_properties() {
	awk '
		/xwininfo/ { id = $4 }
		/Absolute/ { if(/X/) ax = $NF; else ay = $NF }
		/Relative/ { if(/X/) rx = $NF; else ry = $NF }
		/geometry/ {
			split($NF, pa, "[^0-9]")
			#print id, pa[3] - 0, pa[4] - 0, pa[1], pa[2], 2 * xb, yb + xb + '$handle_width'
			#x += (x == pa[3]) ? xb : -xb
			#y += (y == pa[4]) ? yb : -yb
			#xb = (ax == pa[3]) ? 0 : 2 * rx
			#yb = (ay == pa[4]) ? 0 : ry + rx + '$handle_width'

			x = pa[3]; y = pa[4]

			if (ax == pa[3]) {
				x += rx
				xb = 0
			} else {
				xb = 2 * rx
			}

			if (ay == pa[4]) {
				y += ry
				yb = 0
			} else {
				yb = ry + rx + '$handle_width'
			}

			print id, x, y, pa[1], pa[2], xb, yb
		}'
}

parse_properties() {
	awk '
		/xwininfo/ { id = $4 }
		/Absolute/ { if(/X/) x = $NF; else y = $NF }
		/Relative/ { if(/X/) xb = $NF; else yb = $NF }
		/Width/ { w = $NF }
		/Height/ { print id, x - xb, y - yb, w, $NF, 2 * xb, yb + xb + '$handle_width' }'
}

parse_properties() {
	awk '
		/xwininfo/ { id = $4 }
		/Absolute/ { if(/X/) x = $NF; else y = $NF }
		/Relative/ { if(/X/) xb = $NF; else yb = $NF }
		/Width/ { w = $NF }
		/Height/ { print id, x - xb, y - yb, w, $NF, 2 * xb, yb + xb + '$handle_width' }'
}

border_gap() {
	awk '
		/xwininfo/ { id = $4 }
		/Absolute/ { if(/X/) x = $NF; else y = $NF }
		/Relative/ { if(/X/) xb = $NF; else yb = $NF }
		/Corners/ { ax = $NF; gsub("^.|.[0-9]*$", "", ax) }
		/geometry/ { ay = $NF; sub("^.*[^0-9]", "", ay) }
		END {
			if (y == ay) print id, xb, yb
			#print id, x - 0, y - 0, w, h, 2 * xb, yb + xb + '$handle_width'
		}'
}

get_border_gap() {
	 awk '
	 	/xwininfo/ { id = $4 }
		/Absolute.*Y/ { ay = $NF }
		/Relative/ { if(/X/) xb = $NF; else yb = $NF }
		$0 ~ "geometry.*" ay "$" { print id, xb, yb }
	 '
}

add_border_gap() {
	#echo $@
	local ids="$1" wid {x,y}bg
	#[[ $ids != *' '* ]] && xwininfo -id $ids #| get_border_gap
	while read wid xbg ybg; do
		#echo GAP $wid: $xbg, $ybg
		[[ $wid ]] && border_gaps[$wid]="$xbg $ybg"
	done <<< $(xargs -rn1 xwininfo -id <<< "$ids" | get_border_gap)
}

get_windows() {
	if [[ $1 == 0x* ]]; then
		local specific_id=${1#0x}
	elif [[ $1 == all ]]; then
		local workspace
	fi

	wmctrl -l | awk '
		$2 ~ "'"$workspace"'" && !/('"${blacklist//,/|}"')$/ && $1 ~ /0x0*'$specific_id'/ \
			{ print $1 }' | xargs -rn 1 xwininfo -id 2> /dev/null | parse_properties
}

unset_vars() {
	unset aligned_windows edges tiling {align_,}ratio action event temp* stop
	all_aligned_windows=()
}

update_windows() {
	[[ $id ]] || id=$(xdotool getactivewindow 2> /dev/null | awk '{ printf "0x%x", $1 }')

	[[ -z $@ ]] && windows=()

	while read window_id window_properties; do
		if [[ $window_id ]]; then
			windows[$window_id]="$window_properties" #${windows[$wid]##* }"
			all_windows[$window_id]="$window_properties" #${windows[$wid]##* }"
			[[ $window_id == $id ]] &&
				properties=( $window_properties ) &&
					read {x,y}_border <<< ${properties[*]: -2}
		fi
	done <<< $(get_windows $1)

	window_count=${#windows[*]}
}

select_window() {
	~/.orw/scripts/select_window.sh
	second_window_id=$(printf '0x%x' $(xdotool getactivewindow))
	second_window_properties=( $(get_windows $second_window_id | cut -d ' ' -f 2-) )
}

select_tiling_window() {
	if [[ ! $second_window_properties ]]; then
		# let user select window to which should selected window tile to
		~/.orw/scripts/select_window.sh
		local second_window_id=$(printf '0x%x' $(xdotool getactivewindow))
		local second_window_properties=( $(get_windows $second_window_id | cut -d ' ' -f 2-) )

		# set id and properties
		id=$second_window_id
		current_id=${original_properties[0]}
		#properties=( $second_window_id ${second_window_properties[*]} )
		properties=( $id ${all_windows[$id]} )
	fi
}

select_tiling_win() {
	if [[ ! $second_window_properties ]]; then
		# let user select window to which should selected window tile to
		~/.orw/scripts/select_window.sh
		printf '0x%x' $(xdotool getactivewindow)
	fi
}

update_alignment() {
	#reversing stored alignment in case this is the only window
	local action=$1 force=$2
	local opposite_direction aligned_window_count=${#aligned_windows[*]}

	#this line ignores expected behaviour in case of moving windows
	([[ $action ]] && ((aligned_window_count == 1))) ||
		([[ ! $action ]] && ((aligned_window_count == 2))) ||
		[[ $force ]] &&
		for window_id in ${!aligned_windows[*]}; do
			window_direction=${alignments[$window_id]}

			if [[ ${alignments[$window_id]} ]]; then
				if [[ $action && $aligned_window_count -eq 1 ]]; then
					[[ $window_direction == h ]] &&
						opposite_direction=v || opposite_direction=h
					alignments[$window_id]=$opposite_direction
				elif [[ ($aligned_window_count -eq 2 || $force) &&
						$window_direction != $alignment_direction ]]; then
					alignments[$window_id]=$alignment_direction
				fi
			fi
		done
}

update_alignment() {
	#reversing stored alignment in case this is the only window
	local action=$1 force=$2 aligned_size=${properties[opposite_index + 2]} window_size
	local opposite_direction aligned_blocks=$block_segments
	aligned_blocks=${#aligned_windows[*]}

	#this line ignores expected behaviour in case of moving windows
	([[ $action ]] && ((aligned_blocks == 1))) ||
		([[ ! $action ]] && ((aligned_blocks == 2))) ||
		[[ $force ]] &&
		for window_id in ${!aligned_windows[*]}; do
			window_direction=${alignments[$window_id]}
			window_size=$(cut -d ' ' -f $((opposite_index + 2)) <<< ${windows[$window_id]})

			if ((window_size == aligned_size)); then
				if [[ ${alignments[$window_id]} ]]; then
					if [[ $action && $aligned_blocks -eq 1 ]]; then
						[[ $window_direction == h ]] &&
							opposite_direction=v || opposite_direction=h
						alignments[$window_id]=$opposite_direction
					elif [[ ($aligned_blocks -eq 2 || $force) &&
							$window_direction != $alignment_direction ]]; then
						alignments[$window_id]=$alignment_direction
					fi
				fi
			fi
		done
}

update_alignment() {
	#reversing stored alignment in case this is the only window
	local action=$1 force=$2
	local opposite_direction aligned_window_count=${#aligned_windows[*]}

	#this line ignores expected behaviour in case of moving windows
	([[ $action ]] && ((aligned_window_count == 1))) ||
		([[ ! $action ]] && ((aligned_window_count == 2))) ||
		[[ $force ]] &&
		for window_id in ${!aligned_windows[*]}; do
			window_direction=${alignments[$window_id]}

			if [[ ${alignments[$window_id]} ]]; then
				if [[ $action && $aligned_window_count -eq 1 ]]; then
					[[ $window_direction == h ]] &&
						opposite_direction=v || opposite_direction=h
					alignments[$window_id]=$opposite_direction
				elif [[ ($aligned_window_count -eq 2 || $force) &&
						$window_direction != $alignment_direction ]]; then
					alignments[$window_id]=$alignment_direction
				fi
			fi
		done
}

remove_tiling_window() {
	unset event
	declare -A aligned_windows

	get_workspace_windows

	properties=( $id ${windows[$id]} )
	original_properties=( ${properties[*]} )

	alignment_direction=${alignments[$id]}
	set_alignment_properties $alignment_direction

	read _ _ _ aligned <<< $(get_alignment move)
	eval aligned_windows=( $aligned )
	update_alignment move

	for window_id in ${!aligned_windows[*]}; do
		read ws wd <<< ${aligned_windows[$window_id]}
		new_properties=( ${windows[$window_id]} )
		new_properties[index - 1]=$ws
		new_properties[index + 1]=$wd
		all_aligned_windows[$window_id]="${new_properties[*]}"
		resize_after_tiling+=( $window_id )
	done

	#[[ $move_window ]] && xdotool windowminimize $id
	update_aligned_windows $@ #no_change

	unset windows[$id]
}

get_bar_transparency() {
	bar_conf=$(sed -n 's/^last_.*=\([^,]*\).*/\1/p' ~/.orw/scripts/barctl.sh)
	colorscheme=$(sed -n 's/\(\([^-]*\)-[^c]*\)c\s*\([^, ]*\).*/\3/p' \
		~/.config/orw/bar/configs/$bar_conf)

	awk --non-decimal-data '
		/^#bar/ { b = 1 }
		b && /^bg/ {
			gsub(".*#|\\w{6}$", "")
			d = sprintf("%d", "0x" (($0) ? $0 : 90))
			print int(d / 255 * 100)
			exit
		}' ~/.config/orw/colorschemes/$colorscheme.ocs
}

set_opacity() {
	case $window_title in
		input) opacity=0;;
		DROPDOWN) opacity=90;;
		DROPDOWN) opacity=$(get_bar_transparency);;
		*) opacity=100
	esac

	~/.orw/scripts/set_window_opacity.sh ${1:-$current_id} $opacity
}

list_windows() {
	[[ $windows_to_ignore ]] ||
		local windows_to_ignore="${!states[*]}"

	for wid in ${!windows[*]}; do
		[[ ${windows[$wid]} ]] && echo $wid ${windows[$wid]}
	done | grep -v "^\(${windows_to_ignore// /\\|}\)\s\+\w"
}

set_new_position() {
	local monitor=${display_map[$display]}
	#echo $id, $current_id: $monitor
	awk -i inplace '
		/class="(\*|input)"/ { t = 1 } t && /<\/app/ { t = 0 }

		#t && /<decor>/ { v = ("'"${tiling_workspaces[*]}"'" !~ "'$workspace'") ? "yes" : "no" }

		t && /<(width|height)>/ { v = (/width/) ? "'$3'" : "'$4'" }
		#t && /<monitor>/ { sub("[0-9]+", "'"$monitor"'") }
		t && /<[xy]>/ { v = (/x/) ? "'$1'" : "'$2'" }

		t && v { 
			sub(">.*<", ">" v "<")
			v = ""
		}

		{ print }' ~/.config/openbox/rc.xml

	openbox --reconfigure &
}

get_full_window_properties() {
	x=$x_start
	[[ $rofi_state == opened ]] &&
		((x += rofi_offset))

	y=$y_start
	w=$((x_end - x - x_border))
	h=$((y_end - y_start - y_border))
}

set_orientation_properties() {
	if [[ $1 == h ]]; then
		index=1
		dimension=width
		offset=$x_offset
		start=$display_x
		opposite_dimension=height
		opposite_start=$display_y
		border=${properties[index + 4]:-$default_x_border}
		bar_vertical_offset=0
	else
		index=2
		dimension=height
		offset=$y_offset
		start=$display_y
		opposite_dimension=width
		opposite_start=$display_x
		border=${properties[index + 4]:-$default_y_border}
		bar_vertical_offset=$((bar_top_offset + bar_bottom_offset))
	fi

	start_index=$((index % 2 + 1))
	end=$((start + ${!dimension:-0}))
	opposite_end=$((opposite_start + ${!opposite_dimension:-0}))
}

set_alignment_properties() {
	if [[ $1 == h ]]; then
		index=1
		opposite_index=2
		border=$x_border
		opposite_border=$y_border
		offset=$x_offset
		opposite_offset=$y_offset
		display_property=$display_x
		display_dimension=$width
	else
		index=2
		opposite_index=1
		border=$y_border
		opposite_border=$x_border
		offset=$y_offset
		opposite_offset=$x_offset
		display_property=$display_y
		display_dimension=$height
	fi

	separator=$((border + ${margin:-$offset}))
}

get_alignment() {
	[[ $windows_to_ignore ]] ||
		local windows_to_ignore="${!states[*]}"
	list_windows | sort -nk $((index + 1)),$((index + 1)) \
		-nk $((opposite_index + 1)),$((opposite_index + 1)) -nk 1,1r |
		awk '
			function sort(a) {
				#removing/unseting variables
				delete cwp
				delete fdw
				ai = fdwi = pdwc = csf = min = 0

				cmax = cumax = 0

				for(ai in a) {
					split(a[ai], cwp)

					#parse properties
					id = cwp[1]
					cb = cwp[i + 5]
					cob = cwp[oi + 5]
					cws = cwp[i + 1]
					cwd = cwp[i + 3]
					cwos = cwp[oi + 1]
					cwod = cwp[oi + 3]

					if(cwos == wos) {
						if((!cmax && cws > max + s) ||
							(cmax && cws >= cmax)) {
								if ("'"$2"'") print "BREAK", id, cws, max + s
								if (cws > ws + wd && id != "temp") break
								else {
									if ("'"$2"'") print "break", id, min, max
									cumax = min = csf = tsf = 0
									delete fdw
									pdw = ""
								}
						}
					}

					if(!min) min = cws

					cwsf = (cwd + s) * (cwod + os)
					csf += cwsf

					if(!cmax || cws <= cmax) {
						if(cws + cwd + s > cumax) cumax = cws + cwd + s
						if (cwod == wod) fdw[++fdwi] = id " " cws " " cwd - cb " " cb " " min " " cumax - s
						else pdw = pdw "," id ":" cws "-" cwd - cb "-" cb
					}

					if(cwos + cwod == wos + wod &&
						(!max || (cws == max + s || cmax))) {
							if("'"$2"'") print "TSF", id, (cwd + s), (wod + os)
							tsf += (cwd + s) * (wod + os)
							cmax = cumax
					}

					if("'"$2"'") print "ID", id, min, max, cwsf, csf, tsf

					if(csf == tsf) {
						if (pdw) fdw[++fdwi] = min "_" cumax - s "_" substr(pdw, 2)
						tsf = csf = cumax = cmax = 0
						max = cws + cwd
						pdw = ""
					}
				}

				#repopulate original array
				delete a
				for(wi in fdw) a[wi] = fdw[wi]

				return min " " max
			}

			BEGIN {
				#variable assignment
				i = '$index'
				oi = '$opposite_index'
				o = '${margin:-$offset}'
				oo = '${margin:-$opposite_offset}'
				wc = '${#windows[*]}'
				ws = '${properties[index]}'
				b = '${properties[index + 4]}'
				ob = '${properties[opposite_index + 4]}'
				wd = '${properties[index + 2]}' + b
				wos = '${properties[opposite_index]}'
				wod = '${properties[opposite_index + 2]}' + ob
				woe = wos + wod
				we = ws + wd

				#new window size
				nws = '$new_window_size'

				#full and reverse
				f = "'$full'"
				r = "'$reverse'"

				#closing properties
				c = ("'$1'")
				cp = "'$closing_properties'"

				#align ratio
				if(length("'$align_ratio'")) ar = '${align_ratio:-0}'

				#min/max event
				e = "'"$event"'"

				if ('${resize_area:-0}') {
					ra = '${resize_area:-0}'
					bd = ra; ad = -1 * ra
				}

				wsp = "'"${sorted_ids[*]}"'"
				if(wsp) gsub(" ", "|", wsp)
			}

			{
				#border assignemt
				cb = $(i + 5)
				cob = $(oi + 5)

				#current window properties assignment
				$(i + 3) += cb
				$(oi + 3) += cob

				cws = $(i + 1)
				cwd = $(i + 3)
				cwos = $(oi + 1)
				cwod = $(oi + 3)
				cwe = cws + cwd
				cwoe = cwos + cwod

				#separator assignment
				s = o
				os = oo

				if ("'"$2"'") print "PROCESSING WINDOW:", $0
				if("'"$2"'") print "here", cwos, wos, cwos + cwod, wos + wod, $0

				if($1 == "'$id'" ||
					($1 ~ wsp &&
					((cwos >= wos && cwos + cwod <= wos + wod &&
					(cws + cwd <= ws || cws >= ws + wd)) &&
					!($4 == nws && $5 == nws)))) {
						if ("'"$2"'") print "HERE:", $0
						if($1 == "'"$id"'") {
							if(!c) {
								if(r) aw[++awi] = $0
								else bw[++bwi] = $0
							}
						}
						else if(f && $1 == "'$original_id'") next
						else if(cws + cwd <= ws) bw[++bwi] = $0
						else if(cws >= ws + wd) aw[++awi] = $0
				}
			}

			# arguments:
			#	od - original dimension (sum of all window dimensions)
			#	wae - end point of the window array
			#	wane - new end point of window array
			#	pos - position (set only if window start after original window)
			function add_window(od, was, wae, wane, pos) {
				wr = (od + s - b) / ((cwd + s) ? cwd + s : 1)

				# find where window originally started, and adjust it to start after previously resized windows
				if(nsc) {
					# iterate through window orginal/new start positions
					for(nsi in ns) {
						if(nsi == cws) {
							found = 1
							# if original start position is found, assign start to corresponding new position
							cwns = ns[nsi]
							break
						}
					}
				}

				# choose new start depending on wether original start was found or not
				cns = (found) ? cwns : (pos) ? mns : cws

				# set new window dimension depending on wether window is last or not:
				# if it is, simply subtract its dimention from new end point
				# if not, apply ratio calculated earlier on the new dimension
				if (cwid == "'$id'" && e) cwnd = '${properties[index + 2]}'
				else {
					if ((cwbe && cws + cwd + cb == cwbe) ||
						(!cwbe && cws + cwd + cb == wae)) {

						if (cwbe && cwbe != wane && cwbe != wae) {
							cbod = cwbe - cwbs + s - cb
							cbr = (od + s) / cbod
							cbnd = (nd + s) / cbr
							cwnd = was + cbnd - (cns + s)
						} else cwnd = wane - cns - cb
					} else cwnd = (nd + s - b) / wr - s
				}

				cwnd = sprintf("%.0f", cwnd)
				cwns = cns + cwnd + s

				# add original/new window start to array
				ns[cws + cwd + s] = cwns
				nsc++

				# add window to all winodws array
				aaw[++aawi] = "[" cwid "]=\"" cns " " cwnd "\""

				# if window starts after original window, set new minimal start
				if(!pos && cwns > mns) mns = cwns
			}

			# arguments:
			#	wa - window array
			#	wae - end point of the window array
			#	wane - new end point of window array
			#	od - original dimension (sum of all window dimensions)
			#	pos - position (set only if window start after original window)
			function align(wa, was, wae, wane, od, pos) {
				# unset any existing variables
				delete cwp
				delete ns
				delete ne

				# iterate through "window blocks"
				for(wai in wa) {
					cwb = wa[wai]

					# if window block consiste from multiple windows
					if(cwb ~ ",") {
						split(cwb, cwbp, "_")
						split(cwbp[3], cwbw, ",")
						cwbs = cwbp[1]; cwbe = cwbp[2] #- (s - cb)

						# iterate through windows
						for(cwbwi in cwbw) {
							# parse window properties
							split(cwbw[cwbwi], cw, ":")
							split(cw[2], cwp, "-")
							cwid = cw[1]
							cws = cwp[1]
							cwd = cwp[2]
							cb = cwp[3]

							s = o + cb

							# adding window
							found = 0
							add_window(od, was, wae, wane, pos)
						}
					} else {
						# parse window properties
						split(cwb, cwp)
						cwid = cwp[1]
						cws = cwp[2]
						cwd = cwp[3]
						cb = cwp[4]
						cwbs = cwp[5]; cwbe = cwp[6] #- (s - cb)

						s = o + cb

						# adding window
						found = 0
						add_window(od, was, wae, wane, pos)
					}
				}
			}

			# function which parse window start
			function get_start(window) {
				sp = (window ~ ",") ? "[:-]" : " "
				split(window, wp, sp)
				return wp[2]
			}

			# custom comparison function which compares start of two windows
			function compare(i1, v1, i2, v2) {
				s1 = get_start(v1)
				s2 = get_start(v2)

				return s1 > s2
			}

			# function for sorting array
			function set_array(a, sa) {
				sort(a)
				if (max > min || e) asort(a, sa, "compare")
			}

			#arguments:
			#	ca - current array
			#	cac - current array count
			#	cas - current array start
			#	cd - current array dimension
			#	cae - current array end point
			#	pos - position
			function set_ratio(ca, cac, cas, cd, cae, pos) {
				# if array contains windows
				if(cac) {
					# if there are both arrays (both windows before and after original window)
					# set new padding to separator
					if(ba) np = s
					# if there are both arrays (both windows before and after original window)
					# set padding to be two separators (one from each side)
					p = (ba) ? 2 * s : s
					# current ratio (new dimension / old dimension)
					cr = (cd) ? td / cd : 1

					# if window is closing
					if(c) {
						# new window dimension:
						# new total dimension + original window dimension + padding - new padding
						if (ra) nd = cd + ((pos) ? ad : bd)
						else nd = (td + wd + p - np) / cr
					} else {
						nwd = int((td - p) / (twc + 1))
						nd = (td - nwd) / cr
						cane = cas + td - nwd - p

						# set alignment ratio if it is enforced, otherwise devide it evenly
						nwdp = (ar) ? ar : twc + 1
						# set new window dimension by deviding total dimension with alignment ratio
						nwd = int((td + np - (twc * s)) / nwdp)
						# calculate new dimension by applying ratio computed earlier
						nd = (td + np - p - nwd) / cr

						# if reverse is enabled (window should open before original window),
						# and there is no widnows before original window, offset all windows to start after new window (after its dimension + separator)
						if(pos && r && !bc) {
							# separator after new window:
							# if full is enabled, separator should have double value because 
							# full window is set to start a separator before first window,

							# if full is enabled, new window is set to start a separator before first window,
							# so this will neutralize it
							nwd -= b
							mns += nwd + s + b
						}
					}

					# setting new end point according to position regarding original window
					cane = (pos) ? aas + cd : cas + nd
					if (r && !bc) cas += nwd + b + o

					if("'"$2"'") print "CANE", cas, cane, cd, nwdp, nwd, nd, ar, twc, e

					align(ca, cas, cae, cane, cd, pos)
				}
			}

			END {
				# setting before windows array and its properties
				set_array(bw, nbw)

				if ("'"$2"'") print "BEFORE", min, max, ws, wd

				if ((c && (max == ws - s ||
					(e == "resize" && max == ws + wd))) ||
					(!c && ((r && max == ws -s) ||
					(!r && max == ws + wd)))) {
					bc = length(nbw)
					if(bc) { bas = min; bae = max; bad = max - min }
				}

				if (length(aw)) {
					# setting after windows array and its properties
					if (!r || (r && c)) max = ws + wd

					set_array(aw, naw)
					ac = length(naw)
					if(ac) { aas = min; aae = max; aad = max - min }
				}

				# total window dimension and total window count
				ba = (bc && ac)
				td = bad + aad
				twc = bc + ac
				if (e) twc--

				if (e == "restore") ar = ar * ('${old_count:-1}' + 1) / (twc + 1)
				if ("'"$2"'") print "RATIO", ar, td, wd + m

				set_ratio(nbw, bc, bas, bad, bae)

				if (!mns) mns = ws + ra

				# if window is not closing
				if(!c) {
					# if there are windows before original window, set new window start after last window
					# otherwise set it at the beggining of current windows
					nws = (bc) ? mns : aas
					# if there are windows after original window, set new window dimension to already calculated size
					# otherwise set it to fill all the space until the end point
					nwd = ((ac) ? nwd : bas + td - nws) - b
					if (bc) {
						nw = "['"$current_id"']=\"" nws " " nwd "\""
						# increment new minimum start by new window dimension and separator
						mns += nwd + s
					}
				}

				set_ratio(naw, ac, mns, aad, aae, "after")
				if(!c && !bc) nw = "['"$current_id"']=\"" nws " " nwd "\""

				# format all aligned windows
				for(aawi in aaw) a = a " " aaw[aawi]

				if (ba) bs = o

				min = (bc) ? bas : aas
				if (wd) sc =  td / wd
				#system("~/.orw/scripts/notify.sh -t 11 \"" td + bs " " bad " " aad "\"")
				#print min, td + bs, twc + 1 "_" 1 + sc, nw, a
				#printf "%d %d %d_%.02f %s %s", min, td + bs, twc + 1 "_" 1 + sc, nw, a
				print min, td + bs, twc + 1 "_" 1 + sprintf("%.02f", sc), nw, a
			}'
}

get_workspace_windows() {
	[[ $1 ]] &&
		local display=$1 ||
		display=${workspaces[$id]#*_}

	#echo $display: ${displays[*]}, ${display_properties[*]}, $id, ${workspaces[$id]}

	[[ ${FUNCNAME[*]: -3:1} != update_values ]] &&
		display_properties=( ${displays[$display]} )

	windows=()
	for window in ${!workspaces[*]}; do
		[[ ${workspaces[$window]} == ${closing_id_workspace:-$workspace}_${display} ]] &&
			windows[$window]="${all_windows[$window]}"
	done
}

adjust_workspaces() {
	((current_ws_count)) && previous_ws_count=$current_ws_count
	current_ws_count=$(xdotool get_num_desktops)
	#echo adjust: $current_ws_count, $previous_ws_count, $closing_id_workspace, $workspace, $id, $current_window_id
	#wmctrl -d

	if ((previous_ws_count && current_ws_count != previous_ws_count)); then
		((current_ws_count > previous_ws_count)) &&
			local ws_direction=+1 referent_workspace=$previous_workspace ||
			local ws_direction=-1 referent_workspace=${new_workspace:-${closing_id_workspace:-$previous_workspace}}
		#workspace=$(xdotool get_desktop)

		#echo $previous_ws_count, $current_ws_count, $sign
			#echo ${w%_*}: $privious_workspace $((${w%_*} $sign 1))_${w#*_}]="${workspaces[$w]}"
			#((${w%_*} >= referent_workspace)) &&
			#	workspaces[$((${w%_*} $sign 1))_${w#*_}]="${workspaces[$w]}" &&
			#	unset workspaces[$w]
			#echo in $w: "$((${workspaces[$w]%_*} $sign 1))_${workspaces[$w]#*_}", ${workspaces[$w]%_*} - $referent_workspace

		for w in ${!workspaces[*]}; do
			[[ $w != "$moving_id" ]] && ((${workspaces[$w]%_*} > referent_workspace)) &&
				workspaces[$w]="$((${workspaces[$w]%_*} + ws_direction))_${workspaces[$w]#*_}"
			#echo win: $w: ${workspaces[$w]}
		done

		#for w in ${!workspaces[*]}; do
		#	echo ws: $w: ${workspaces[$w]}
		#done

		for tw in ${!tiling_workspaces[*]}; do
			#echo $tw: $referent_workspace, ${tiling_workspaces[tw]}, $workspace_offset
			if ((current_ws_count < previous_ws_count &&
				${tiling_workspaces[tw]} == referent_workspace)); then
					echo unset tiling_workspaces[$tw] - ${tiling_workspaces[tw]}
					unset tiling_workspaces[tw]
					local workspace_offset=-1
			else
				#((${tiling_workspaces[tw]} > referent_workspace)) &&
				#	tiling_workspaces[tw - workspace_offset]=$((${tiling_workspaces[tw]} + ws_direction))

				if ((${tiling_workspaces[tw]} > referent_workspace)); then
					if [[ $new_tiling_workspace ]]; then
						#echo NEW: $new_tiling_workspace
						tiling_workspaces[tw]=$new_tiling_workspace
						unset new_tiling_workspace
						local workspace_offset=1
					fi

					#echo else tiling_workspaces[$tw + $workspace_offset], $((${tiling_workspaces[tw]} + ws_direction))
					tiling_workspaces[tw + workspace_offset]=$((${tiling_workspaces[tw]} + ws_direction))
				fi
			fi

			#echo tw: $tw - ${tiling_workspaces[tw]}
			#((${tiling_workspaces[tw]} > referent_workspace)) &&
			#	((tiling_workspaces[tw - workspace_offset]$sign$sign))
		done

		((workspace_offset < 0)) && unset tiling_workspaces[-1]

		((current_ws_count > previous_ws_count)) && [[ $new_tiling_workspace ]] &&
			tiling_workspaces+=( $new_tiling_workspace ) && unset new_tiling_workspace

		echo adjust: $referent_workspace - ${tiling_workspaces[*]}

		signal_tiling
		sed -i "/^tiling/ s/[0-9 ]\+/ ${tiling_workspaces[*]} /" $0
	fi

	#echo end $workspace, ${workspaces[$id]}
	unset closing_id_workspace
}

get_display_mapping() {
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
	eval display_map=( $display_mapping )
}

set_alignment() {
	local id=$1
	read new_{start,size} <<< ${aligned_windows[$id]}

	if ((new_size)); then
		[[ $id != $current_id ]] &&
			properties=( $id $window_properties )
		properties[index]=$new_start
		properties[index + 2]=$new_size

		if [[ $tiling ]]; then
			[[ $id != ${original_properties[0]} ]] &&
				windows[$id]="${properties[*]:1}"
			[[ $id == $second_window_id ]] &&
				second_window_properties=( ${properties[*]:1} )
		fi

		all_aligned_windows[$id]="${properties[*]:1}"
	fi
}

align_windows() {
	local action=$1
	local window_index=0
	declare -A aligned_windows

	if [[ $action && ! $enforced_direction ]]; then
		local original_alignment_direction=$alignment_direction
		local alignment_direction=${alignments[$id]}

		if [[ ! $alignment_direction ]]; then
			if [[ $tiling && ! $new_desktop ]]; then
				[[ $original_alignment_direction == h ]] &&
					local alignment_direction=v ||
					local alignment_direction=h
			else
				local alignment_direction=$original_align_direction
			fi
		fi

		[[ $action == close ]] && unset ${alignments[$id]}
	fi

	#[[ $tiling ]] || get_workspace_windows
	get_workspace_windows ${workspaces[$id]#*_}

	#if display is set to some other display than the one the current active window is on
	#select the first window from the correct display
	#if ((display != ${workspaces[$id]#*_})); then
	#	if [[ ${last_display_window[$display]} ]]; then
	#		id=${last_display_window[$display]}
	#	else
	#		local all_window_ids=${!windows[*]}
	#		id=${all_window_ids%% *}
	#	fi

	#	properties=( $id ${windows[$id]} )
	#	echo $id: ${properties[*]}
	#fi

	set_alignment_properties $alignment_direction

	#if [[ $action ]]; then
	#	echo $alignment_direction: $id, ${properties[*]}, ${alignments[$id]}
	#	list_windows
	#	get_alignment "$action" print
	#fi

	read block_{start,dimension,segments} aligned <<< $(get_alignment $action)
	alignments[${current_id:-$id}]=$alignment_direction

	eval aligned_windows=( $aligned )
	[[ ${!aligned_windows[*]} =~ temp ]] && unset aligned_windows[temp]

	local before after
	if [[ $event =~ min|max ]] &&
		((${#aligned_windows[*]})); then
			while read wid new_{start,size}; do
				new_properties=( ${windows[$wid]} )
				new_properties[index - 1]=$new_start
				new_properties[index + 1]=$new_size
				windows[$wid]="${new_properties[*]}"
				all_windows[$wid]="${new_properties[*]}"

				((${properties[index]} > $new_start)) &&
					before+=" $wid" || after+=" $wid"
			done < <(
				for aw in ${!aligned_windows[*]}; do
					echo $aw ${aligned_windows[$aw]}
				done | sort -nk 2,2
			)

		states[$id]="$block_segments $before $id $after"
	else
		if [[ ${states[*]} == *$id* ]]; then
			[[ $reverse ]] &&
				local new_ids="$current_id $id" || local new_ids="$id $current_id"

			for state_window in ${!states[*]}; do
				local neighbours="${states[$state_window]}"

				[[ $action ]] &&
					states[$state_window]="${neighbours/$id}" ||
					states[$state_window]="${neighbours/$id/$new_ids}"
			done
		fi
	fi

	#if new window should be inserted
	[[ $action ]] || set_alignment $current_id

	update_alignment "$action" $force

	#iterating through all windows
	while read window_id window_properties; do
		#if this is the stage of removing window from the alignment, remove selected window
		#otherwise, adjust alignment for the given window
		[[ $window_id == ${original_properties[0]} && $action == move ]] &&
			unset windows[$window_id] && ((window_count--)) ||
			set_alignment $window_id

		(( window_index++ ))
	done <<< $(list_windows)
}

handle_first_window() {
	x_border=$default_x_border y_border=$default_y_border
	#x_border=$default_x_border y_border=$default_x_border

	props=( ${display_properties[*]} )
	(( props[2] -= ${props[0]} + x_border ))
	(( props[3] -= ${props[1]} + y_border ))
	props+=( $x_border $y_border )

	set_border_diff $id

	local new_props="${props[*]::4}"
	#wmctrl -ir $id -e 0,${new_props// /,} &
	set_window $id props[*]

	all_windows[$id]="${props[*]}"
	windows[$id]="${props[*]}"
	properties=( $id ${props[*]} )
	((window_count++))

	get_display_properties
	workspaces[$id]="${workspace}_${display}"
}

align() {
	# checking optional arguments
	[[ $1 =~ m$ ]] && local window_action=move
	[[ $1 =~ c$ ]] && local window_action=close
	[[ $1 =~ ^[0-9.]+$ ]] && align_ratio=$1
	[[ $1 && ! $window_action ]] && alignment_direction=${1:0:1}

	[[ $window_action ]] && ignore=1

	if ((first_window)); then
		handle_first_window
	else
		set_orientation_properties $display_orientation

		if [[ $window_action ]]; then
			alignment_direction=${alignments[$id]}
		else
			if [[ $mode == tiling && ! $event ]]; then
				# if mode is equal to auto, select opposite of larger dimension
					if [[ $tiling ]]; then
						if [[ $choosen_alignment ]]; then
							alignment_direction=$choosen_alignment
						else
							[[ ${alignments[${original_properties[0]}]} == h ]] &&
								alignment_direction=v || alignment_direction=h
						fi
					else
						if [[ ! $enforced_direction ]]; then
							((${properties[3]} > ${properties[4]})) &&
								alignment_direction=h || alignment_direction=v
						fi
					fi
			elif [[ $mode == stack ]]; then
				# if windows are already splited into main and stack, align it with stack windows 
				if ((window_count > 2)); then
					[[ $alignment_direction == h ]] &&
						alignment_direction=v align_index=3 ||
						alignment_direction=h align_index=2

					((index++))
					# find last (or first, in case reverse is enabled) stack window
					properties=( $(list_windows |
						sort -nk $index,$index -nk $align_index${reverse:1:1},$align_index | tail -1) )
					id=${properties[0]}
				fi
			fi
		fi

		# align windows according to corresponding action
		align_windows $window_action
	fi
}

sort_windows() {
	list_windows | awk '
		{
			i = '$index' + 1
			d = (i == 2)
			sc = $i

			if ($1 == "'$id'") {
				if ("'$1'" ~ /[BRbr]/) sc += '${properties[index + 2]}'
			} else {
				if ("'$1'" ~ /[LTlt]/) sc = $i + $(i + 2)
			}

			print sc, $0
		}' | sort $reverse -nk 1
}

function set_sign() {
	sign=${1:-+}
	[[ $sign == + ]] && opposite_sign=- || opposite_sign=+
}

get_display_properties() {
	[[ -z $@ ]] &&
		local properties=( ${properties[*]: -6} ) ||
		local properties=( $(get_windows $1 | cut -d ' ' -f 2-) )
	[[ $2 ]] && echo GDP ${BASH_LINENO[*]} $@, $id: ${properties[*]}, $display, ${properties[*]:1}

	if [[ ${properties[*]} ]] && ((window_count)); then
		for display in ${!displays[*]}; do
			display_properties=( ${displays[$display]} )

			#echo P: ${properties[*]}, DP: ${display_properties[*]}

			#if ((${properties[display_index]} >= ${display_properties[display_index]} &&
			#	${properties[display_index]} + ${properties[display_index + 2]} <= \
			#	${display_properties[display_index + 2]})); then

			if ((${properties[0]} >= ${display_properties[0]} &&
				${properties[0]} + ${properties[2]} <= ${display_properties[2]} &&
				${properties[1]} >= ${display_properties[1]} &&
				${properties[1]} + ${properties[3]} <= ${display_properties[3]})); then
					read {x,y}_start {x,y}_end <<< ${display_properties[*]}
					break
			fi
		done
	else
		display_properties=( ${displays[$primary]} )
	fi

	read {x,y}_start {x,y}_end <<< ${display_properties[*]}
}

set_border_diff() {
	local {x,y}_border_diff #borders
	((current_window_count == 1)) && local first=true

	if [[ ${windows[$id]} || $first ]]; then
		local current_properties=( ${windows[$id]} )

		[[ $id == 0x* && ! $first ]] &&
			previous_borders="${current_properties[*]: -2:2}" ||
			previous_borders="$default_x_border $default_y_border"

		read previous_{x,y}_border <<< "$previous_borders"
		#read borders <<< $(xwininfo -id ${1:-$current_id} 2> /dev/null |
		#	awk '/Relative/ { if (/Y/) h = '$handle_width'; print $NF + h }' | xargs -r)
		read borders <<< $(xwininfo -id ${1:-$current_id} 2> /dev/null |
			awk '/Relative/ {
					if (/Y/) y = x + $NF + '$handle_width'
					else x = $NF
				} END { print 2 * x, y }' | xargs -r)

		if [[ $borders ]]; then
			read current_{x,y}_border <<< "$borders"

			#x_border_diff=$((previous_x_border - current_x_border * 2))
			#y_border_diff=$((previous_y_border - (current_y_border + current_x_border)))
			x_border_diff=$((previous_x_border - current_x_border))
			y_border_diff=$((previous_y_border - current_y_border))

			((x_border_diff)) && ((props[2] += x_border_diff))
			((y_border_diff)) && ((props[3] += y_border_diff))

			if [[ $first ]]; then
				(( y_border -= y_border_diff ))
				props[5]=$y_border
			fi
		fi
	fi
}

set_window() {
	local id=$1 temp_properties{,_string}

	[[ $2 == *' '* ]] &&
		temp_properties=( $2 ) ||
		temp_properties=( ${!2} )

	#echo $id, ${!border_gaps[*]}
	if [[ ${!border_gaps[*]} == *$id* ]]; then
		local {x,y}_border_gap
		read {x,y}_border_gap <<< ${border_gaps[$id]}
		(( temp_properties[0]+=x_border_gap ))
		(( temp_properties[1]+=y_border_gap ))
	fi

	temp_properties_string="${temp_properties[*]::4}"

	#echo wmctrl -ir $id -e 0,${temp_properties_string// /,}
	wmctrl -ir $id -e 0,${temp_properties_string// /,}
}

update_aligned_windows() {
	local borders {new_,}props aligned_ids=${!all_aligned_windows[*]}
	[[ ${@: -1} == no_change ]] && local no_change=true

	[[ ${FUNCNAME[*]} == *set_align_event* ]] &&
		local save_original_properties=true

	if [[ $aligned_ids ]]; then
		for window_id in ${aligned_ids/$current_id} $current_id; do
			props=( ${all_aligned_windows[$window_id]} )

			if ((${#props[*]})); then
				[[ $1 && $window_id == $1 ]] && set_border_diff $1
				[[ $window_id == $current_id ]] &&
					workspaces[$current_id]="${workspace}_${display}"

				new_props="${props[*]::4}"
				[[ $no_change ]] ||
					set_window $window_id props[*]
					#wmctrl -ir $window_id -e 0,${new_props// /,}

				[[ $1 && $window_id == $1 ]] &&
					windows[$window_id]="${props[*]::4} $borders" ||
					windows[$window_id]="${props[*]}"

				all_windows[$window_id]="${windows[$window_id]}"
			fi
		done
	fi

	all_aligned_windows=()
}

orw_config=~/.config/orw/config

running_pid=$(pidof -o %PPID -x ${0##*/})
[[ $running_pid ]] && echo "Script is already running ($running_pid), exiting" && exit

new_window_size=60
padding=$(awk '/padding/ { print $NF * 2; exit }' ~/.config/gtk-3.0/gtk.css)
((new_window_size += padding))

blacklist='.*input,get_borders,DROPDOWN,color_preview,cover_art_widget,image_preview'

update_displays() {
	local current_workspace=$workspace
	unset workspace

	while read display display_properties; do
		if [[ ${displays[$display]} ]]; then
			new_display_properties=( $display_properties )
			current_display_properties=( ${displays[$display]} )

			for property_index in ${!new_display_properties[*]}; do
				diff=$((${new_display_properties[property_index]} - \
					${current_display_properties[property_index]}))
				diffs+=( $diff )
			done

			while read window window_properties; do
				temp_properties=( $window_properties )

				if ((${temp_properties[display_index]} >= ${current_display_properties[display_index]} &&
					${temp_properties[display_index]} + ${temp_properties[display_index + 2]} <= \
					${current_display_properties[display_index + 2]})); then
					for diff_index in ${!diffs[*]}; do
						diff=${diffs[diff_index]}

						if ((diff)); then
							if ((diff_index < 2)); then
								if ((${temp_properties[diff_index]} == ${current_display_properties[diff_index]})); then
									((temp_properties[diff_index] += diff))
									((temp_properties[diff_index + 2] -= diff))
									[[ ${tiling_worksapces[*]} != *$workspace* ]] && edge=true
								fi
							else
								if ((${temp_properties[diff_index - 2]} + ${temp_properties[diff_index]} + \
									${temp_properties[diff_index + 2]} == ${current_display_properties[diff_index]})); then
									((temp_properties[diff_index] += diff))
									[[ ${tiling_worksapces[*]} != *$workspace* ]] && edge=true
								fi
							fi
						fi
					done
				fi

				if [[ $edge ]]; then
					windows[$window]="${temp_properties[*]}"
					edge_windows[$window]="${temp_properties[*]::4}"
					unset edge
				fi
			done <<< $( \
				for w in ${!windows[*]}; do echo $w ${windows[$w]}; done
				comm -23 <(get_windows | sort) \
					<(for w in ${!windows[*]}; do echo $w ${windows[$w]}; done | sort)
				)
	
			unset diffs
		fi

		displays[$display]="$display_properties"
	done <<< $(sed 's/\(\([0-9]\+\s*\)\{5\}\)/\1\n/g' <<< "$all_displays")

	workspace=$current_workspace
}

update_borders() {
	local property=$1
	local diff_value=$3
	local direction_index=$2
	local {start,end}_edge {first,second}_half current_workspace=$workspace rofi_start
	unset workspace

	[[ $property == margin ]] &&
		first_half=$((diff_value / 2)) second_half=$((diff_value - first_half))

	for window in ${sorted_ids[*]}; do
		current_properties=( ${all_windows[$window]} )

		if [[ $property == border ]]; then
			((current_properties[direction_index + 4] -= diff_value))
			((current_properties[direction_index + 2] += diff_value))
			all_windows[$window]="${current_properties[*]}"
		else
			direction_start=${current_properties[direction_index]}
			direction_end=$((direction_start + \
				${current_properties[direction_index + 2]} + ${current_properties[direction_index + 4]}))

			[[ $rofi_state == opened ]] &&
				((!direction_index && (rofi_offset > 0 || rofi_opening_offset))) &&
				rofi_start=$rofi_opening_offset || unset rofi_start

			for display in ${!displays[*]}; do
				display_properties=( ${displays[$display]} )
				((direction_start == rofi_start + ${display_properties[direction_index]})) &&
					start_edge=true
				((direction_end == ${display_properties[direction_index + 2]})) &&
					end_edge=true
			done

			[[ ! $start_edge ]] &&
				 ((current_properties[direction_index] -= first_half)) &&
				 ((current_properties[direction_index + 2] += first_half))
			[[ ! $end_edge ]] &&
				((current_properties[direction_index + 2] += second_half))

			[[ $start_edge && $end_edge ]] || all_windows[$window]="${current_properties[*]}"

			unset {start,end}_edge
		fi
	done

	workspace=$current_workspace
}

get_workspace_icons() {
	read {p,s}wi <<< $(awk '
		BEGIN { p = s = "" }

		function make_icon(icon, color) {
			ic = (color) ? "pbfg" : "sbg"
			return "<span font=\"Iosevka Orw 27\" foreground=\"\\\$" ic "\">" icon "</span>"
		}

		/^[^#]/ {
			if (NR == FNR) {
				it = gensub(".*-W\\s*([^i ]*i:?([^, ]*)).*", "\\2", 1)
				gsub(".", "&[^_]*_", it)
			} else {
				if ($1 ~ "Workspace_" it "[sp]") {
					i = $0
					gsub(".*=", "", i)
					if($1 ~ "_s=") s = i
					else p = i
				}
			}
		}

		END { print p, s }' $bar_config ~/.orw/scripts/icons 2> /dev/null)
}

get_rofi_pid() {
	local script=$1
	ps -C dmenu.sh -o pid=,args= | awk '$NF == "'$script'" { print $1; exit }'
}

update_values() {
	event=update
	orw_config=~/.config/orw/config

	#read mode alignment_direction reverse full default_{x,y}_border margin \
	read margin default_{x,y}_border mode full reverse alignment_direction interactive \
		primary display_{count,orientation,index} diff_{property,value} <<< \
		$(awk -F '[_ ]' '
			BEGIN {
				xb = '${default_x_border:-0}'
				yb = '${default_y_border:-0}'
				m = '${margin:-0}'
			}

			NR == FNR { d[$1] = $2 " " $3 " " $4 " " $5; next }

			wm && /^$/ { wm = 0 }

			wm && !/^offset/ {
				if($1 == "margin" && m) {
					if($NF != m) {
						dp = "margin"
						dv = m - $NF
					}
				}

				if($2 == "border" && xb + yb) {
					if(/^x/ && $NF != xb || /^y/ && $NF != yb) {
						dp = "border"

						if ($1 == "x") dv = xb - $NF
						else dv = dv " " yb - $NF
					}
				}

				if($2 == "offset") {
					if($1 == "x") xo = $NF
					else yo = $NF
				} else p = p " " $NF
			}

			/^#wm/ { wm = 1 }
			/^orientation / { o = substr($NF, 1, 1) }

			$1 == "primary" { pd = $NF }

			$1 == "display" {
				switch ($3) {
					case "xy":
						x = $(NF - 1)
						y = $NF
						break
					case "size":
						w = $(NF - 1)
						h = $NF
						break
					case "offset":
						bto = $(NF - 1)
						bbo = $NF

						cd = x + xo " " y + bto + yo " " x + w - xo " " y + h - bbo - yo

						if(d[$2] != cd) {
							dv = dv " " $2 " " cd
							dp = "display"
						}

						dc++
						break
				}
			}

			END {
				print p, pd, dc, o, (o == "v") + 0, dp, dv
			}' <(((${#displays[*]})) &&
					for d in ${!displays[*]}; do
						echo $d ${displays[$d]}
					done || echo 0) $orw_config)

	[[ $full == false ]] && unset full
	[[ $reverse == false ]] && unset reverse
	[[ $use_ratio == false ]] && unset use_ratio
	[[ $interactive == false ]] && unset interactive
	[[ $alignment_direction == auto ]] &&
		unset enforced_direction || enforced_direction=true

	global_alignment_direction=$alignment_direction

	signal_tiling

	if [[ $diff_property ]]; then
		case $diff_property in
			display)
				if [[ $diff_value ]]; then
					current_workspace=$workspace
					unset workspace

					if ((${#FUNCNAME[*]} > 2)); then
						local sorted_ids
						read -a sorted_ids <<< $(wmctrl -lG | awk '
							BEGIN {
								tw = "'"${tiling_workspaces[*]}"'"
								gsub(" ", "|", tw)
							}

							$2 ~ "^(" tw ")$" {
								sub("0x0*", "0x", $1)
								if($2 == "'${current_workspace:-$workspace}'") cw[NR] = $1
								else ow[NR] = $1
							} END {
								for(wi in cw) sw = sw " " cw[wi]
								for(wi in ow) sw = sw " " ow[wi]
								print sw
							}' | xargs)
					fi

					declare -A diffs offset_windows updated_displays

					sorted_workspaces="$(tr ' ' '\n' <<< ${workspaces[*]} |
						cut -d '_' -f 1 | sort | uniq | grep -v $current_workspace)"

					current_id=$id

					local current_display=$display tiling_rofi_pid=$(get_rofi_pid tiling)

					while read display display_properties; do
						if [[ ${displays[$display]} ]]; then
							local adjust_windows=true
							local new_display_properties=( $display_properties )
							local current_display_properties=( ${displays[$display]} )
							local rofi_diff=$((${new_display_properties[rofi_index - 1]} < \
								${current_display_properties[rofi_index - 1]} + rofi_offset))

							for property_index in ${!new_display_properties[*]}; do
								diff=$((${new_display_properties[property_index]} - \
									${current_display_properties[property_index]}))

								((diff)) && diffs[$((property_index + 0))]=$diff
							done
						fi

						for diff in ${sorted_diffs:-${!diffs[*]}}; do
							local id=temp
							x_border=0 y_border=0
							temp_properties=( ${current_display_properties[*]::2} )

							temp_properties+=( $((${current_display_properties[2]} \
								- ${current_display_properties[0]})) )
							temp_properties+=( $((${current_display_properties[3]} \
								- ${current_display_properties[1]})) )

							value=${diffs[$diff]}

							((diff % 2)) &&
								alignment_direction=v || alignment_direction=h
							set_alignment_properties $alignment_direction

							if ((diff > 1)); then
								temp_properties[index - 1]=$((${current_display_properties[diff]} + margin))
								temp_properties[diff]=$((-(margin - value)))
							else
								(( temp_properties[index - 1] += value + 0))
								temp_properties[diff + 2]=$((-(margin + value)))
							fi

							properties=( $id ${temp_properties[*]} 0 0 )

							for workspace in $current_workspace $sorted_workspaces; do
								if [[ ${workspaces[*]} == *${workspace}_${display}* ]]; then
									windows=()
									for window in ${!workspaces[*]}; do
										[[ ${workspaces[$window]} == ${workspace}_${display} ]] &&
											windows[$window]="${all_windows[$window]}"
									done

									rofi_opening_offset=$rofi_offset

									if [[ $rofi_state == opened && $rofi_opening_display -eq $display ]] &&
										(((rofi_opening_offset > 0 || rofi_diff) &&
											workspace == current_workspace)); then
												if ((diff % 2 == rofi_index % 2)); then
														((properties[rofi_index]+=$rofi_opening_offset))
														((diff % 2 == rofi_index % 2)) &&
															((properties[rofi_index + 2]-=$rofi_opening_offset))
												else
													local open_rofi=true new_rofi_offset=$((rofi_opening_offset + value))
													#echo CLOSING ROFI: $rofi_opening_offset, $value, $new_rofi_offset
													toggle_rofi $current_workspace no_change
												fi
									fi

									windows[temp]="${properties[*]:1}"

									read bs bd bseg aligned <<< $(get_alignment move)
									eval all_aligned_windows=( $aligned )

									for w in ${!all_aligned_windows[*]}; do
											read p d <<< ${all_aligned_windows[$w]}
											window_properties=( ${windows[$w]} )
											window_properties[index - 1]=${all_aligned_windows[$w]% *}
											window_properties[index + 1]=${all_aligned_windows[$w]#* }
											windows[$w]="${window_properties[*]}"
											all_windows[$w]="${window_properties[*]}"
									done

									if (((rofi_opening_offset > 0 || rofi_diff) &&
										workspace == current_workspace && diff % 2 == rofi_index % 2)); then
										if [[ $rofi_state == opened && $rofi_opening_display -eq $display ]]; then
											((properties[rofi_index]-=$rofi_opening_offset))
											((diff % 2 == rofi_index % 2)) &&
												((properties[rofi_index + 2]+=$rofi_opening_offset))
										fi
									fi
								fi
							done

							((current_display_properties[$diff] += value))
						done

						windows=()
						id=$current_id

						if [[ $adjust_windows ]]; then
							for w in ${sorted_ids[*]}; do
								if [[ ${!all_windows[*]} =~ $w ]]; then
									props="${all_windows[$w]% * *}"
									#wmctrl -ir $w -e 0,${props// /,} &
									set_window $w "${all_windows[$w]}"
									[[ ${workspaces[$w]} == ${current_workspace}_${display} ]] &&
										windows[$w]="${all_windows[$w]}"
								fi
							done
						fi

						if ((display == rofi_opening_display)); then
							if [[ $open_rofi ]]; then
								set_rofi_windows $new_rofi_offset
								sleep 1 && toggle_rofi $current_workspace
								kill -USR1 $tiling_rofi_pid
								unset open_rofi
							elif [[ $rofi_style =~ icons|dmenu ]]; then
								[[ $tiling_rofi_pid ]] && kill -USR1 $tiling_rofi_pid
							fi
						fi

						updated_displays[$display]="$display_properties"
					done <<< $(sed 's/\(\([0-9]\+\s*\)\{5\}\)/\1\n/g' <<< "$diff_value")

					eval displays="$(typeset -p updated_displays | sed 's/^[^=]*.//')"

					workspace=$current_workspace
					all_displays="$diff_value"
					get_display_properties $id #print

					bars=$(sed -n 's/^last.*=//p' ~/.orw/scripts/barctl.sh)
					[[ $bars =~ , ]] && bars="{$bars}"
					bar_config=$(grep -l '\-W' $(eval ls ~/.config/orw/bar/configs/$bars))

					get_workspace_icons
					unset current_display_properties
				fi
				;;
			*)
				diffs=( $diff_value )

				current_ids="${!all_windows[*]}"
				local sorted_ids=( $(sort_by_workspaces) )

				for direction_index in 0 1; do
					value=${diffs[direction_index]:-${diffs[0]}}
					((value)) && update_borders $diff_property $direction_index $value
				done

				for window in ${sorted_ids[*]}; do
					#wmctrl -ir $window -e 0,${all_windows[$window]// /,} &
					set_window $window "${all_windows[$window]}"
					[[ "${!windows[*]}" =~ $window ]] &&
						windows[$window]="${all_windows[$window]}"
				done
		esac
	fi

	set_rofi_windows

	unset event diff_{property,value}
}

make_workspace_notification() {
	local notification

	for workspace_index in $(seq 0 $((current_ws_count - 1))); do
		local fg='sbg' spacing_start="<span font='Iosevka Orw 5'>" spacing_end="</span>"

		case $workspace_index in
			$1)
				extra_space="$spacing_start $spacing_end"
				fg='pbfg' workspace_icon="$pwi"
			 ;;
			$2) workspace_icon=$swi;;
			*) workspace_icon=$swi;;
		esac

		((workspace_index)) &&
			workspace_icon="$spacing_start $spacing_end$extra_space$workspace_icon$extra_space"
		notification+="<span foreground='\$$fg'>$workspace_icon</span>"
		unset extra_space
	done

	notification="<span foreground='\$sbg' font='Iosevka Orw 15'>$notification</span>"
	~/.orw/scripts/notify.sh -r 404 -t 600m -s windows_osd \
		"     $notification     " 2> /dev/null &
}

swap_windows() {
	((index)) &&
		local opposite_index=0 || local opposite_index=1

	((diff > 0)) &&
		local sign=+ opposite_sign=- reverse ||
		local sign=- opposite_sign=+ reverse=r

	read {source,target}_move move_ids <<< $(list_windows |
		sort -n${reverse}k $((index + 2)),$((index + 2)) |
		awk '
			BEGIN {
				d = '$diff'
				wob = '${properties[opposite_index + 4]}'
				wod = '${properties[opposite_index + 2]}'
				wos = '${properties[opposite_index]}'
				wb = '${properties[index + 4]}'
				wd = '${properties[index + 2]}'
				ws = '${properties[index]}'
				woe = wos + wod + wob
				we = ws + wd + wb

				oi = '$opposite_index' + 2
				i = '$index' + 2
				m = '$margin'
			}

			$1 != "'"$id"'" {
				cwb = $(i + 4); cwob = $(oi + 4)
				cws = $i; cwos = $oi; cwd = $(i + 2); cwod = $(oi + 2)
				cwe = cws + cwd + cwb; cwoe = cwos + cwod + cwob

				#print d, cws, we + m, we, m, cwos, wos, cwoe, woe

				if (((d < 0 && cwe <= ws - m) ||
					(d > 0 && cws >= we + m)) &&
					(cwos >= wos && cwoe <= woe)) {
						if ((cwd + cwb + m) > md) {
							md = (cwd + cwb + m)
							tsf = md * (wod + wob + m)
						}

						ids = ids " " $1

						csf += (cwd + cwb + m) * (cwod + cwob + m)
						if (csf == tsf) exit
					}
			} END {
				print md, wd + wb + m, ids
			}')

	for move_id in $id $move_ids; do
		props=( ${windows[$move_id]} )
		[[ $move_id == $id ]] &&
			((props[index] ${sign}= source_move)) ||
			((props[index] ${opposite_sign}= target_move))
		all_windows[$move_id]="${props[*]}"
		windows[$move_id]="${props[*]}"
		all_props="${props[*]::4}"
		#wmctrl -ir $move_id -e 0,${all_props// /,} &
		set_window $move_id props[*]
	done

	signal_event "launchers" "swap" "$id ${move_ids// /,} $reverse"

	properties=( ${windows[$id]} )
}

resize() {
	declare -A aligned_windows
	local index diffs changed_properties resize_area
	local move=$1 window_{start,end} {opposite_,}index {{al{l,igned},neighbour}_,}ids

	[[ $event == *mouse* ]] && local count=1

	for property in {0..3}; do
		if ((${old_properties[property]} != ${properties[property]})); then
			index=$(( property % 2 ))

			if [[ ! ${diffs[index]} ]]; then
				diffs[index]=$((${properties[property]} - ${old_properties[property]}))
				changed_properties[index]=$property
			fi

			[[ ($event == *mouse* && ${#diffs[*]} -eq 2) ||
				$event != *mouse* ]] && break
		fi
	done

	if [[ $event == *move* ]]; then
		local diff=${diffs[*]: -1}
		((diff > 0)) &&
			changed_properties=( $((property + 2)) $property ) ||
			changed_properties=( $property $((property + 2)) )
	fi

	for property_index in ${!changed_properties[*]}; do
		property=${changed_properties[property_index]}

		if [[ $event == move ]]; then
			properties=( ${old_properties[*]} )
			properties=( ${windows[$id]} )
		else
			properties[property]=${old_properties[property]}
			((${diffs[property_index]})) && diff=${diffs[property_index]}
		fi

		windows[$id]="${properties[*]}"

		[[ ! $event =~ .*(mouse|rofi) && ${diff#-} -eq 1 ]] && (( diff *= 50 ))

		index=$((property % 2))
		window_start=${properties[index]}
		window_end=$((window_start + ${properties[index + 2]} + ${properties[index + 4]}))

		if [[ $event == swap ]]; then
			properties=( ${old_properties[*]} )
			windows[$id]="${properties[*]}"
			swap_windows
			continue
		fi

		read ws wos we woe same_windows <<< \
			$(list_windows | sort -nk $((index + 1)),$((index + 1)) |
			awk '
				BEGIN {
					p = '$property'
					i = (p % 2) + 2
					oi = ((p + 1) % 2) + 2

					id = "'"$id"'"
					ws = '$window_start'
					we = '$window_end'
					m = '$margin'
				}

				function find_size(cws, cwe) {
					for (w in aw) {
						if (!chw || w !~ "^(" chw ")$") {
							split(aw[w], chwp)
							chws = chwp[1]; chwe = chwp[2]

							if ((chws < cws && chwe + m > cws) ||
								(chwe > cwe && chws < cwe - m) ||
								(chws >= cws && chwe <= cwe)) {
									if(!chw) chw = w
									else chw = chw "|" w

									if (chwe > me) me = chwe
									if (!ms || chws < ms) ms = chws

									find_size(chws, chwe)
							}
						}
					}
				}

				{
					if ($1 == id) {
						wos = $oi
						woe = wos + $(oi + 2) + $(oi + 4)
						next
					}

					cwe = $i + $(i + 2) + $(i + 4)
					if ((p > 1 && cwe == we) || (p < 2 && ws == $i)) sw = sw " " $1

					if ((p > 1 && ($i == we + m || cwe == we)) ||
						(p < 2 && ($i == ws || cwe + m == ws)))
							aw[$1] = $oi " " $oi + $(oi + 2) + $(oi + 4)
				} END {
					find_size(wos, woe)
					print ws, (ms) ? ms : wos, we, (me) ? me : woe, id, sw
				}')

		((index)) &&
			direction=v || direction=h

		properties=( temp 0 0 0 0 0 0 )
		opposite_index=$(((index + 1) % 2 + 1))
		((index++))

		properties[opposite_index]=$wos
		properties[opposite_index + 2]=$((woe - wos))

		local interactive
		if [[ $interactive ]]; then
			properties[index]=${old_properties[index - 1]}
			properties[index + 2]=$((${old_properties[index + 1]} + ${old_properties[index + 3]}))

			windows[$id]="${properties[*]:1}"
			local alignment_direction=$direction

			((diff > 0)) &&
				local sign=- opposite_sign=+ ||
				local sign=+ opposite_sign=-

			diff=0

			adjust_window resize
		else
			((property < 2)) &&
				properties[index]=$ws ||
				properties[index]=$((we + margin))

			properties[index + 2]=-$margin

			if [[ $event == move && $property -gt 1 ]]; then
				local old_end=$((${old_properties[property - 2]} + ${old_properties[property]}))
				local new_end=$((${properties[property - 1]} + ${properties[property + 1]} - \
					${properties[property + 3]}))

				((diff > 0)) &&
					local end_diff=$((new_end - old_end)) ||
					local end_diff=$((old_end - new_end))

				resize_area=$((diff - end_diff))
			else
				resize_area=$diff
			fi

			windows[$id]="${all_windows[$id]}"

			id=temp
			windows[$id]="${properties[*]:1}"
			set_alignment_properties $direction

			read _ _ _ aligned <<< $(get_alignment move)
			eval aligned_windows=( $aligned )
		fi

		id=${same_windows%% *}
		windows[$id]="${all_windows[$id]}"
		unset windows[temp]

		(((diff < 0 && property < 2) || (diff > 0 && property > 1))) &&
			ids="${neighbour_ids:-${!aligned_windows[*]}} ${same_windows/$id} $id" ||
			ids="$same_windows ${neighbour_ids:-${!aligned_windows[*]}}"

		ids="${neighbour_ids:-${!aligned_windows[*]}}"

		for wid in $ids; do
			[[ ${windows[$wid]} ]] || continue

			props=( ${windows[$wid]} )

			read window_{start,size} <<< ${aligned_windows[$wid]}
			props[property % 2]=$window_start
			props[(property % 2) + 2]=$window_size

			windows[$wid]="${props[*]}"
			all_windows[$wid]="${props[*]}"
			[[ $aligned_ids != *$wid* ]] && aligned_ids+="$wid "

			[[ $wid == $id ]] && echo ${props[*]}
		done

		[[ ${windows[$id]} ]] &&
			properties=( ${windows[$id]} )
	done

	for wid in ${aligned_ids/$id *$id/$id}; do
		props=( ${windows[$wid]} )
		new_props="${props[*]::4}"
		#wmctrl -ir $wid -e 0,${new_props// /,} &
		set_window $wid props[*]
		all_windows[$wid]="${props[*]}"
	done

	[[ ${windows[$id]} ]] &&
		properties=( ${windows[$id]} )
}

get_rotation_properties() {
	list_windows | grep -v "^\(${windows_to_ignore// /\\|}\)\s\+\w" |
		sort -nk 1,1 -nk 2,2 | awk '
			BEGIN {
				m = '$margin'
				dx = '$display_x'
				dy = '$display_y'
				dw = '$display_width'
				dh = '$display_height'

				dhs = '$display_x'
				dvs = '$display_y'
				dhe = '$display_width'
				dve = '$display_height'
			}

			{
				wx = $2; wy = $3; ww = $4; wh = $5; wbx = $6; wby = $7

				if (wy == dvs) rwx = dhs
				else {
					yp = (dve - dvs + m) / (wy - dvs)
					rwx = int(dhs + (dhe - dhs + m) / yp)
				}

				if (wx == dhs) rwy = dvs
				else {
					xp = (dhe - dhs + m) / (wx - dhs)
					rwy = int(dvs + (dve - dvs + m) / xp)
				}

				if (wh == dve - dvs) rww = dhe - dhs - wbx
				else if (wy + wh + wby == dve) rww = dhe - rwx - wbx
				else {
					hp = (dve - dvs + m) / (wh + wby + m)
					rww = int((dhe - dhs + m) / hp - wbx - m)
				}

				if (ww == dhe - dhs) rwh = dve - dvs - wby
				else if (wx + ww + wbx == dhe) rwh = dve - rwy - wby
				else {
					wp = (dhe - dhs + m) / (ww + wbx + m)
					rwh = int((dve - dvs + m) / wp - wby - m)
				}

				print $1, rwx, rwy, rww, rwh, wbx, wby
			}'
}

rotate() {
	local display_{x,y,width,height}

	get_display_properties
	read display_{x,y,width,height} <<< ${display_properties[*]}

	while read w{id,x,y,w,h,bx,by}; do
		#wmctrl -ir $wid -e 0,$wx,$wy,$ww,$wh &
		set_window $wid "$wx $wy $ww $wh" &
		windows[$wid]="$wx $wy $ww $wh $wbx $wby"
		all_windows[$wid]="$wx $wy $ww $wh $wbx $wby"
		[[ ${alignments[$wid]} == h ]] &&
			alignments[$wid]="v" || alignments[$wid]="h"
	done <<< $(get_rotation_properties)

	properties=( ${windows[$id]} )
}

adjust_helper() {
	declare -A neighbours aligned_windows
	local properties=( "${old_properties[@]}" )

	unset windows[${current_id:-$id}]

	for window_id in ${ids/${current_id:-$id}}; do
		cwp=( $window_id ${all_aligned_windows[$window_id]:-${windows[$window_id]}} )

		if [[ ($edge == [hk] && ${cwp[index]} -gt ${old_properties[index]}) || ($edge == [jl] &&
			${cwp[index]} -lt $((${old_properties[index]} + ${old_properties[index + 2]}))) ]]; then
			unset windows[$window_id]
		else
			[[ $window_id != ${current_id:-$id} ]] && windows[$window_id]="${cwp[*]:1}"
		fi
	done

	if [[ $edge == [jl] ]]; then
		properties[index]=$((${new_properties[index]} + ${new_properties[index + 2]}))
		((properties[index] += separator))
	fi

	properties[index + 2]=-${edges[$edge]}
	((properties[index + 2] -= separator))

	id=temp
	properties[0]=$id

	read _ _ _ aligned <<< $(get_alignment move)
	eval aligned_windows=( $aligned )
	neighbour_ids="${!aligned_windows[*]}"

	for wid in $neighbour_ids; do
		props=( $wid ${all_aligned_windows[$wid]:-${windows[$wid]}} )
		props[index]=${aligned_windows[$wid]% *}
		props[index + 2]=${aligned_windows[$wid]#* }
		all_aligned_windows[$wid]="${props[*]:1}"
	done
}

start_interactive() {
	local evaluate_type=$1 notify_only=$2 no_restart=$3
	[[ $evaluate_type == offset ]] &&
		local block_{start,dimension,segments}

	set_${evaluate_type}_steps

	get_dimension_size x
	get_dimension_size y

	if [[ ! $no_restart ]]; then
		pidof -x notify.sh dunst | xargs -r kill -9
		dunst -config ~/.config/dunst/windows_osd_dunstrc &> /dev/null &
	fi

	wmctrl -l | grep "^0x0*${current_id#0x}" &> /dev/null
	local window_exists=$?
	if ((window_exists)); then
		unset {x,y}_{window,block}_{before,after,size}
		return
	fi

	[[ $notify_only ]] ||
		read_keyboard_input
}

notify_current_state() {
	local {x,y}_{,border} w h properties=( $id ${windows[$id]} )
	read x y w h {x,y}_border <<< ${properties[*]:1}
	start_interactive window true

	unset {x,y}_{step,start,end,{window,block}_{after,before,size}}
}

adjust_window() {
	declare -A edges

	local old_id=$id orientation
	local cw_start window_end enforced_direction=true
	local {old,new}_properties {property,dimension}_diff
	[[ $1 ]] &&
		old_properties=( $id ${windows[$id]} ) ||
		old_properties=( $current_id ${all_aligned_windows[$current_id]} )
	read x y w h {x,y}_border <<< ${old_properties[*]:1}

	get_display_properties

	[[ $alignment_direction == h ]] &&
		orientation=x || orientation=y
	set_alignment_properties $alignment_direction

	if [[ $1 ]]; then
		properties=( ${old_properties[*]} )
		((!start_block && !block_dimension)) &&
			read block_{start,dimension} _ <<< $(get_alignment)
	fi

	start_interactive window

	border=${old_properties[-(index % 2 + 1)]}
	separator=$((margin + border))
	new_properties=( ${current_id:-$id} $x $y $w $h ${old_properties[*]: -2} )

	if [[ $1 ]]; then
		local ids="${!windows[*]}"
	else
		local ids="${!all_aligned_windows[*]}"
		all_aligned_windows[$current_id]="${new_properties[*]:1}"
	fi

	for edge in ${!edges[*]}; do
		[[ $edge == [hjkl] ]] && adjust_helper
	done

	id=$old_id
	[[ $1 ]] && all_aligned_windows[$id]="${new_properties[*]:1}"
}

update_workspaces() {
	workspaces=$(awk '{
			if (NR == FNR) {
				if (/^orientation/) i = ($NF == "horizontal") ? 2 : 3
				if (/^display.*(xy|size)/) {
					gsub("[^0-9]", "", $1)
					#ad[$1] = ad[$1] " " ad[$1] + $i
					ad[$1] = ad[$1] + $i " " $i
				}
			} else {
				sub("0x0*", "0x", $1)
				for (di in ad) {
					split(ad[di], dp)
					#if ($(i + 1) > dp[1] &&
					#	$(i + 1) + $(i + 3) < dp[2]) d = di
					if ($(i + 1) > dp[2] &&
						$(i + 1) + $(i + 3) < dp[1]) d = di
				}
				print "[" $1 "]=" $2 "_" d
			}
		}' ~/.config/orw/config <(wmctrl -lG))

	eval workspaces=( $workspaces )
}

set_workspace_windows() {
	unset id properties window_count
	windows=()

	for ws in ${!workspaces[*]}; do
		[[ ${workspaces[$ws]} == ${workspace}_${display} ]] &&
			windows[$ws]="${all_windows[$ws]}"
	done

	window_count=${#windows[*]}
}

sort_by_workspaces() {
	for wid in $current_ids; do
		workspace_diff=$((${workspaces[$wid%_*]} - workspace))
		echo ${workspace_diff#-} $wid
	done | sort -nk 1,1 | cut -d ' ' -f 2 | xargs
}

spy() {
	xprop -spy -root _NET_ACTIVE_WINDOW _NET_CLIENT_LIST_STACKING _NET_CURRENT_DESKTOP |
		awk '{
			c = ($1 ~ "ACTIVE_WINDOW") ? "id" : ($1 ~ "DESKTOP") ? "desktop" : "all_ids"
			gsub("(.*#|,)", "")

			v = $0
			if (c != lc || ac[c] != v) {
				if (c == "desktop") gsub(".* ", "")
				else if (c == "all_ids" && length(v) == length(ac[c])) next
				else if (c == "id" && (length(v) < 5 || v !~ "0x\\w*")) next

				lc = c
				ac[c] = v

				print c, $0
				fflush()
			}
		}'
}

signal_event() {
	local module=$1 change="$2" value="$3"

	[[ -p /tmp/$module.fifo ]] &&
		echo "$change $value" > /tmp/$module.fifo &
}

signal_tiling() {
	if [[ $alignment_direction == [hv] ]]; then
		local wm_mode
		[[ $reverse ]] && wm_mode+='r'
		[[ $full ]] && wm_mode+='f'
	fi

	signal_event "workspaces" "tiling" \
		"$wm_mode${global_alignment_direction::1} ${tiling_workspaces[*]}"
}

signal_event_event() {
	#adjust_workspaces
	signal_tiling
	signal_event "workspaces" "windows" "$workspace $id ${!windows[*]}"
	signal_event "launchers" "active" "${current_id:-$id}"

	read sbg pbfg <<< $(\
		sed -n 's/^\w*g=.\([^"]*\).*/\1/p' ~/.orw/scripts/notify.sh | xargs)
}

set_tile_event() {
	local tiling=true {align,full}_index choosen_alignment reverse
	local original_properties=( ${properties[*]} ) resize_after_tiling
	local original_alignment=${alignments[$current_id]}
	local style=$rofi_style item_count theme_str

	[[ $rofi_state == opened ]] && toggle_rofi
	#remove_tiling_window no_change
	#local windows_to_ignore=$id

	local tiling_id=$(select_tiling_win)
	#select_tiling_window
	toggle_rofi

	item_count=4
	set_theme_str
	align_index=$(echo -e '\n\n\n' |
		rofi -dmenu -format i -theme-str "$theme_str" -theme main)

	item_count=2
	set_theme_str
	full_index=$(echo -e '\n' |
		rofi -dmenu -format i -theme-str "$theme_str" -theme main)

	toggle_rofi

	if [[ $align_index ]]; then
		((align_index > 1)) &&
			choosen_alignment=v || choosen_alignment=h
		((!(align_index % 2))) && reverse=true
	fi

	remove_tiling_window no_change
	local windows_to_ignore=$id
	id=$tiling_id
	properties=( $id ${all_windows[$id]} )

	#sec_properties=( $id ${properties[*]} )
	#properties=( $current_id ${all_windows[$current_id]} )
	#properties=( $id ${sec_properties[*]} )
	#local windows_to_ignore=$current_id

	local windows_to_ignore=( $current_id )
	((full_index)) &&
		make_full_window || align

	#if [[ $choosen_alignment != $original_alignment ]]; then
		for resized_id in ${resize_after_tiling[*]}; do
			[[ ${!all_aligned_windows[*]} != *$resized_id* ]] &&
				all_aligned_windows[$resized_id]="${all_windows[$resized_id]}"
		done
	#fi

	update_aligned_windows
	xdotool windowactivate ${original_properties[0]} &
	workspaces[${original_properties[0]}]=${workspaces[$tiling_id]}
}

set_min_event() {
	local event=min

	xdotool windowminimize $id

	[[ $rofi_state == opened ]] && toggle_rofi
	properties=( $id ${windows[$id]} )

	align m
	update_aligned_windows
}

set_max_event() {
	local event=max

	[[ $rofi_state == opened ]] && toggle_rofi

	if [[ ${states[$id]} ]]; then
		unset maxed_id
		restore
	else
		maxed_id=$id
		get_full_window_properties $id
		#wmctrl -ir $id -e 0,$x,$y,$w,$h &
		set_window $id "$wx $wy $ww $wh" &
		properties=( $id ${windows[$id]} )

		align m

		properties=( $x $y $w $h ${properties[*]: -2} )
		all_windows[$maxed_id]="${properties[*]}"
		local current_id
	fi

	update_aligned_windows
}
	
set_update_event() {
	update_values
}

set_move_event() {
	moving_id=$id move_window=true

	#[[ ${tiling_workspaces[*]} == *$workspace* ]] &&
	#	remove_tiling_window no_change || xdotool windowminimize $id

	[[ ${tiling_workspaces[*]} == *$workspace* ]] &&
		remove_tiling_window no_change || unset windows[$id]

	local rofi_pid=$(pidof -x signal_windows_event.sh)
	[[ $rofi_pid ]] && kill -USR1 $rofi_pid

	if [[ $rofi_state != closed ]]; then
		local new_workspace{,_name}
		read new_workspace{,_name} added_workspace <<< \
			$(~/.orw/scripts/rofi_scripts/dmenu.sh workspaces move)
		[[ $rofi_state ]] && toggle_rofi
	fi

	#if [[ $new_workspace ]]; then
	#	[[ ${tiling_workspaces[*]} == *$workspace* ]] &&
	#		new_tiling_workspace=$new_workspace
	#	wmctrl -ir $id -t $new_workspace
	#	wmctrl -s $new_workspace
	#fi

	#local added_workspace=$(wmctrl -d | awk '$2 == "*" { print $1 == "'"$new_workspace"'" }')
	([[ ${tiling_workspaces[*]} == *$new_workspace* ]] || ((added_workspace))) &&
		#(($(wmctrl -d | awk '$2 == "*" { print $1 == "'"$new_workspace"'" }')))) &&
		xdotool windowminimize $id

	#echo "SW: $(date +'%s') - $workspace: $new_workspace" >> ~/sec.log
	#echo "SW: $added_workspace - $workspace: $new_workspace"
	#wmctrl -d

	if ((!${#windows[*]})); then
		tmp=$(awk '
			/names/ {
				wn = !wn
				if (wn) wi = NR + 1 + '$workspace'
			}

			wi && NR == wi && /tmp/ {
				gsub("\\s*<[^>]*.", "")
				print
				exit
			}' ~/.config/openbox/rc.xml)

		#echo TMP: $tmp, $workspace, $new_workspace, ${#windows[*]}

		if [[ $tmp ]]; then
			((new_workspace -= new_workspace > workspace))
			~/.orw/scripts/workspacectl.sh remove $tmp $new_workspace

			if ((new_workspace == workspace)); then
				#wmctrl -ir $id -t $workspace
				adjust_workspaces
				set_workspace_windows
				align_moved_window
				#wmctrl -ir $id -b add,above &
				#echo xdotool windowactivate $id
				xdotool windowactivate $id

				#echo LIST: $workspace, $new_workspace, $id, ${properties[*]}
				#list_windows
			fi

			unset tmp
		fi
	elif [[ $new_workspace ]]; then
		declare -A all_aligned_windows
		for resized_id in ${resize_after_tiling[*]}; do
			[[ ${!all_aligned_windows[*]} != *$resized_id* ]] &&
				all_aligned_windows[$resized_id]="${all_windows[$resized_id]}"
		done

		update_aligned_windows

		##echo $added_workspace, ${tiling_workspaces[*]} == $workspace 
		#((added_workspace)) && [[ ${tiling_workspaces[*]} == *$workspace* ]] &&
		#	new_tiling_workspace=$new_workspace
		if ((added_workspace)); then
			[[ ${tiling_workspaces[*]} == *$workspace* ]] &&
				new_tiling_workspace=$new_workspace
			workspaces[$id]=${new_workspace}_${display}
			echo workspaces[${new_workspace}_${display}]=$id
		fi
	fi

	wmctrl -ir $id -t $new_workspace
	wmctrl -s $new_workspace

	xdotool windowminimize $id
}

tile_windows() {
	local alignment_direction {display,total}_surface scale
	declare -A surfaces {all_,}aligned_windows

	update_windows

	for windex in ${!windows[*]}; do
		read x y w h xb yb <<< "${windows[$windex]}"
		surface=$(((w + xb) * (h + yb)))
		((total_surface+=surface))
		surfaces[$windex]=$surface

		echo "$windex $xb $yb $x $y $w $h" #>> $shm_floating_properties
	done

	read d_{xs,ys,xe,ye} <<< ${display_properties[*]}
	display_surface=$(((d_xe - d_xs) * (d_ye - d_ys)))
	scale=$(echo "$display_surface / $total_surface" | bc -l)

	scalled_surfaces=(
		$(
			for surface_win in ${!surfaces[*]}; do
				surface=${surfaces[$surface_win]}
				scalled_surface=$(echo "($scale * $surface) / 1" | bc)
				echo "${scalled_surface}_${surface_win}"
			done | sort -nr
		)
	)

	for surface_index in ${!scalled_surfaces[*]}; do
		read scalled_surface wid <<< "${scalled_surfaces[surface_index]/_/ }"
		read {x,y}_border <<< "${all_windows[$wid]#* * * * }"

		if ((surface_index < ${#scalled_surfaces[*]} - 1 ||
			${#scalled_surfaces[*]} == 1)); then
			if ((!surface_index)); then
				properties=( ${display_properties[*]} )
				(( properties[2] -= ${properties[0]} ))
				(( properties[3] -= ${properties[1]} ))

				[[ ${alignments[$wid]} == h ||
					(! ${alignments[$wid]} && ${properties[2]} -gt ${properties[3]}) ]] &&
					alignment_direction=h fixed_index=3 changing_index=2 ||
					alignment_direction=v fixed_index=2 changing_index=3
			else
				[[ $alignment_direction == h ]] &&
					alignment_direction=v fixed_index=2 changing_index=3 ||
					alignment_direction=h fixed_index=3 changing_index=2
			fi

			changing_side=$((scalled_surface / ${properties[fixed_index]}))
			aligned_properties=( ${properties[*]} $x_border $y_border)
			aligned_properties[changing_index]=$((changing_side - margin))
			((aligned_properties[2]-=x_border))
			((aligned_properties[3]-=y_border))

			all_aligned_windows[$wid]="${aligned_properties[*]}"
			alignments[$wid]=$alignment_direction

			((properties[changing_index - 2] += changing_side))
			((properties[changing_index] -= changing_side))
		fi
	done

	if ((${#scalled_surfaces[*]} > 1)); then
		aligned_properties=( ${properties[*]} $x_border $y_border)
		((aligned_properties[2]-=x_border))
		((aligned_properties[3]-=y_border))

		all_aligned_windows[$wid]="${aligned_properties[*]}"
		alignments[$wid]=$alignment_direction
	fi

	update_aligned_windows

	properties=( ${windows[$id]} )
}

untile_windows() {
	window_ids="${!windows[*]}"

	while read wid {x,y}b props; do
		#wmctrl -ir $wid -e 0,${props// /,} &
		set_window $wid props &
		windows[$wid]="$props $xb $yb"
		all_windows[$wid]="$props $xb $yb"
	done <<< $(awk -i inplace '
		BEGIN { wp = "'"${window_ids// /|}"'" }

		$1 ~ "^(" wp ")$" {
			id = $1
			sub("[^ ]* ", "")
			ow[id] = $0
			next
		}

		{ print }

		END { for (id in ow) print id, ow[id] }' $shm_floating_properties)
}

set_toggle_tiling_workspace_event() {
	local event=update_workspaces

	if [[ ${tiling_workspaces[*]} == *$workspace* ]]; then
		tiling_workspaces=( ${tiling_workspaces[*]/$workspace} )
		set_new_position center center 0 0 yes
	else
		tiling_workspaces+=( $workspace )
		tile_windows
		set_new_position ${new_x:-center} ${new_y:-center} 150 150
	fi

	signal_tiling

	sed -i "/^tiling/ s/[0-9 ]\+/ ${tiling_workspaces[*]} /" $0
}

set_update_workspaces_event() {
	event=update_workspaces

	[[ ${tiling_workspaces[*]} =~ $desktop_index ]] && toggle_rofi

	all_tiling_workspaces=${tiling_workspaces[*]}
	read desktop_{index,name} <<< $(~/.orw/scripts/rofi_scripts/dmenu.sh \
		workspaces move ${all_tiling_workspaces// /,})

	[[ $rofi_state == opened ]] && toggle_rofi

	if [[ $desktop_index ]]; then
		if [[ ${tiling_workspaces[*]} =~ $desktop_index ]]; then
			tiling_workspaces=( ${tiling_workspaces[*]/$desktop_index} )
			set_new_position center center 0 0 yes
		else
			tiling_workspaces+=( $desktop_index )
			tile_windows
			set_new_position ${new_x:-center} ${new_y:-center} 150 150
		fi
	fi

	signal_tiling

	sed -i "/^tiling/ s/[0-9 ]\+/ ${tiling_workspaces[*]} /" $0
}

set_rotate_event() {
	local event=rotate
	[[ $rofi_state == opened ]] && toggle_rofi
	rotate
}

transform() {
	properties=( $(get_windows $id | cut -d ' ' -f 2-) )

	if [[ ${tiling_workspaces[*]} == *$workspace* ]]; then
		old_properties=( ${all_windows[$id]} )
		[[ "${old_properties[*]}" != "${properties[*]}" ]] && resize
	else
		all_windows[$id]="${properties[*]}"
		windows[$id]="${properties[*]}"
	fi
}

set_transform_resize_event() {
	local event=resize
	get_workspace_windows
	transform
}

set_transform_move_event() {
	local event=move
	get_workspace_windows
	transform
}

set_transform_swap_event() {
	local event=swap
	get_workspace_windows
	transform
}

set_swap_event() {
	event=swap
	update_windows
	select_window

	windows[$id]="${second_window_properties[*]}"
	windows[$second_window_id]="${properties[*]}"

	for wid in $id $second_window_id; do
		props=${windows[$wid]% * *}
		#wmctrl -ir $wid -e 0,${props// /,} &
		set_window $wid props &
	done
}

set_align_event() {
	local alignment_direction
	declare -A surfaces {all_,}aligned_windows

	for windex in ${!windows[*]}; do
		read w h xb yb <<< "${windows[$windex]#* * }"
		surface=$(((w + xb) * (h + yb)))
		((total_surface+=surface))
		surfaces[$windex]=$surface

		echo "$windex ${windows[$windex]::4}" >> $shm_floating_properties
	done

	read d_{xs,ys,xe,ye} <<< ${display_properties[*]}
	display_surface=$(((d_xe - d_xs) * (d_ye - d_ys)))
	scale=$(echo "$display_surface / $total_surface" | bc -l)

	ratios=(
		$(
			for ratio_win in ${!surfaces[*]}; do
				surface=${surfaces[$ratio_win]}
				scalled_surface=$(echo "($scale * $surface) / 1" | bc)
				((total_scalled_surface+=scalled_surface))
				ratio=$(echo "$surface / $total_surface" | bc -l)
			done | sort -nr
		)
	)

	total_ratio=1

	for ratio_index in ${!ratios[*]}; do
		current_id=${ratios[ratio_index + 1]#*_}
		read ratio id <<< "${ratios[$ratio_index]/_/ }"
		align_ratio=$(echo "$total_ratio / ($total_ratio - $ratio)" | bc -l)
		total_ratio=$(echo "$total_ratio - $ratio" | bc -l)

		x_border=0 y_border=0

		if [[ ${total_ratio#.} != 000* ]]; then
			if ((!ratio_index)); then
				properties=( $id ${display_properties[*]} )
				(( properties[3] -= ${properties[1]} ))
				(( properties[4] -= ${properties[2]} ))
			fi

			properties+=( $x_border $y_border )

			windows=( [$id]="${properties[*]:1}" )

			[[ $alignment_direction == h ]] &&
				alignment_direction=v || alignment_direction=h
			set_alignment_properties $alignment_direction

			read _ _ _ aligned <<< $(get_alignment)
			eval aligned_windows=( $aligned )

			for aligned_win in $id $current_id; do
				props="${aligned_windows[$aligned_win]}"
				properties[index + 2]=${props#* }
				properties[index]=${props% *}

				if [[ $aligned_win == $current_id ]]; then
					properties=( $current_id ${properties[*]:1:4} )
				else
					read {x,y}_border <<< "${all_windows[$id]#* * * * }"
					aligned_properties=( ${properties[*]:1} )
					(( aligned_properties[2] -= x_border ))
					(( aligned_properties[3] -= y_border ))
					aligned_properties[-2]=$x_border
					aligned_properties[-1]=$y_border

					all_aligned_windows[$aligned_win]="${aligned_properties[*]}"
					alignments[$aligned_win]=$alignment_direction
				fi
			done
		fi
	done

	read {x,y}_border <<< "${all_windows[$id]#* * * * }"
	aligned_properties=( ${properties[*]:1} )
	(( aligned_properties[2] -= x_border ))
	(( aligned_properties[3] -= y_border ))
	all_aligned_windows[$id]="${aligned_properties[*]} $x_border $y_border"
	alignments[$aligned_win]=$alignment_direction

	update_aligned_windows

	[[ ${tiling_workspaces[*]} =~ $workspace ]] ||
		tiling_workspaces+=( $workspace )
}

set_offset_steps() {
	get_display_properties
	read x y dxe dye <<< ${display_properties[*]}

	w=$((dxe - x))
	h=$((dye - y))
	x_border=0
	y_border=0
	properties=( $x $y $w $h 0 0 )

	#read {x,y}_start {x,y}_end columns rows step <<< \
	#	$(awk -F '[_ ]' '
	#		$1 == "display" && $2 == "'"$display"'" {
	#			switch ($3) {
	#				case "xy":
	#					x = $(NF - 1)
	#					y = $NF
	#					break
	#				case "size":
	#					xs = $(NF - 1)
	#					xe = x + xs
	#					ys = $NF
	#					ye = y + ys
	#					break
	#				case "offset":
	#					y += $(NF - 1)
	#					ye -= $NF
	#					break
	#			}
	#		} END {
	#			s = 50
	#			while (xs % s + ys % s) s++
	#			print x, y, xe, ye, xs / s, ys / s, s
	#		}' $orw_config)

	#echo $display, ${display_properties[*]}

	read {x,y}_start {x,y}_end columns rows step <<< \
		$(awk -F '[_ ]' '
			$1 == "display" && $2 == "'"$display"'" {
				switch ($3) {
					case "size":
						w = $(NF - 1)
						h = $NF
						break
					case "xy":
						x = $(NF - 1)
						y = $NF
						xs = w
						xe = x + xs
						ys = h
						ye = y + ys
						break
					case "offset":
						y += $(NF - 1)
						ye -= $NF
						break
				}
			} END {
				s = 50
				while (xs % s + ys % s) s++
				print x, y, xe, ye, xs / s, ys / s, s
			}' $orw_config)

	x_step=$step
	y_step=$step
}

interactive_offsets() {
	declare -A offsets
	local empty_bg=$sbg step_diff

	[[ $rofi_state == opened ]] && toggle_rofi

	start_interactive offset

	awk -F '[_ ]' -i inplace '
		$2 == "offset" && $1 in o { sub($NF, $NF + o[$1]) }
		{
			if( NR == FNR) o[$1] = $2
			else print
		}' <(
			((${#offsets[*]})) &&
				for offset in ${!offsets[*]}; do
					echo $offset ${offsets[$offset]}
				done || echo 0
			) $orw_config &> /dev/null

	local offset_aligned_bars=$(awk '/^[^#]/ {
			f = FILENAME
			sub(".*/", "", f)
			if (!/-x/) print f
		}' $(eval ls ~/.config/orw/bar/configs/$bars) | xargs)

	if [[ $offset_aligned_bars ]]; then
		local bar_pid=$(ps -C run.sh --sort=start_time -o pid=,args= |
			awk '/'"$offset_aligned_bars"'/ { print $1; exit }')
		[[ $bar_pid ]] && kill -USR1 $bar_pid
	fi

	current_display=$display
	update_values
	display=$current_display
}

restore() {
	declare -A aligned_windows
	local alignment_direction=${alignments[$id]} neighbours reverse
	local {min_,opposite_,}start {current_{,opposite_},}end opposite_end next
	local segments old_count align_ratio
	set_alignment_properties $alignment_direction
	((opposite_index--))
	((index--))

	read segments neighbours <<< ${states[$id]}
	old_count=${segments%_*}
	align_ratio=${segments#*_}
	neighbours=( $neighbours )

	for neighbour in ${neighbours[*]}; do
		[[ $neighbour == $id ]] &&
			next=true && continue

		read -a neighbour_properties <<< ${windows[$neighbour]}
		read current_{start,size,border} <<< "${neighbour_properties[index]} \
			${neighbour_properties[index + 2]} ${neighbour_properties[index + 4]}"
		read current_opposite_{start,size,border} <<< "${neighbour_properties[opposite_index]} \
			${neighbour_properties[opposite_index + 2]} ${neighbour_properties[opposite_index + 4]}"
		current_opposite_end=$((current_opposite_start + current_opposite_size + 0))
		current_end=$((current_start + current_size + current_border))

		((!min_start || current_start < min_start)) && min_start=$current_start
		((current_end > end)) && end=$current_end

		((!opposite_start || current_opposite_start < opposite_start)) &&
			opposite_start=$current_opposite_start
		((current_opposite_end > opposite_end)) &&
			opposite_end=$current_opposite_end

		if [[ $next ]]; then
			start=$current_start
			unset next
		fi
	done

	size=-$margin

	[[ $next ]] &&
		start=$((end + margin)) &&
		((size-=${properties[index + 4]}))

	size=-$((margin + ${properties[index + 4]}))

	temp_properties=( 0 0 0 0 ${properties[*]: -2} )
	temp_properties[index]=$start
	temp_properties[opposite_index]=$opposite_start
	temp_properties[index + 2]=$size
	temp_properties[opposite_index + 2]=$((opposite_end - opposite_start))

	original_properties=( ${windows[$id]} )
	unset windows[$id]

	current_id=$id
	id=temp
	properties=( $id ${temp_properties[*]} )
	windows[$id]="${properties[*]:1}"

	local event=restore
	set_alignment_properties $alignment_direction
	read _ _ _ aligned <<< $(get_alignment) #"" print
	eval aligned_windows=( $aligned )

	unset windows[temp] aligned_windows[temp]
	id=$current_id

	for aw in ${!aligned_windows[*]}; do
		read new_{start,size} <<< ${aligned_windows[$aw]}

		[[ $aw == $id ]] &&
			old_properties=( ${properties[*]:1} ) ||
			old_properties=( ${windows[$aw]} )
		old_properties[index - 1]=$new_start
		old_properties[index + 1]=$new_size

		windows[$aw]="${old_properties[*]}"
		all_windows[$aw]="${old_properties[*]}"

		props="${old_properties[*]::4}"
		#wmctrl -ir $aw -e 0,${props// /,} &
		set_window $aw props &
	done

	update_alignment 
	properties=( ${windows[$id]} )

	unset states[$id]
}

make_full_window() {
	local event=full
	local direction=${choosen_alignment:-$alignment_direction}
	declare -A aligned_windows

	[[ ${direction::1} != [hv] ]] &&
		direction=${alignments[$id]}
	set_alignment_properties $direction

	read temp_{start,opposite_{start,dimension}} <<< $(list_windows | awk '
			BEGIN {
				m = '$margin'
				i = '$index' + 1
				oi = '$opposite_index' + 1
				r = "'"$reverse"'"
				s = (r) ? '${properties[index]}' : \
					'${properties[index]}' + '${properties[index + 2]}' + '${properties[index + 4]}'
			}

			{
				cws = (r) ? $i : $i + $(i + 2) + $(i + 4)
				cwoe = $oi + $(oi + 2) + $(oi + 4)
				if (cws == s) {
					if (!mos || $oi < mos) mos = $oi
					if (!moe || cwoe > moe) moe = cwoe
				}
			} END { print s + ((r) ? 0 : m), mos, moe - mos }
		')

	old_id=$id
	id=temp
	properties=( $id 0 0 0 0 ${properties[*]: -2} )
	properties[index + 2]=-$((margin + ${properties[index + 4]}))
	properties[index]=$temp_start
	properties[opposite_index]=$temp_opposite_start
	properties[opposite_index + 2]=$((temp_opposite_dimension - \
		${properties[opposite_index + 4]}))
	windows[$id]="${properties[*]:1}"

	read block_{start,dimension,segments} aligned <<< $(get_alignment)

	eval aligned_windows=( $aligned )
	read new_{start,size} <<< ${aligned_windows[$current_id]}

	properties[index]=$new_start
	properties[index + 2]=$new_size
	properties=( ${properties[*]:1} )
	windows[$current_id]="${properties[*]}"
	unset aligned_windows[temp]
	unset windows[temp]

	for win in ${!aligned_windows[*]}; do
		props=( $win ${windows[$win]} )
		props[index]=${aligned_windows[$win]% *}
		props[index + 2]=${aligned_windows[$win]#* }
		all_aligned_windows[$win]="${props[*]:1}"
	done

	alignments[$current_id]=$direction
	update_alignment 

	id=$old_id
}

get_stretch_properties() {
	list_windows | awk '
			BEGIN {
				nxs = '$dxs'
				nys = '$dys'
				nxe = '$dxe'
				nye = '$dye'

				wxs = '$wx'
				wys = '$wy'
				wxb = '$wxb'
				wyb = '$wyb'
				wxe = wxs + '$ww' + wxb + m
				wye = wys + '$wh' + wyb + m

				m = '$margin'
			}

			$1 != "'"$id"'" {
				cwxs = $2; cwys = $3; cwxe = $2 + $4 + $6 + m; cwye = $3 + $5 + $7 + m

				if ((cwys <= wys && cwye > wys) ||
					(cwye >= wye && cwys < wye) ||
					(cwys >= wys && cwye <= wye)) {
						if (cwxe <= wxs && cwxe > nxs) nxs = cwxe
						if (cwxs >= wxe && cwxs < nxe) nxe = cwxs - m
				}

				if ((cwxs <= wxs && cwxe > wxs) ||
					(cwxe >= wxe && cwxs < wxe) ||
					(cwxs >= wxs && cwxe <= wxe)) {
						if (cwye <= wys && cwye > nys) nys = cwye
						if (cwys >= wye && cwys < nye) nye = cwys - m
				}
			} END { print nxs, nys, nxe - wxb - nxs, nye - wyb - nys }'
}

set_stretch_event() {
	get_workspace_windows
	get_display_properties

	read d{xs,ys,xe,ye} <<< "${display_properties[*]}"
	read w{x,y,w,h,{x,y}b} <<< "${properties[*]}"

	properties=( $(get_stretch_properties) $wxb $wyb )
	local props="${properties[*]::4}"
	#wmctrl -ir $id -e 0,${props// /,} &
	set_window $id properties[*]

	all_windows[$id]="${properties[*]}"
	windows[$id]="${properties[*]}"
}

find_window_under_pointer() {
	local x y
	read x y display <<< $(xdotool getmouselocation --shell |
		awk -F '=' 'NR < 4 { print $NF }' | xargs)

	display=$(awk -F '[_ ]' '
		/^display.*(xy|size)/ {
			if ($3 == "xy") { x = $4; y = $5 }
			else if ('$x' > x && '$x' < x + $4 &&
				'$y' > y && '$y' < y + $4) { print $2; exit }
		}' ~/.config/orw/config)

	get_workspace_windows $display

	read id h v <<< \
		$(list_windows | awk '
			{
				wxs = $2
				wys = $3
				wxe = wxs + $4
				wye = wys + $5

				if (wxs <= '$x' && wxe >= '$x' && wys <= '$y' && wye >= '$y') {
					h = $2 + ($4 / 2) > '$x'
					v = $3 + ($5 / 2) > '$y'
					i = $1
				}
			} END { print i, h, v }'
		)
}

set_aligned_windows() {
	for wid in ${!aligned_windows[*]}; do
		read window_{start,size} <<< ${aligned_windows[$wid]}
		props=( ${windows[$wid]} )
		props[index - 1]=$window_start
		props[index + 1]=$window_size

		[[ $1 && $wid == $1 ]] && set_border_diff $wid
		new_props="${props[*]}"

		#[[ $no_change ]] || wmctrl -ir $wid -e 0,${new_props// /,} &
		[[ $no_change ]] || set_window $wid props[*] &

		all_windows[$wid]="${props[*]}"
		windows[$wid]="${props[*]}"
	done
}

wait_for_mouse_movement() {
	#local drag_counter pointer_id=$(xinput list |
	#	awk -F '=' '/pointer/ { sub("\t.*", "", $NF); p = $NF } END { print p }')

	#local pointer_id=$(xinput list | awk -F '=' '
	#	/(USB|Touchpad).*pointer/ { sub("\t.*", "", $NF)
	#		print $NF
	#		exit
	#	}')

	while read device_id; do
		xinput --query-state $device_id |
			grep 'down$' &> /dev/null && break
	done < <(xinput list | awk '
		p && $0 !~ "^" p { exit }
		/XTEST pointer/ { p = $0; sub("Virtual.*", "", p) }
		p && /Touchpad|USB|Mouse/ { d = $(NF - 3); sub(".*=", "", d); print d }')

	[[ $@ ]] &&
		local button=3 || local button=1

	while
		action=$(xinput --query-state $device_id |
			awk -F '=' '/button\['$button'\]/ { print $NF == "down" }')
		((action))
	do
		[[ $@ ]] && $@
		sleep 0.05
	done
}

set_move_with_mouse_event() {
	if [[ ${tiling_workspaces[*]} == *$workspace* ]]; then
		declare -A aligned_windows
		local action alignment {block_,}size align_ratio

		find_window_under_pointer
		properties=( $id ${windows[$id]} )

		alignment=${alignments[$id]}
		set_alignment_properties $alignment

		#test
		#echo MOVING $alignment: ${properties[*]}
		#get_alignment move print

		#get_alignment move print
		#read _ block_size _ aligned <<< $(get_alignment move)
		read _ _ align_ratio aligned <<< $(get_alignment move)
		eval aligned_windows=( $aligned )
		#size=${properties[index + 2]}

		update_alignment move
		set_aligned_windows
		wait_for_mouse_movement

		current_id=$id
		local windows_to_ignore=$current_id
		find_window_under_pointer

		if [[ $id ]]; then
			properties=( $id ${windows[$id]} )
			((${properties[3]} > ${properties[4]})) &&
				alignment=h || alignment=v
			((${!alignment})) && local reverse=true
			#align_ratio=$(echo "scale=1; ($block_size + $margin + $size) / ($size + $margin / 2)" | bc -l)
			echo $block_size, $margin, $size, $align_ratio

			set_alignment_properties $alignment

			align_ratio=${align_ratio#*_}
			read _{,,} aligned <<< $(get_alignment)
			eval aligned_windows=( $aligned )
			update_alignment

			new_properties=( ${all_windows[$current_id]} )
			new_properties[opposite_index - 1]=${properties[opposite_index]}
			new_properties[opposite_index + 1]=${properties[opposite_index + 2]}
			windows[$current_id]="${new_properties[*]}"

			set_aligned_windows $current_id

			signal_event "launchers" "swap" "$current_id $id $reverse"

			id=$current_id
			alignments[$id]=$alignment
			properties=( ${windows[$id]} )
			workspaces[$id]="${workspace}_${display}"
		else
			current_window_count=1
			display_properties=( ${displays[$display]} )
			id=$current_id
			handle_first_window
		fi
	fi
}

set_resize_with_mouse_event() {
	if [[ ${tiling_workspaces[*]} == *$workspace* ]]; then
		local action event=mouse_resize
		wait_for_mouse_movement transform resize
		transform resize
	fi
}

interactive_window_resize() {
	[[ ${alignment_direction::1} != [hv] ]] &&
		alignment_direction=${alignments[$id]}
	set_alignment_properties $alignment_direction

	adjust_window resize

	update_aligned_windows
}

set_rofi_window() {
	((rofi_offset <= 0 && rofi_opening_offset)) &&
		local rofi_offset=$rofi_opening_offset

	if ((rofi_offset > 0)); then
		local state=$1
		if [[ $state == open* ]]; then
			(( rofi_window[rofi_index] += rofi_offset ))
			local open_sign=-
		fi

		(( rofi_window[rofi_opposite_index + 2] -= ${rofi_window[rofi_opposite_index]} ))
		rofi_window[rofi_index + 2]=$open_sign$rofi_offset
		(( rofi_window[rofi_index + 2] -= margin ))

		echo "${rofi_window[*]}"
	fi
}

set_rofi_window() {
	((rofi_offset <= 0 && rofi_opening_offset)) &&
		local rofi_offset=$rofi_opening_offset

	if ((rofi_offset > 0)); then
		local state=$1

		local rofi_start=$(awk '
			$1 == "display_'"$display"'_xy" { print $('$rofi_index' + 1) + '$rofi_offset' }
			' ~/.config/orw/config)

		[[ $state == open* ]] && local open_sign=-

		(( rofi_window[rofi_opposite_index + 2] -= ${rofi_window[rofi_opposite_index]} ))
		rofi_window[rofi_index + 2]=$open_sign$((rofi_start - ${rofi_window[rofi_index]}))
		[[ $state == open* ]] && rofi_window[rofi_index]=$rofi_start
		(( rofi_window[rofi_index + 2] -= margin ))

		echo "${rofi_window[*]}"
	fi
}

set_rofi_windows() {
	rofi_style=$(awk 'END { gsub(".*\\s\"|\\..*", ""); print }' ~/.config/rofi/main.rasi)

	#local rofi_window=( temp ${current_display_properties[*]:-${display_properties[*]}} 0 0 )

	if [[ $1 ]]; then
		rofi_offset=$1
	elif [[ $rofi_style =~ ^((vertical_)?icons|dmenu)$ ]]; then
		[[ $rofi_style == dmenu ]] &&
			rofi_index=2 rofi_opposite_index=1 rofi_direction=v ||
			rofi_index=1 rofi_opposite_index=2 rofi_direction=h

		rofi_offset=$(awk '
			function get_value() {
				gsub("[^0-9]0?|(\";|px).*", "")
				return $0
			}

			$1 == "display_'$display'_offset" { d_o = $2 }

			$1 ~ "[xy]-offset:" {
				y = ($1 ~ "y")
				bo = get_value()
				ao = y ? bo - d_o : bo
			}

			$1 == "window-padding:" { wp = 2 * get_value() }
			$1 == "element-padding:" { ep = 2 * get_value() }
			$1 == "font:" { f = sprintf("%.0f", 1.65 * 12) } #get_value()
			END {
				print bo + wp + ep + f + ao #- '${display_properties[rofi_index-1]}'
			}' ~/.config/{orw/config,rofi/$rofi_style.rasi})
	fi

	#rofi_restore_windows="$(set_rofi_window restore)"
	#rofi_align_windows="$(set_rofi_window align)"
}

toggle_maxed_window() {
	local {opposite_,}sign
	[[ $rofi_windows_state == align ]] &&
		sign=+ opposite_sign=- || sign=- opposite_sign=+

	properties=( ${windows[$maxed_id]} )
	((properties[0] $sign= rofi_offset))
	((properties[2] $opposite_sign= rofi_offset))
	read x y w h b{x,y} <<< "${properties[*]}"

	#wmctrl -ir $maxed_id -e 0,$x,$y,$w,$h &
	set_window $maxed_id "$x $y $w $h" &

	windows[$maxed_id]="${properties[*]}"
	all_windows[$maxed_id]="${properties[*]}"
}

toggle_rofi() {
	local rofi_windows_state current_rofi_workspace=$rofi_workspace
	local {align,restore}_maxed no_change=$2

	[[ $1 ]] && local workspace=$1

	if [[ ! $rofi_state || $rofi_state == closed ]]; then
		rofi_workspace=$workspace
		rofi_windows_state=align
		local current_rofi_workspace=$rofi_workspace
		rofi_opening_offset=$rofi_offset
		rofi_opening_display=$display
		rofi_state=opened
		align_maxed=true
	else
		rofi_state=closed
		unset rofi_workspace
		[[ $event == resize_rofi ]] &&
			unset event {all_,}windows[rofi]

		rofi_windows_state=restore
		restore_maxed=true
		closing_rofi=true
	fi

	if ((rofi_offset > 0 || rofi_opening_offset > 0)); then
		if [[ $1 || ($workspace == $current_rofi_workspace &&
			${tiling_workspaces[*]} == *$workspace*) ]]; then
				declare -A aligned_windows
				local event=rofi #reverse=true
				local state_properties=rofi_${rofi_windows_state}_windows

				if [[ $id ]]; then
					[[ $id != temp ]] && get_workspace_windows

					local rofi_window=( temp ${display_properties[*]} 0 0 )
					local properties=( $(set_rofi_window $rofi_state) )
					echo $rofi_index: ${rofi_window[*]}, ${properties[*]}
					local id=temp

					local aligned=$(list_windows | grep -v "^\<$maxed_id\>" |
						sort -nk $((rofi_index + 1)),$((rofi_index + 1)) | awk '{
							print "'${properties[rofi_index]}'" + \
								"'${properties[rofi_index + 2]}'" + '$margin' == $('$rofi_index' + 1)
							exit
						}')

					if ((aligned)); then
						windows[$id]="${properties[*]:1}"
						set_alignment_properties $rofi_direction

						read _{,,} aligned <<< $(get_alignment move)
						eval aligned_windows=( $aligned )

						[[ $restore_maxed && $maxed_id ]] && toggle_maxed_window
						unset windows[temp]
						set_aligned_windows $no_change
						[[ $align_maxed && $maxed_id ]] && toggle_maxed_window
					fi
				fi
		fi
	fi

	if [[ $rofi_state == closed ]]; then
		local rofi_pid=$(get_rofi_pid rofi)
		((rofi_offset != rofi_opening_offset || rofi_pid)) &&
			local reset_rofi_windows=true

		#echo CLOSED $rofi_pid: $rofi_offset, $reset_rofi_windows
		unset rofi_opening_offset

		[[ $reset_rofi_windows ]] && set_rofi_windows
		[[ $rofi_pid ]] && kill -USR1 $rofi_pid
		unset rofi_state
	fi

	return 0
}

resize_rofi() {
	local id=rofi old_properties=( ${rofi_restore_windows#* } )
	set_rofi_windows
	local properties=( ${rofi_restore_windows#* } )
	windows[$id]="${properties[*]}"
}

get_translated_windows() {
	new_display=$1
	get_display_properties $id

	awk '
		/[xy]_offset/ { if (/x/) xo = $NF; yo = $NF }
		$1 ~ "display_'"$display"'_(size|xy|offset)" {
			if (/xy/) { cdx = $2; cdy = $3 } else {
				if (/size/) { cdw = $2; cdh = $3 } else { cdto = $2; cdbo = $3 }
			}
		}
		$1 ~ "display_'"$new_display"'_(size|xy)" {
			if (/xy/) { ndx = $2; ndy = $3 } else { ndw = $2; ndh = $3 }
		}

		function move() {
			mx = my = 0

			for (max in xm[d]) {
				split(max, maxa, "_")
				if (((y >= maxa[1] && y + h <= maxa[2]) ||
					(y <= maxa[1] && y + h >= maxa[2]) ||
					(y <= maxa[1] && y + h > maxa[1]) ||
					(y >= maxa[1] && y < maxa[2])) &&
						xm[d][max] > mx) mx = xm[d][max]
			}

			if (!mx) mx = int(nx)
			xm[d][y "_" y + h] = mx + nw

			for (max in ym[d]) {
				split(max, maxa, "_")
				if (((x >= maxa[1] && x + w <= maxa[2]) ||
					(x <= maxa[1] && x + w >= maxa[2]) ||
					(x <= maxa[1] && x + w > maxa[1]) ||
					(x >= maxa[1] && x < maxa[2])) &&
						ym[d][max] > my) my = ym[d][max]
			}

			if (!my) my = int(ny)
			ym[d][x "_" x + w] = my + nh

			if (mx + nw > ndw) nw = ndw - mx
			if (my + nh > ndh) nh = ndh - my
			#print d, $3, ndx + xo + mx, ndy + yo + cdto + my, nw - $8 - m, nh - $9 - m, $8, $9
			print d, $3, xo + mx, yo + cdto + my, nw - $8 - m, nh - $9 - m, $8, $9

			#print d, $3, ndx + xo + mx, ndy + yo + my, nw - $8 - m, nh - $9 - m, $8, $9
			#print d, $3, xo + mx, yo + my, nw - $8 - m, nh - $9 - m, $8, $9
		}

		NR > FNR && $2 == "'$display'" {
			d = $1; x = $4 - cdx - xo; y = $5 - cdy - (yo + cdto); w = $6 + $8 + m; h = $7 + $9 + m
			nx = x * hr; ny = y * vr; nw = sprintf("%.0f", w * hr); nh = sprintf("%.0f", h * vr)
			move()
		}

		ENDFILE {
			m = '$margin'
			if (NR == FNR) {
				ndw = ndw - 2 * xo + m; ndh = ndh - 2 * yo - (cdto + cdbo) + m
				cdw = cdw - 2 * xo + m; cdh = cdh - 2 * yo - (cdto + cdbo) + m
				#cdw = cdw - 2 * xo + m; cdh = cdh - 2 * yo - (cdto + cdbo) + m
				#ndw = ndw - 2 * xo + m; ndh = ndh - 2 * yo + m
				hr = ndw / cdw
				vr = ndh / cdh
			}
		}' ~/.config/orw/config <(
				for wid in ${!all_windows[*]}; do
					echo ${workspaces[$wid]/_/ } $wid ${all_windows[$wid]}
				done | sort -nk 1,1 -nk 4,4 -nk 5,5 -nk 6,6
			)
}

get_translated_windows() {
	new_display=$1
	new_display=2
	get_display_properties $id

	awk '
		/[xy]_offset/ { if (/x/) xo = $NF; yo = $NF }
		$1 ~ "display_'"$display"'_(size|xy|offset)" {
			if (/xy/) { cdx = $2; cdy = $3 } else {
				if (/size/) { cdw = $2; cdh = $3 } else { cdto = $2; cdbo = $3 }
			}
		}
		$1 ~ "display_'"$new_display"'_(size|xy)" {
			if (/xy/) { ndx = $2; ndy = $3 } else { ndw = $2; ndh = $3 }
		}

		function round(n) {
			return sprintf("%.0f", n)
		}

		function move() {
			#if (x) nx = round((cdw + m) / x)
			#if (y) nh = round((cdh + m) / y)
			#nxe = round((cdw + m) / (x + w + m))
			#nye = round((cdh + m) / (y + h + m))

			#print "START", x, y, nxa[x], nya[y]
			#nx = (x) ? nxa[x] : 0
			#ny = (y) ? nya[y] : 0
			nx = (x) ? ((nxa[x]) ? nxa[x] : round(ndw / (cdw / (x + m))) - m) : 0
			ny = (y) ? ((nya[y]) ? nya[y] : round(ndh / (cdh / (y + m))) - m) : 0
			nxe = round(ndw / (cdw / (x + w)))
			nye = round(ndh / (cdh / (y + h)))
			nxa[x + w] = nxe
			nya[y + h] = nye
			#print "END", x + w, nxe, y + h, nye
			nw = nxe - nx - m
			nh = nye - ny - m

			#print d, $3, x, y, w, h, cdw, cdh
			print d, $3, xo + nx, (yo + cdto) + ny, nw, nh
		}

		NR > FNR && $2 == "'$display'" {
			d = $1; x = $4 - cdx - xo; y = $5 - cdy - (yo + cdto); w = $6 + $8 + m; h = $7 + $9 + m
			nx = x * hr; ny = y * vr; nw = sprintf("%.0f", w * hr); nh = sprintf("%.0f", h * vr)
			move()
		}

		ENDFILE {
			m = '$margin'
			if (NR == FNR) {
				ndw = ndw - 2 * xo + m; ndh = ndh - 2 * yo - (cdto + cdbo) + m
				cdw = cdw - 2 * xo + m; cdh = cdh - 2 * yo - (cdto + cdbo) + m
				hr = ndw / cdw
				vr = ndh / cdh
			}
		}' ~/.config/orw/config <(
				for wid in ${!all_windows[*]}; do
					echo ${workspaces[$wid]/_/ } $wid ${all_windows[$wid]}
				done | sort -nk 1,1 -nk 4,4 -nk 5,5 -nk 6,6
			)
}

move_windows_to_display() {
	local current_workspace=$workspace all_displays="${!displays[*]}"
	local icons_template="^number_\(${all_displays// /\\\|}\)="

	[[ $rofi_state != opened ]] && toggle_rofi
	new_display_index=$(~/.orw/scripts/rofi_scripts/dmenu.sh menu_template "$icons_template")
	[[ $rofi_state == opened ]] && toggle_rofi

	(( new_display_index++ ))

	turn_off_display=$(xrandr -q |
		awk '$2 == "connected" { if (++di == "'"$new_display_index"'") d = $1 } END { print d }')

	#           
	~/.orw/scripts/notify.sh -t 100 -s fullscreen -i '' "DISCONNECT $turn_off_display" &

	while
		connected=$(xrandr -q | awk '$1 == "'"$turn_off_display"'" { print $2 == "connected" }')
		#connected=$(xrandr -q | awk '
		#	$2 ~ "connected" { if (++di == "'"$new_display_index"'") print $2 == "connected" }')
		((connected))
	do
		sleep 1
	done

	pidof dunst | xargs -r kill

	#xrandr --output $turn_off_display --off
	xrandr --auto

	while read workspace wid new_properties; do
		#workspaces[$wid]="${workspace}_${new_display_index}"
		echo ${all_windows[$wid]}: $new_properties
		((workspace == current_workspace)) &&
			windows[$wid]="$new_properties"
		all_windows[$wid]="$new_properties"
		set_window $wid "$new_properties"
		#echo $wid $new_properties
	done <<< $(get_translated_windows $new_display_index)

	properties=( ${windows[$id]} )
	workspace=$current_workspace
	#update_aligned_windows

	~/.orw/scripts/generate_orw_config.sh display
	update_values
	~/.orw/scripts/barctl.sh

	echo END $display: ${!displays[*]}, ${display_properties[*]}

	return

	new_display=1
	get_display_properties $id
	#local new_display_properties=( ${displays[$new_display]} )
	#local display_width=$((${display_properties[2]} - ${display_properties[0]}))
	#local display_height=$((${display_properties[3]} - ${display_properties[1]}))
	#local new_display_width=$((${new_display_properties[2]} - ${new_display_properties[0]}))
	#local new_display_height=$((${new_display_properties[3]} - ${new_display_properties[1]}))
	#echo $display_width, $new_display_width, $display_height, $new_display_height

	awk '
		/[xy]_offset/ { if (/x/) xo = $NF; yo = $NF }
		$1 ~ "display_'"$display"'_(size|xy|offset)" {
			if (/xy/) { cdx = $2; cdy = $3 } else {
				if (/size/) { cdw = $2; cdh = $3 } else { cdto = $2; cdbo = $3 }
			}
		}
		$1 ~ "display_'"$display_index"'_(size|xy)" {
			if (/xy/) { ndx = $2; ndy = $3 } else { ndw = $2; ndh = $3 }
		}

		function move() {
			##print x, y, $0, cdx, cdy
			#d = $2; x = $3 - cdx - xo; y = $4 - cdy - (yo + cdto); w = $5 + $7 + 10; h = $6 + $8 + 10
			#nx = x * hr; ny = y * vr; nw = w * hr; nh = h * vr
			##print x, y, nx, ny, w, h, nw, nh
			#print nx, ny, nw, nh

			mx = my = 0

			#if (length(xm)) {
				for (max in xm[d]) {
					split(max, maxa, "_")
					#if (y >= maxa[1] && y + h <= maxa[2] && xm[d][max] > mx) mx = xm[d][max]
					if (((y >= maxa[1] && y + h <= maxa[2]) ||
						(y <= maxa[1] && y + h >= maxa[2]) ||
						(y <= maxa[1] && y + h > maxa[1]) ||
						(y >= maxa[1] && y < maxa[2])) &&
							xm[d][max] > mx) mx = xm[d][max]
					#print max, xm[d][max], mx
				}
			#}
			if (!mx) mx = x
			xm[d][y "_" y + h] = mx + nw

			#if (length(ym)) {
				for (max in ym[d]) {
					split(max, maxa, "_")
					#if (x >= maxa[1] && x + w <= maxa[2] && ym[d][max] > my) my = ym[d][max]
					if (((x >= maxa[1] && x + w <= maxa[2]) ||
						(x <= maxa[1] && x + w >= maxa[2]) ||
						(x <= maxa[1] && x + w > maxa[1]) ||
						(x >= maxa[1] && x < maxa[2])) &&
							ym[d][max] > my) my = ym[d][max]
					#print max, ym[d][max], my
				}
			#}
			if (!my) my = y
			ym[d][x "_" x + w] = my + nh

			if (mx + nw > ndw) nw = ndw - mx
			if (my + nh > ndh) nh = ndh - my
			#print mx, nw, m, ndw, ndh
			print d, $3, ndx + mx, ndy + my, nw - $8 - m, nh - $9 - m
		}

		NR > FNR && $2 == "'$display'" {
			#d = $1; x = $3 - cdx - xo; y = $4 - cdy - (yo + cdto); w = $5 + $7 + m; h = $6 + $8 + m
			d = $1; x = $4 - cdx - xo; y = $5 - cdy - (yo + cdto); w = $6 + $8 + m; h = $7 + $9 + m
			nx = x * hr; ny = y * vr; nw = sprintf("%.0f", w * hr); nh = sprintf("%.0f", h * vr)
			#print "OP:", $5, w, $6, h

			move()
		}

		ENDFILE {
			m = '$margin'
			if (NR == FNR) {
				ndw = ndw - 2 * xo + m; ndh = ndh - 2 * yo - (cdto + cdbo) + m
				cdw = cdw - 2 * xo + m; cdh = cdh - 2 * yo - (cdto + cdbo) + m
				hr = ndw / cdw
				vr = ndh / cdh
				#print (ndw - 2 * xo), (cdw - 2 * xo)
				#print (ndh - 2 * yo - (cdto + cdbo)), (cdh - 2 * yo - (cdto + cdbo))
				#print cdw, cdh, ndw, ndh, hr, vr
			}
		}' ~/.config/orw/config <(
				for wid in ${!all_windows[*]}; do
					echo ${workspaces[$wid]/_/ } $wid ${all_windows[$wid]}
				done | sort -nk 1,1 -nk 4,4 -nk 5,5 -nk 6,6
			)
}

test() {
	#for w in ${!workspaces[*]}; do
	#	echo $w: ${workspaces[$w]}
	#done
	#exit

	get_translated_windows
	return

	move_windows_to_display
	return

	local size start {{align,full}_,}index choosen_alignment reverse

	[[ $rofi_state != opened ]] && toggle_rofi
	align_index=$(echo -e '\n\n\n\n\n\n\n' | rofi -dmenu -format i -theme main)
	toggle_rofi

	if [[ $align_index ]]; then
		if ((align_index)); then
			if ((align_index > 4)); then
				case $align_index in
					5) set_rotate_event;;
					6) set_move_event;;
					7) set_tile_event;;
				esac
			else
				if [[ ${tiling_workspaces[*]} == *$workspace* ]]; then
					remove_tiling_window no_change

					((align_index > 2)) &&
						choosen_alignment=v || choosen_alignment=h
					((align_index % 2)) && reverse=true

					local properties=( full ${display_properties[*]} ${properties[*]: -2} )
					((properties[3] -= ${properties[1]} + ${properties[5]}))
					((properties[4] -= ${properties[2]} + ${properties[6]}))

					make_full_window
					update_aligned_windows
					wmctrl -ia $id &
				else
					echo ${display_properties[*]}

					((align_index > 2)) &&
						index=1 opposite_index=0 || index=0 opposite_index=1

					local properties=( ${display_properties[*]} ${properties[*]: -2} )
					echo ${properties[*]}
					size=$(((${display_properties[index + 2]} - ${display_properties[index]}) / 2))
					properties[index + 2]=$((size - ${properties[index + 4]}))
					((!(align_index % 2))) && ((properties[index] += size))
					((properties[opposite_index + 2] -= \
						${properties[opposite_index]} + ${properties[opposite_index + 4]}))
					local props="${properties[*]::4}"
					echo ${properties[*]}: $props
					wmctrl -ir $id -e 0,${props// /,} &
				fi
			fi
		else
			set_stretch_event
		fi
	fi

	#local windows_to_ignore=$id

	#update_aligned_windows

	#killall spy_windows.sh xprop
	#exit



	for a in ${!alignments[*]}; do
		echo $a: ${alignments[$a]} - ${windows[$a]}
	done
	return

	declare -A aligned_windows
	local properties=( $id ${properties[*]} )
	local alignment_direction=${alignments[$id]}
	set_alignment_properties $alignment_direction
	read block_{start,dimension,segments} aligned <<< $(get_alignment move)
	echo ${aligned}
	#alignments[${current_id:-$id}]=$alignment_direction

	eval aligned_windows=( $aligned )
	update_alignment move force

	for a in ${!alignments[*]}; do
		echo $a: ${alignments[$a]} - ${windows[$a]}
	done
	return

	killall spy_windows.sh xprop
	exit

	return

	make_workspace_notification $workspace $previous_workspace
	#local properties=( $id ${properties[*]} )
	#start_interactive window true
	return

	local properties=( $id ${properties[*]} )
	local alignment_direction=${alignments[$id]}
	set_alignment_properties $alignment_direction
	get_alignment '' print

	killall spy_windows.sh xprop
	exit

	local old_properties=( 130 535 667 339 6 6 )
	local properties=( 130 520 681 354 6 6 )
	#windows[$id]="${old_properties[*]}"
	windows[$id]="130 535 667 339 6 6"
	all_windows[$id]="130 535 667 339 6 6"
	windows[0xc00003]="130 172 667 342 6 6"
	transform resize

	killall spy_windows.sh xprop
	exit

	toggle_rofi
	local id=0x1400003
	local properties=( $id ${windows[$id]} )
	local alignment_direction=${alignments[$id]}
	#local alignment_direction=h
	echo $alignment_direction: ${properties[*]}
	#make_full_window
	set_alignment_properties $alignment_direction
	get_alignment move print
	killall spy_windows.sh xprop
	exit

	local properties=( $id ${properties[*]} )
	local alignment_direction=${alignments[$id]}
	local alignment_direction=h
	echo $alignment_direction: ${properties[*]}
	make_full_window
	set_alignment_properties $alignment_direction
	get_alignment move print
	killall spy_windows.sh xprop
	exit

	align

	set_alignment_properties $alignment_direction

	echo $alignment_direction
	get_alignment '' print

	killall spy_windows.sh xprop
	exit

	local alignment_direction=h orientation=x
	local temp_index temp_properties=( ${display_properties[*]} )
	#temp_properties[2]=$((${properties[0]} + ${properties[2]} - ${temp_properties[0]}))
	#temp_properties[3]=$((${properties[1]} + ${properties[3]} - ${temp_properties[1]}))
	#temp_properties+=( ${properties[*]: -2} )
	((temp_properties[2] -= ${temp_properteis[0]}))
	((temp_properties[3] -= ${temp_properteis[1]}))
	temp_properties+=( 0 0 )

	set_alignment_properties $alignment_direction
	echo $index
	#[[ $alignment_direction == h ]] &&
	#	temp_index=0 || temp_index=1

	local block_{start,_,dimension}
	read block_{start,_,dimension} <<< "${temp_properties[*]:index-1:3}"
	echo ${display_properties[*]}
	echo $block_start, $block_dimension, ${temp_properties[*]}, ${properties[*]}
	read x y w h {x,y}_border <<< ${properties[*]}
	start_interactive window true
	killall spy_windows.sh xprop
	exit

	a=${alignments[$id]}
	properties=( $id ${properties[*]} )

	echo $a, ${properties[*]}

	set_alignment_properties $a
	get_alignment #move print

	killall spy_windows.sh xprop
	exit

	properties=( $rofi_restore_windows )
	echo ROFI ${properties[*]}
	list_windows
	list_windows | sort -nk 2,2 |
		awk '{
				print $2, $4
				print "'${properties[1]}'" + "'${properties[3]}'" + '$margin', $2
				exit
			}'
	
	echo $rofi_state: $rofi_align_windows, $rofi_restore_windows
	return

	killall spy_windows.sh xprop
	exit

	local tiling=true align_{index,options} choosen_alignment reverse

	remove_tiling_window
	[[ $rofi_state == opened ]] && toggle_rofi $workspace
	select_tiling_window

	toggle_rofi
	align_index=$(echo -e '\n\n\n' | rofi -dmenu -format i -theme main)
	toggle_rofi

	if [[ $align_index ]]; then
		((align_index > 1)) &&
			choosen_alignment=v || choosen_alignment=h
		((!(align_index % 2))) && reverse=true
	fi

	echo $align_index, $reverse, $choosen_alignment

	align
	update_aligned_windows
	wmctrl -ia ${original_properties[0]} &

	#set_alignment_properties $choosen_alignment
	#get_alignment

	killall spy_windows.sh xprop
	exit





	#echo TEST #>> rofi.log
	toggle_rofi
	return
	#echo $rofi_align_windows, $rofi_restore_windows, 
	#local id=rofi old_properties=( ${rofi_restore_windows#* } )
	#local properties=( ${old_properties[*]} )
	#((properties[2] += 5))
	#windows[$id]="${properties[*]}"
	#echo ${old_properties[*]}, ${properties[*]}
	#sleep 1
	#resize
	#echo ${properties[*]}, ${windows[$id]}
	#toggle_rofi
	
	sleep 1
	resize_rofi 5
	sleep 1
	resize_rofi -5
	sleep 1
	resize_rofi 5
	sleep 1
	toggle_rofi
	killall xprop spy_windows.sh
	exit
	return

	local properties=( $id ${properties[*]} )
	local alignment=${alignments[$id]}
	set_alignment_properties $alignment
	echo $alignment, ${properties[*]}
	get_alignment move print
	killall xprop sww.sh
	exit

	#list_windows
	#make_workspace_notification 2 0
	#killall sww.sh xprop
	#exit

	#~/.orw/scripts/notify.sh "toglling ROFI" &
	toggle_rofi
	return

	declare -A aligned_windows
	local event=rofi
	local reverse=true
	local rofi_offset=50
	#local rofi_start=$((${display_properties[0]} + rofi_offset))

	local id=temp
	properties=( $id ${display_properties[*]} 0 0 )

	local opened=true
	if [[ ! $opened ]]; then
		local open_sign=-
		(( properties[1] += rofi_offset ))
	fi

	properties[3]=$open_sign$rofi_offset
	(( properties[3] -= margin ))
	(( properties[4] -= ${properties[2]} ))

	windows[$id]="${properties[*]:1}"

	echo ${display_properties[*]}, ${properties[*]}

	#local alignment_direction=h
	set_alignment_properties h
	read _{,,} aligned <<< $(get_alignment move)
	eval aligned_windows=( $aligned )
	#echo $aligned
	set_aligned_windows

	killall xprop sww.sh
	exit

	local event=swap

	old_properties=( ${windows[$id]} )
	((properties[0]--))
	echo ${properties[*]}, ${old_properties[*]}
	resize

	killall xprop sww.sh
	exit

	interactive_offsets
	return

	properties=( $id ${properties[*]} )
	local ad=${alignments[$id]}
	set_alignment_properties $ad
	echo ${properties[*]}, ${properties[index]}
	get_alignment move print

	return
	killall sww.sh xprop
	exit

	local event=resize alignment_direction=h
	transform

	local alignment_direction=h
	interactive_window_resize

	interactive_offsets
	killall sww.sh xprop
	exit

	return

	[[ ${alignment_direction::1} != [hv] ]] &&
		alignment_direction=${alignments[$id]}
	set_alignment_properties $alignment_direction

	adjust_window resize

	for w in ${!all_aligned_windows[*]}; do
		echo $w: ${all_aligned_windows[$w]}
	done

	killall sww.sh xprop
	exit

	set_alignment_properties $alignment_direction
	echo $alignment_direction, $index, $opposite_index, $id, ${properties[index]}

	properties=( $(list_windows | awk '
			BEGIN {
				m = '$margin'
				i = '$index' + 1
				oi = '$opposite_index' + 1
				r = "'"$reverse"'"
				s = (r) ? '${properties[index - 1]}' : \
					'${properties[index - 1]}' + '${properties[index + 1]}' + '${properties[index + 3]}'
			}

			{
				cws = (r) ? $i : $i + $(i + 2) + $(i + 4)
				cwoe = $oi + $(oi + 2) + $(oi + 4)
				if (cws == s) {
					if (!mos || $oi < mos) mos = $oi
					if (!moe || cwoe > moe) moe = cwoe
				}
			} END { print "temp", s + m, mos, -m, moe - mos, 0, 0 }
		') )

	current_id=new
	id=temp
	windows[$id]="${properties[*]:1}"
	echo ${properties[*]}, ${windows[$id]}
	killall sww.sh xprop
	exit

	read block_{start,dimension,segments} aligned <<< $(get_alignment)
	eval aligned_windows=( $aligned )
	read new_{start,size} <<< ${aligned_windows[new]}
	echo $aligned
	echo $new_start, $new_size, ${aligned_windows[new]}, ${properties[*]}
	properties[index]=$new_start
	properties[index + 2]=$new_size
	properties=( "${properties[*]:1}" )
	windows[new]="${properties[*]}"
	unset windows[temp]

	echo $block_start, $block_dimension

	id=new
	adjust_window resize

	for w in ${!all_aligned_windows[*]}; do
		echo $w: ${all_aligned_windows[$w]}
	done

	killall sww.sh xprop
	exit

	adjust_window resize
	echo DONE
	for w in ${!all_aligned_windows[*]}; do
		echo $w: ${all_aligned_windows[$w]}
	done
	#update_aligned_windows
	return

	declare -A aligned_windows
	echo TEST

	align_on_mouse_drag
	return

	#~/.orw/scripts/notify.sh "MOUSE"
	#echo $id, ${properties[*]}
	local action alignment_direction

	#local id=$(xdotool getmouselocation --shell | awk -F '=' 'END { print $NF }')

			#xargs -rn 1 xwininfo -id | parse_properties

	#read x y <<< $(xdotool getmouselocation --shell | awk -F '=' 'NR < 3 { print $NF }')

	#id=$(find_window_under_pointer)
	read id _ <<< $(find_window_under_pointer)
	properties=( $id ${windows[$id]} )
	local alignment_direction=${alignments[$id]}
	set_alignment_properties $alignment_direction
	local size=${properties[index + 2]}
	#read _{,,} aligned <<< $(get_alignment move)
	read _ block_size _ aligned <<< $(get_alignment move)
	eval aligned_windows=( $aligned )

	set_aligned_windows

	while
		action=$(xinput --query-state 11 |
			awk -F '=' '/button\[1\]/ { print $NF == "down" }')
			#awk -F '=' '$1 == "button[1]" { print $NF == "down" }')

		((action))
	do
		#echo DRAGGING
		#sleep 0.1
		continue
	done

	current_id=$id
	#id=$(find_window_under_pointer)
	read id h v <<< $(find_window_under_pointer)
	properties=( $id ${windows[$id]} )
	echo ${properties[*]}
	alignment_direction=${alignments[$id]}
	((${!alignment_direction})) && local reverse=true
	#echo LR: $alignment_direction, $v, $h, $reverse
	#echo $block_size, $size
	local align_ratio=$(echo "($block_size + $margin + $size) / $size" | bc -l)

	set_alignment_properties $alignment_direction
	read _{,,} aligned <<< $(get_alignment)
	eval aligned_windows=( $aligned )

	new_properties=( ${windows[$current_id]} )
	new_properties[opposite_index - 1]=${properties[opposite_index]}
	new_properties[opposite_index + 1]=${properties[opposite_index + 2]}
	windows[$current_id]="${new_properties[*]}"

	set_aligned_windows

	return
	killall sww.sh xprop
	exit

	stretch_window
	killall sww.sh xprop
	exit

	get_display_properties
	read d{xs,ys,xe,ye} <<< "${display_properties[*]}"
	read w{x,y,w,h,{x,y}b} <<< "${properties[*]}"

	list_windows | awk '
			BEGIN {
				nxs = '$dxs'
				nys = '$dys'
				nxe = '$dxe'
				nye = '$dye'

				wxs = '$wx'
				wys = '$wy'
				wxe = wxs + '$ww' + '$wxb' + m
				wye = wys + '$wh' + '$wyb' + m

				m = '$margin'
			}

			$1 != "'"$id"'" {
				cwxs = $2; cwys = $3; cwxe = $2 + $4 + $6 + m; cwye = $3 + $5 + $7 + m

				if ((cwys <= wys && cwye > wys) ||
					(cwye >= wye && cwys < wye) ||
					(cwys >= wys && cwye <= wye)) {
						if (cwxe <= wxs && cwxe > nxs) nxs = cwxe
						if (cwxs >= wxe && cwxs < nxe) nxe = cwxs - m
				}

				if ((cwxs <= wxs && cwxe > wxs) ||
					(cwxe >= wxe && cwxs < wxe) ||
					(cwxs >= wxs && cwxe <= wxe)) {
						if (cwye <= wys && cwye > nys) nys = cwye
						if (cwys >= wye && cwys < nye) nye = cwys - m
				}
			} END { print nxs, nys, nxe - wxb - nxs, nye - yb - nys }'

	killall sww.sh xprop
	exit

	echo ${alignments[$id]}
	properties=( $id ${properties[*]} )
	set_alignment_properties h #${alignments[$id]}
	get_alignment move print
	killall sww.sh xprop
	exit

	#adjust_window resize
	#
	#for w in ${!all_aligned_windows[*]}; do
	#	echo $w: ${all_aligned_windows[$w]}
	#done

	#killall sww.sh xprop
	#exit

	set_alignment_properties $alignment_direction
	echo $alignment_direction, $index, $opposite_index, $id, ${properties[index]}

	properties=( $(list_windows | awk '
			BEGIN {
				m = '$margin'
				i = '$index' + 1
				oi = '$opposite_index' + 1
				r = "'"$reverse"'"
				s = (r) ? '${properties[index - 1]}' : \
					'${properties[index - 1]}' + '${properties[index + 1]}' + '${properties[index + 3]}'
			}

			{
				cws = (r) ? $i : $i + $(i + 2) + $(i + 4)
				cwoe = $oi + $(oi + 2) + $(oi + 4)
				if (cws == s) {
					if (!mos || $oi < mos) mos = $oi
					if (!moe || cwoe > moe) moe = cwoe
				}
			} END { print "temp", s + m, mos, -m, moe - mos, 0, 0 }
		') )

	current_id=new
	id=temp
	windows[$id]="${properties[*]:1}"
	read block_{start,dimension,segments} aligned <<< $(get_alignment)
	eval aligned_windows=( $aligned )
	read new_{start,size} <<< ${aligned_windows[new]}
	echo $aligned
	echo $new_start, $new_size, ${aligned_windows[new]}, ${properties[*]}
	properties[index]=$new_start
	properties[index + 2]=$new_size
	properties=( "${properties[*]:1}" )
	windows[new]="${properties[*]}"
	unset windows[temp]

	echo $block_start, $block_dimension

	id=new
	adjust_window resize
	
	for w in ${!all_aligned_windows[*]}; do
		echo $w: ${all_aligned_windows[$w]}
	done

	killall sww.sh xprop
	exit

	adjust_window resize
	update_aligned_windows
	return

	interactive_offsets
	return


	#for w in ${!all_aligned_windows[*]}; do
	#	echo $w: ${all_aligned_windows[$w]}
	#done
	return
	#echo $id ${properties[*]}
	#killall sww.sh xprop
	#exit

	local al=${alignments[$id]}
	local count=3 align_ratio=3 event=restore
	echo A: $al

	properties=( $id ${properties[*]} )
	set_alignment_properties $al
	get_alignment

	killall sww.sh xprop
	exit

	#for w in ${!parents[*]}; do
	for w in ${!alignments[*]}; do
		echo $w: ${alignments[$w]}, ${states[$w]}
	done
	return

	#interactive_offset
	#killall xprop sww.sh
	#exit

	declare -A aligned_windows
	local alignment=${alignments[$id]}
	set_alignment_properties $alignment

	properties=( $id ${properties[*]} )
	read block_{start,size,segments} aligned <<< $(get_alignment move)
	eval aligned_windows=( $aligned )
	#echo $aligned

	while read wid new_start new_size; do
		new_properties=( ${windows[$wid]} )
		new_properties[index - 1]=$new_start
		new_properties[index + 1]=$new_size
		windows[$wid]="${new_properties[*]}"
		all_windows[$wid]="${new_properties[*]}"

		((${properties[index]} > $new_start)) &&
			before+=" $wid" || after+=" $wid"
	done < <(
		for aw in ${!aligned_windows[*]}; do
			echo $aw ${aligned_windows[$aw]}
		done | sort -nk 2,2
	)

	neighbours=( $before $id $after)

	echo NEI: ${neighbours[*]}
	restore
	killall xprop sww.sh
	exit

	set_alignment_properties $alignment
	((opposite_index--))
	((index--))

	for neighbour in ${neighbours[*]}; do
		echo NEI: ${windows[$neighbour]}

		[[ $neighbour == $id ]] &&
			next=true && continue

		#current_properties=( ${windows[$neighbour]} )

		#((!start || ${current_properties[index] < start)) &&
		#	start=${current_properties[index]}
		#((${

		#read current_{{,opposite_}start,{,opposite_}size,{x,y}_border} <<< ${windows[$neighbour]}
		read -a neighbour_properties <<< ${windows[$neighbour]}
		read current_{start,size,border} <<< "${neighbour_properties[index]} \
			${neighbour_properties[index + 2]} ${neighbour_properties[index + 4]}"
		read current_opposite_{start,size,border} <<< "${neighbour_properties[opposite_index]} \
			${neighbour_properties[opposite_index + 2]} ${neighbour_properties[opposite_index + 4]}"
		current_opposite_end=$((current_opposite_start + current_opposite_size + current_opposite_border))
		current_end=$((current_start + current_size + current_border))

		#echo $current_start, $current_opposite_start, $current_end
		#echo $current_size, $current_opposite_size

		((!min_start || current_start < min_start)) && min_start=$current_start
		((current_end > end)) && end=$current_end

		((!opposite_start || current_opposite_start < opposite_start)) &&
			opposite_start=$current_opposite_start
		((current_opposite_end > opposite_end)) &&
			opposite_end=$current_opposite_end

		if [[ $next ]]; then
			start=$current_start
			unset next
		fi

		#((old_size += current_size + current_border))
		#((old_size += current_size + current_border + margin))
	done

	local align_ratio=$(echo \
		"$((end - min_start)) / (${properties[index + 3]} + 2 * $margin)" | bc -l)

	size=-$margin

	[[ $next ]] &&
		start=$((end + margin)) &&
		((size-=${properties[index + 5]}))

	temp_properties=( 0 0 0 0 0 0 )
	temp_properties[index]=$((start + ${properties[index + 3]}))
	temp_properties[index]=$start
	temp_properties[opposite_index]=$opposite_start
	temp_properties[index + 2]=-$((${properties[index + 3]} + margin))
	temp_properties[index + 2]=$size
	temp_properties[opposite_index + 2]=$((opposite_end - opposite_start))
	#local align_ratio=$(echo "${properties[index + 3]}" | bc -l)
	echo $align_ratio, $start, $end, ${temp_properties[*]}

	original_properties=( ${windows[$id]} )
	unset windows[$id]

	current_id=$id
	id=temp
	properties=( $id ${temp_properties[*]} )
	windows[$id]="${properties[*]:1}"

	#set_alignment_properties $alignment
	#event=restore
	#get_alignment #"move" print
	##get_alignment "move" print
	#killall sww.sh xprop

	event=restore
	set_alignment_properties $alignment
	read _ _ _ aligned <<< $(get_alignment) #"" print
	eval aligned_windows=( $aligned )

	unset aligned_windows[temp]

	for aw in ${!aligned_windows[*]}; do
		read new_{start,size} <<< ${aligned_windows[$aw]}

		[[ $aw != $current_id ]] &&
			old_properties=( ${windows[$aw]} ) ||
			old_properties=( ${original_properties[*]} )
		old_properties[index - 1]=$new_start
		old_properties[index + 1]=$new_size

		props="${old_properties[*]::4}"
		echo wmctrl -ir $aw -e 0,${props// /,} &
	done

	unset event
	killall xprop sww.sh
	exit

	interactive_offsets
	return

	echo $display_orientation, $id, ${properties[*]}
	get_alignment_properties ${alignments[$id]}
	get_alignment move print
	killall xprop sww.sh
	exit

	for w in ${!parents[*]}; do
		echo $w: ${alignments[${w#*_}]}, ${parents[$w]}, ${states[${w#*_}]}
	done
	return

	local input=$1

	get_display_properties
	read x y dxe dye <<< ${display_properties[*]}
	w=$((dxe - x))
	h=$((dye - y))
	x_border=0
	y_border=0
	properties=( $x $y $w $h 0 0 )
	echo ${properties[*]}

	#read x y w h {x,y}_border <<< ${properties[*]}

	echo STARTS: $display, $x_start, $y_start, $x_end

	read {x,y}_start {x,y}_end columns rows step <<< \
		$(awk -F '[_ ]' '
			$1 == "display" && $2 == "'"$display"'" {
				switch ($3) {
					case "xy":
						x = $(NF - 1)
						y = $NF
						break
					case "size":
						xs = $(NF - 1)
						xe = x + xs
						ys = $NF
						ye = y + ys
						break
					case "offset":
						y += $(NF - 1)
						ye -= $NF
						break
				}
			} END {
				s = 50
				while (xs % s + ys % s) s++
				print x, y, xe, ye, xs / s, ys / s, s
			}' $orw_config)
		
		echo $x_start, $y_start, $x_end, $y_end, $columns, $rows, $step

	#x=80
	#w=1760
	#x_start=0
	#x_end=1920
	#x_step=60
	#orientation=x
	#block_start=0
	#block_dimension=1920
	#columns=32

	#alignment_direction=v
	#get_dimension_size y

	#echo $y_window_before, $y_window_size, $y_window_after
	#killall sww.sh xprop
	#exit

	#y_step=60
	#y=138
	#h=862
	#orientation=y
	#block_start=58
	#block_dimension=1022
	#total=18
	#get_dimension_size y

	((block_dimension)) &&
		empty_bg=$(sed -n '0,/^\s*background/ s/^\s*background[^"]*.\([^"]*\).*/\1/p' \
		~/.orw/dotfiles/.config/dunst/windows_osd_dunstrc) ||
		empty_bg='\$sbg'

	#orientation=x
	#alignment_direction=h
	#eval ${orientation}_step=$step
	x_step=$step
	y_step=$step

	get_dimension_size x
	get_dimension_size y
	#echo $x_window_before, $x_window_size, $x_window_after

	#set_geometry

	echo KILLING
	(
		killall dunst
		dunst -config ~/.config/dunst/windows_osd_dunstrc &
	) &> /dev/null

	local evaluate=offset empty_bg=$sbg step_diff
	display_notification

	#echo ${properties[*]}
	#echo $display
	#get_display_properties

	declare -A offsets
	read_keyboard_input

	#killall sww.sh xprop
	#exit

	awk -F '[_ ]' -i inplace '
		$2 == "offset" && $1 in o { sub($NF, $NF + o[$1]) }
		{
			if( NR == FNR) o[$1] = $2
			else print
		}' <(
			for offset in ${!offsets[*]}; do
				echo $offset ${offsets[$offset]}
			done
			) $orw_config &> /dev/null

	#sorted_diffs='0 2 1 3'
	current_display=$display
	update_values
	display=$current_display
	echo $display: ${displays[$display]}
	
	#killall sww.sh xprop
	#exit

	#[[ $step_diff == [0-9]* ]] && step_diff="+$step_diff"
	#~/.orw/scripts/borderctl.sh w_$orientation $step_diff
	#unset {x,y}_{window_size,{window,block}_{before,after}}
	return

	killall sww.sh xprop
	exit

	#if [[ $action == close ]]; then
		echo $alignment_direction, ${alignments[$id]}, ${properties[*]}
		set_alignment_properties $alignment_direction
		properties=( $id ${properties[*]} )
		#read {x,y}_border <<< ${properties[*]: -2}
		#list_windows
		get_alignment close print
		killall sww.sh xprop
		exit
	#fi
	return

	echo $workspace, $id, $current_id, ${windows[*]}
	return

	for a in ${!alignments[*]}; do
		echo $a, ${alignments[$a]}
	done
	return
	
	properties=( $id ${properties[*]} )
	echo $id, ${properties[*]}
	action=close
	alignment_direction=h
	set_alignment_properties $alignment_direction
	get_alignment $action
	killall sww.sh xprop
	exit
}

save_state() {
	rm $alignments_file $states_file

	for w in ${!alignments[*]}; do
		echo "$w ${alignments[$w]}" >> $alignments_file
		[[ ${!states[*]} == *$w* ]] &&
			echo "$w ${states[$w]}" >> $states_file
	done
}

set_interactive_offset_event() {
	interactive_offsets
}

set_interactive_resize_event() {
	local alignment_direction=${alignments[$id]}
	interactive_window_resize
}

set_rofi_toggle_event() {
	toggle_rofi
}

set_toggle_image_preview() {
	rofi_index=1 rofi_opposite_index=2 rofi_direction=h
	local image_preview_offset=$(sed -n '/^\s*window-width/ s/[^0-9]//gp' \
		~/.config/rofi/image_preview.rasi)
	[[ ! $rofi_state || $rofi_state == closed ]] &&
		set_rofi_windows $((image_preview_offset + margin))
	toggle_rofi
	[[ ! $rofi_state || $rofi_state == closed ]] &&
		unset rofi_offset && set_rofi_windows
}

set_rofi_resize_event() {
	local id=rofi old_properties=( ${rofi_restore_windows#* } )
	event=resize_rofi
	set_rofi_windows
	local properties=( ${rofi_restore_windows#* } )

	if ((rofi_offset > 0)); then
		[[ ! ${old_properties[*]} && ${properties[*]} ]] &&
			toggle_rofi || resize
	else
		if [[ ${old_properties[*]} && ! ${properties[*]} ]]; then
			local rofi_offset=1 rofi_restore_windows="temp ${old_properties[*]}"
			toggle_rofi
		fi
	fi
}

set_untile_event() {
	local new_{x,y}

	[[ $rofi_state == opened ]] && toggle_rofi
	remove_tiling_window

	get_display_properties $id
	new_x=$((x_start + ((x_end - x_start - ${properties[3]}) / 2)))
	new_y=$((y_start + ((y_end - y_start - ${properties[4]}) / 2)))
	properties[1]=$new_x
	properties[2]=$new_y
	local props="${properties[*]:1:4}"

	echo $x_start, $x_end
	echo $y_start, $y_end
	echo $new_x, $new_y: ${properties[*]}, ${props// /,}

	#wmctrl -ir $id -e 0,${props// /,}
	set_window $id properties[*]
	#wmctrl -ia $id
	xdotool windowactivate $id

	unset {all_,}windows[$id]
}

set_layout_event() {
	local size start {{align,full}_,}index choosen_alignment reverse
	local icons_template='^\(.*_side\|rotate\|tile\|move\|resize\)='

	#toggle_rofi
	align_index=$(~/.orw/scripts/rofi_scripts/dmenu.sh menu_template "$icons_template")
	[[ $rofi_state == opened ]] && toggle_rofi

	if [[ $align_index ]]; then
		if ((align_index)); then
			if ((align_index > 4)); then
				case $align_index in
					5) set_rotate_event;;
					6) set_move_event;;
					7) set_tile_event;;
				esac
			else
				[[ $rofi_state == opened ]] && toggle_rofi

				get_display_properties

				if [[ ${tiling_workspaces[*]} == *$workspace* ]]; then
					remove_tiling_window no_change

					((align_index > 2)) &&
						choosen_alignment=v || choosen_alignment=h
					((align_index % 2)) && reverse=true

					local properties=( full ${display_properties[*]} ${properties[*]: -2} )
					((properties[3] -= ${properties[1]} + ${properties[5]}))
					((properties[4] -= ${properties[2]} + ${properties[6]}))

					make_full_window
					update_aligned_windows
					#wmctrl -ia $id &
					xdotool windowactivate $id &
				else
					local margin=$((margin / 2))

					((align_index > 2)) &&
						index=1 opposite_index=0 || index=0 opposite_index=1

					local properties=( ${display_properties[*]} ${properties[*]: -2} )
					size=$(((${display_properties[index + 2]} - ${display_properties[index]}) / 2))
					properties[index + 2]=$((size - ${properties[index + 4]} - margin))
					((!(align_index % 2))) && ((properties[index] += size + margin))

					((properties[opposite_index + 2] -= \
						${properties[opposite_index]} + ${properties[opposite_index + 4]}))
					local props="${properties[*]::4}"

					#wmctrl -ir $id -e 0,${props// /,} &

					set_window $id properties[*] &
					all_windows[$id]="${properties[*]}"
					windows[$id]="${properties[*]}"
				fi
			fi
		else
			set_stretch_event
		fi
	fi
}

get_split_ratio() {
	read alignment_direction align_ratio <<< $(awk '{
			sx = '$start_x'; sy = '$start_y'
			ex = '$end_x'; ey = '$end_y'
			dx = sqrt((sx - ex) ^ 2)
			dy = sqrt((sy - ey) ^ 2)

			if (dx > dy) {
				a = "v"; i = 3
				s = (sy > ey) ? ey : sy
				p = s + dy / 2
			} else {
				a = "h"; i = 2
				s = (sx > ex) ? ex : sx
				p = s + dx / 2
			}

			r = (p - $i) / $(i + 2)
			if (!"'"$reverse"'") r = 1 - r
			r = 1 / r
			print a, r
		}' <<< ${properties[*]})
}

mouse_split() {
	find_window_under_pointer

	read start_{x,y} display <<< $(xdotool getmouselocation --shell |
		awk -F '=' 'NR < 4 { print $NF }' | xargs)

	wait_for_mouse_movement

	read end_{x,y} display <<< $(xdotool getmouselocation --shell |
		awk -F '=' 'NR < 4 { print $NF }' | xargs)

	[[ $reverse ]] && reverse_state=$reverse
	enforced_direction=true mouse_split=true reverse=$1
	properties=( $id ${all_windows[$id]} )

	get_split_ratio

	~/.orw/scripts/rofi_scripts/dmenu.sh run &
}

set_split_with_mouse_event() {
	mouse_split
}

set_split_with_mouse_reverse_event() {
	mouse_split true
}

trap test 63

trap set_min_event 35
trap set_max_event 36
trap set_move_event 37
trap set_swap_event 38
trap set_tile_event 39
trap signal_event_event 40
trap set_align_event 41
trap set_update_event 42
trap set_rotate_event 43
trap set_stretch_event 44
trap set_transform_move_event 45
trap set_transform_resize_event 46
trap set_transform_swap_event 47
trap set_update_workspaces_event 48
trap set_toggle_tiling_workspace_event 49
trap set_move_with_mouse_event 50
trap set_split_with_mouse_event 59
trap set_split_with_mouse_reverse_event 60
trap set_resize_with_mouse_event 51
trap set_interactive_offset_event 52
trap set_interactive_resize_event 53
trap set_rofi_toggle_event 54
trap set_rofi_resize_event 55
trap set_toggle_image_preview 56
trap set_untile_event 57
trap set_layout_event 58
trap display_notification 59
trap save_state SIGKILL SIGINT SIGTERM

declare -A {all_,}windows {all_,}aligned_windows workspaces border_gaps
declare -A displays alignments states last_display_window display_map

tiling_workspaces=( 1 2 )
workspace=$(xdotool get_desktop)

read total_workspace_count workspace <<< \
	$(wmctrl -d | awk '$2 ~ "^\\*" { cd = $1 } END { print $1, cd }')
read default_{x,y}_border <<< \
	$(awk '/border/ { print $NF }' $orw_config | xargs)
read -a all_ids <<< $(xprop -root _NET_CLIENT_LIST_STACKING | awk '{ gsub(".*#|,", ""); print }')

handle_width=$(sed -n 's/^.*handle.*width.*\s\+//p' \
	~/.orw/themes/theme/openbox-3/themerc)
update_windows all
update_workspaces
update_values

add_border_gap "${!all_windows[*]}"

get_display_mapping
set_workspace_windows

source ~/.orw/scripts/windowctl_by_input.sh windowctl_osd source
source ~/.orw/scripts/rofi_scripts/dmenu.sh

input_file=/tmp/input_test.fifo
read_command="id=\$(printf '0x%x' \$(xdotool getactivewindow));"
read_command+="while [[ \$input != d ]];"
read_command+="do read -rsn 1 input;"
read_command+="[[ \$input == d ]] && input_id=\$id;"
read_command+="echo \$id, \$current_id: \${input_id:-\$input} >> w.log;"
read_command+="wmctrl -lG >> w.log;"
read_command+="echo \${input_id:-\$input} > $input_file;"
read_command+="done"

input_file=/tmp/input_test.fifo
read_command="pidof -x auto.sh | xargs -r kill -SIGUSR1;"
read_command+="while [[ \$input != d ]];"
read_command+="do read -rsn 1 input;"
read_command+="echo \$input > $input_file;"
read_command+="done;"
read_command+="printf '0x%x' \$(xdotool getactivewindow) > $input_file"

evaluate_window_resize() {
	local move{_opposite,}_sign

	case $input in
		"<") sign=- opposite_sign=+;;
		">") sign=+ opposite_sign=-;;
		[jklh])
			if [[ $sign ]]; then
				if [[ $input == [jl] ]]; then
					[[ $input == j ]] &&
						properties=h || properties=w
					position=after
				else
					[[ $input == h ]] &&
						properties='w x' ||
						properties='h y'

					((${properties#* } $opposite_sign= step))
					position=before
				fi
			else
				local edge_sign=+

				[[ $input == [jk] ]] &&
					properties=y || properties=x
				[[ $input == [jl] ]] &&
					move_sign=+ move_opposite_sign=- ||
					move_sign=- move_opposite_sign=+

				case $input in
					j) local opposite_input=k;;
					k) local opposite_input=j;;
					h) local opposite_input=l;;
					l) local opposite_input=h;;
				esac

				position=after opposite_position=before
				eval "((${orientation}_block_$opposite_position $move_sign= 1))"
				((edges[$opposite_input] -= step))
			fi

			((${properties% *} ${move_sign:-$sign}= step))
			((diff += ${move_sign:-$opposite_sign}step))
			((edges[$input] += ${edge_sign:-$sign}step))

			[[ $sign ]] && eval "((${orientation}_window_size ${move_sign:-$sign}= 1))"
			eval "((${orientation}_block_$position ${move_opposite_sign:-$opposite_sign}= 1))"

			display_notification
	esac
}

evaluate_offset_resize() {
	local input=$1
	case $input in
		"<") sign=- opposite_sign=+;;
		">") sign=+ opposite_sign=-;;
		*)
			[[ $input == v ]] &&
				alignment_direction=v orientation=y properties='h y'
			[[ $input == h ]] &&
				alignment_direction=h orientation=x properties='w x'
			return
	esac

	((${properties#* } $sign= 2 * step))
	((${properties% *} $opposite_sign= step))

	((offsets[$orientation] $sign= step))

	eval "((${orientation}_window_after $sign= 1))"
	eval "((${orientation}_window_before $sign= 1))"
	eval "((${orientation}_window_size $opposite_sign= 2))"
	display_notification
}

read_keyboard_input() {
	[[ -p $input_file ]] && rm $input_file
	mkfifo $input_file

	alacritty -t input --class=input \
		-e bash -c "$read_command" &> /dev/null &

	display_notification

	local sign input_id
	while [[ $input != d ]]; do
		input=$(cat $input_file)
		[[ $input == 0x* ]] &&
			input_id=$input input=d
		evaluate_${evaluate_type}_resize $input
	done

	input_id=$(cat $input_file)
	input_ids+=( $input_id )

	killall dunst &> /dev/null

	unset input stop {x,y}_{window_size,{window,block}_{before,after}}
	rm $input_file
}

alignments_file=/tmp/alignments
states_file=/tmp/states

((window_count)) || rm $alignments_file $states_file

for file in alignments states; do
	file="${file}_file"
	if [[ -f ${!file} ]]; then
		eval "${file%%_*}=( $(awk '{ w = $1; sub(w " *", ""); printf "[%s]=\"%s\" ", w, $0 }' ${!file}) )"
	fi
done

align_moved_window() {
	#echo ALIGN: $id, $current_id, $moving_id
	if [[ ${tiling_workspaces[*]} =~ $workspace ]]; then
		if ((window_count)); then
			[[ $rofi_state == opened ]] && toggle_rofi 
			select_tiling_window

			toggle_rofi
			align_index=$(echo -e '\n\n\n' | rofi -dmenu -format i -theme main)
			full_index=$(echo -e '\n ' | rofi -dmenu -format i -theme main)
			toggle_rofi

			[[ $reverse ]] && reverse_state=$reverse
			[[ $choosen_alignment ]] && alignment_state=$choosen_alignment

			if [[ $align_index ]]; then
				((align_index > 1)) &&
					choosen_alignment=v || choosen_alignment=h
				((!(align_index % 2))) &&
					reverse=true
			fi

			tiling=true current_id=$moving_id

			((full_index)) &&
				make_full_window || align
			[[ $interactive ]] && adjust_window
			update_aligned_windows "$current_id"
			alignments[$current_id]=$alignment_direction

			unset reverse
			[[ $reverse_state ]] &&
				reverse=$reverse_state &&
				unset reverse_state

			unset choosen_alignment
			[[ $alignment_state ]] &&
				choosen_alignment=$alignment_state &&
				unset alignment_state
		else
			id=${original_properties[0]}
			current_window_count=1
			handle_first_window
		fi
	fi

	workspaces[${moving_id:-${current_id:-$id}}]=${workspace}_${display}
	#wmctrl -ia ${current_id:-$id} &
	#wmctrl -ir ${current_id:-$id} -t $workspace
	#echo ALIGN MOVED: xdotool windowactivate ${current_id:-$id} &
	xdotool windowactivate ${moving_id:-${current_id:-$id}} &

	properties=( ${all_windows[${moving_id:-${current_id:-$id}}]} )

	unset move_window tiling moving_id
}

shm_alignments=/tmp/alignments
shm_floating_properties=/tmp/shm_floating_properties

while read change new_value; do
	if [[ $change == desktop ]]; then
		unset notification
		previous_workspace=$workspace
		workspace=$new_value

		#((current_ws_count)) && previous_ws_count=$current_ws_count
		#current_ws_count=$(xdotool get_num_desktops)
		#echo $previous_ws_count, $current_ws_count

		#echo WSCHANGE: $workspace, $previous_workspace

		if ((workspace != previous_workspace)); then
			adjust_workspaces
			#echo tw $workspace: ${tiling_workspaces[*]}

			[[ $rofi_state == opened &&
				 ${tiling_workspaces[*]} == *$previous_workspace* ]] &&
				 toggle_rofi $previous_workspace

			set_workspace_windows

			[[ ! ${windows[*]} ]] &&
				signal_event "launchers" "active" &&
				signal_event "workspaces" "desktop" "$workspace"
			make_workspace_notification $workspace $previous_workspace
		fi

		current_ws_count=$(xdotool get_num_desktops)
		pattern="$previous_workspace.*$workspace|$workspace.*$previous_workspace"

		if [[ ! ${tiling_workspaces[*]} =~ $pattern ]]; then
			if [[ ${tiling_workspaces[*]} =~ $previous_workspace ]]; then
				set_new_position center center 0 0 yes
				latest_tiling_workspace=$previous_workspace
			elif [[ ${tiling_workspaces[*]} =~ $workspace ]]; then
				set_new_position ${new_x:-center} ${new_y:-center} 150 150
			fi
		fi

		[[ $move_window ]] && align_moved_window
	elif [[ $change == all_ids ]]; then
		previous_ids=( ${all_ids[*]} )
		all_ids=( $new_value )

		((${#previous_ids[*]} == ${#all_ids[*]})) && continue

		current_ids=$(comm -3 \
			<(tr ' ' '\n' <<< ${all_ids[*]} | sort) \
			<(tr ' ' '\n' <<< ${previous_ids[*]} | sort) | grep -o '0x\w\+')

		if [[ $missing_id && $missing_id == $current_id ]]; then
			current_id=$id
			properties=( ${windows[$id]} )
			unset missing_{window,id}
			continue
		fi

		if (((!input_count || input_count == 2) &&
			${#previous_ids[*]} > ${#all_ids[*]})); then
				[[ $current_ids =~ ' ' ]] &&
					closing_ids=$(sort_by_workspaces)

				current_window_id=$id
				for current_id in ${closing_ids:-$current_ids}; do
					[[ ${input_ids[*]} != *$current_id* ]] &&
						signal_event "launchers" "close" "$current_id"

					closing_id_workspace=${workspaces[$current_id]%_*}
					#echo ciw: $closing_id_workspace, $id, $current_id
					id=$current_id

					if [[ ${tiling_workspaces[*]} == *$closing_id_workspace* ]]; then
						if [[ ${input_ids[*]} == *$id* ]]; then
							for iid in ${!input_ids[*]}; do
								[[ ${input_ids[iid]} == $id ]] &&
									unset input_ids[iid] && break
							done

							continue
						elif [[ ${all_windows[$id]} ]]; then
							[[ $rofi_state == opened ]] && toggle_rofi
							properties=( $id ${all_windows[$id]} )

							align c

							update_aligned_windows
							((window_count--))
						fi
					fi

					if [[ ${all_windows[$id]} ]]; then
						unset {{all_,}windows,workspaces,alignments}[$id]
					fi
				done

				id=$current_window_id

				#echo closing: $closing_id_workspace, $workspace, $window_count
				windows_in_closing_workspace="${workspaces[*]//[^$closing_id_workspace]_?}"
				#echo "${#window_count} - ^$window_count^: $windows_in_closing_workspace : ${workspaces[*]}", $id: ${workspaces[$id]}
				#for w in ${!workspaces[*]}; do
				#	echo ws: $w, ${workspaces[$w]}
				#done
				#((!${#window_count})) && echo empty || echo not

				#if ((closing_id_workspace == workspace && !window_count)); then
				#if ((!${window_count//[^0-9]})); then
				if [[ ! ${windows_in_closing_workspace//[^0-9]} ]]; then
					tmp=$(awk '
						/names/ {
							wn = !wn
							if (wn) wi = NR + 1 + '$closing_id_workspace'
						}

						wi && NR == wi && /tmp/ {
							gsub("\\s*<[^>]*.", "")
							print
							exit
						}' ~/.config/openbox/rc.xml)

					if [[ $tmp ]]; then
						#if we're on a tmp workspace while last window is closed
						#we should move to the previously visited workspace and remove the current empty one
						#and shift all the windows to the right of the removed workspace, to the left
						if ((workspace == closing_id_workspace)); then
							workspace_to_restore=$((previous_workspace - (previous_workspace > closing_id_workspace)))
							workspace_not_shifted=$((workspace_to_restore == closing_id_workspace))
							#workspace_to_restore=$previous_workspace
							#workspace_not_shifted=$((previous_workspace - \
							#	(previous_workspace > closing_id_workspace) == closing_id_workspace))

							#shift_workspace_back=$((previous_workspace > closing_id_workspace))
							#workspace_to_restore=$((previous_workspace - shift_workspace_back))
							#((previous_workspace > closing_id_workspace)) &&
							#	shift_left_count=1 && unset workspaces_not_shifted || workspaces_not_shifted=1
							#workspace_to_restore=$((previous_workspace - shift_left_count))
						#else
						#	((closing_id_workspace > workspace)) && unset closing_id_workspace
						fi

						#echo aws: $shift_left_count, $workspaces_not_shifted, $workspace_to_restore

						~/.orw/scripts/workspacectl.sh remove $tmp $workspace_to_restore
						#since adjust_workspaces function is triggered by workspace change (from removed to the previous),
						#if it happens that previously visited workspace (the one we should move to after removal)
						#should become the current workspace (one to be removed) after shift is applied,
						#workspace won't change, thus adjust_workspace won't be triggered automatically,
						#so we have to run it manually
						((workspace_not_shifted)) && adjust_workspaces
						#echo ~/.orw/scripts/manage_workspaces.sh remove $tmp $workspace_to_restore
						((closing_id_workspace > workspace)) && unset closing_id_workspace
						unset workspace{s_not_shifted,_to_restore}



						#((workspace == closing_id_workspace)) &&
						#	workspace=$((previous_workspace - (previous_workspace > closing_id_workspace)))
						#	#workspace_to_restore=$previous_workspace || unset workspace_to_restore
						#echo WS: $workspace

						##~/.orw/scripts/manage_workspaces.sh remove $tmp $workspace_to_restore
						#echo ~/.orw/scripts/manage_workspaces.sh remove $tmp $workspace_to_restore
						##new_ws_count=$(~/.orw/scripts/manage_workspaces.sh remove $tmp $restore_workspace)

						##echo ~/.orw/scripts/manage_workspaces.sh remove $tmp $no_change
						##echo tmp: $tmp, $no_change, $workspace, $closing_id_workspace, $id
						##~/.orw/scripts/notify.sh -t 5 "CHANGING: $new_ws_count, $no_change, $closing_id_workspace"


						##if [[ $no_change ]]; then
						##	sleep 2
						##	wmctrl -s $previous_workspace
						##	echo CLOSING $previous_workspace
						##	sleep 2
						##	wmctrl -n $new_ws_count
						##fi
					else
						unset closing_id_workspace
					fi
				fi

				if ((closing_id_workspace != workspace)); then
					windows=()

					for wid in ${!all_windows[*]}; do
						[[ ${workspaces[$wid]} == ${workspace}_${display} ]] &&
							windows[$wid]="${all_windows[$wid]}"
						done
				fi


				[[ ! ${windows[*]} ]] &&
					signal_event "workspaces" "close" "$workspace"
				unset closing_ids

				# count should be decremented only when this condition is hit due to input window
				# if it has a value of 2, that means condition was hit due to closed window during input
				((input_count == 1)) && ((input_count--))
		else
			((input_count)) && ((input_count--)) && continue

			current_id=$current_ids
			window_title=$(wmctrl -l | sed -n "s/^0x0*${current_id#0x}.* //p")

			if [[ ${tiling_workspaces[*]} =~ $workspace ]]; then
				if [[ ${input_ids[*]} == *$current_id* ]]; then
					current_id=$id
					ignore=1
				else
					get_display_properties $current_id
					read current_window_count ignore <<< $(wmctrl -lG | awk '
						BEGIN {
							di = '$display_index' + 3
							ds = '${display_properties[display_index]}'
							dd = '${display_properties[display_index + 2]}'
							de = ds + dd
						}

						#$1 ~ "'"${current_id#0x}"'" { i = ($NF ~ "('${blacklist//,/|}')") }
						$1 ~ "'"${current_id#0x}"'" {
							i = (($NF ~ "('${blacklist//,/|}')") || $(di + 2) >= dd)
						}
						$2 == '$workspace' && $di >= ds && $di + 0 <= de \
							{ if($NF !~ "('${blacklist//,/|}')") cwc++ }
						END { print cwc++, i }')
				fi

				((ignore)) ||
					ignore=$(xprop -id $current_id _NET_WM_WINDOW_TYPE 2> /dev/null |
						awk '{ print $NF ~ "DIALOG$" }')

				if ((ignore)); then
					[[ $window_title =~ image_preview|cover_art_widget|DROPDOWN ]] && set_opacity
				else
					wmctrl -l | grep "^0x0*${current_id#0x}" &> /dev/null
					missing_window=$?

					if ((missing_window)); then
						missing_id=$current_id
					else
						if ((current_window_count == 1)); then
							id=$current_id
							handle_first_window
							alignments[$id]=$display_orientation
						else
							properties=( $id ${all_windows[$id]} )

							[[ $full ]] && make_full_window || align
							#[[ $interactive ]] && adjust_window
							if [[ $mouse_split ]]; then
								unset mouse_split align_ratio enforced_direction reverse
								[[ $reverse_state ]] &&
									reverse=$reverse_state &&
									unset reverse_state
							else
								[[ $interactive ]] && adjust_window
							fi

							wmctrl -l | grep "^0x0*${current_id#0x}" &> /dev/null
							missing_window=$?

							if ((missing_window)); then
								missing_id=$current_id
							else
								add_border_gap "$current_id"
								update_aligned_windows $current_id
								((window_count++))

								[[ ${input_ids[*]} ]] &&
									id=$current_id properties=( ${windows[$current_id]} )
							fi
						fi

						workspaces[$current_id]=${workspace}_${display}

						read x y w h xb yb <<< ${windows[$current_id]}
						new_x=$((x + (w - new_window_size) / 2 - ${display_properties[0]}))
						new_y=$((y + (h - new_window_size) / 2 - ${display_properties[1]}))

						#new_x=$x new_y=$y
						#new_x=$((x - ${display_properties[0]})) new_y=$((y - ${display_properties[1]}))

						set_new_position $new_x $new_y 150 150

						#echo $new_x, $new_y: $x, $y, $w, $h - ${display_properties[*]},   ${windows[$current_id]}, $offset, $offset_x, $offset_y

						[[ ! $id ]] && id=$current_id
					fi
				fi
			else
				if [[ $window_title && ! $window_title =~ ${blacklist//,/|} ]]; then
					properties=( $(get_windows $current_id | cut -d ' ' -f 2-) )
					all_windows[$current_id]="${properties[*]}"
					windows[$current_id]="${properties[*]}"
					add_border_gap "$current_id"
				fi
			fi

			if [[ $window_title && ! $window_title =~ ${blacklist//,/|} ]]; then
				signal_event "workspaces" "new_window" "$current_id $window_title"
				signal_event "launchers" "new_window" "$current_id ${window_title,,}"

				workspaces[$current_id]=${workspace}_${display}
				wmctrl -ir $current_id -b add,above &
			else
				ignore=1
			fi

			#wmctrl -ia $current_id 2> /dev/null
			[[ $window_title != image_preview ]] && xdotool windowactivate $current_id
		fi
	else
		signal_event "workspaces" "windows" "$workspace $new_value ${!windows[*]}"

		[[ "$new_value" =~ "0x0" || "$new_value" == $id || $move_window || #]] && continue
			${input_ids[*]} == *$new_value* ]] && continue

		#save the last active window on each display,
		#so it can be targeted as a default window, when different display is selected 
		#[[ $id && ${workspaces[$id]} ]] && last_display_window[${workspaces[$id]#*_}]=$id
			#echo ldw: $id, ${!workspaces[*]}, ${last_display_window[${workspaces[$id]#*_}]}

		id=$new_value
		signal_event "launchers" "active" "$id"
		current_id=$id
		display=${workspaces[$id]#*_}
		properties=( ${windows[$id]} )

		if [[ ${states[$id]} ]]; then
			restore
		else
			if ((ignore)); then
				unset ignore
			else
				temp_props=$(xwininfo -id $id 2> /dev/null |
					parse_properties | cut -d ' ' -f 2-)

				if [[ $temp_props ]]; then
					properties=( $temp_props )
					all_windows[$id]="${properties[*]}"
					windows[$id]="${properties[*]}"
				fi
			fi
		fi
	fi

	unset_vars
done < <(spy)
