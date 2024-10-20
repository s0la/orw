#!/bin/bash

arguments="$@"
argument_index=1
options='(resize|move|tile)'

theme=~/.orw/themes/theme/openbox-3/themerc
blacklist="Keyboard Status Monitor,DROPDOWN"

config=~/.config/orw/config
offsets_file=~/.config/orw/offsets
alignment_file=~/.config/orw/windows_alignment
alignment_file=/dev/shm/alignments
property_log=~/.config/orw/windows_properties

[[ ! -f $config ]] && ~/.orw/scripts/generate_orw_config.sh
[[ ! $current_desktop ]] && current_desktop=$(xdotool get_desktop)

read margin default_{x,y}_border {x,y}_offset full reverse alignment_direction \
	display_count display_orientation <<< $(awk '
		/^(margin|full|reverse|direction|[xy]_(border|offset)) / { p = p " " $NF }
		/^display_[0-9]_name/ { dc++ }
		/^orientation / { o = substr($NF, 1, 1) }
		END { print p, dc, o }' $config)

[[ $full == false ]] && unset full
[[ $reverse == false ]] && unset reverse
[[ $use_ratio == false ]] && unset use_ratio

declare -A windows_indexes

# getting default size of opening window
#new_window_size=$(awk -F '=' '/^new_window_size/ { print $NF }' ~/.orw/scripts/tile_windows.sh)
new_window_size=130

[[ -f $offsets_file && $(awk '/^offset/ { print $NF }' $config) == true ]] && eval $(cat $offsets_file | xargs)

read {x,y}_offset <<< $(sed -n 's/[xy]_offset\s*//p' $config | xargs)

parse_properties() {
	awk '
		/xwininfo/ { id = $4 }
		/Relative/ { if(/X/) xb = $NF; else yb = $NF }
		/geometry/ {
			ap = gensub("([+-]?[0-9]+)(x)?", " \\1", "g", $NF)
			split(ap, pa, " ")
			
			w = (pa[3] ~ /^-/) ? '$width' : 0
			h = (pa[4] ~ /^-/) ? '$height' : 0
			print id, pa[1], pa[2], w + pa[3], h + pa[4], 2 * xb, yb + xb
		}'
}

parse_properties() {
	awk '
		/xwininfo/ { id = $4 }
		/Absolute/ { if(/X/) x = $NF; else y = $NF }
		/Relative/ { if(/X/) xb = $NF; else yb = $NF }
		/Width/ { w = $NF }
		/Height/ { print id, x - xb, y - yb, w, $NF, 2 * xb, yb + xb }'
}

function get_windows() {
	if [[ $1 =~ ^0x ]]; then
		local current_id=${1#0x}
	else
		[[ $1 ]] && local desktop=$1
	fi

	wmctrl -l | awk '
		$2 ~ "'${desktop:-$current_desktop}'" && ! /('"${blacklist//,/|}"')$/ && $1 ~ /'$current_id'/ { print $1 }' |
			xargs -n 1 xwininfo -id | parse_properties
}

function set_windows_properties() {
	[[ ! $properties ]] &&
		properties=( $(xwininfo -id $id | parse_properties) ) &&
			x_border=${properties[5]} y_border=${properties[6]}

	[[ $2 ]] || get_display_properties $1

	if ((!window_count)); then
		local window_index

		while read -r wid wx wy ww wh xb yb; do
			if ((wx > display_x && wx + ww < display_x + width && wy > display_y && wy + wh < display_y + height)); then
				all_windows+=( "$wid $wx $wy $ww $wh $xb $yb" )
				windows_indexes[$wid]=${window_index:-0}
				((window_index++))
			fi
		done <<< $(get_windows $2)

		window_count=${#all_windows[*]}
	fi
}

function update_properties() {
	local window_index=${windows_indexes[$id]}
	[[ $1 ]] && unset all_windows[window_index] || all_windows[window_index]="${properties[*]}"
}

function list_all_windows() {
	for window in "${all_windows[@]}"; do
		echo $window
	done
}

[[ ! $arguments =~ -[in] ]] &&
	id=$(printf "0x%x" $(xdotool getactivewindow)) &&
	properties=( $(xwininfo -id $id | parse_properties) ) &&
		x_border=${properties[5]} y_border=${properties[6]}

function generate_printable_properties() {
	id=${1%% *}
	printable_properties=${1#* }
}

function save_properties() {
	echo ${1:-$id} $printable_properties >> $property_log
}

function backtrace_properties() {
	#read line_number properties <<< $(awk '/^'$id'/ {
	#		nr = NR; p = gensub($1 " (.*) ?" $6, "\\1", 1)
	#	} END { print nr, p }' $property_log)
	#	sed -i "${line_number}d" $property_log
	#	echo "$properties"
	read line_number properties <<< $(awk '
		/^'$id'/ { nr = NR; p = $0 }
		END { print nr, p }' $property_log)
	sed -i "${line_number}d" $property_log
	echo "$properties"
}

function apply_new_properties() {
	read {x,y}b_diff <<< $(xwininfo -id $id | awk '
	 	/xwininfo/ { id = $4 }
		/Absolute.*Y/ { ay = $NF }
		/Relative/ { if(/X/) xb = $NF; else yb = $NF }
		$0 ~ "geometry.*" ay "$" { print xb, yb }')

	#echo ${printable_properties[*]}, ${properties[*]}
	((xb_diff)) && ((properties[3] += xb_diff))
	((yb_diff)) && ((properties[4] += yb_diff))
	printable_properties="${properties[*]:1:4}"
	[[ $printable_properties ]] && wmctrl -ir $id -e 0,${printable_properties// /,}
}

function set_sign() {
	sign=${1:-+}
	[[ $sign == + ]] && opposite_sign=- || opposite_sign=+
}

function resize() {
	edge=$1

	(( properties[$index + 2] ${sign}= value ))
	[[ $edge =~ [lt] ]] && (( properties[$index] ${opposite_sign}= value ))

	[[ $adjacent && $edge =~ [rt] ]] && reverse_adjacent=-r
}

select_window() {
	~/.orw/scripts/select_window.sh
	second_window_id=$(printf '0x%x' $(xdotool getactivewindow))
	second_window_properties=( $(get_windows $second_window_id | cut -d ' ' -f 1-) )
}

select_window_using_mouse() {
	color=$(awk -Wposix -F '#' '/\.active.border/ { 
		r = sprintf("%d", "0x" substr($NF, 1, 2)) / 255
		g = sprintf("%d", "0x" substr($NF, 3, 2)) / 255
		b = sprintf("%d", "0x" substr($NF, 5, 2)) / 255
		print r "," g "," b }' $theme)

	read -a second_window_properties <<< $( \
		slop -nqb $((x_border / 2)) -c $color -f '%i %x %y %w %h' | awk '{
			$1 = sprintf("0x%.8x", $1)
			x = '$x_border'; y = '$y_border'
			$3 -= y - x / 2
			$2 -= x / 2
			print
		}')
}

set_orientation_properties() {
	direction=$1

	if [[ $direction == h ]]; then
		index=1
		dimension=width
		offset=$x_offset
		step=$font_width
		start=$display_x
		opposite_dimension=height
		opposite_start=$display_y
		border=${properties[index + 4]:-$default_x_border}
		bar_vertical_offset=0
	else
		index=2
		dimension=height
		offset=$y_offset
		step=$font_height
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

get_display_properties() {
	local index

	if [[ $1 == [hv] ]]; then
		[[ $1 == h ]] && index=1 || index=2
	else
		index=$1
	fi

	read display{,_{x,y}} width height original_{min,max}_point bar_{min,max} x y <<< \
		$(awk -F '[_ ]' '{ if(/^orientation/) {
			cd = 1
			bmin = 0
			d = '${display:-0}'
			i = '$index'; mi = i + 2
			wx = '${properties[1]}'
			wy = '${properties[2]}'

			if($NF ~ /^h/) {
				i = 4
				p = wx
			} else {
				i = 5
				p = wy
			}
		} {
			if($1 == "display") {
				if($3 == "xy") {
					cd = $2

					if((d && d == cd) || !d) {
						dx = $4
						dy = $5
						minp = $(mi + 1)
					}
				} else if($3 == "size") {
					if((d && d == cd) || !d) {
						dw = $4
						dh = $5
						maxp = minp + $(mi + 1)
					}

					max += $i

					s = ((d && p < max && (cd >= d)) || (!d && p < max))

					if (!s) {
						if(d && cd < d || !d) bmin += $4
						if(p > max) if(i == 4) wx -= $i
						else wy -= $i
					}
				} else if ($3 == "offset") {
					if (s) {
						print (d) ? d : cd, dx, dy, dw, dh, minp, maxp, bmin, bmin + dw, dx + wx, dy + wy
						exit
					}
				}
			}
		}
	}' $config)
}

get_bar_properties() {
	if [[ ! $bars_checked ]]; then
		while read -r bar_name position bar_x bar_y bar_width bar_height adjustable_width frame; do
			current_bar_height=$((bar_y + bar_height))
			((position)) && (( current_bar_height += frame ))

			if ((position)); then
				((current_bar_height > bar_top_offset)) && bar_top_offset=$current_bar_height
			else
				((current_bar_height > bar_bottom_offset)) && bar_bottom_offset=$current_bar_height
			fi

			if [[ $1 == add && $bar_name ]]; then
				if ((adjustable_width)); then
					read bar_width bar_height bar_x bar_y < ~/.config/orw/bar/geometries/$bar_name
				else
					((!position)) && bar_y=$((display_y + height - (bar_y + bar_height)))
					(( bar_x -= bar_min ))
				fi

				[[ $bar_offset ]] && bar_x=$display_x bar_width=$width

				bar_properties="$bar_name $bar_x $bar_y $bar_width $bar_height $frame"
				all_windows+=( "$bar_properties" )
				bars+=( "$bar_properties" )
			fi
		done <<< $(~/.orw/scripts/get_bar_info.sh $display)
	fi

	bars_checked=true
}

set_base_values() {
	[[ $2 ]] &&
		set_windows_properties $1 ||
		get_display_properties $1

	original_properties=( ${properties[*]} )

	set_orientation_properties $1

	properties[1]=$x
	properties[2]=$y

	update_properties

	if [[ $option == tile ]]; then
		original_properties[1]=$x
		original_properties[2]=$y
	fi

	[[ $option != tile ]] && min_point=$((original_min_point + offset))

	get_bar_properties add
	echo $bar_top_offset, $bar_bottom_offset
}

sort_windows() {
	list_all_windows | awk '
		{
			i = '$index' + 1
			d = (i == 2)
			sc = $i

			if($1 == "'$id'") {
				if("'$1'" ~ /[BRbr]/) sc += '${properties[index + 2]}'
			} else {
				if("'$1'" ~ /[LTlt]/) sc = $i + $(i + 2)
			}

			print sc, $0
		}' | sort $reverse -nk 1
}

add_offset() {
	[[ ! -f $offsets_file ]] && touch $offsets_file

	if [[ "$arguments" =~ -o ]]; then
		 eval $(awk '/^'$1'=/ {
				e = 1
				cv = gensub("[^0-9]*", "", 1)
				sub("[0-9]+", ("'${!1}'" ~ "[+-]") ? cv '${!1}' : '${!1}')
			} { o = o "\n" $0 }
				END {
					if(!e) o = o "\n'$1=${!1}'"
					print o | "xargs"
					print substr(o, 2)
				}' $offsets_file | { read -r o; { printf "%s\n" "$o" >&1; cat > $offsets_file; } })

		~/.orw/scripts/notify.sh -pr 22 "<b>${1/_/ }</b> changed to <b>${!1}</b>"
	fi
}

function calculate_size() {
	[[ $denominator -eq 1 ]] && window_margin=0 || window_margin=${margin:-$offset}

	[[ $dimension =~ [[:alpha:]]+ ]] && dimension=${!dimension}

	available_size=$((dimension - bar_vertical_offset - 2 * offset - (denominator - 1) * window_margin - denominator * border))
	window_size=$((available_size / denominator))

	[[ ${1:-$option} == move ]] && ((numerator--))

	size=$(((numerator * window_size) + (numerator - 1) * (window_margin + border)))

	if [[ ${1:-$option} == move ]]; then
		[[ $argument == v ]] && bar_offset=$bar_top_offset || bar_offset=0
		start_point=$((start + bar_offset + offset + size + border + window_margin))
	else
		if ((numerator == denominator)); then
			size=$available_size
			start_point=$min_point
		else
			start_point=$((min_point + size + border + window_margin))
		fi
	fi

	end_point=$((start_point + window_size))
}

get_max_value() {
	[[ ${1:-$argument} =~ [LR] ]] && set_orientation_properties h || set_orientation_properties v
	[[ ${1:-$argument} =~ [BR] ]] && reverse='-r' || reverse=''

	max=$(sort_windows ${1:-$argument} |
		awk '{
			if($2 == "'$id'") exit
			else {
				i = '$index' + 2
				si = '$start_index' + 2
				cws = '${properties[start_index]}'
				cwe = cws + '${properties[start_index + 2]}'
				ws = $si; we = ws + $(si + 2)
				#wm = $i; b = ($2 ~ /^0x/) ? '$border' : $7
				wm = $i; b = ($2 ~ /^0x/) ? $(i + 4) : $7

				if((ws >= cws && ws <= cwe) ||
					(we >= cws && we <= cwe) ||
					(ws <= cws && we >= cwe)) {
									max = ("'${1:-$argument}'" ~ /[BR]/) ? wm : wm + $(i + 2) + b
									print max
								}
						}
				}' | tail -1)
}

function resize_to_edge() {
	index=$1
	offset=$2

	[[ ${3:-$argument} =~ [LR] ]] && offset_orientation=x_offset || offset_orientation=y_offset
	((!max || (max == bar_top_offset || max == end - bar_bottom_offset))) && offset=${!offset_orientation} ||
		offset=${margin:-${!offset_orientation}}

	((index > 1)) && border=$y_border || border=$x_border

	if [[ ${3:-$argument} == [BR] ]]; then
		#echo ${properties[index + 2]} = ${max:-$end} - $offset - ${properties[index]} - border
		properties[$index + 2]=$((${max:-$end} - offset - ${properties[$index]} - border))
	else
		properties[$index + 2]=$((${properties[$index]} + ${properties[$index + 2]} - max - offset))
		properties[$index]=$((${max:-$start} + offset))
	fi
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
	list_all_windows | sort -nk $((opposite_index + 1)),$((opposite_index + 1)) -k $((index + 1)),$((index + 1)) |
		awk '
			function sort(a) {
				#removing/unseting variables
				delete cwp
				delete fdw
				ai = fdwi = pdwc = min = max = 0

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

					#if this is a first window, assign a min point
					if(!min) min = cws
					#if window end point is greater then max, assign new max
					if(cws + cwd > max) max = cws + cwd

					if(cwod == wod) {
						#if window opposite dimension is full (same as original), add window to fdw 
						fdw[++fdwi] = id " " cws " " cwd - cb " " cb
					} else {
						#add window to partial dimension windows
						pdw = pdw "," id ":" cws "-" cwd - cb "-" cb
						#calculate window surface
						cwsf = (cwd + s) * (cwod + os)
						csf += cwsf

						#if this is the last window in the row/column, increase total surface by multiplying its dimension with total opposite dimension 
						if(cwos + cwod == wos + wod) tsf += (cwd + s) * (wod + os)

						#if this is the last piece of the surface (last window), add all windows belonging to this surface as one full window
						if(csf == tsf) {
							fdw[++fdwi] = substr(pdw, 2)
							tsf = csf = 0
							pdw = ""
						}
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
				wc = '${#all_windows[*]}'
				ws = '${properties[index]}'
				b = '${properties[index + 4]}'
				ob = '${properties[opposite_index + 4]}'
				wd = '${properties[index + 2]}' + b
				wos = '${properties[opposite_index]}'
				wod = '${properties[opposite_index + 2]}' + ob

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
			}

			{
				#border assignemt
				cb = $(i + 5)
				cob = $(oi + 5)
				#cb = ($1 == "'$id'") ? b : $(i + 5)
				#cob = ($1 == "'$id'") ? ob : $(oi + 5)

				#current window properties assignment
				$(i + 3) += cb
				$(oi + 3) += cob

				cws = $(i + 1)
				cwd = $(i + 3)
				cwos = $(oi + 1)
				cwod = $(oi + 3)

				#separator assignment
				s = o
				os = oo

				if($1 == "'$id'" ||
					((cwos >= wos && cwos + cwod <= wos + wod &&
					(cws + cwd < ws || cws > ws + wd)) &&
					!($4 == nws && $5 == nws))) {
						if(f && $1 == "'$original_id'") next
						else if(cws < ws) bw[++bwi] = $0
						else if(cws > ws) aw[++awi] = $0
						else {
							if(!c) {
								if(r) aw[++awi] = $0
								else bw[++bwi] = $0
							}
						}
				}
			}

			# arguments:
			#	od - original dimension (sum of all window dimensions)
			#	wae - end point of the window array
			#	wane - new end point of window array
			#	pos - position (set only if window start after original window)
			function add_window(od, wae, wane, pos) {
				wr = (od + s - b) / (cwd + s)

				#print od + s - b, cwd + s, s
				#print wr, od, (nd + s) / wr - s, od, wr * (cwd + s)

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
				cwnd = sprintf("%.0f", (cws + cwd + cb == wae) ? wane - cns - cb : (nd + s - b) / wr - s)
				cwns = cns + cwnd + s

				# add original/new window start to array
				ns[cws + cwd + s] = cwns
				nsc++

				# add window to all winodws array
				aaw[++aawi] = "[" cwid "]=\"" cns " " cwnd "\""

				# if winodw starts after original window, set new minimal start
				if(!pos && cwns > mns) mns = cwns
			}

			# arguments:
			#	wa - window array
			#	wae - end point of the window array
			#	wane - new end point of window array
			#	od - original dimension (sum of all window dimensions)
			#	pos - position (set only if window start after original window)
			function align(wa, wae, wane, od, pos) {
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
						split(cwbp[1], cwbw, ",")

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
							add_window(od, wae, wane, pos)
						}
					} else {
						# parse window properties
						split(cwb, cwp)
						cwid = cwp[1]
						cws = cwp[2]
						cwd = cwp[3]
						cb = cwp[4]

						s = o + cb
						#system("~/.orw/scripts/notify.sh " cb)

						# adding window
						found = 0
						add_window(od, wae, wane, pos)
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
				if(max > min) asort(a, sa, "compare")
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
					cr = td / cd

					# if window is closing
					if(c) {
						# new window dimension:
						# new total dimension + original window dimension + padding - new padding
						nd = (td + wd + p - np) / cr
					} else {
						nwd = int((td - p) / (twc + 1))
						nd = (td - nwd) / cr
						cane = cas + td - nwd - p

						# set alignment ratio if it is enforced, otherwise devide it evenly
						nwdp = (ar) ? ar * twc : twc + 1
						# set new window dimension by deviding total dimension with alignment ratio
						nwd = int((td + np - (twc * s)) / nwdp)
						# calculate new dimension by applying ratio computed earlier
						nd = (td + np - p - nwd) / cr

						#print nwd, nd, td + np - p - nwd

						# if reverse is enabled (window should open before original window),
						# and there is no widnows before original window, offset all windows to start after new window (after its dimension + separator)
						if(pos && r && !bc) {
							# separator after new window:
							# if full is enabled, separator should have double value because 
							# full window is set to start a separator before first window,

							# if full is enabled, new window is set to start a separator before first window,
							# so this will neutralize it
							mns += nwd + s
						}
					}

					# setting new end point according to position regarding original window
					cane = (pos) ? aas + cd : cas + nd
					align(ca, cae, cane, cd, pos)
				}
			}

			END {
				# setting before windows array and its properties
				set_array(bw, nbw)
				bc = length(nbw)
				if(bc) { bas = min; bae = max; bad = max - min }

				# setting after windows array and its properties
				set_array(aw, naw)
				ac = length(naw)
				if(ac) { aas = min; aae = max; aad = max - min }

				#system("~/.orw/scripts/notify.sh '$border'")
				#s += b; os += ob

				#for(i in nbw) print nbw[i]
				#for(i in naw) print naw[i]
				#exit

				# total window dimension and total window count
				ba = (bc && ac)
				td = bad + aad
				twc = bc + ac

				set_ratio(nbw, bc, bas, bad, bae)

				if(!mns) mns = ws

				# if window is not closing
				if(!c) {
					# if there are windows before original window, set new window start after last window, otherwise set it at the beggining of current windows
					nws = (bc) ? mns : aas
					# if there are windows after original window, set new window dimension to already calculated size, otherwise set it to fill all the space until the end point
					nwd = ((ac) ? nwd : bas + td - nws) - b
					if(bc) {
						nw = "[new]=\"" nws " " nwd "\""
						# increment new minimum start by new window dimension and separator
						mns += nwd + s
					}
				}

				set_ratio(naw, ac, mns, aad, aae, "after")
				if(!c && !bc) nw = "[new]=\"" nws " " nwd "\""

				# format all aligned windows
				for(aawi in aaw) a = a " " aaw[aawi]
				print nw, a
			}'
}

set_alignment() {
	local id=$1

	#getting properties after alignment
	read new_start new_dimension <<< ${aligned_windows[$id]}

	#if this window has been changed
	if ((new_dimension)); then
		#load window properties into properties array
		[[ $id == new ]] || properties=( $id $window_properties )

		#setting new properties
		properties[index]=$new_start
		properties[index + 2]=$new_dimension

		read x y w h xb yb <<< ${properties[*]:1}

		#if windows should tile (two step operation)
		if [[ $tiling ]]; then
			#set window which should tile to fill "new" position of new alignment,
			#otherwise, update all_windows array with new properties after alignment, so the next iteration can be calculated with accurate values
			[[ $id == new ]] && id=$original_properties ||
				all_windows[window_index]="$id $x $y $w $h $xb $yb"
			#update properties of the window to which selected window should be tiled to
			[[ $id == $second_window_id ]] && second_window_properties=( $x $y $w $h $xb $yb )
		fi

		#populate all_aligned_windows array
		all_aligned_windows[$id]="$x $y $w $h $xb $yb"
	fi
}

align_windows() {
	local action=$1
	local window_index=0
	declare -A aligned_windows

	#if window should tile or close
	if [[ $action ]]; then
		#backup original alignment
		local original_alignment_direction=$alignment_direction
		#get initial window alignment for this particular window
		local alignment_direction=$(sed -n "s/^$id: //p" $alignment_file)

		#if aignment was not stored
		if [[ ! $alignment_direction ]]; then
			#if window should tile on current desktop
			if [[ $tiling && ! $new_desktop ]]; then
				#reverse the initial alignment
				[[ $original_alignment_direction == h ]] &&
					local alignment_direction=v ||
					local alignment_direction=h
			else
				#otherwise set alignment back to the original value
				local alignment_direction=$original_align_direction
			fi
		fi

		#if window is closing, remove it from stored alignments
		[[ $action == close ]] && sed -i "/^$id/d" $alignment_file
	fi

	set_alignment_properties $alignment_direction
	#~/.orw/scripts/notify.sh "borders: $border, $opposite_border"

	#if window is not closing
	if [[ $action != close ]]; then
		#if ratio should be used and if window should tile
		if [[ $use_ratio && ! $align_ratio ]]; then
			if [[ $tiling ]]; then
				#if this is the stage of removing window from the alignment
				if [[ $action == move ]]; then
					original_width=$((${properties[3]} + x_border))
					original_height=$((${properties[4]} + y_border))
				else
					if [[ $alignment_direction == v ]]; then
						get_bar_properties
						bar_offset=$((bar_top_offset + bar_bottom_offset))
						local window_dimension=$original_height
					else
						local window_dimension=$original_width
					fi

					#getting ratio
					local display_dimension=$((display_dimension - 2 * offset - bar_offset))
					align_ratio=$(echo "$display_dimension / $window_dimension" | bc -l)

					[[ $align_ratio =~ ^1.0+$ ]] && unset align_ratio
				fi
			else
				align_ratio=$(echo "$ratio / $part" | bc -l)
			fi
		fi
	fi

	#storing new window properties after alignment
	eval aligned_windows=( $(get_alignment $action) )

	#if new window should be inserted
	[[ $action ]] || set_alignment new

	#reversing stored alignment in case this is the only window
	local aligned_window_count=${#aligned_windows[*]}
	#this line ignores expected behaviour in case of moving windows
	([[ $action ]] && ((aligned_window_count == 1))) ||
		([[ ! $action ]] && ((aligned_window_count == 2))) &&
			awk -i inplace -F '[: ]' '\
				BEGIN {
					awc = '$aligned_window_count'
					p = gensub(/ /, "|", "g", "'"${!aligned_windows[*]}"'")
					#p = gensub(/ /, "|", 1, "'"${!aligned_windows[*]}"'")
				}
				$1 ~ "^(" p ")" {
					d = $NF
					if(awc == 1 || (awc == 2 && d != "'"$alignment_direction"'"))
						sub(d, (d == "h") ? "v" : "h")
				} { print }' $alignment_file

	#iterating through all windows
	while read window_id window_properties; do
		#if this is the stage of removing window from the alignment, remove selected window, otherwise, adjust alignment for the given window
		[[ $window_id == ${original_properties[0]} && $action == move ]] &&
			unset all_windows[window_index] && ((window_count--)) ||
			set_alignment $window_id

		(( window_index++ ))
	done <<< $(list_all_windows)
}

align() {
	# checking optional arguments
	[[ $optarg =~ m$ ]] && window_action=move
	[[ $optarg =~ c$ ]] && window_action=close
	[[ $optarg =~ ^[0-9.]+$ ]] && align_ratio=$optarg
	[[ $optarg && ! $window_action ]] && alignment_direction=${optarg:0:1}

	if [[ $mode == selection ]]; then
		select_window_using_mouse

		(( second_window_properties[0] -= display_x ))
		(( second_window_properties[1] -= display_y ))

		read x y w h xb yb <<< ${second_window_properties[*]}
		~/.orw/scripts/set_geometry.sh -c '\\\*' -x $x -y $y -w $w -h $h
	else
		#if there is any window/s, get its/their properties
		# set window properties (only in case there is any window opened)
		[[ $id == none ]] || set_windows_properties $display_orientation

		# if there are windows
		if ((window_count > 1)); then
			# if OPENED window should occupy whole dimension (widthe/height)
			if [[ $full && $window_action != close ]]; then
				set_orientation_properties $alignment_direction
				set_alignment_properties $alignment_direction

				# getting position (start, end, and width/height)
				read new_start new_opposite_start new_opposite_dimension <<< \
					$(list_all_windows | awk '
						BEGIN {
							i = '$index' + 1
							oi = '$start_index' + 1
							nws = '$new_window_size'
						}
						
						{
							# finding furthest window
							if(!($4 == nws && $5 == nws)) {
								os = $oi
								oe = $oi + $(oi + 2)
								e = $i + $(i + 2)

								if(!mos) mos = os
								if(os < mos) mos = os
								if(oe > moe) moe = oe
								if(e > me) me = e

								ms = ("'$reverse'") ? '$offset' : me + '$separator'
							}
						# set window start after furthest window end
						} END { print ms, mos, moe - mos }')

				#original_id=$(printf '0x%.8x' $(xdotool getactivewindow))
				original_id=$(printf '0x%x' $(xdotool getactivewindow))

				id=none
				properties[0]=$id
				properties[index]=$new_start
				properties[opposite_index]=$new_opposite_start
				# if window should be spawned before other windows (reverse), set its dimension to be negative of separtor value, because distance between windows should be equal to separator value, and window end is calculated by adding its dimension to its start, which will in this case be separator before first window's start
				[[ $reverse ]] && new_width=-$separator
				properties[index + 2]=${new_width:-0}
				properties[opposite_index + 2]=$new_opposite_dimension
			else
				set_orientation_properties $display_orientation

				if [[ $mode == auto && $window_action != close ]]; then
					#align_ratio=$(echo "$ratio / $part" | bc -l)

					# if mode is equal to auto, select opposite of larger dimension
					if [[ $tiling ]]; then
						alignment_direction=$(awk '$1 == "'${original_properties[0]}':" { print $NF == "h" ? "v" : "h" }' $alignment_file)
					else
						((${properties[3]} > ${properties[4]})) &&
							alignment_direction=h || alignment_direction=v
					fi
				elif [[ $mode == stack && $window_action != close ]]; then
					# if windows are already splited into main and stack, align it with stack windows 
					if ((window_count > 2)); then
						[[ $alignment_direction == h ]] &&
							alignment_direction=v align_index=3 ||
							alignment_direction=h align_index=2

						((index++))
						# find last (or first, in case reverse is enabled) stack window
						properties=( $(list_all_windows |
							sort -nk $index,$index -nk $align_index${reverse:1:1},$align_index | tail -1) )
						id=${properties[0]}
					fi
				fi
			fi

			# align windows according to corresponding action
			align_windows $window_action
			[[ $window_action == close ]] && wmctrl -ic $id &> /dev/null
		else
			# if there is no windows opened
			get_bar_properties
			read width height <<< $(awk '/^display_'${display:-1}'_size/ { print $2, $3 }' $config)

			id=$(xdotool getactivewindow)
			read {x,y}_border <<< $(xwininfo -id $id | sed -n 's/.*Relative.* //p' | xargs)

			# set window properties to occupy all space between offsets
			x=$x_offset
			y=$((y_offset + bar_top_offset))
			w=$((width - 2 * (x_offset + x_border)))
			h=$((height - (bar_top_offset + bar_bottom_offset) - 2 * y_offset - (x_border + y_border)))

			~/.orw/scripts/notify.sh "$x $y $w $h $alignment_direction $x_border $y_border^"

			if [[ $tiling ]]; then
				id=$original_properties
				properties=( $id $x $y $w $h )
				~/.orw/scripts/notify.sh "$x $y $w $h $alignment_direction"
				return
			else
				echo $x $y $w $h $alignment_direction
				exit
			fi
		fi
	fi

	[[ $original_properties ]] && properties=( ${original_properties[*]} )
}

get_alignment2() {
	list_all_windows | sort -nk $((opposite_index + 1)),$((opposite_index + 1)) -k $((index + 1)),$((index + 1)) |
		awk '
			function sort(a) {
				#removing/unseting variables
				delete cwp
				delete fdw
				ai = fdwi = pdwc = min = max = 0

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

					#if this is a first window, assign a min point
					if(!min) min = cws
					#if window end point is greater then max, assign new max
					if(cws + cwd > max) max = cws + cwd

					if(cwod == wod) {
						#if window opposite dimension is full (same as original), add window to fdw 
						fdw[++fdwi] = id " " cws " " cwd - cb " " cb
					} else {
						#add window to partial dimension windows
						pdw = pdw "," id ":" cws "-" cwd - cb "-" cb
						#calculate window surface
						cwsf = (cwd + s) * (cwod + os)
						csf += cwsf

						#if this is the last window in the row/column, increase total surface by multiplying its dimension with total opposite dimension 
						if(cwos + cwod == wos + wod) tsf += (cwd + s) * (wod + os)

						#if this is the last piece of the surface (last window), add all windows belonging to this surface as one full window
						if(csf == tsf) {
							fdw[++fdwi] = substr(pdw, 2)
							tsf = csf = 0
							pdw = ""
						}
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

				#separator assignment
				s = o
				os = oo

				if($1 == "'$id'" ||
					((cwos >= wos && cwos + cwod <= wos + wod &&
					(cws + cwd < ws || cws > ws + wd)) &&
					!($4 == nws && $5 == nws))) {
						if($1 == "'"$id"'") {
							if(!c) {
								if(r) aw[++awi] = $0
								else bw[++bwi] = $0
							}
						}
						else if(f && $1 == "'$original_id'") next
						else if(cws + cwd < ws) bw[++bwi] = $0
						else if(cws > ws + wd) aw[++awi] = $0

						#else {
						#	if(!c) {
						#		if(r) aw[++awi] = $0
						#		else bw[++bwi] = $0
						#	}
						#}
				}
			}

			# arguments:
			#	od - original dimension (sum of all window dimensions)
			#	wae - end point of the window array
			#	wane - new end point of window array
			#	pos - position (set only if window start after original window)
			function add_window(od, wae, wane, pos) {
				#system("~/.orw/scripts/notify.sh " cwd + s)
				wr = (od + s - b) / ((cwd + s) ? cwd + s : 1)

				#print od + s - b, cwd + s, s
				#print wr, od, (nd + s) / wr - s, od, wr * (cwd + s)

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
				else cwnd = sprintf("%.0f", (cws + cwd + cb == wae) ? wane - cns - cb : (nd + s - b) / wr - s)
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
			function align(wa, wae, wane, od, pos) {
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
						split(cwbp[1], cwbw, ",")

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
							add_window(od, wae, wane, pos)
						}
					} else {
						# parse window properties
						split(cwb, cwp)
						cwid = cwp[1]
						cws = cwp[2]
						cwd = cwp[3]
						cb = cwp[4]

						s = o + cb
						#system("~/.orw/scripts/notify.sh " cb)

						# adding window
						found = 0
						add_window(od, wae, wane, pos)
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
				#if(max > min) asort(a, sa, "compare")
				if(max > min || e) asort(a, sa, "compare")
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
					cr = td / cd

					# if window is closing
					if(c) {
						# new window dimension:
						# new total dimension + original window dimension + padding - new padding
						nd = (td + wd + p - np) / cr
					} else {
						nwd = int((td - p) / (twc + 1))
						nd = (td - nwd) / cr
						cane = cas + td - nwd - p

						# set alignment ratio if it is enforced, otherwise devide it evenly
						#nwdp = (ar) ? ar * twc : twc + 1
						nwdp = (ar) ? ar : twc + 1
						# set new window dimension by deviding total dimension with alignment ratio
						nwd = int((td + np - (twc * s)) / nwdp)
						# calculate new dimension by applying ratio computed earlier
						nd = (td + np - p - nwd) / cr

						#print nwd, nd, td + np - p - nwd

						# if reverse is enabled (window should open before original window),
						# and there is no widnows before original window, offset all windows to start after new window (after its dimension + separator)
						if(pos && r && !bc) {
							# separator after new window:
							# if full is enabled, separator should have double value because 
							# full window is set to start a separator before first window,

							# if full is enabled, new window is set to start a separator before first window,
							# so this will neutralize it
							mns += nwd + s
						}
					}

					# setting new end point according to position regarding original window
					cane = (pos) ? aas + cd : cas + nd
					align(ca, cae, cane, cd, pos)
				}
			}

			END {
				# setting before windows array and its properties
				set_array(bw, nbw)
				bc = length(nbw)
				if(bc) { bas = min; bae = max; bad = max - min }

				# setting after windows array and its properties
				set_array(aw, naw)
				ac = length(naw)
				if(ac) { aas = min; aae = max; aad = max - min }

				# total window dimension and total window count
				ba = (bc && ac)
				td = bad + aad
				twc = bc + ac
				if(e) twc--

				set_ratio(nbw, bc, bas, bad, bae)

				if(!mns) mns = ws

				# if window is not closing
				if(!c) {
					# if there are windows before original window, set new window start after last window, otherwise set it at the beggining of current windows
					nws = (bc) ? mns : aas
					# if there are windows after original window, set new window dimension to already calculated size, otherwise set it to fill all the space until the end point
					nwd = ((ac) ? nwd : bas + td - nws) - b
					if(bc) {
						#nw = "[new]=\"" nws " " nwd "\""
						nw = "['"$current_id"']=\"" nws " " nwd "\""
						# increment new minimum start by new window dimension and separator
						mns += nwd + s
					}
				}

				set_ratio(naw, ac, mns, aad, aae, "after")
				if(!c && !bc) nw = "['"$current_id"']=\"" nws " " nwd "\""

				# format all aligned windows
				for(aawi in aaw) a = a " " aaw[aawi]
				print nw, a
			}'
}

align_neighbours() {
	declare -A aligned_windows
	local remaining_windows
	local id=$id edge=$1 value=$sign$2
	local {old,new}_properties

	old_properties=( ${properties[*]} )
	new_properties=( ${properties[*]} )
	(( new_properties[$index + 2] += value ))

	set_alignment_properties $direction

	if [[ $edge =~ [lt] ]]; then
		(( new_properties[index] -= value ))

		for window_id in ${!all_windows[*]}; do
			cwp=( ${all_windows[window_id]} )
			window_start=${old_properties[index]}

			if [[ ${cwp[index]} -gt $window_start || ${cwp[0]} == $id ]]; then
				[[ ${cwp[0]} == $id ]] &&
					remaining_windows+=( "${new_properties[*]}" ) ||
					remaining_windows+=( "${cwp[*]}" )
				unset all_windows[window_id]
			fi
		done
	else
		window_end=$((${old_properties[index]} + ${old_properties[index + 2]}))

		for window_id in ${!all_windows[*]}; do
			cwp=( ${all_windows[window_id]} )

			if ((${cwp[index]} < window_end)); then
				remaining_windows+=( "${cwp[*]}" )
				unset all_windows[window_id]
			fi
		done

		properties[index]=$((${new_properties[index]} + ${new_properties[index + 2]}))
		((properties[index] += separator))
	fi

	org_new_properties=( ${new_properties[*]} )

	properties[index + 2]=-$value
	((properties[index + 2] -= separator))

	id=temp
	properties[0]=$id
	all_windows+=( "${properties[*]}" )
	eval aligned_windows=( $(get_alignment2 move) )

	if [[ $sign ]]; then
		read id new_properties <<< ${new_properties[*]::5}
		aligned_neighbours[$id]="$new_properties"
	else
		all_windows+=( "${new_properties[*]}" )
	fi

	for window in "${all_windows[@]}"; do
		if [[ ${window%% *} == 0x* ]]; then
			id=${window%% *}
			current_properties=( ${window% * *} )
			aligned_properties=( ${aligned_windows[$id]} )

			if ((${#aligned_properties[*]})); then
				current_properties[index]=${aligned_properties[0]}
				current_properties[index + 2]=${aligned_properties[1]}
			fi

			properties=$(tr ' ' ',' <<< ${current_properties[*]:1})
			wmctrl -ir $id -e 0,$properties
			aligned_neighbours[$id]="${current_properties[*]:1:4}"
		fi
	done

	properties=( ${org_new_properties[*]} )
	all_windows=( "${remaining_windows[@]}" )
}

align_adjacent() {
	declare -A changed_properties
	local continue=$1 base_index
	old_properties=( ${original_properties[*]} )

	for property_index in {1..4}; do
		new_property=${properties[property_index]}
		old_property=${old_properties[property_index]}

		if ((property_index > 2)); then
			(( new_property += ${properties[property_index - 2]} ))
			(( old_property += ${old_properties[property_index - 2]} ))
		fi

		if ((new_property != old_property)); then
			changed_properties[$property_index]=$((new_property - old_property))
		fi
	done

	((index == 1)) && orientation=h || orientation=v

	for changed_index in ${!changed_properties[*]}; do
		((changed_index > 2)) && ra=-r || dual=true
		if ((changed_index > 2)); then
			after_dimension_sign=${changed_properties[$changed_index]%%[0-9]*}
			[[ $after_dimension_sign ]] && after_sign=+ || after_sign=-
		else
			before_sign=${changed_properties[$changed_index]%%[0-9]*}
		fi

	done

	value=${value#-}

	set_sign $sign

	set_main_side() {
		(( properties[index + 2] ${2}= ${1:-$value} ))
		[[ $3 ]] && (( properties[index] ${3}= ${1:-$value} ))
	}

	set_opposite_side() {
		(( properties[index + 2] ${2}= ${1:-$value} ))
		[[ $3 ]] && (( properties[index] ${3}= ${1:-$value} ))
	}

	[[ $ra ]] &&
		main_function=set_main_side opposite_function=set_opposite_side ||
		main_function=set_opposite_side opposite_function=set_main_side

	((window_count)) || set_base_values $orientation windows

	get_adjacent() {
		local reverse=$2
		local properties=( $1 )

		sort_windows | sort -n $reverse | awk '
			BEGIN {
				r = "'$reverse'"
				i = '$index' + 2
				si = '$start_index' + 2
				cb =  '${properties[index + 4]}'
				o = '${margin:-$offset}'

				id = "'${properties[0]}'"
				cwsp = '${properties[index]}'
				cwep = '${properties[index]}' + '${properties[index + 2]}'
				cws = '${properties[start_index]}'
				cwe = '${properties[start_index]}' + '${properties[start_index + 2]}'
			} {
				if($2 ~ "0x" && $2 != "'$original_id'") {
					if($2 == id) {
						if('${#changed_properties[*]}' == 1) exit; else next
					} else {
						ws = $si
						b = $(i + 4)
						s = o + $(i + 4)
						we = ws + $(si + 2)
						cp = (r) ? $i : $i + $(i + 2)

						if(((cwep + o + cb == $i) || (cwsp - s == $i + $(i + 2))) &&
							((ws >= cws && ws <= cwe) ||
							(we >= cws && we <= cwe) ||
							(ws <= cws && we >= cwe))) {
								d = ""
								os = '${old_properties[index]}'
								oe = '${old_properties[index]}' + '${old_properties[index + 2]}'

								if(cwep + cb + o == $i) {
									d = "true"
									v = (cwep + o + cb == $i) ? $i : cwsp
								} else v = cwsp

								if(cwep + cb + o == $i) {
									d = "true"
									p = ($i == os) ? "before" : "after"
								} else {
									p = ($i + $(i + 2) + b == oe + '${old_properties[index + 4]}') ? "after" : "before"
								}

								cv = (p == "before") ? '${changed_properties[$index]:-0}' : '${changed_properties[$((index + 2))]:-0}'
								print $0, cv, d
							}
					}
				}
			}'
	}

	add_adjacent_window() {
		local value=$2
		properties=( $1 )
		id=${properties[0]}
		original_properties=( ${properties[*]} )

		if [[ $3 ]]; then
			(( properties[index] += value ))
			[[ ${value%%[0-9]*} ]] && value=${value#-} || value=-$value
		fi

		(( properties[index + 2] += value ))

		adjacent_windows+=( "${properties[*]}" )
	}

	find_neighbour() {
		while read -r c id x y w h xb yb v d; do
			if [[ $c ]]; then
				add_adjacent_window "$id $x $y $w $h $xb $yb" $v $d

				[[ $2 ]] && ra='' || ra=-r
				original_id=${1%% *}
				find_neighbour "$id $x $y $w $h $xb $yb" $ra
			fi
		done <<< $(get_adjacent "$1" $2)
	}

	[[ $sign == - ]] &&
		adjacent_windows=( "${properties[*]}" ) ||
			new_original_properties=( "${properties[*]}" )
	find_neighbour "${old_properties[*]}" $ra
	[[ $new_original_properties ]] && adjacent_windows+=( "${new_original_properties[*]}" )

	for window in "${adjacent_windows[@]}"; do
		read id x y w h xb yb <<< "$window"
		wmctrl -ir $id -e 0,$x,$y,$w,$h
	done
}

while ((argument_index <= $#)); do
	argument=${!argument_index#-}
	((argument_index++))

	if [[ $argument =~ $options ]]; then
		[[ $option ]] && previous_option=$option
		option=$argument

		if [[ $option == tile ]]; then
			arguments=${@:argument_index}
			orientations="${arguments%%[-mr]*}"
			((argument_index += (${#orientations} + 1) / 2))

			set_windows_properties $display_orientation

			if [[ ! $orientations ]]; then
				window_x=$(wmctrl -lG | awk '$1 == "'$id'" { print $3 }')
				width=$(awk '/^display_'$display'_size/ { print $2; exit }' $config)

				orientations=$(list_all_windows | sort -nk 2,4 -uk 2 | \
					awk '
						BEGIN {
							xo = '$x_offset'
							xb = '$x_border'
							x = '$display_x' + xo
							m = '${margin:-$x_offset}'
						}

						$1 ~ /^0x/ && $1 != "'$id'" {
							if($2 >= x) {
								x = $2 + $4 + xb + m
								w += $4; c++
							}
						} END {
							mw = '$width' - ((2 * xo) + (c * xb) + (c - 1) * m)
							if(mw - 1 > w && mw > w) print "h v"; else print "v h"
						}')
			fi

			tile() {
				local window_count

				max_point=$original_max_point
				min_point=$((original_min_point + offset))

				while read wid w_min w_max w_border; do
					if [[ $id != $wid ]]; then
						[[ ! $wid =~ ^0x ]] && distance=$offset ||
							distance=$((${margin:-$offset} + w_border))

						if ((min_point == offset)); then
							if [[ $wid =~ ^0x ]]; then
								if ((w_min == min_point)); then
									min_point=$((w_max + distance))
									((window_count++))
								else
									max_point=$w_min && break
								fi
							else
								if ((!window_count)); then
									min_point=$((w_max + distance))
								else
									max_point=$w_min
									break
								fi
							fi
						else
							if ((w_min > min_point)); then
								if [[ ! $wid =~ ^0x && ! $window_count ]]; then
									min_point=$((w_max + distance))
								else 
									max_point=$w_min
									break
								fi
							else
								((w_max + distance > min_point)) && min_point=$((w_max + distance))
							fi
						fi
					else
						((window_count++))
					fi
				done <<< $(list_all_windows | awk '
						BEGIN {
							si = '$start_index' + 1
							cws = '${properties[start_index]}'
							cwe = cws + '${properties[start_index + 2]}'
						} {
							ws = $si; we = ws + $(si + 2)
							if ((ws >= cws && ws <= cwe) ||
								(we >= cws && we <= cwe) ||
								(ws <= cws && we >= cwe)) print $0
						}' | sort -nk $((index + 1)),$((index + 1)) -nk $((start_index + 1)) | awk '
							function assign(w_index) {
								b = ($1 ~ "0x") ? $(pi + 4) : $NF
								i = (w_index) ? w_index : (l) ? l : 1
								mix_a[i] = $1 " " $pi " " $pi + $(pi + 2) + (($1 ~ "0x") ? 0 : b) " " b
							}

							BEGIN { pi = '$index' + 1 }
							{
								if(NR == 1) {
									assign()
								} else {
									l = length(mix_a)
									split(mix_a[l], mix)

									if($pi == mix[2]) {
										if($pi + $(pi + 2) > mix[3]) assign()
									} else {
										assign(l + 1)
									}
								}
							}
							END { for (w in mix_a) { print mix_a[w] } }')

				if ((${properties[index]} != min_point ||
					${properties[index]} + ${properties[index + 2]} != max_point)); then
					((max_point < original_max_point)) && [[ $wid =~ ^0x ]] && 
						local last_offset=$margin

					if [[ $orientation == h ]]; then
						win_x=$min_point
						win_y=${original_properties[2]}
						win_width=$((max_point - min_point - ${last_offset:-$offset} - border))
						win_height=${original_properties[4]}
					else
						win_x=${original_properties[1]}
						win_y=$min_point
						win_width=${original_properties[3]}
						win_height=$((max_point - min_point - ${last_offset:-$offset} - border))
					fi

					properties=( $id $win_x $win_y $win_width $win_height $x_border $y_border )
				else
					properties=( ${original_properties[*]} )
				fi
			}

			for orientation in $orientations; do
				set_base_values $orientation windows
				tile
			done
		else
			if [[ ! $previous_option =~ (resize|move) ]]; then
				[[ $(sed -n '/ (move|resize).*-[trbl]/p' <<< "$arguments") && ($mode == floating || $current_desktop -ne 1) ]] || with_windows=windows
				set_base_values $display_orientation $with_windows
			fi
		fi
	else
		optarg=${!argument_index}
		[[ $argument =~ ^[SMCATRBLHDItrblhvjxymoiPdsrcp]$ &&
			! $optarg =~ ^(-[A-Za-z]|$options)$ ]] && ((argument_index++))

		case $argument in
			C) select_window_using_mouse;;
			A)
				((${#all_aligned_windows[*]})) || declare -A all_aligned_windows
				[[ ${!argument_index} =~ ^[1-9.]+$ ]] &&
					align_ratio=${!argument_index} && shift
				align;;
			[TRBLHD])
				if [[ ! $option ]]; then
					if [[ $argument == R ]]; then
						set_windows_properties $display_orientation

						while read -r id properties; do
							#printable_properties=$(backtrace_properties)
							properties=( $(backtrace_properties) )
							apply_new_properties
						done <<< $(list_all_windows)
						exit
					else
						[[ $arguments =~ -t ]] &&
							new_desktop=$optarg || current_desktop=$optarg

						if [[ ! $properties ]]; then
							[[ $id ]] || id=$(get_windows | awk 'NR == 1 { print $1 }')
							set_windows_properties
						fi
					fi
				else
					[[ $argument =~ [LR] ]] && set_orientation_properties h || set_orientation_properties v
					[[ $argument =~ [BR] ]] && reverse='-r' || reverse=''

					# ADDED DIMENSION TO SONRTING CRITERIA
					# Peace of code until the first sort command formats properties so it could be appropriatelly
					# compared with current window properties, by sorting all windows before/after current one,
					# depending on choosen direction.
					# ##NOTE! In case of D/R, current window sorting criteria(property which is compared with other windows)
					# is incremented by height/width, respectively.
					# After first sort we have only windows before/arter current window.
					# We are setting index, depending on direction, and start index, for opposite orientation.
					# Then we set all current window properties, and properties of window we are currently looking at,
					# as well as their min and max points, so we can eliminate windows from another screen.
					# After that condition, we are checking if window is blocking current window opposite orientation,
					# so we can move/resize it toward that window.
					max=$(sort_windows $argument | \
						awk '{
								if($2 == "'$id'") exit
								else {
									i = '$index' + 2
									si = '$start_index' + 2
									cws = '${properties[start_index]}'
									cwe = cws + '${properties[start_index + 2]}'
									ws = $si; we = ws + $(si + 2)
									#wm = $i; b = ($2 ~ /^0x/) ? '$border' : $7
									wm = $i; b = ($2 ~ /^0x/) ? $(i + 4) : $7

									if((ws >= cws && ws <= cwe) ||
										(we >= cws && we <= cwe) ||
										(ws <= cws && we >= cwe)) {
											max = ("'$argument'" ~ /[BR]/) ? wm : wm + $(i + 2) + b
											print max
										}
									}
								}' | tail -1)

					[[ $argument =~ [LR] ]] && offset_orientation=x_offset || offset_orientation=y_offset
					((!max || (max == bar_top_offset || max == end - bar_bottom_offset))) && offset=${!offset_orientation} ||
						offset=${margin:-${!offset_orientation}}

					case $argument in
						L) [[ $option == resize ]] && resize_to_edge 1 $offset || 
							properties[1]=$((${max:-$start} + offset));;
						T) [[ $option == resize ]] && resize_to_edge 2 $offset || 
							properties[2]=$((${max:-$start} + offset));;
						R) [[ $option == resize ]] && resize_to_edge 1 $offset ||
							properties[1]=$((${max:-$end} - offset - ${properties[3]} - x_border));;
						B)
							[[ $option == resize ]] && resize_to_edge 2 $offset ||
							properties[2]=$((${max:-$end} - offset - ${properties[4]} - y_border));;
						*)
							[[ ${!argument_index} =~ ^[1-9] ]] && ratio=${!argument_index} && shift

							resize_by_ratio() {
								local argument=$1
								local orientation=$2
								local ratio=$3

								[[ $orientation =~ r$ ]] && orientation=${orientation:0:1} reverse=true

								if [[ ${orientation:0:1} == a ]]; then
									((${properties[3]} > ${properties[4]})) && orientation=h || orientation=v
									((ratio)) || ratio=$(awk '/^(part|ratio)/ { if(!p) p = $NF; else { print p "/" $NF; exit } }' $config)

									auto_tile=true
									argument=H
								fi

								set_orientation_properties $orientation

								[[ ${ratio:=2} =~ / ]] && part=${ratio%/*} ratio=${ratio#*/}

								[[ $argument == D ]] && op1=* op2=+ || op1=/ op2=-
								[[ $orientation == h ]] && direction=x || direction=y

								if ((!separator)); then
									border=${direction}_border
									offset=${direction}_offset
									separator=$(((${!border} + ${margin:-${!offset}})))
								fi

								original_start=${properties[index]}
								original_property=${properties[index + 2]}

								if [[ $argument == H || $part ]]; then
									portion=$((original_property - (ratio - 1) * separator))
									(( portion /= ratio ))

									if [[ $part ]]; then
										(( portion *= part ))
										(( portion += (part - 1) * separator ))
									fi

									if [[ $argument == H ]]; then
										properties[index + 2]=$portion
										[[ $reverse == true ]] && (( properties[index] += original_property - portion ))
									else
										(( properties[index + 2] += portion + separator ))
										[[ $reverse == true ]] && (( properties[index] -= portion + separator ))
									fi
								else
									portion=$(((original_property + separator) * (ratio - 1)))
									(( properties[index + 2] += portion ))
									[[ $reverse == true ]] && (( properties[index] -= portion ))
								fi

								read -a wm_properties <<< $(awk '{
									r = "'$reverse'"
									s = '$separator'
									o = "'$display_orientation'"

									p = $('$index' + 3) + s
									$('$index' + 3) = '$original_property' - p
									$('$index' + 1) = (r == "true") ? '$original_start' : $('$index' + 1) + p
									print gensub(/[^ ]* /, "", 1)
								}' <<< "${properties[*]}")
							}

							resize_by_ratio $argument $optarg $ratio
					esac

					update_properties
					unset max
				fi;;
			I)
				set_base_values $display_orientation windows

				x_start=$((display_x + x_offset))
				x_end=$((display_x + width - x_offset))
				y_start=$((display_y + y_offset + bar_top_offset))
				y_end=$((display_y + height - (y_offset + bar_bottom_offset)))

				x_step=$(((width - 2 * x_offset) / 16))
				y_step=$(((height - (bar_top_offset + bar_bottom_offset) - 2 * y_offset) / 9))

				read x y w h xb yb <<< ${properties[*]:1}

				source ~/.orw/scripts/windowctl_by_input.sh windowctl_osd source

				new_properties=( $id $x $y $w $h $xb $yb )
				properties=( ${original_properties[*]} )

				##ignore aligning adjacent windows if window was moved
				if [[ $mode != floating && ! $moved ]]; then
					if [[ $horizontal ]]; then
						set_orientation_properties h
						properties[1]=$x properties[3]=$w
						old_original_properties=( ${properties[*]} )

						update_properties
						align_adjacent con

						original_properties=( ${old_original_properties[*]} )
					fi

					properties=( ${new_properties[*]} )

					[[ $vertical ]] &&
						set_orientation_properties v &&
						update_properties && align_adjacent
					exit

					properties=( ${new_properties[*]} )
					update_properties
					align_adjacent
				fi

				properties=( ${new_properties[*]} )
				update_properties;;
			[hv])
				set_orientation_properties $argument

				if [[ $optarg =~ / ]]; then
					numerator=${optarg%/*}
					denominator=${optarg#*/}
					calculate_size
				fi

				if [[ $option == move ]]; then
					[[ $edge =~ [br] ]] && properties[index]=$((end_point - properties[index + 2])) ||
						properties[index]=${start_point:-$optarg}
				else
					if [[ $edge ]]; then
						set_sign +
						calculate_size move

						[[ $edge =~ [lt] ]] && value=$((properties[index] - start_point)) ||
							value=$((end_point - (properties[index] + properties[index + 2])))

						resize $edge $value
					else
						properties[index + 2]=${size:-$optarg}
					fi
				fi

				update_properties;;
			c)
				orientation=$optarg

				set_base_values $display_orientation

				for orientation in ${orientation:-h v}; do
					if [[ $orientation == h ]]; then
						properties[1]=$((display_x + (width - (${properties[3]} + x_border)) / 2))
					else
						y=$((display_y + bar_top_offset))
						bar_vertical_offset=$((bar_top_offset + bar_bottom_offset))
						properties[2]=$((y + ((height - bar_vertical_offset) - (${properties[4]} + y_border)) / 2))
					fi
				done

				update_properties;;
			i) id=$optarg;;
			P)
				closing_properties=true
				properties=( $id $optarg )
				x_border=${properties[5]}
				y_border=${properties[6]}
				all_windows=( "${properties[*]}" );;
			n)
				name="$optarg"
				id=$(wmctrl -lG | awk '$NF ~ "'$name'" { print $1 }')

				if [[ $id ]]; then
					id=$id
					properties=( $(get_windows $id) )
				else
					get_bar_properties add
					properties=( $(list_all_windows | grep "$name") )
				fi;;
			D) current_desktop=$optarg;;
			d) display=$optarg;;
			[trbl])
				if [[ ! $option ]]; then
					case $argument in
						b) bar_offset=true;;
						r)
							properties=( $id $(backtrace_properties) )
							update_properties
							;;
						t)
							tiling=true

							original_properties=( ${properties[*]} )

							set_windows_properties $display_orientation
							set_orientation_properties $display_orientation

							# assigning optional alignment argument
							[[ $optarg == [hv] ]] && alignment_direction=$optarg

							if [[ $mode != floating ]]; then
								declare -A all_aligned_windows

								# if window to which selected window should be tiled to is on a different workspace
								if [[ $new_desktop ]]; then
									# remove original window from the current workspace, and align the rest of the windows
									align_windows move

									# unset windows (ones from the current workspace) and set window properties on the new workspace
									unset all_windows window_count
									wmctrl -s $new_desktop
									set_windows_properties $display_orientation $new_desktop
								fi

								# check if new workspace is empty
								if ((window_count)); then
									if [[ ! $full && ! $second_window_properties ]]; then
										# let user select window to which should selected window tile to
										select_window

										# if selected window is on the same workspace,
										# remove original window from the workspace, and align the rest of the windows
										[[ $new_desktop ]] || align_windows move

										# set id and properties
										id=$second_window_id
										properties=( $second_window_id ${second_window_properties[*]} )
									fi
								else
									id=none
								fi

								for aligned_window_id in ${!all_aligned_windows[*]}; do
									read aligned_window_width aligned_window_height current_x_border current_y_border <<< \
										${all_aligned_windows[$aligned_window_id]#* * }

									if ((index == 1)); then
										current_border=$current_x_border
										(( aligned_dimension += aligned_window_width ))
									else
										current_border=$current_y_border
										(( aligned_dimension += aligned_window_height ))
									fi
								done

								(( aligned_dimension -= current_border + ${margin:-$offset} ))
								moved_window_dimension=${original_properties[index + 2]}
								align_ratio=$(echo "$aligned_dimension / $moved_window_dimension" | bc -l)

								echo $alignment_direction, ${properties[*]}
								align
							fi
					esac
				else
					value=${optarg#*[-+]}
					set_sign ${optarg%%[0-9]*}

					[[ $argument =~ [lr] ]] && set_orientation_properties h || set_orientation_properties v

					if [[ $option == move ]]; then
						property=${properties[index]}
						dimension=${properties[index + 2]}

						[[ $argument =~ [br] ]] && direction=+ || direction=-

						((property $direction value < start + offset && display_count > 1)) && 
							properties[index + index_offset]=$((start - offset - dimension - border)) ||
							(( properties[index + index_offset] $direction= value ))

						((property $direction value > end - offset - dimension - border && display_count > 1)) &&
							properties[index + index_offset]=$((end + offset))
					else
						declare -A aligned_neighbours
						align_neighbours $argument $value
					fi

					update_properties

					[[ $mode != floating && $current_desktop -eq 1 ]] && align_adjacent

				fi;;
			g)
				set_windows_properties $display_orientation
				set_orientation_properties $display_orientation
				get_bar_properties

				while read -r window_properties; do
						grid_windows+=( "$window_properties" )
				done <<< $(list_all_windows | sort -nk 3)

				window_count=${#grid_windows[*]}
				max_window_count=$window_count

				if((window_count == 1)); then
					rows=1
					columns=1
				elif((window_count % 3 == 0)); then
					columns=3
					rows=$((window_count / 3))
				elif((window_count < 5)); then
					rows=$((window_count / 2))
					columns=$((window_count / rows))
				else
					max_window_count=$window_count

					while ((max_window_count % 3 > 0)); do
						((max_window_count++))
					done

					rows=3
					middle_row=$(((rows / 2) + 1))

					columns=$((max_window_count / rows))
					middle_row_columns=$((window_count % columns))
				fi

				calculate() {
					[[ $1 == width ]] && set_orientation_properties h || set_orientation_properties v

					calculate_size

					[[ $option == resize ]] && echo $size || echo $start_point
				}

				numerator=1

				option=resize

				denominator=$columns
				window_width=$(calculate width)

				denominator=$rows
				window_height=$(calculate height)

				option=move

				denominator=$((columns * 2))
				numerator=$((denominator / (middle_row_columns + 1)))

				middle_start=$(calculate width)

				for row in $(seq 0 $((rows - 1))); do
					window_y=$((display_y + bar_top_offset + y_offset + row * (window_height + y_border + ${margin:-$y_offset})))

					if ((row + 1 == middle_row)); then
						row_columns=$middle_row_columns
						x_start=$middle_start
					else
						row_columns=$columns
						x_start=$x_offset
					fi

					for column in $(seq 0 $((row_columns - 1))); do
						id=${grid_windows[window_index]%% *}

						window_x=$((display_x + x_start + column * (window_width + x_border + ${margin:-$x_offset})))

						printable_properties="$window_x $window_y $window_width $window_height"
						apply_new_properties

						((window_index++))
					done
				done

				exit;;
			M)
				set_windows_properties $display_orientation
				set_orientation_properties $display_orientation

				optind=${!argument_index}

				select_window

				get_bar_properties add

				if [[ $second_window_properties ]]; then
					second_window_properties=( ${second_window_properties[*]:1} )
					optind=$optarg
				else
					case $optarg in
						s) select_window;;
						[trbl]) select_window;;
						*)
							if [[ $optarg =~ ^0x ]]; then
								mirror_window_id=$optarg
							else
								list_bars() {
									for bar in "${bars[@]}"; do
										echo $bar
									done
								}

								mirror_window_id=$((wmctrl -l && list_bars) |
									awk '{
										wid = (/^0x/) ? $NF : $1
										if(wid == "'$optarg'") {
											sub("^0x0*", "0x")
											print $1
											exit
										}
									}')
							fi

							second_window_properties=( $(list_all_windows |
								awk '$1 == "'$mirror_window_id'" {
									if(NF < 7) { $4 -= $6; $5 -= $7 }
									gsub("(" $1 "|" $6 "$)", "")
									print }') )
					esac
				fi

				if [[ $optind && $optind =~ ^[xseywh,+-/*0-9]+$ ]]; then
					for specific_mirror_property in ${optind//,/ }; do 
						unset operation operand additional_{operation,operand} mirror_value

						case $specific_mirror_property in
							x*) second_window_property_index=0;;
							y*) second_window_property_index=1;;
							w*) second_window_property_index=2;;
							h*) second_window_property_index=3;;
						esac

						if [[ ${specific_mirror_property:1:1} =~ [se] ]]; then
							mirror_border=${second_window_properties[second_window_property_index + 4]}

							if [[ $specific_mirror_property =~ ee ]]; then
								mirror_value=$((second_window_properties[second_window_property_index] + (${second_window_properties[second_window_property_index + 2]} - ${properties[second_window_property_index + 3]})))
							else
								#[[ ${specific_mirror_property:1:1} == s ]] &&
								#	mirror_value=$((second_window_properties[second_window_property_index] - (${properties[second_window_property_index + 3]} + ${!mirror_border:-0}))) ||
								#	mirror_value=$((second_window_properties[second_window_property_index] + (${second_window_properties[second_window_property_index + 2]} + ${!mirror_border:-0})))
								[[ ${specific_mirror_property:1:1} == s ]] &&
									mirror_value=$((second_window_properties[second_window_property_index] - (${properties[second_window_property_index + 3]} + ${properties[second_window_property_index + 5]} + ${mirror_border:-0}))) ||
									mirror_value=$((second_window_properties[second_window_property_index] + (${second_window_properties[second_window_property_index + 2]} + ${properties[second_window_property_index + 5]} + ${mirror_border:-0})))
							fi
						fi

						if [[ $specific_mirror_property =~ [+-/*] ]]; then
							read operation operand additional_operation additional_operand<<< \
								$(sed 's/\w*\(.\)\([^+-]*\)\(.\)\?\(.*\)/\1 \2 \3 \4/' <<< $specific_mirror_property)
							echo ${second_window_properties[*]}
							((operand)) &&
								mirror_value=$((${mirror_value:-${second_window_properties[second_window_property_index]}} $operation operand))
							((additional_operand)) &&
								mirror_value=$((${mirror_value:-${second_window_properties[second_window_property_index]}} $additional_operation additional_operand))

							if [[ $specific_mirror_property =~ [+-]$ ]]; then
								((properties[second_window_property_index + 1] ${specific_mirror_property: -1}= ${mirror_value:-${second_window_properties[second_window_property_index]}}))
								continue
							fi
						fi

						properties[second_window_property_index + 1]=${mirror_value:-${second_window_properties[second_window_property_index]}}
					done

					shift
				elif ((${#second_window_properties[*]})); then
					index_property=${properties[index]}

					properties=( $id )
					properties+=( ${second_window_properties[*]:0:index - 1} )
					properties+=( $index_property )
					properties+=( "${second_window_properties[*]:index}" )
				else
					echo "Mirror window wasn't found in specified direction, please try another direction.."
				fi

				update_properties;;
			x)
				x_offset=$optarg
				add_offset x_offset;;
			y)
				y_offset=$optarg
				add_offset y_offset;;
			m)
				margin=$optarg
				add_offset margin;;
			o) [[ -f $offsets_file ]] && eval $(cat $offsets_file | xargs);;
			e) edge=$optarg;;
			[Ss])
				if [[ $option == move ]]; then
					[[ $optarg =~ [br] ]] && reverse=-r || start_reverse=r
					set_windows_properties $display_orientation
					set_orientation_properties $display_orientation

					[[ $optarg =~ [lr] ]] && index=1 start_index=2 || index=2 start_index=1

					swap_window_properties=( $(sort_windows $optarg | sort $reverse -nk 1,1 | \
						awk '{ si = '$start_index'; sp = $(si + 2); csp = '${properties[start_index]}'; \
						print (csp > sp) ? csp - sp : sp - csp, $0 }' | sort $reverse -nk 2,2 -nk 1,1$start_reverse | \
						awk '{ if($3 == "'$id'") { print p; exit } else { gsub(/.*0x/, "0x", $0); p = $0 } }') )

					original_properties=( ${properties[*]} )
					printable_properties="${swap_window_properties[*]:1}"

					apply_new_properties
					id=${swap_window_properties[0]}
					printable_properties="${original_properties[*]:1}"

					apply_new_properties
					exit
				else
					set_windows_properties $display_orientation

					original_properties=( ${properties[*]} )

					if [[ $argument == S ]]; then
						while read -r id printable_properties; do
							save_properties
						done <<< $(list_all_windows)
					else
						generate_printable_properties "${properties[*]}"
						save_properties
					fi

					properties=( ${original_properties[*]} )
					id=$properties
				fi;;
			p)
				[[ $id ]] &&
					xwininfo -id $id | parse_properties ||
					xwininfo -name $name | parse_properties

				[[ $display_orientation == h ]] && index=1 || index=2
				get_display_properties $index

				if ((${#properties[*]} > 5)); then
					awk '{
						if(NF > 5 && $3 < 0) $3 += '$display_y' + '$height'
						print
					}' <<< ${properties[*]}
				else
					if [[ $second_window_properties ]]; then
						[[ ! $properties ]] && properties=( ${second_window_properties[*]} )

						properties=( ${properties[*]:1} )

						(( properties[0] -= display_x ))
						(( properties[1] -= display_y ))
					fi

					[[ $properties ]] || properties=( $(get_windows ${id:-$name}) )
					echo "$x_border $y_border ${properties[*]:1}"
				fi

				exit;;
			o) overwrite=true;;
			a) align_adjacent;;
			?) continue;;
		esac
	fi
done

if ((${#aligned_neighbours[*]})); then
	for window_id in ${!aligned_neighbours[*]}; do
		wmctrl -ir $window_id -e 0,${aligned_neighbours[$window_id]// /,}
	done
	exit
fi

generate_printable_properties "${properties[*]}"
apply_new_properties

# iterate through all windows which should be aligned, and apply new properties
if ((${#all_aligned_windows[*]})); then
	for window_id in ${!all_aligned_windows[*]}; do
		read x y w h xb yb <<< "${all_aligned_windows[$window_id]}"

		# adjust original window's alignment direction
		[[ $window_id == $original_properties ]] &&
			sed -i "/^$window_id/ s/.$/$alignment_direction/" $alignment_file
		# apply new properties for opened windows and print properties to be set for the new window
		[[ $window_id =~ ^0x ]] && wmctrl -ir $window_id -e 0,$x,$y,$w,$h ||
			echo $x $y $w $h $alignment_direction
	done

	# change workspace if window should tile to window on the different workspace, and focus it
	[[ $new_desktop ]] && wmctrl -ir $original_properties -t $new_desktop
	[[ $tiling ]] && wmctrl -ia $original_properties
fi
