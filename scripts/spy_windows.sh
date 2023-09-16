#!/bin/bash

parse_properties() {
	awk '
		/xwininfo/ { id = $4 }
		/Absolute/ { if(/X/) x = $NF; else y = $NF }
		/Relative/ { if(/X/) xb = $NF; else yb = $NF }
		/Width/ { w = $NF }
		/Height/ { print id, x - xb, y - yb, w, $NF, 2 * xb, yb + xb }'
}

get_windows() {
	if [[ $1 == 0x* ]]; then
		local specific_id=${1#0x}
	elif [[ $1 == all ]]; then
		local workspace
	fi

	wmctrl -l | awk '
		$2 ~ "'"$workspace"'" && !/('"${blacklist//,/|}"')$/ && $1 ~ /0x0*'$specific_id'/ \
			{ print $1 }' | xargs -rn 1 xwininfo -id | parse_properties
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
	#if [[ ! $full && ! $second_window_properties ]]; then
	if [[ ! $second_window_properties ]]; then
		# let user select window to which should selected window tile to
		~/.orw/scripts/select_window.sh
		local second_window_id=$(printf '0x%x' $(xdotool getactivewindow))
		local second_window_properties=( $(get_windows $second_window_id | cut -d ' ' -f 2-) )

		# set id and properties
		id=$second_window_id
		current_id=${original_properties[0]}
		properties=( $second_window_id ${second_window_properties[*]} )
	fi
}

#manage_tiling() {
#	tiling=true
#	original_properties=( ${properties[*]} )
#
#	select_tiling_window
#
#	local aligned_dimension
#
#	for aligned_window_id in ${!all_aligned_windows[*]}; do
#		current_aligned_window=( ${all_aligned_windows[$aligned_window_id]} )
#		(( aligned_dimension += ${current_aligned_window[index + 1]} ))
#	done
#
#	(( aligned_dimension -= ${current_aligned_window[index + 3]} + ${margin:-$offset} ))
#	moved_window_dimension=${original_properties[index + 2]}
#
#	unset event
#	align
#}

update_alignment() {
	#reversing stored alignment in case this is the only window
	local action=$1 force=$2
	local opposite_direction aligned_window_count=${#aligned_windows[*]}

	echo HERE 

	#echo $action, $aligned_window_count, $alignment_direction
	#this line ignores expected behaviour in case of moving windows
	([[ $action ]] && ((aligned_window_count == 1))) ||
		([[ ! $action ]] && ((aligned_window_count == 2))) ||
		[[ $force ]] &&
		for window_id in ${!aligned_windows[*]}; do
			window_direction=${alignments[$window_id]}

			echo $window_direction: $window_id - ${windows[$window_id]},    $index - $id: ${properties[*]}

			if [[ ${alignments[$window_id]} ]]; then
				if [[ $action && $aligned_window_count -eq 1 ]]; then
					[[ $window_direction == h ]] &&
						opposite_direction=v || opposite_direction=h
					alignments[$window_id]=$opposite_direction
					echo $opposite_direction: $window_id - ${windows[$window_id]}
				elif [[ ($aligned_window_count -eq 2 || $force) &&
						$window_direction != $alignment_direction ]]; then
					alignments[$window_id]=$alignment_direction
				fi
			fi
			#echo $window_id, $window_direction, ${alignmetns[$window_id]}
		done
}

update_alignment() {
	#reversing stored alignment in case this is the only window
	local action=$1 force=$2 aligned_size=${properties[opposite_index + 2]} window_size
	local opposite_direction aligned_blocks=$block_segments
	aligned_blocks=${#aligned_windows[*]}

	#echo $action, $aligned_blocks, $alignment_direction
	#this line ignores expected behaviour in case of moving windows
	([[ $action ]] && ((aligned_blocks == 1))) ||
		([[ ! $action ]] && ((aligned_blocks == 2))) ||
		[[ $force ]] &&
		for window_id in ${!aligned_windows[*]}; do
			window_direction=${alignments[$window_id]}
			window_size=$(cut -d ' ' -f $((opposite_index + 2)) <<< ${windows[$window_id]})

			#echo $window_direction: $window_id - ${windows[$window_id]},    $index - $id: ${properties[*]}
			#echo $opposite_index: $window_size / $aligned_size

			if ((window_size == aligned_size)); then
				if [[ ${alignments[$window_id]} ]]; then
					if [[ $action && $aligned_blocks -eq 1 ]]; then
						[[ $window_direction == h ]] &&
							opposite_direction=v || opposite_direction=h
						alignments[$window_id]=$opposite_direction
						#echo $opposite_direction: $window_id - ${windows[$window_id]}
					elif [[ ($aligned_blocks -eq 2 || $force) &&
							$window_direction != $alignment_direction ]]; then
						alignments[$window_id]=$alignment_direction
					fi
				fi
			fi
			#echo $window_id, $window_direction, ${alignmetns[$window_id]}
		done
}

update_alignment() {
	#reversing stored alignment in case this is the only window
	local action=$1 force=$2
	local opposite_direction aligned_window_count=${#aligned_windows[*]}

	#echo $action, $aligned_window_count, $alignment_direction
	#this line ignores expected behaviour in case of moving windows
	([[ $action ]] && ((aligned_window_count == 1))) ||
		([[ ! $action ]] && ((aligned_window_count == 2))) ||
		[[ $force ]] &&
		for window_id in ${!aligned_windows[*]}; do
			window_direction=${alignments[$window_id]}

			echo $window_direction: $window_id - ${windows[$window_id]},    $index - $id: ${properties[*]}

			if [[ ${alignments[$window_id]} ]]; then
				if [[ $action && $aligned_window_count -eq 1 ]]; then
					[[ $window_direction == h ]] &&
						opposite_direction=v || opposite_direction=h
					alignments[$window_id]=$opposite_direction
					echo $opposite_direction: $window_id - ${windows[$window_id]}
				elif [[ ($aligned_window_count -eq 2 || $force) &&
						$window_direction != $alignment_direction ]]; then
					alignments[$window_id]=$alignment_direction
				fi
			fi
			#echo $window_id, $window_direction, ${alignmetns[$window_id]}
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
	done

	xdotool windowminimize $id
	update_aligned_windows

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
		DROPDOWN) opacity=$(get_bar_transparency);;
		*) opacity=100
	esac

	#wmctrl -ir ${1:-$id} -b add,above
	#sleep 0.1
	~/.orw/scripts/set_window_opacity.sh ${1:-$id} $opacity
}

list_windows() {
	[[ $windows_to_ignore ]] ||
		local windows_to_ignore="${!states[*]}"

	for wid in ${!windows[*]}; do
		[[ ${windows[$wid]} ]] && echo $wid ${windows[$wid]}
	done | grep -v "^\(${windows_to_ignore// /\\|}\)\s\+\w"
}

set_new_position() {
	awk -i inplace '
		/class="\*"/ { t = 1 } t && /<\/app/ { t = 0 }

		t && /<decor>/ {
			v = ("'"${tiling_workspaces[*]}"'" !~ "'$workspace'") ? "yes" : "no"
		}
		t && /<(width|height)>/ { v = (/width/) ? "'$3'" : "'$4'" }
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
	#list_windows | grep -v "^\(${windows_to_ignore// /\\|\s\+\w}\)" |
	#list_windows | grep -v "^\(${windows_to_ignore// /\\|}\)\s\+\w" |
	list_windows | sort -nk $((index + 1)),$((index + 1)) \
		-nk $((opposite_index + 1)),$((opposite_index + 1)) -nk 1,1r |
		awk '
			function sort(a) {
				#removing/unseting variables
				delete cwp
				delete fdw
				#ai = fdwi = pdwc = min = max = 0
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
								#print "BREAK", id, cws, max + s
								if ("'"$2"'") print "BREAK", id, cws, max + s
								if (cws > ws + wd && id != "temp") break
								#if(cws > ws + wd) break
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
						#if (cwod == wod) fdw[++fdwi] = id " " cws " " cwd - cb " " cb
						#else pdw = pdw "," id ":" cws "-" cwd - cb "-" cb
						#if(cws + cwd + s > cumax) cumax = cws + cwd + s

						if(cws + cwd + s > cumax) cumax = cws + cwd + s
						if (cwod == wod) fdw[++fdwi] = id " " cws " " cwd - cb " " cb " " min " " cumax - s
						else pdw = pdw "," id ":" cws "-" cwd - cb "-" cb

						#if (cws + cwd + s > cumax) cumax = cws + cwd + s
						#if (cwod == wod) fdw[++fdwi] = id " " cws " " cwd - cb " " cb " " cumax
						#else {
						#	pdw = pdw "," id ":" cws "-" cwd - cb "-" cb
						#	if (cumax > pdwmax) pdwmax = cumax
						#}
					}

					#if("'"$2"'") print "CWD", cwos, cwod, wos, wod
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

				#if (e == "resize") { bd = '$diff'; ad = -1 * bd }
				##	if ('${property:-0}' > 1) {
				##		bd = '$diff'; ad = -1 * bd
				##	} else { ad = '$diff'; bd = -1 * ad }
				##}

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

				#if (e == "resize") { ms = cws; me = ws }
				#else { ms = cws + cwd; me = ws + wd }

				#ms = cws + cwd; me = ws + wd

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
				#cwnd = sprintf("%.0f", (cws + cwd + cb == wae) ? wane - cns - cb : (nd + s - b) / wr - s)
				if(cwid == "'$id'" && e) cwnd = '${properties[index + 2]}'
				#else cwnd = sprintf("%.0f", (cws + cwd + cb == wae) ? wane - cns - cb : (nd + s - b) / wr - s)

				#else cwnd = (cws + cwd + cb == wae) ? wane - cns - cb : (nd + s - b) / wr - s
				#if (cwnd % 1) cwnd = int(cwnd + 1)
				else {
					#cwbe = wae
					#cwbe -= (s - cb)
					#print "HERHERHERE", cwbe, cws, cwd, s, cb, wae, wane
					if ((cwbe && cws + cwd + cb == cwbe) ||
						(!cwbe && cws + cwd + cb == wae)) {
						#print "THEREH", cwbe, wane, max, wae

						#if ((cwbe && cwbe != wane) &&
							#wane != wae && cwbe != wae) {
						if (cwbe && cwbe != wane && cwbe != wae) {
							cbod = cwbe - cwbs + s - cb
							cbr = (od + s) / cbod
							cbnd = (nd + s) / cbr
							cwnd = was + cbnd - (cns + s)
							#print "CBR", cbr, cbod, cbnd, was, was + cbnd, cns, cwnd
						} else cwnd = wane - cns - cb
					} else cwnd = (nd + s - b) / wr - s
					#print "BE", cwnd, wane, wae
				}

				cwnd = sprintf("%.0f", cwnd)
				#print "CWND:", cwnd

				#else cwnd = (cws + cwd + cb == wae) ? wane - cns - cb : (nd + s - b) / wr - s
				#if (cwnd % 1) cwnd = int(cwnd + 1)
				cwns = cns + cwnd + s

				#if ("'"$2"'") print "CW:", cns, cwnd, cwns, cws + cwd + cb, wae, (nd + s - b) / wr - s, (cws + cwd + cb == wae)
				#xs = cwbs + cas + s
				#xs = was
				#x = (od + s - b) / (cwbe - cwbs)
				#if ("'"$2"'") print od + s, cwbe, cwbs, (cwbe - cwbs + s), (od + s) / (cwbe - cwbs + s), nd + s, (nd + s) / ((od + s) / (cwbe - cwbs + s))

				##xs = was
				#x = (od + s) / (cwbe - cwbs + s - cb)
				#cbod = cwbe - cwbs + s
				#cbr = (od + s) / cbod
				#cbnd = (nd + o) / cbr
				#if ("'"$2"'") print cwbe, cwbs, cwbe - cwbs + s, x
				#if ("'"$2"'") print cws, cwd, wae, wane, cwbe, x, nd + s, (nd + s) / x, od, nd

				#print "CB", cbr, cbod, cbnd
				#if ("'"$2"'") print cws, cwd, cb, wae, wane, cwbe, cwbe / wr, x, nd, nd / x, xs

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
						#print "FB", cwb
						cwbs = cwp[5]; cwbe = cwp[6] #- (s - cb)

						s = o + cb
						#system("~/.orw/scripts/notify.sh " cb)

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

				#if ((c && (e == "resize" &&
				#	((wd > 0 && max == ws + wd) ||
				#	(wd < 0 && )) || max == ws - s) ||
				if ((c && (max == ws - s ||
					(e == "resize" && max == ws + wd))) ||
					(!c && ((r && max == ws -s) ||
					(!r && max == ws + wd)))) {
					bc = length(nbw)
					if(bc) { bas = min; bae = max; bad = max - min }
				}

				if (length(aw)) {
					# setting after windows array and its properties
					#if (e != "resize" && (!r || (r && c))) max = ws + wd
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
				#if (e && e != "full") twc--

				#if (e == "restore") ar = ar / '${old_count:-1}' * (twc + 1)
				if (e == "restore") ar = ar * ('${old_count:-1}' + 1) / (twc + 1)
				if ("'"$2"'") print "RATIO", ar, td, wd + m

				#system("~/.orw/scripts/notify.sh \"" td " " wd + m " " (td + wd + p) / (wd + m) "\"")

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

				#if("'"$enforced_direction"'") ptd = td
				min = (bc) ? bas : aas
				#print min, td, twc + 1, nw, a
				if (wd) sc =  td / wd
				print min, td + bs, twc + 1 "_" 1 + sc, nw, a
			}'
}

get_workspace_windows() {
	[[ $1 ]] &&
		local display=$1 ||
		display=${workspaces[$id]#*_}

	[[ ${FUNCNAME[*]: -3:1} != update_values ]] &&
		display_properties=( ${displays[$display]} )

	#echo $1: $id - ${properties[*]}, $display

	#[[ ! $display ]] &&
	#	echo "$id: ${properties[*]} - $window_title -> ${BASH_SOURCE[*]}, ${BASH_LINENO[*]}"

	windows=()
	for window in ${!workspaces[*]}; do
		[[ ${workspaces[$window]} == ${closing_id_workspace:-$workspace}_${display} ]] &&
			windows[$window]="${all_windows[$window]}"
	done
}

set_alignment() {
	local id=$1
	read new_{start,size} <<< ${aligned_windows[$id]}

	if ((new_size)); then
		[[ $id != $current_id ]] &&
			properties=( $id $window_properties )
		properties[index]=$new_start
		properties[index + 2]=$new_size

		#NEW
		if [[ $tiling ]]; then
			[[ $id != ${original_properties[0]} ]] &&
				windows[$id]="${properties[*]:1}"
			[[ $id == $second_window_id ]] &&
				second_window_properties=( ${properties[*]:1} )
		fi

		all_aligned_windows[$id]="${properties[*]:1}"

		#OLD
		#read x y w h xb yb <<< ${properties[*]:1}

		##if windows should tile (two step operation)
		#if [[ $tiling ]]; then
		#	#set window which should tile to fill "new" position of new alignment,
		#	#otherwise, update all_windows array with new properties after alignment, so the next iteration can be calculated with accurate values
		#	[[ $id == $original_properties ]] && id=$original_properties ||
		#		windows[$id]="$x $y $w $h $xb $yb"
		#	#update properties of the window to which selected window should be tiled to
		#	[[ $id == $second_window_id ]] && second_window_properties=( $x $y $w $h $xb $yb )
		#fi

		##populate all_aligned_windows array
		#all_aligned_windows[$id]="$x $y $w $h $xb $yb"
		##echo $id, aaw: all_aligned_windows[$id]="$x $y $w $h $xb $yb"
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

	#display=${workspaces[$id]#*_}
	##get_display_properties
	##echo $display, $id, ${properties[*]}

	#windows=()
	#for window in ${!workspaces[*]}; do
	#	[[ ${workspaces[$window]} == ${workspace}_${display} ]] &&
	#		windows[$window]="${all_windows[$window]}"
	#done

	[[ $tiling ]] || get_workspace_windows

	set_alignment_properties $alignment_direction

	#if [[ $action ]]; then
	#	echo $alignment_direction: $id, ${properties[*]}, ${alignments[$id]}
	#	get_alignment "$action" print
	#fi

	#killall spy_windows.sh xprop
	#exit

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

	[[ $action ]] || local force=true
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

	#read x y w h <<< ${properties[*]::4}
	set_border_diff $id

	local new_props="${props[*]::4}"
	wmctrl -ir $id -e 0,${new_props// /,} &
	#wmctrl -ir $id -e 0,$x,$y,$w,$h &

	all_windows[$id]="${props[*]}"
	windows[$id]="${props[*]}"
	properties=( ${props[*]} )
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

	#[[ $original_properties ]] && properties=( ${original_properties[*]} )
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
	#echo PRE $@, $id: ${properties[*]}, $display, ${properties[*]:1}
	#echo $@ - $id, $current_id: ${properties[*]}, ${BASH_LINENO[*]}: ${BASH_SOURCE[*]}

	[[ -z $@ ]] &&
		local properties=( ${properties[*]:1} ) ||
		local properties=( $(get_windows $1 | cut -d ' ' -f 2-) )
	[[ $2 ]] && echo GDP $@, $id: ${properties[*]}, $display, ${properties[*]:1}

	#if [[ $@ ]]; then
	#	echo $1, $id: ${properties[*]}
	#	get_windows $1
	#	#wmctrl -lG
	#fi

	#echo POST $@, $id: ${properties[*]}, $display
	#for w in ${!all_windows[*]}; do
	#	echo $w: ${all_windows[$w]} - ${windows[$w]}
	#done

	if ((window_count)); then
		for display in ${!displays[*]}; do
			display_properties=( ${displays[$display]} )
			#echo DISP: ${displays[$display]}, ${display_properties[*]}

			#echo DIS: $display - ${displays[$display]}, $display_index: ${display_properties[*]} - ${display_properties[display_index]}
			#echo $id: ${properties[display_index]}, ${properties[*]}

			if ((${properties[display_index]} >= ${display_properties[display_index]} &&
				${properties[display_index]} + ${properties[display_index + 2]} <= \
				${display_properties[display_index + 2]})); then
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
	local {x,y}_border_diff borders
	#[[ ${FUNCNAME[1]} == handle_first_window ]] && local first=true
	((current_window_count == 1)) && local first=true
	#echo sb $current_window_count, $first

	#echo $id, $current_id

	if [[ ${windows[$id]} || $first ]]; then
		local current_properties=( ${windows[$id]} )

		[[ $id == 0x* && ! $first ]] &&
			previous_borders="${current_properties[*]: -2:2}" ||
			previous_borders="$default_x_border $default_y_border"

		read previous_{x,y}_border <<< "$previous_borders"
		read borders <<< $(xwininfo -id ${1:-$current_id} 2> /dev/null |
			awk '/Relative/ { print $NF }' | xargs -r)

		#echo CUR: $previous_borders, $borders, ${current_properties[*]}

		if [[ $borders ]]; then
			read current_{x,y}_border <<< "$borders"

			x_border_diff=$((previous_x_border - current_x_border * 2))
			y_border_diff=$((previous_y_border - (current_y_border + current_x_border)))

			#echo $previous_borders, $borders
			#echo diffs: $id - $first, $x_border_diff, $y_border_diff, ${new_props[*]}

			#((x_border_diff)) && ((w += x_border_diff))
			#((y_border_diff)) && ((h += y_border_diff))

			((x_border_diff)) && ((props[2] += x_border_diff))
			((y_border_diff)) && ((props[3] += y_border_diff))

			#echo NEW: ${new_props[*]}

			if [[ $first ]]; then
				(( y_border -= y_border_diff ))
				props[5]=$y_border
			fi
		fi
	fi
}

update_aligned_windows() {
	local {new_,}props aligned_ids=${!all_aligned_windows[*]}

	[[ ${FUNCNAME[*]} == *set_align_event* ]] &&
		local save_original_properties=true

	if [[ $aligned_ids ]]; then
		for window_id in ${aligned_ids/$current_id} $current_id; do
			props=( ${all_aligned_windows[$window_id]} )

			if ((${#props[*]})); then
				[[ $1 && $window_id == $1 ]] && set_border_diff $1
				[[ $window_id == $current_id ]] &&
					workspaces[$current_id]="${workspace}_${display}"

				#echo AL: ${windows[$window_id]}, ${props[*]}

				new_props="${props[*]::4}"
				wmctrl -ir $window_id -e 0,${new_props// /,} #&
				all_windows[$window_id]="${props[*]}"
				windows[$window_id]="${props[*]}"
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

blacklist='.*input,get_borders,DROPDOWN,image_preview,cover_art_widget'

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
				#rofi_start=${rofi_opening_offset:-$rofi_offset} || unset rofi_start

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
	read pwi swi <<< $(awk '
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
					gsub("%[^}]*}", " ")
					if($1 ~ "_s_") s = $2
					else p = $2
				}
			}
		}

		END { print p, s }' $bar_config ~/.orw/scripts/new_bar/icons 2> /dev/null)
}

update_values() {
	event=update
	orw_config=~/.config/orw/config

	#read mode alignment_direction reverse full default_{x,y}_border margin \
	#	interactive primary display_{count,orientation,index} diff_{property,value} <<< \
	#	$(awk -F '[_ ]' '
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

					declare -A diffs offset_windows

					sorted_workspaces="$(tr ' ' '\n' <<< ${workspaces[*]} |
						cut -d '_' -f 1 | sort | uniq | grep -v $current_workspace)"

					current_id=$id

					local current_display=$display

					((rofi_opening_offset > 0)) &&
						#local tiling_rofi_pid=$(pidof -x tiling.sh)
						local tiling_rofi_pid=$(ps -C dmenu.sh -o pid=,args= |
							awk '$NF == "tiling" { print $1; exit }')

					while read display display_properties; do
						if [[ ${displays[$display]} ]]; then
							local adjust_windows=true
							local new_display_properties=( $display_properties )
							local current_display_properties=( ${displays[$display]} )

							#echo ITER: ${current_display_properties[*]}, ${new_display_properties[*]}

							for property_index in ${!new_display_properties[*]}; do
								diff=$((${new_display_properties[property_index]} - \
									${current_display_properties[property_index]}))

								((diff)) && diffs[$((property_index + 0))]=$diff
							done
						fi

						#echo ${!diffs[*]}, ${current_display_properties[*]}

						for diff in ${sorted_diffs:-${!diffs[*]}}; do
							local id=temp
							x_border=0 y_border=0
							temp_properties=( ${current_display_properties[*]::2} )

							#[[ $rofi_state == opened && $rofi_offset -gt 0 &&
							#	$rofi_opening_display -eq $display ]] &&
							#	((temp_properties[0]+=$rofi_opening_offset))

							temp_properties+=( $((${current_display_properties[2]} \
								- ${current_display_properties[0]})) )
								#- ${temp_properties[0]})) )
							temp_properties+=( $((${current_display_properties[3]} \
								- ${current_display_properties[1]})) )

								#local rofi_value=$rofi_opening_offset

							value=${diffs[$diff]}

							((diff % 2)) &&
								alignment_direction=v || alignment_direction=h
							set_alignment_properties $alignment_direction

							#echo diff $diff
							#echo $alignment_direction, $diff, $index, $value, ${temp_properties[diff]}
							if ((diff > 1)); then
								temp_properties[index - 1]=$((${current_display_properties[diff]} + margin))
								temp_properties[diff]=$((-(margin - value)))
							else
								#((temp_properties[0]+=rofi_offset))
								#echo $diff, $index, ${temp_properties[index - 1]}, $value, $rofi_value: $rofi_opening_offset
								(( temp_properties[index - 1] += value + 0))
								temp_properties[diff + 2]=$((-(margin + value)))
							fi

							#echo $rofi_offset: ${temp_properties[*]}
							#killall spy_windows.sh xprop
							#exit

							#echo ${temp_properties[*]}
							properties=( $id ${temp_properties[*]} 0 0 )

							#legit, but slower way
							for workspace in $current_workspace $sorted_workspaces; do
								if [[ ${workspaces[*]} == *${workspace}_${display}* ]]; then
									windows=()
									for window in ${!workspaces[*]}; do
										[[ ${workspaces[$window]} == ${workspace}_${display} ]] &&
											windows[$window]="${all_windows[$window]}"
									done

									if [[ $rofi_state == opened && $rofi_opening_display -eq $display ]] &&
										((rofi_opening_offset > 0 && workspace == current_workspace )); then
											if ((diff % 2)); then
												echo CWS OLD: ${properties[*]}
												((properties[1]+=$rofi_opening_offset))
												((diff % 2)) && ((properties[3]-=$rofi_opening_offset))
												echo CWS: ${properties[*]}
											else
												local open_rofi=true new_rofi_offset=$((rofi_opening_offset + value))
												echo CLOSING ROFI: $rofi_opening_offset, $value, $new_rofi_offset
												toggle_rofi $current_workspace no_change
											fi
									fi

									#if ((workspace == current_workspace && diff != 2)); then
									#	if [[ $rofi_state == opened && $rofi_opening_display -eq $display ]]; then
									#		#local opened_rofi_offset=$rofi_opening_offset
									#		echo CWS OLD: ${properties[*]}
									#		((properties[1]+=$rofi_opening_offset))
									#		((diff % 2)) && ((properties[3]-=$rofi_opening_offset))
									#		echo CWS: ${properties[*]}
									#		#toggle_rofi
									#		#killall spy_windows.sh xprop
									#		#exit
									#	fi
									#fi

									windows[temp]="${properties[*]:1}"

									#if ((workspace == current_workspace && diff == 0)); then
									#	echo ROFI: $rofi_offset, $rofi_value
									#	echo ${properties[*]}
									#	get_alignment move print
									#	#killall spy_windows.sh xprop
									#	#exit
									#fi

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

									if ((rofi_opening_offset > 0 &&
										workspace == current_workspace && diff % 2)); then
										if [[ $rofi_state == opened && $rofi_opening_display -eq $display ]]; then
											((properties[1]-=$rofi_opening_offset))
											((diff % 2)) && ((properties[3]+=$rofi_opening_offset))
											#((${current_display_properties[0]} < rofi_opening_offset)) && toggle_rofi
											#killall spy_windows.sh xprop
											#exit
										fi
									fi
								fi
							done

							((current_display_properties[$diff] += value))
						done

						#if [[ $rofi_state == opened ]]; then
						#	echo $diff: ${current_display_properties[0]}, ${new_display_properties[*]}
						#	#if ((${current_display_properties[0]} < rofi_opening_offset)); then
						#	if ((rofi_opening_offset > 0)); then
						#		local opened_rofi_offset=$rofi_opening_offset
						#		local open_rofi=true
						#		echo CLOSING ROFI
						#		toggle_rofi
						#	else
						#		unset open_rofi
						#	fi

						#	echo $open_rofi: ${current_display_properties[0]}, $rofi_opening_offset
						#fi

						windows=()
						id=$current_id

						if [[ $adjust_windows ]]; then
							for w in ${sorted_ids[*]}; do
								if [[ ${!all_windows[*]} =~ $w ]]; then
									props="${all_windows[$w]% * *}"
									#[[ $rofi_state == closed ]] &&
										wmctrl -ir $w -e 0,${props// /,} &
									[[ ${workspaces[$w]} == ${current_workspace}_${display} ]] &&
										windows[$w]="${all_windows[$w]}"
								fi
							done
						fi

						#if ((${current_display_properties[0]} < opened_rofi_offset)); then
						if [[ $open_rofi ]]; then
							#echo PRE ${display_properties[*]}, $display_properties
							set_rofi_windows $new_rofi_offset
							#echo OPENING ROFI: $rofi_state, $display_properties
							sleep 1 && toggle_rofi $current_workspace
							kill -USR1 $tiling_rofi_pid
							#echo ${display_properties[*]}, $display_properties
							unset open_rofi
							#killall spy_windows.sh xprop
							#exit
						fi

						#killall spy_windows.sh xprop
						#exit

						#if ((workspace == current_workspace && diff != 2)); then
						#	if [[ $rofi_state == opened && $rofi_opening_display -eq $display ]]; then
								#((properties[1]-=$rofi_opening_offset))
								#((diff % 2)) && ((properties[3]+=$rofi_opening_offset))
						#	fi
						#fi

						displays[$display]="$display_properties"
					done <<< $(sed 's/\(\([0-9]\+\s*\)\{5\}\)/\1\n/g' <<< "$diff_value")

					workspace=$current_workspace
					all_displays="$diff_value"
					#update_displays
					#echo $id: ${properties[*]}, ${windows[$id]}
					get_display_properties $id #print

					#set_rofi_windows
					#[[ $rofi_state == opened ]] && toggle_rofi $workspace

					#for window in "${!edge_windows[@]}"; do
					#	echo EDGE: wmctrl -ir $window -e 0,${edge_windows[$window]// /,} &
					#done

					bars=$(sed -n 's/^last.*=//p' ~/.orw/scripts/barctl.sh)
					[[ $bars =~ , ]] && bars="{$bars}"
					#bar_configs=$(eval ls ~/.config/orw/bar/configs/$bars)
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
					wmctrl -ir $window -e 0,${all_windows[$window]// /,} &
					[[ "${!windows[*]}" =~ $window ]] &&
						windows[$window]="${all_windows[$window]}"
				done

				#[[ $diff_property == margin && $rofi_state == opened ]] && set_rofi_windows

				#echo m: $margin, b: $default_x_border $default_y_border
		esac
	fi

	#echo SETTING: ${current_display_properties[*]}
	set_rofi_windows

	unset event diff_{property,value}
}

make_workspace_notification() {
	local notification

	for workspace_index in $(seq 0 $total_workspace_count); do
		fg='sbg'

		case $workspace_index in
			$1) workspace_icon=$pwi fg='pbfg';;
			$2) workspace_icon=$pwi;;
			*) workspace_icon=$swi;;
		esac

		((workspace_index)) &&
			workspace_icon="<span font='Iosevka Orw 10'> </span>$workspace_icon"
		notification+="<span foreground='\$$fg'>$workspace_icon</span>"
	done

	notification="<span foreground='\$sbg' font='Iosevka Orw 20'>$notification</span>"
	~/.orw/scripts/notify.sh -r 404 -t 600m -s windows_osd \
		"\n         $notification         \n" 2> /dev/null &
}

swap_windows() {
	((index)) &&
		local opposite_index=0 || local opposite_index=1

	((diff > 0)) &&
		local sign=+ opposite_sign=- reverse ||
		local sign=- opposite_sign=+ reverse=r

	#echo PRE: $index, $reverse: ${properties[*]}

	#list_windows | sort -n${reverse}k $((index + 2)),$((index + 2))

	#list_windows |
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
						#print "HERE", $0
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

	#echo PRE
	#list_windows

	for move_id in $id $move_ids; do
		props=( ${windows[$move_id]} )
		[[ $move_id == $id ]] &&
			((props[index] ${sign}= source_move)) ||
			((props[index] ${opposite_sign}= target_move))
		all_windows[$move_id]="${props[*]}"
		windows[$move_id]="${props[*]}"
		all_props="${props[*]::4}"
		wmctrl -ir $move_id -e 0,${all_props// /,} &
	done

	#echo POST
	#list_windows

	signal_event "launchers" "swap" "$id ${move_ids// /,} $reverse"

	properties=( ${windows[$id]} )

	#echo POST: ${properties[*]}
}

resize() {
	#touch /tmp/wmctrl_lock

	#echo "RESIZE: $workspace ($tiling_workspaces) - $id: ${properties[*]}"

	declare -A aligned_windows
	local index diffs changed_properties resize_area
	local move=$1 window_{start,end} {opposite_,}index {{al{l,igned},neighbour}_,}ids

	#for property in {0..3}; do
	#	((${old_properties[property]} != ${properties[property]})) &&
	#		diff=$((${properties[property]} - ${old_properties[property]})) && break
	#done

	[[ $event == *mouse* ]] && local count=1

	for property in {0..3}; do
		if ((${old_properties[property]} != ${properties[property]})); then
			#echo DIFF: $((${properties[property]} - ${old_properties[property]}))
			index=$(( property % 2 ))

			if [[ ! ${diffs[index]} ]]; then
				#diffs[index]=$((${properties[property]} - ${old_properties[property]}))
				diffs[index]=$((${properties[property]} - ${old_properties[property]}))
				changed_properties[index]=$property
			fi

			#echo $index: ${diffs[index]}, ${changed_properties[index]}

			[[ ($event == *mouse* && ${#diffs[*]} -eq 2) ||
				$event != *mouse* ]] && break

			#((!count || count == 2)) && break
			#((count++))
		fi
	done

	#for d in ${!diffs[*]}; do
	#	echo $d: ${diffs[$d]} - ${changed_properties[$d]}
	#done

	##properties=( ${windows[$id]} )
	#echo ${changed_properties[*]}, ${diffs[*]}, ${properties[*]}
	#sleep 2
	#read x y w h b <<< ${old_properties[*]}
	#wmctrl -ir $id -e 0,$x,$y,$w,$h
	#return

	if [[ $event == *move* ]]; then
		#local move_diff=${diffs[*]: -1}
		#diffs[property + 2]=$move_diff

		#if ((${diffs[*]: -1})); then
		#	changed_properties[property + 2]=$move_diff
		#	changed_properties[property]=$move_diff
		#else
		#	changed_properties[property]=$move_diff
		#	changed_properties[property + 2]=$move_diff
		#fi

		#((${diffs[*]: -1})) &&
		#local diff=${diffs[*]: -1}

		#((${diffs[*]: -1})) &&
		local diff=${diffs[*]: -1}
		((diff > 0)) &&
			changed_properties=( $((property + 2)) $property ) ||
			changed_properties=( $property $((property + 2)) )

		#diffs[property + 2]=${diffs[*]: -1}
		#diffs=( ${diffs[*]: -1} ${diffs[*]: -1} )

		#diffs[property + 2]=${diffs[*]: -1}
		#echo DIFF: $property, ${!diffs[*]}, ${diffs[*]}, 
		#killall spy_windows.sh xprop
		#exit
	fi

	for property_index in ${!changed_properties[*]}; do
		#property=${changed_properties[property_index]}
		#((${diffs[property_index]})) && diff=${diffs[property_index]}
		#[[ ! $event =~ .*(mouse|rofi) && ${diff#-} -eq 1 ]] && (( diff *= 50 ))
		##echo DIFF: $diff, ${diffs[property_index]}, $property_index, ${!diffs[*]}, ${diffs[*]}
		##echo $property, $diff, ${old_properties[*]}

		##properties=( ${old_properties[*]} )
		#[[ $event == move ]] &&
		#	properties=( ${old_properties[*]} ) ||
		#	properties[property]=${old_properties[property]}
		#windows[$id]="${properties[*]}"

		property=${changed_properties[property_index]}

		if [[ $event == move ]]; then
			properties=( ${old_properties[*]} )
			properties=( ${windows[$id]} )
			#echo props: $id - ${properties[*]}
		else
			properties[property]=${old_properties[property]}
			((${diffs[property_index]})) && diff=${diffs[property_index]}
		fi

		windows[$id]="${properties[*]}"

		[[ ! $event =~ .*(mouse|rofi) && ${diff#-} -eq 1 ]] && (( diff *= 50 ))

		#if [[ ${tiling_workspaces[*]} != *$workspace* ]]; then
		#	((properties[$property] += diff))
		#	continue
		#fi

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

		#list_windows | sort -nk $((index + 1)),$((index + 1)) |
		#	awk '
		#		BEGIN {
		#			p = '$property'
		#			i = (p % 2) + 2
		#			oi = ((p + 1) % 2) + 2

		#			id = "'"$id"'"
		#			ws = '$window_start'
		#			we = '$window_end'
		#			m = '$margin'
		#		}

		#		function find_size(cws, cwe) {
		#			for (w in aw) {
		#				if (!chw || w !~ "^(" chw ")$") {
		#					split(aw[w], chwp)
		#					chws = chwp[1]; chwe = chwp[2]

		#					if ((chws < cws && chwe + m > cws) ||
		#						(chwe > cwe && chws < cwe - m) ||
		#						(chws >= cws && chwe <= cwe)) {
		#							if(!chw) chw = w
		#							else chw = chw "|" w

		#							if (chwe > me) me = chwe
		#							if (!ms || chws < ms) ms = chws

		#							find_size(chws, chwe)
		#					}
		#				}
		#			}
		#		}

		#		{
		#			if ($1 == id) {
		#				print "HRE", i, oi, $0
		#				wos = $oi
		#				woe = wos + $(oi + 2) + $(oi + 4)
		#				next
		#			}

		#			cwe = $i + $(i + 2) + $(i + 4)
		#			if ((p > 1 && cwe == we) || (p < 2 && ws == $i)) sw = sw " " $1

		#			if ((p > 1 && ($i == we + m || cwe == we)) ||
		#				(p < 2 && ($i == ws || cwe + m == ws)))
		#					aw[$1] = $oi " " $oi + $(oi + 2) + $(oi + 4)
		#		} END {
		#			find_size(wos, woe)
		#			print wos, woe
		#			print ws, (ms) ? ms : wos, we, (me) ? me : woe, id, sw
		#		}'

				#list_windows
				#killall spy_windows.sh xprop
				#exit

		((index)) &&
			direction=v || direction=h

		#id=temp
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

			#[[ $event == move ]] &&
			#	local windows_to_ignore=$id ||
			#	windows[$id]="${all_windows[$id]}"

			if [[ $event == move && $property -gt 1 ]]; then
				#echo MOVE RA: $diff, $property, ${properties[*]}
				#echo ${old_properties[property - 2]} + ${old_properties[property]}
				#echo ${properties[property - 1]} + ${properties[property + 1]}

				#local old_end=$((${old_properties[property - 2]} + ${old_properties[property]} + \
				#	${old_properties[property + 2]}))
				local old_end=$((${old_properties[property - 2]} + ${old_properties[property]}))
				local new_end=$((${properties[property - 1]} + ${properties[property + 1]} - \
					${properties[property + 3]}))

				((diff > 0)) &&
					local end_diff=$((new_end - old_end)) ||
					local end_diff=$((old_end - new_end))

				#echo ENDS: $old_end, $new_end

				resize_area=$((diff - end_diff))
			else
				resize_area=$diff
			fi

			#echo RA: $resize_area - ${properties[*]}

			windows[$id]="${all_windows[$id]}"

			id=temp
			windows[$id]="${properties[*]:1}"
			set_alignment_properties $direction

			#echo $direction, ${properties[*]}
			#get_alignment move print
			#killall spy_windows.sh xprop
			#exit

			read _ _ _ aligned <<< $(get_alignment move)
			eval aligned_windows=( $aligned )
			#unset aligned_windows[${same_windows%% *}]

			#echo $index, $property: $direction - ${properties[*]}
			#echo $aligned

			#((property)) && get_alignment move print
			#echo $property, $diff, $aligned
			#echo $same_windows
		fi

		id=${same_windows%% *}
		windows[$id]="${all_windows[$id]}"
		unset windows[temp]
		#continue

		(((diff < 0 && property < 2) || (diff > 0 && property > 1))) &&
			ids="${neighbour_ids:-${!aligned_windows[*]}} ${same_windows/$id} $id" ||
			ids="$same_windows ${neighbour_ids:-${!aligned_windows[*]}}"

		ids="${neighbour_ids:-${!aligned_windows[*]}}"

		#echo PRE $rofi_restore_windows

			#((index--))
			#list_windows | sort -nk $((index + 1)),$((index + 1)) |
			#awk '
			#	BEGIN {
			#		p = '$property'
			#		i = (p % 2) + 2
			#		oi = ((p + 1) % 2) + 2

			#		id = "'"$id"'"
			#		ws = '$window_start'
			#		we = '$window_end'
			#		m = '$margin'
			#	}

			#	function find_size(cws, cwe) {
			#		for (w in aw) {
			#			if (!chw || w !~ "^(" chw ")$") {
			#				split(aw[w], chwp)
			#				chws = chwp[1]; chwe = chwp[2]

			#				if ((chws < cws && chwe + m > cws) ||
			#					(chwe > cwe && chws < cwe - m) ||
			#					(chws >= cws && chwe <= cwe)) {
			#						if(!chw) chw = w
			#						else chw = chw "|" w

			#						if (chwe > me) me = chwe
			#						if (!ms || chws < ms) ms = chws

			#						find_size(chws, chwe)
			#				}
			#			}
			#		}
			#	}

			#	{
			#		if ($1 == id) {
			#			wos = $oi
			#			woe = wos + $(oi + 2) + $(oi + 4)
			#			next
			#		}

			#		cwe = $i + $(i + 2) + $(i + 4)
			#		if ((p > 1 && cwe == we) || (p < 2 && ws == $i)) sw = sw " " $1

			#		if ((p > 1 && ($i == we + m || cwe == we)) ||
			#			(p < 2 && ($i == ws || cwe + m == ws)))
			#				aw[$1] = $oi " " $oi + $(oi + 2) + $(oi + 4)
			#	} END {
			#		find_size(wos, woe)
			#		print ms, me
			#		print wos, woe
			#		print ws, (ms) ? ms : wos, we, (me) ? me : woe, id, sw
			#	}'

		#if [[ $ids != *$id* ]]; then
		#	echo FAIL
		#	list_windows
		#	killall spy_windows.sh xprop
		#	exit
		#fi

		for wid in $ids; do
			[[ ${windows[$wid]} ]] || continue

			props=( ${windows[$wid]} )

			#echo $wid: ${props[opposite_index]}, ${props[*]}, P: ${properties[*]}

#			if [[ $same_windows =~ $wid ]]; then
#				if ((wos <= ${props[opposite_index - 1]} &&
#					woe >= ${props[opposite_index - 1]} + \
#					${props[opposite_index + 1]} + ${props[opposite_index + 3]})); then
#						(( props[property] += diff ))
#						((property < 2)) && (( props[property + 2] -= diff ))
#
#					#old_properties=( ${props[*]} )
#				fi
#			else

			#if [[ $wid == $id && $event == move ]]; then
			#	((props[$property] += diff))
			#	#echo HERERE: ${props[*]}
			#else

			#if [[ $event != move || ($event == move && $wid != $id) ]]; then
				read window_{start,size} <<< ${aligned_windows[$wid]}
				props[property % 2]=$window_start
				props[(property % 2) + 2]=$window_size
			#fi

			windows[$wid]="${props[*]}"
			all_windows[$wid]="${props[*]}"
			[[ $aligned_ids != *$wid* ]] && aligned_ids+="$wid "

			[[ $wid == $id ]] && echo ${props[*]}
		done

		#echo END, $property, $diff
		#list_windows
		[[ ${windows[$id]} ]] &&
			properties=( ${windows[$id]} )
		#echo ${properties[*]}
	done

	#killall spy_windows.sh xprop
	#exit

	#echo DONE
	#echo "ALIGNED: $id, $aligned_ids, $ids, ${aligned_ids/$id *$id/$id}"
	#read x y w h b <<< ${old_properties[*]}
	#wmctrl -ir $id -e 0,$x,$y,$w,$h
	#return

	#if [[ ${tiling_workspaces[*]} != *$workspace* ]]; then
	#	windows[$id]="${properties[*]}"
	#	all_windows[$id]="${properties[*]}"
	#	#echo REG RESIZE: ${properties[*]}
	#	return
	#	aligned_ids=$id
	#fi

	#if [[ $event == move ]]; then
	#	properties=( ${windows[$id]} )
	#	(( properties[property % 2] += diff ))
	#	windows[$id]="${properties[*]}"
	#fi

	#killall spy_windows.sh xprop
	#exit

	#echo "ALIGNED: $id, $aligned_ids, $ids, ${aligned_ids/$id *$id/$id}"

	#echo AL: ${aligned_ids/$id *$id/$id}
	for wid in ${aligned_ids/$id *$id/$id}; do
		props=( ${windows[$wid]} )
		new_props="${props[*]::4}"
		wmctrl -ir $wid -e 0,${new_props// /,} &
		all_windows[$wid]="${props[*]}"
	done

	[[ ${windows[$id]} ]] &&
		properties=( ${windows[$id]} )
	#rm /tmp/wmctrl_lock

	#echo DONE ${properties[*]}
	#get_windows $id

	#echo POST $rofi_restore_windows, ${properties[*]}
}

get_rotation_properties() {
	#list_windows | grep -v "^\(${windows_to_ignore// /\\|}\)\s\+\w" |
	#list_windows | grep -v "^\(${windows_to_ignore// /\\|\s\+\w}\)" |
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
		wmctrl -ir $wid -e 0,$wx,$wy,$ww,$wh &
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

	#echo $block_start, $block_dimension, $block_segments
	#echo $x, $y, $x_start, $x_end, $y_start, $y_end, $columns, $rows

	get_dimension_size x
	get_dimension_size y

	#set_geometry

	if [[ ! $no_restart ]]; then
		#echo KILLING $(ps -C notify.sh -o args=)
		#ps -C dunst -o pid= | xargs -r kill
		#ps -C dunst -o pid= | xargs -r kill
		pidof -x notify.sh dunst | xargs -r kill -9
		#echo DUNST
		#grep geometry ~/.config/dunst/windows_osd_dunstrc
		dunst -config ~/.config/dunst/windows_osd_dunstrc &> /dev/null &
	fi

	display_notification
	#killall spy_windows.sh xprop
	#exit

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

	#local evaluate_type=window
	#get_dimension_size x
	#display_notification
	#read_keyboard_input

	start_interactive window
	#killall spy_windows.sh xprop
	#exit

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
					ad[$1] = ad[$1] " " ad[$1] + $i
				}
			} else {
				sub("0x0*", "0x", $1)
				for (di in ad) {
					split(ad[di], dp)
					if ($(i + 1) > dp[1] &&
						$(i + 1) + $(i + 3) < dp[2]) d = di
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
		#echo SWW: ${workspaces[$ws]} - $ws, ${all_windows[$ws]}
	done

	#echo AW: ${!windows[*]}
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
	#local workspaces="$(tr ' ' '_' <<< ${tiling_workspaces[*]})"
	#signal_event "workspaces" "tiling" "$workspaces"
	#signal_event "workspaces" "windows" "$workspace $id ${!windows[*]}"
	#signal_event "launchers" "active" "${current_id:-$id}"

	#signal_event "workspaces" "tiling" "${tiling_workspaces[*]}"
	#[[ $alignment_direction == [hv] && $reverse ]] && wm_mode+='reverse_'

	signal_tiling
	signal_event "workspaces" "windows" "$workspace $id ${!windows[*]}"
	signal_event "launchers" "active" "${current_id:-$id}"

	read sbg pbfg <<< $(\
		sed -n 's/^\w*g=.\([^"]*\).*/\1/p' ~/.orw/scripts/notify.sh | xargs)
}

set_tile_event() {
	#echo TILE START
	#list_windows
	local tiling=true {align,full}_index choosen_alignment reverse
	local original_properties=( ${properties[*]} )

	#[[ $rofi_state == opened ]] &&
	#	local rofi_passing_state=opened closing=true
	[[ $rofi_state == opened ]] && toggle_rofi
	remove_tiling_window
	#unset closing
	local windows_to_ignore=$id

	update_aligned_windows


	##[[ $rofi_passing_state ]] &&
	#[[ $rofi_state == opened ]] &&
	#	toggle_rofi || update_aligned_windows
	#unset rofi_passing_state

	#killall spy_windows.sh xprop
	#exit

	select_tiling_window
	#echo TILE SELECT
	#list_windows
	get_workspace_windows

	toggle_rofi
	align_index=$(echo -e '\n\n\n' | rofi -dmenu -format i -theme main)
	full_index=$(echo -e '\n' | rofi -dmenu -format i -theme main)
	toggle_rofi

	if [[ $align_index ]]; then
		((align_index > 1)) &&
			choosen_alignment=v || choosen_alignment=h
		((!(align_index % 2))) && reverse=true
	fi

	#set_alignment_properties $choosen_alignment
	#get_alignment '' print

	#killall spy_windows.sh xprop
	#exit

	#echo TILE: $windows_to_ignore
	#set_alignment_properties $choosen_alignment
	#get_alignment '' print
	#killall spy_windows.sh xprop
	#exit

	((full_index)) &&
		make_full_window || align
	#for w in ${!all_aligned_windows[*]}; do
	#	echo TILE $w: ${all_aligned_windows[$w]}
	#done
	update_aligned_windows

	wmctrl -ia ${original_properties[0]} &

	#echo TILE LIST
	#list_windows
	#wmctrl -lG
}

set_min_event() {
	local event=min

	xdotool windowminimize $id
	#wmctrl -ir $id -b add,below &

	#[[ $rofi_state == opened ]] &&
	#	local rofi_passing_state=opened closing=true
	[[ $rofi_state == opened ]] && toggle_rofi
	properties=( $id ${windows[$id]} )

	#echo MIN $id: ${properties[*]}
	#set_alignment_properties h
	#get_alignment move print
	#killall spy_windows.sh xprop
	#exit

	align m
	update_aligned_windows
	#unset closing

	#[[ $rofi_passing_state ]] &&
	#	toggle_rofi || update_aligned_windows
}

set_max_event() {
	local event=max
	#[[ $rofi_state == opened ]] &&
	#	local rofi_passing_state=opened closing=true

	[[ $rofi_state == opened ]] && toggle_rofi

	if [[ ${states[$id]} ]]; then
		unset maxed_id
		restore
	else
		maxed_id=$id
		get_full_window_properties $id
		#echo MAXING $maxed_id: $x, $y, $w, $h
		wmctrl -ir $id -e 0,$x,$y,$w,$h &
		properties=( $id ${windows[$id]} )
		#local original_properties=( ${properties[*]} )

		align m

		properties=( $x $y $w $h ${properties[*]: -2} )
		all_windows[$maxed_id]="${properties[*]}"
		#windows[$maxed_id]="${properties[*]}"
		#local windows_to_ignore=$maxed_id
		local current_id
	fi
	#unset closing

	#[[ $rofi_passing_state ]] &&
	#	toggle_rofi || update_aligned_windows

	#echo MAX $maxed_id - $current_id: ${properties[*]}
	#sleep 1

	update_aligned_windows
	
	#all_windows[$id]="${properties[*]}"
	#windows[$id]="${properties[*]}"
	#echo END: $id, ${properties[*]}, ${windows[$id]}
	#list_windows
}

set_update_event() {
	update_values
}

set_move_event() {
	[[ ${tiling_workspaces[*]} == *$workspace* ]] &&
		remove_tiling_window || xdotool windowminimize $id

	#local rofi_pid=$(pidof -x workspaces_group.sh)
	echo ROFI: $rofi_state

	local rofi_pid=$(pidof -x signal_windows_event.sh)
	#echo $rofi_pid
	kill -USR1 $rofi_pid

	echo ROFI: $rofi_state

	if [[ $rofi_state == opened ]]; then
		local new_workspace=$(~/.orw/scripts/rofi_scripts/dmenu/workspaces.sh move)
		echo $new_workspace
		local windows_to_ignore=$id
		toggle_rofi
	fi

	#if [[ ${tiling_workspaces[*]} == *$workspace* ]]; then
	#	[[ $rofi_state == opened ]] &&
	#		local rofi_passing_state=opened closing=true
	#	echo REMOVE
	#	remove_tiling_window
	#	unset closing
	#else
	#	xdotool windowminimize $id
	#fi

	##if [[ $rofi_state == opened ]]; then
	#if [[ $rofi_passing_state ]]; then
	#	echo WORKSPACE
	#	new_workspace=$(~/.orw/scripts/rofi_scripts/dmenu/workspaces.sh move)
	#	local windows_to_ignore=$id
	#	echo TOGGLE
	#	toggle_rofi
	#	unset rofi_passing_state
	#else
	#	update_aligned_windows
	#fi

	#list_windows
	#killall spy_windows.sh xprop
	#exit

	if [[ $new_workspace ]]; then
		wmctrl -ir $id -t $new_workspace
		wmctrl -s $new_workspace
	fi

	#new_workspace=$(~/.orw/scripts/rofi_scripts/dmenu/workspaces.sh move)
	#[[ ${tiling_workspaces[*]} == *$workspace* ]] && toggle_rofi

	#wmctrl -ir $id -t $new_workspace
	#wmctrl -s $new_workspace

	#workspaces[$id]=$new_workspace

	move_window=true
	moving_id=$id
}

tile_windows() {
	local alignment_direction {display,total}_surface scale
	declare -A surfaces {all_,}aligned_windows

	update_windows

	#for w in ${!windows[*]}; do
	#	echo AW TILE PRE $w: ${windows[$w]}
	#done

	#get_windows

	#get_workspace_windows

	#for w in ${!windows[*]}; do
	#	echo AW TILE $w: ${windows[$w]}
	#done

	for windex in ${!windows[*]}; do
		read x y w h xb yb <<< "${windows[$windex]}"
		surface=$(((w + xb) * (h + yb)))
		((total_surface+=surface))
		surfaces[$windex]=$surface

		#echo "$windex $xb $yb $x $y $w $h" >> $shm_floating_properties
		echo "$windex $xb $yb $x $y $w $h" #>> $shm_floating_properties
	done

	read d_{xs,ys,xe,ye} <<< ${display_properties[*]}
	display_surface=$(((d_xe - d_xs) * (d_ye - d_ys)))
	scale=$(echo "$display_surface / $total_surface" | bc -l)

	echo $display_surface, $total_surface, $scale

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

		if ((surface_index < ${#scalled_surfaces[*]} - 1)); then
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

		echo p $alignment_direction: $scalled_surface, ${properties[*]}
	done

	aligned_properties=( ${properties[*]} $x_border $y_border)
	echo ap $alignment_direction: $scalled_surface, ${aligned_properties[*]}
	((aligned_properties[2]-=x_border))
	((aligned_properties[3]-=y_border))
	#echo ap: ${aligned_properties[*]}

	all_aligned_windows[$wid]="${aligned_properties[*]}"
	alignments[$wid]=$alignment_direction

	update_aligned_windows

	properties=( ${windows[$id]} )
	#echo TILED: $id, ${properties[*]}
	#list_windows
}

untile_windows() {
	window_ids="${!windows[*]}"

	while read wid {x,y}b props; do
		wmctrl -ir $wid -e 0,${props// /,} &
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

	#signal_event "workspaces" "tiling" \
	#	"$wm_mode${alignment_direction::1} ${tiling_workspaces[*]}"

	sed -i "/^tiling/ s/[0-9 ]\+/ ${tiling_workspaces[*]} /" $0
}

set_update_workspaces_event() {
	event=update_workspaces

	[[ ${tiling_workspaces[*]} =~ $desktop ]] && toggle_rofi

	all_tiling_workspaces=${tiling_workspaces[*]}
	desktop=$(~/.orw/scripts/rofi_scripts/dmenu/workspaces.sh \
		move ${all_tiling_workspaces// /,})

	[[ $rofi_state == opened ]] && toggle_rofi

	if [[ $desktop ]]; then
		if [[ ${tiling_workspaces[*]} =~ $desktop ]]; then
			tiling_workspaces=( ${tiling_workspaces[*]/$desktop} )
			set_new_position center center 0 0 yes
			#untile_windows
		else
			tiling_workspaces+=( $desktop )
			#update_windows
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
		#echo TILING
		old_properties=( ${all_windows[$id]} )

		#update_windows $id

		#echo RESIZE ${old_properties[*]}, ${properties[*]}
		#[[ ! -f /tmp/wmctrl_lock &&
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
		wmctrl -ir $wid -e 0,${props// /,} &
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
				echo "${ratio}_${ratio_win}"
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
		#echo KILLING BAR $bar_pid, $offset_aligned_bars
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

		#echo ${neighbour_properties[*]}
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

	#echo $old_count, $align_ratio, $start, $min_start, $end, ${properties[index + 2]}, ${temp_properties[*]}

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
	#echo $aligned

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
		wmctrl -ir $aw -e 0,${props// /,} &
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
	#echo $alignment_direction, $index, $opposite_index, $id, ${properties[index]}

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

	echo STATS $reverse - $direction: $index, $opposite_index
	#list_windows
	echo TEMP $temp_start, $temp_opposite_start, $temp_opposite_dimension: ${properties[*]}
	#windows_to_ignore='0x600003'
	#list_windows | grep -v "^\(${windows_to_ignore// /\\|}\)\s\+\w" |
	#	sort -nk $((index + 1)),$((index + 1)) \
	#	-nk $((opposite_index + 1)),$((opposite_index + 1)) -nk 1,1r
	#get_alignment '' print
	#killall spy_windows.sh xprop
	#exit

	#windows[$id]="${properties[*]:1}"
	get_alignment "" print
	#killall sww.sh spy_window.sh xprop
	#exit

	read block_{start,dimension,segments} aligned <<< $(get_alignment)

	eval aligned_windows=( $aligned )
	read new_{start,size} <<< ${aligned_windows[$current_id]}
	#echo $aligned
	#echo $new_start, $new_size, ${aligned_windows[$current_id]}, ${properties[*]}
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

	#echo FULL, $id - $current_id: ${properties[*]}, ${windows[$id]}
	#echo ${properties[1]}, ${properties
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
	#get_display_properties
	#display=${workspaces[$id]#*_}
	#display_properties=( ${displays[$display]} )

	#windows=()
	#for window in ${!workspaces[*]}; do
	#	[[ ${workspaces[$window]} == ${workspace}_${display} ]] &&
	#		windows[$window]="${all_windows[$window]}"
	#done

	get_workspace_windows

	read d{xs,ys,xe,ye} <<< "${display_properties[*]}"
	read w{x,y,w,h,{x,y}b} <<< "${properties[*]}"

	properties=( $(get_stretch_properties) $wxb $wyb )
	local props="${properties[*]::4}"
	wmctrl -ir $id -e 0,${props// /,} &

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
	echo $x, $y, $display, IGNORE: $windows_to_ignore
	for w in ${!windows[*]}; do
		echo W - $w: ${windows[$w]}
	done

	#list_windows

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

	echo $id, $h, $v
	echo WIN: ${windows[$id]}
}

set_aligned_windows() {
	for wid in ${!aligned_windows[*]}; do
		read window_{start,size} <<< ${aligned_windows[$wid]}
		props=( ${windows[$wid]} )
		props[index - 1]=$window_start
		props[index + 1]=$window_size

		[[ $1 && $wid == $1 ]] && set_border_diff $wid
		new_props="${props[*]}"

		[[ $no_change ]] || wmctrl -ir $wid -e 0,${new_props// /,} &

		all_windows[$wid]="${props[*]}"
		windows[$wid]="${props[*]}"
	done
}

wait_for_mouse_movement() {
	local drag_counter pointer_id=$(xinput list |
		awk -F '=' '/pointer/ { sub("\t.*", "", $NF); p = $NF } END { print p }')

	[[ $@ ]] &&
		local button=3 || local button=1

	#button=1

	while
		action=$(xinput --query-state $pointer_id |
			awk -F '=' '/button\['$button'\]/ { print $NF == "down" }')
		((action))
	do
		#continue
		[[ $@ ]] &&
			$@ #|| 
		sleep 0.05
	done
}

set_move_with_mouse_event() {
	if [[ ${tiling_workspaces[*]} == *$workspace* ]]; then
		declare -A aligned_windows
		local action alignment {block_,}size align_ratio

		#read id _ <<< $(find_window_under_pointer)
		find_window_under_pointer
		properties=( $id ${windows[$id]} )

		alignment=${alignments[$id]}
		set_alignment_properties $alignment

		test
		echo MOVING $alignment: ${properties[*]}
		get_alignment move print

		read _ block_size _ aligned <<< $(get_alignment move)
		eval aligned_windows=( $aligned )
		size=${properties[index + 2]}

		update_alignment move
		set_aligned_windows
		wait_for_mouse_movement

		current_id=$id
		local windows_to_ignore=$current_id
		find_window_under_pointer
		#read id h v <<< $(find_window_under_pointer)

		#test

		#echo $id, ${!displays[*]}

		#for w in ${!windows[*]}; do
		#	echo $w: ${windows[$w]}
		#done

		#killall swd.sh xprop
		#exit

		if [[ $id ]]; then
			properties=( $id ${windows[$id]} )
			((${properties[3]} > ${properties[4]})) &&
				alignment=h || alignment=v
			#echo MOVE $alignment, ${properties[3]}, ${properties[4]}
			((${!alignment})) && local reverse=true
			align_ratio=$(echo "($block_size + $margin + $size) / $size" | bc -l)

			set_alignment_properties $alignment
			#echo $alignment - $id: ${properties[*]}
			#get_alignment
			#killall swd.sh xprop
			#exit

			read _{,,} aligned <<< $(get_alignment)
			eval aligned_windows=( $aligned )
			update_alignment

			new_properties=( ${all_windows[$current_id]} )
			new_properties[opposite_index - 1]=${properties[opposite_index]}
			new_properties[opposite_index + 1]=${properties[opposite_index + 2]}
			windows[$current_id]="${new_properties[*]}"

			#echo cid: $current_id: ${new_properties[*]}
			#echo id: $id: ${properties[*]}

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

		#echo END: ${workspaces[$id]}
		#for w in ${!windows[*]}; do
		#	echo $w: ${windows[$w]}
		#done
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

	#for w in ${!all_aligned_windows[*]}; do
	#	echo $w: ${all_aligned_windows[$w]}
	#done

	update_aligned_windows
}

set_rofi_window() {
	((rofi_offset <= 0 && rofi_opening_offset)) &&
		local rofi_offset=$rofi_opening_offset

	if ((rofi_offset > 0)); then
		local state=$1
		if [[ $state == align ]]; then
			(( rofi_window[1] += rofi_offset ))
			local open_sign=-
		fi

		(( rofi_window[4] -= ${rofi_window[2]} ))
		rofi_window[3]=$open_sign$rofi_offset
		(( rofi_window[3] -= margin ))

		echo "${rofi_window[*]}"
	fi
}

set_rofi_windows() {
	#local rofi_width=$(awk '
	#	/^[^@]window-location/ { p = (/west;/) }
	#	/^\s*[^@]\w*-padding|font/ {
	#		mp = (/font/) ? 1.8 : 2
	#		gsub("(px|\").*|.* ", "")
	#		t += $0 * mp
	#	} END { if (p) print int(t) }' ~/.config/rofi/icons.rasi)

	#local rofi_width
	#echo DIS: ${display_properties[*]}
	local rofi_window=(
		temp ${current_display_properties[*]:-${display_properties[*]}} 0 0
	)
	#rofi_offset=$((rofi_width - ${rofi_window[1]}))
	[[ $1 ]] &&
		rofi_offset=$1 ||
		rofi_offset=$(awk '
		/width.*px/ {
			sub("[^0-9]*$", "", $NF)
			print int($NF) - '${rofi_window[1]}'
		}' ~/.config/rofi/icons.rasi)

	rofi_restore_windows="$(set_rofi_window restore)"
	rofi_align_windows="$(set_rofi_window align)"

	#echo $rofi_offset - $rofi_opening_offset: ${rofi_window[*]}, $rofi_restore_windows, $rofi_align_windows
}

toggle_maxed_window() {
	local {opposite_,}sign
	[[ $rofi_windows_state == align ]] &&
		sign=+ opposite_sign=- || sign=- opposite_sign=+

	properties=( ${windows[$maxed_id]} )
	echo PRE: ${properties[*]}
	((properties[0] $sign= rofi_offset))
	((properties[2] $opposite_sign= rofi_offset))
	echo POST: ${properties[*]}
	read x y w h b{x,y} <<< "${properties[*]}"

	wmctrl -ir $maxed_id -e 0,$x,$y,$w,$h &

	windows[$maxed_id]="${properties[*]}"
	all_windows[$maxed_id]="${properties[*]}"
	#echo END $maxed_id: ${properties[*]}, ${windows[$maxed_id]}
}

toggle_rofi() {
	#local windows=( [1]=sola [2]=car )
	#list_windows
	#killall spy_windows.sh xprop
	#exit

	#echo $rfi ROFI: $rofi_passing_state - $closing, $id: ${properties[*]}

	#while [[ $rofi_holder ]]; do
	#	sleep 0.05
	#	echo waiting.. $rofi_holder
	#done &
	#local rofi_pid=$!
	#wait $rofi_pid

	##if ((rofi_offset > 0)) && [[ $id != temp ]]; then
	#if ((rofi_offset > 0 || rofi_opening_offset)) &&
	#	[[ ! $closing && (! $rofi_passing_state ||
	#	$rofi_passing_state == $rofi_state) ]]; then
		local rofi_windows_state current_rofi_workspace=$rofi_workspace
		local {align,restore}_maxed no_change=$2

		[[ $1 ]] &&
			local workspace=$1

		if [[ ! $rofi_state || $rofi_state == closed ]]; then
			rofi_workspace=$workspace
			rofi_windows_state=align
			local current_rofi_workspace=$rofi_workspace
			rofi_opening_offset=$rofi_offset
			rofi_opening_display=$display
			rofi_state=opened
			align_maxed=true
		else
			#if [[ ! $1 ]]; then
				rofi_state=closed
				unset rofi_workspace
				[[ $event == resize_rofi ]] &&
					unset event {all_,}windows[rofi]
			#fi

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

				#echo $id: ${properties[*]}, $1: $rofi_state
				if [[ $id ]]; then
					#echo PRE
					#list_windows

					#echo ROFI 1, $id: ${properties[*]}
					#list_windows
					[[ $id != temp ]] && get_workspace_windows
					#echo ROFI AFT: $display_properties - ${FUNCNAME[*]}
					#echo ROFI 2, $id: ${properties[*]}
					#list_windows

					#echo POST
					#list_windows

					local properties=( ${!state_properties} )
					local id=temp

					local aligned=$(list_windows | grep -v "^\<$maxed_id\>" | sort -nk 2,2 |
						awk '{
							print "'${properties[1]}'" + "'${properties[3]}'" + '$margin' == $2
							exit
						}')

					#echo ROFI $1: $(list_windows | sort -nk 2,2 | head -1)
					#echo $1 $rofi_state - $aligned: $margin, ${properties[*]}

					if ((aligned)); then
						windows[$id]="${properties[*]:1}"
						set_alignment_properties h

						#echo ROFI ALIGN:
						#list_windows

						#if [[ $rofi_state == opened ]]; then
						#	echo
						#	get_alignment move print
						#	echo
						#fi

						#if [[ $rofi_state == closed ]]; then
						#	get_alignment move print
						#	#unset {all_,}windows[$id] 
						#	#while [[ $closing ]]; do
						#	#	echo closing..
						#	#	sleep 0.05
						#	#done
						#fi
						#killall spy_windows.sh xprop
						#exit

						#[[ $maxed_id ]] && get_alignment move print
						#if [[ $rofi_state == opened ]]; then
						#	#local event=resize
						#	#properties[1]=50
						#	#properties[3]=-15
						#	#echo ${properties[*]}
						#	#windows[temp]="${properties[*]:1}"
						#	#diff=-41
						#	get_alignment move print
						#	killall spy_windows.sh xprop
						#	exit
						#fi

						#[[ $rofi_state == closed ]] &&
						#	echo CLOSING && sleep 1

						#if [[ $rofi_state == closed && $closing ]]; then
						#	#unset {all_,}windows[$id] 
						#	#get_workspace_windows

						#	echo ROFI
						#	list_windows
						#	echo AL
						#	get_alignment move print
						#	return

						#	read _{,,} aligned <<< $(get_alignment move)
						#	echo ROFI: $aligned
						#	eval aligned_windows=( $aligned )
						#	for w in ${!aligned_windows[*]}; do
						#		read n{s,d} <<< ${aligned_windows[$w]}
						#		wp=( ${windows[$w]} )
						#		wp[0]=$ns wp[2]=$nd
						#		windows[$w]="${wp[*]}"
						#		all_windows[$w]="${wp[*]}"
						#		echo NEW $w: ${wp[$w]}
						#	done
						#fi

						#[[ $maxed_id ]] &&
						#	local windows_to_ignore=$maxed_id

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

	#echo ${BASH_LINENO[*]} $1 $rofi_state: $rofi_offset, $rofi_opening_offset
	if [[ $rofi_state == closed ]]; then
		((rofi_offset != rofi_opening_offset)) &&
			local reset_rofi_windows=true
		unset rofi_opening_offset
		[[ $reset_rofi_windows ]] && set_rofi_windows
	fi

	return 0
}

resize_rofi() {
	local id=rofi old_properties=( ${rofi_restore_windows#* } )
	set_rofi_windows
	local properties=( ${rofi_restore_windows#* } )
	#echo ${old_properties[*]}, ${properties[*]}
	#killall xprop spy_windows.sh
	#exit
	#((properties[2] += diff))
	windows[$id]="${properties[*]}"

	#echo ${old_properties[*]}, ${properties[*]}
}

test() {
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

	#sed -i "/^tiling/ s/[0-9].*[0-9]/${tiling_workspaces[*]}/" $0

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
	local rfi=TOGGLEING
	toggle_rofi
}

set_rofi_resize_event() {
	#resize_rofi
	#echo RRW: $rofi_restore_windows
	local id=rofi old_properties=( ${rofi_restore_windows#* } )
	event=resize_rofi
	set_rofi_windows
	local properties=( ${rofi_restore_windows#* } )
	#echo ${old_properties[*]}, $rofi_offset, ${properties[*]}

	if ((rofi_offset > 0)); then
		[[ ! ${old_properties[*]} && ${properties[*]} ]] &&
			toggle_rofi || resize

		#rofi_restore_windows="$id ${properties[*]: -6}"
		#echo RRW POST: $rofi_restore_windows, ${properties[*]}, ${properties[*]: -6}

		#if [[ ! ${old_properties[*]} && ${properties[*]} ]]; then
		#	toggle_rofi
		#else
		#	resize
		#	rofi_restore_windows="$id ${properties[*]}"
		#fi
	else
		#echo "${old_properties[*]} && ${properties[*]}, $rofi_align_windows"
		if [[ ${old_properties[*]} && ! ${properties[*]} ]]; then
			local rofi_offset=1 rofi_restore_windows="temp ${old_properties[*]}"
			toggle_rofi
		fi
	fi

	#windows[$id]="${properties[*]}"
	#resize

	#rofi_restore_windows="$id ${properties[*]}"
	#rofi_restore_windows="$id ${properties[*]: -6}"
	#echo ${old_properties[*]}, ${properties[*]}
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

	wmctrl -ir $id -e 0,${props// /,}
	wmctrl -ia $id

	unset {all_,}windows[$id]
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
trap set_resize_with_mouse_event 51
trap set_interactive_offset_event 52
trap set_interactive_resize_event 53
trap set_rofi_toggle_event 54
trap set_rofi_resize_event 55
trap set_untile_event 56
trap save_state SIGKILL SIGINT SIGTERM

declare -A {all_,}windows {all_,}aligned_windows workspaces
declare -A displays alignments states

tiling_workspaces=( 1 2 3 )
workspace=$(xdotool get_desktop)

read total_workspace_count workspace <<< \
	$(wmctrl -d | awk '$2 ~ "^\\*" { cd = $1 } END { print $1, cd }')
read default_{x,y}_border <<< \
	$(awk '/border/ { print $NF }' $orw_config | xargs)
read -a all_ids <<< $(xprop -root _NET_CLIENT_LIST_STACKING | awk '{ gsub(".*#|,", ""); print }')

update_windows all
update_workspaces
update_values

set_workspace_windows

source ~/.orw/scripts/windowctl_by_input.sh windowctl_osd source

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
read_command="while [[ \$input != d ]];"
read_command+="do read -rsn 1 input;"
read_command+="echo \$input > $input_file;"
read_command+="done;"
#read_command+="wmctrl -lG >> w.log;"
read_command+="printf '0x%x' \$(xdotool getactivewindow) > $input_file"

#read_command+="while [[ \$input != d ]];"
#read_command+="do read -rsn 1 input;"
#read_command+="echo \$input > $input_file;"
#read_command+="done"

evaluate_window_resize() {
	case $input in
		"<") sign=- opposite_sign=+;;
		">") sign=+ opposite_sign=-;;
		[jklh])
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

			((${properties% *} $sign= step))
			((edges[$input] += $sign$step))
			((diff += $opposite_sign$step))

			eval "((${orientation}_window_size $sign= 1))"
			eval "((${orientation}_block_$position $opposite_sign= 1))"

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

	#wmctrl -lG | awk '$2 == 2'

	#LIBGL_ALWAYS_SOFTWARE=1 alacritty -t input --class=input -e bash -c "$read_command" #&> /dev/null &
	alacritty -t input --class=input \
		-e bash -c "$read_command" &> /dev/null &
	#termite -t input --class=input \
	#	-e "bash -c '$read_command'" &> /dev/null &
	##local pid=$!

	#while true; do
	#	if [[ $input != d ]]; then
	#		input=$(cat $input_file)
	#		evaluate_${evaluate_type}_resize $input
	#	else
	#		input_id=$(wmctrl -l | awk '$NF == "input" { sub("0x0*", "0x", $1); print $1 }')
	#		break
	#	fi
	#done

	#until
	#	input_id=$(wmctrl -l | awk '$NF == "input" { sub("0x0*", "0x", $1); print $1 }')
	#	[[ $input_id ]]
	#do
	#	sleep 0.05
	#done

	#echo WINDOW: $id, $current_id
	local input_id
	while [[ $input != d ]]; do
		input=$(cat $input_file)
		[[ $input == 0x* ]] &&
			input_id=$input input=d
		evaluate_${evaluate_type}_resize $input
	done
	input_id=$(cat $input_file)
	##wait $pid
	#echo END: $input_id

	input_ids+=( $input_id )

	killall dunst &> /dev/null

	#input_count=2
	unset input stop {x,y}_{window_size,{window,block}_{before,after}}
	rm $input_file
}

#read display{,_{x,y}} width height rest <<< $(~/.orw/scripts/get_display.sh ${x:-0} ${y:-0})

alignments_file=/tmp/alignments
states_file=/tmp/states

((window_count)) || rm $alignments_file $states_file

for file in alignments states; do
	file="${file}_file"
	if [[ -f ${!file} ]]; then
		eval "${file%%_*}=( $(awk '{ w = $1; sub(w " *", ""); printf "[%s]=\"%s\" ", w, $0 }' ${!file}) )"
	fi
done

shm_alignments=/tmp/alignments
shm_floating_properties=/tmp/shm_floating_properties

while read change new_value; do
	#echo ${change^^}: $new_value
	#continue

	#echo "HERE $change: $new_value"

	if [[ $change == desktop ]]; then
		unset notification
		previous_workspace=$workspace
		workspace=$new_value

		#echo DESK: $previous_workspace, $workspace: $move_window

		if ((workspace != previous_workspace)); then
			[[ $rofi_state == opened &&
				 ${tiling_workspaces[*]} == *$previous_workspace* ]] &&
				 toggle_rofi $previous_workspace

			set_workspace_windows

			#((workspace == 2)) &&
			#	~/.orw/scripts/notify.sh "WS: ${windows[*]}" &&
			#	echo "WS: $workspace, ${#windows[*]}: ${windows[*]}"
			#((!${#windows[*]})) &&

			[[ ! ${windows[*]} ]] &&
				signal_event "launchers" "active" &&
				signal_event "workspaces" "desktop" "$workspace"
			make_workspace_notification $workspace $previous_workspace
		fi

		pattern="$previous_workspace.*$workspace|$workspace.*$previous_workspace"

		if [[ ! ${tiling_workspaces[*]} =~ $pattern ]]; then
			if [[ ${tiling_workspaces[*]} =~ $previous_workspace ]]; then
				set_new_position center center 0 0 yes
				latest_tiling_workspace=$previous_workspace
			elif [[ ${tiling_workspaces[*]} =~ $workspace ]]; then
				set_new_position ${new_x:-center} ${new_y:-center} 150 150
			fi
		fi

		if [[ $move_window ]]; then
			#echo MOVING: ${tiling_workspaces[*]} - $workspace : $window_count
			if [[ ${tiling_workspaces[*]} =~ $workspace ]]; then
				#if ((window_count == 1)); then
				#	id=${original_properties[0]}
				#	handle_first_window
				if ((window_count)); then
				#else
					[[ $rofi_state == opened ]] && toggle_rofi 
					select_tiling_window

					#echo $rofi_state: $rofi_align_windows, $rofi_restore_windows
					toggle_rofi
					align_index=$(echo -e '\n\n\n' | rofi -dmenu -format i -theme main)
					full_index=$(echo -e '\n ' | rofi -dmenu -format i -theme main)
					toggle_rofi
					#echo TILE $align_index, $full_index, $rofi_state: $rofi_align_windows, $rofi_restore_windows

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

			workspaces[$current_id]=${workspace}_${display}
			wmctrl -ia ${current_id:-$id} &

			unset move_window tiling moving_id
		fi
	elif [[ $change == all_ids ]]; then
		previous_ids=( ${all_ids[*]} )
		all_ids=( $new_value )

		#echo ALL: $input_count, $new_value
		((${#previous_ids[*]} == ${#all_ids[*]})) && continue

		current_ids=$(comm -3 \
			<(tr ' ' '\n' <<< ${all_ids[*]} | sort) \
			<(tr ' ' '\n' <<< ${previous_ids[*]} | sort) | grep -o '0x\w\+')

		#echo CURRENT: $current_id, $id

		#((${#previous_ids[*]} > ${#all_ids[*]})) &&
		#	closing=true || opening=true

		#((input_count)) && ((input_count--)) && continue

		#if ((input_count)); then
		#	((input_count--))
		#	#continue
		#	skip=true
		#else
		#	unset skip
		#fi

		#echo ID $id, ${properties[*]}, $current_id, ${windows[$current_id]}
		#((input_count)) && killall spy_windows.sh xprop && exit

		#if (((!input_count && ${#previous_ids[*]} > ${#all_ids[*]}) ||
		#	(input_count == 2 && ${#previous_ids[*]} == ${#all_ids[*]}))); then

		# first condition covers the case when opened window closes during input
		# since loop will start processing events after input gets closed,
		# input_count will have a value of 2, thus input_count == 2
		# and since window closing will be considered first event when loop gets control
		# it will let it handle closing even under input_count value
		if (((!input_count || input_count == 2) &&
			${#previous_ids[*]} > ${#all_ids[*]})); then
			#echo STUPID

			[[ $current_ids =~ ' ' ]] &&
				closing_ids=$(sort_by_workspaces)

			for current_id in ${closing_ids:-$current_ids}; do
				[[ ${input_ids[*]} != *$current_id* ]] &&
					signal_event "launchers" "close" "$current_id"

				closing_id_workspace=${workspaces[$current_id]%_*}
				id=$current_id

				#echo CLOING ID: $current_id

				if [[ ${tiling_workspaces[*]} == *$closing_id_workspace* ]]; then
					#if ((closing_id_workspace != workspace)); then
					#fi

					#id=$current_id

					if [[ ${input_ids[*]} == *$id* ]]; then
						for iid in ${!input_ids[*]}; do
							[[ ${input_ids[iid]} == $id ]] &&
								unset input_ids[iid] && break
						done

						continue
						#echo UNSETTING $input_id
						#unset input_id
					elif [[ ${all_windows[$id]} ]]; then
						#if [[ ${all_windows[$id]} ]]; then
							properties=( $id ${all_windows[$id]} )
							#while [[ $closing_rofi ]]; do
							#	echo PRE $rofi_state
							#	sleep 0.05
							#done

							#al=${alignments[$id]}
							#set_alignment_properties $al
							#echo POST $id: $al, ${properties[*]}
							#get_alignment move print

							#while [[ $rofi_state == opened ]]; do
							#	echo PRE $rofi_state
							#	sleep 0.05
							#done

							#echo CLOSE: $id, ${properties[*]} - ${all_windows[$id]}
							#[[ $rofi_state == opened ]] && rofi_opened=true
							#echo CLOSING: $rofi_state, $id: ${properties[*]} - $window_title
							#list_windows

							#if [[ $rofi_state != opened ]]; then
								align c
								#for w in ${!all_aligned_windows[*]}; do
								#	echo $w: ${all_aligned_windows[$w]}
								#done

								#echo STEP 1, $id: ${properties[*]} - ${windows[$id]}
								#[[ $rofi_opened ]] || update_aligned_windows
								update_aligned_windows
								#echo STEP 2, $id: ${properties[*]} - ${windows[$id]}
								((window_count--))
								#echo STEP 3
								#list_windows

								#if ((closing_id_workspace != workspace)); then
								#	windows=()

								#	for wid in ${!all_windows[*]}; do
								#		#((${workspaces[$wid]} == workspace)) && windows[$wid]
								#		[[ ${workspaces[$wid]} == ${workspace}_${display} ]] &&
								#			windows[$wid]="${all_windows[$wid]}"
								#	done
								#fi
							#fi
					fi
				fi

				if [[ ${all_windows[$id]} ]]; then
					#echo CLOSING UNTILED $id
					unset {{all_,}windows,workspaces,alignments}[$id]
					#for w in ${!windows[*]}; do
					#	echo WIN $w: ${windows[$w]}
					#done
				fi
			done

			if ((closing_id_workspace != workspace)); then
				windows=()

				for wid in ${!all_windows[*]}; do
					#((${workspaces[$wid]} == workspace)) && windows[$wid]
					[[ ${workspaces[$wid]} == ${workspace}_${display} ]] &&
						windows[$wid]="${all_windows[$wid]}"
					done
			fi

			unset closing_id_workspace #windows[$id] all_windows[$id] alignments[$id]

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

			#echo INPUTS: ${input_ids[*]}, $id, $current_id, $window_title: ${properties[*]}

			if [[ ${tiling_workspaces[*]} =~ $workspace ]]; then
				#echo $current_id: ${input_ids[*]}

				if [[ ${input_ids[*]} == *$current_id* ]]; then
					#properties=( ${windows[$id]} )
					#echo INPUT HIT: $id - ${windows[$id]}, $current_id - ${windows[$current_id]}
					#properties=( ${windows[$current_id]} )
					current_id=$id
					#continue
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

						$1 ~ "'"${current_id#0x}"'" { i = ($NF ~ "('${blacklist//,/|}')") }
						$2 == '$workspace' && $di >= ds && $di + 0 <= de \
							{ if($NF !~ "('${blacklist//,/|}')") cwc++ }
						END { print cwc++, i }')
				fi

				#echo $window_title, $ignore: $current_id
				#((ignore)) && killall spy_windows.sh xprop && exit

				((ignore)) ||
					ignore=$(xprop -id $current_id _NET_WM_WINDOW_TYPE | awk '{ print $NF ~ "DIALOG$" }')

				if ((ignore)); then
					[[ $window_title =~ image_preview|cover_art_widget ]] && set_opacity
				else
					if ((current_window_count == 1)); then
						id=$current_id
						handle_first_window
						alignments[$id]=$display_orientation
					else
						properties=( $id ${all_windows[$id]} )

						#echo WIN: $id, $current_id - $ignore: $window_title
						[[ $full ]] && make_full_window || align
						[[ $interactive ]] && adjust_window

						update_aligned_windows $current_id
						((window_count++))

						[[ ${input_ids[*]} ]] &&
							id=$current_id properties=( ${windows[$current_id]} )
					fi

					workspaces[$current_id]=${workspace}_${display}

					read x y w h xb yb <<< ${windows[$current_id]}
					new_x=$((x + (w - new_window_size) / 2))
					new_y=$((y + (h - new_window_size) / 2))
					new_x=$x new_y=$y
					set_new_position $new_x $new_y 150 150

					[[ ! $id ]] && id=$current_id
				fi
			else
				if [[ $window_title && ! $window_title =~ ${blacklist//,/|} ]]; then
					properties=( $(get_windows $current_id | cut -d ' ' -f 2-) )
					all_windows[$current_id]="${properties[*]}"
					windows[$current_id]="${properties[*]}"
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

			wmctrl -ia $current_id
			#echo wmctrl -ia $current_id

			#echo SIGNAL NEW: $ignore - $current_id, $window_title
		fi
	else
		#echo CRT, $new_value, $id, ${properties[*]}, $current_id, ${windows[$new_value]}
		signal_event "workspaces" "windows" "$workspace $new_value ${!windows[*]}"

		#[[ "$new_value" =~ "0x0" || "$new_value" == $id || $input_count -gt 0 ]] && continue
		#[[ "$new_value" =~ "0x0" || "$new_value" == $id || $move_window ]] && continue
		#signal_event "workspaces" "windows" "$workspace $new_value ${!windows[*]}"

		#[[ "$new_value" =~ "0x0" || "$new_value" == $id || $move_window ]] && continue
		[[ "$new_value" =~ "0x0" || "$new_value" == $id || $move_window || #]] && continue
			${input_ids[*]} == *$new_value* ]] && continue

		#if [[ ${input_ids[*]} == *$new_value* ]]; then
		#	properties=( ${windows[$id]} )
		#	echo NEW INPUT: $new_value - ${windows[$new_value]}, $id - ${windows[$id]}, $current_id - ${windows[$current_id]}  --- ${properties[*]}
		#	continue
		#fi

		#echo NEW: $new_value, $id, $current_id

		id=$new_value
		[[ $id != $current_id ]] && signal_event "launchers" "active" "$id"
		current_id=$id

		#echo ${properties[*]}: ${windows[$id]}
		#list_windows

		properties=( ${windows[$id]} )
		#get_display_properties

		if [[ ${states[$id]} ]]; then
			restore
		else
			if ((ignore)); then
				#echo IGNORE: $id - $window_title, ${all_windows[$id]}
				unset ignore
			else
				temp_props=$(xwininfo -id $id 2> /dev/null |
					parse_properties | cut -d ' ' -f 2-)

				if [[ $temp_props ]]; then
					properties=( $temp_props )
					all_windows[$id]="${properties[*]}"
					windows[$id]="${properties[*]}"
				fi

				#echo TEMP: $temp_props
				#wmctrl -lG
				#list_windows
			fi
		fi
	fi

	unset_vars
done < <(spy)
