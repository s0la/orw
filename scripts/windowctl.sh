#!/bin/bash

theme=~/.orw/themes/theme/openbox-3/themerc
blacklist="Keyboard Status Monitor,DROPDOWN"

set_window_id() {
	id=$1

	#client_width=$(awk '/client.*width/ { print $NF }' $theme)
	#read x_border y_border <<< $([[ $id =~ ^0x ]] && xwininfo -id $id | awk '\
	#	/Relative/ { if(/X/) x = $NF; else y = $NF + x } END { print 2 * x, y }')
	#read x_border y_border <<< $([[ $id =~ ^0x ]] && xwininfo -id $id | awk '/Relative/ { print $NF * 2 }' | xargs)
		#/Relative/ { if(/X/) x = $NF; else y = $NF + x } END { print 2 * x, y }')
		#/Relative/ { if(/X/) x = $NF; else y = $NF + x - '$client_width' } END { print 2 * x, y }')
}

function get_windows() {
	#[[ $1 ]] || local desktop=$current_desktop
	if [[ $1 =~ ^0x ]]; then
		local current_id=$1
	else
		[[ $1 ]] && local desktop=$1 || local desktop=$current_desktop
	fi

	wmctrl -lG | awk '$2 ~ "'$desktop'" && ! /('"${blacklist//,/|}"')$/ && $1 ~ /'$current_id'/ \
		{ print $1, $3 - '${x_border:=0}', $4 - ('${y_border:=0}' - '$x_border' / 2) * 2, $5, $6 }'
		#{ print $1, $3 - '${x_border:-0}', $4 - '${y_border:-0}', $5, $6 }'
}

function set_windows_properties() {
	[[ ! $properties ]] && properties=( $(get_windows $id) )

	if [[ ! $2 ]]; then
		[[ $1 == h ]] && index=1 || index=2
		get_display_properties $index
	fi

	#if [[ ! $all_windows ]]; then
	if ((!window_count)); then
		while read -r wid wx wy ww wh; do
			if ((wx > display_x && wx + ww < display_x + width && wy > display_y && wy + wh < display_y + height)); then
				all_windows+=( "$wid $wx $wy $ww $wh" )
			fi
		done <<< $(get_windows $2)

		window_count=${#all_windows[*]}
	fi

	#window_count=${#all_windows[*]}
}

function update_properties() {
	for window_index in "${!all_windows[@]}"; do
		#[[ ${all_windows[window_index]%% *} == $id ]] && all_windows[window_index]="${properties[*]}"
		if [[ ${all_windows[window_index]%% *} == $id ]]; then
			[[ $1 ]] && unset all_windows[window_index] || all_windows[window_index]="${properties[*]}"
		fi
	done
}

function generate_properties_format() {
	echo -n 0
	for property in ${properties[*]:1}; do echo -n ",$property"; done
}

function generate_printable_properties() {
	id=${1%% *}
	printable_properties=${1#* }
}

function save_properties() {
	#[[ -f $property_log ]] && echo $id $printable_properties >> $property_log
	echo ${1:-$id} $printable_properties >> $property_log
}

function backtrace_properties() {
	read line_number properties <<< $(awk '/^'$id'/ { nr = NR; p = substr($0, 12) } END { print nr, p }' $property_log)
	sed -i "${line_number}d" $property_log
	echo "$properties"
}

function restore_properties() {
	[[ -f $property_log ]] && properties=( $(grep "^$id" $property_log) )
}

function apply_new_properties() {
	[[ $printable_properties ]] && wmctrl -ir $id -e 0,${printable_properties// /,}
}

function list_all_windows() {
	for window in "${all_windows[@]}"; do
		echo $window
	done
}

function backup() {
	backup_properties="wmctrl -ir $id -e 0$(generate_properties_format original ${original_properties[*]})"

	if [[ -f $property_log && $(grep $id $property_log) ]]; then
		[[ $overwrite ]] && sed -i "s/.*$id.*/$backup_properties/" $property_log
	else
		echo "$backup_properties" >> $property_log
	fi
}

list_bars() {
	for bar in "${bars[@]}"; do
		echo $bar
	done
}

set_orientation_properties() {
	if [[ $1 == h ]]; then
		index=1
		dimension=width
		offset=$x_offset
		step=$font_width
		start=$display_x
		opposite_dimension=height
		opposite_start=$display_y
		border=${edge_border:-$x_border}
		bar_vertical_offset=0
	else
		index=2
		dimension=height
		offset=$y_offset
		step=$font_height
		start=$display_y
		opposite_dimension=width
		opposite_start=$display_x
		border=${edge_border:-$y_border}
		bar_vertical_offset=$((bar_top_offset + bar_bottom_offset))
	fi

	start_index=$((index % 2 + 1))
	end=$((start + ${!dimension:-0}))
	opposite_end=$((opposite_start + ${!opposite_dimension:-0}))
}

get_display_properties() {
	read display display_x display_y width height original_min_point original_max_point bar_min bar_max x y <<< \
		$(awk -F '[_ ]' '{ if(/^orientation/) {
			cd = 1
			bmin = 0
			d = '${display:-0}'
			i = '$1'; mi = i + 2
			wx = '${properties[1]}'
			wy = '${properties[2]}'

			if($NF ~ /^h/) {
				i = 3
				p = wx
			} else {
				i = 4
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
				} else {
					if((d && d == cd) || !d) {
						dw = $3
						dh = $4
						maxp = minp + $mi
					}

					max += $i

					if((d && p < max && (cd >= d)) || (!d && p < max)) {
						print (d) ? d : cd, dx, dy, dw, dh, minp, maxp, bmin, bmin + dw, dx + wx, dy + wy
						exit
					} else {
						if(d && cd < d || !d) bmin += $3
						if(p > max) if(i == 3) wx -= $i
						else wy -= $i
					}
				}
			}
		}
	}' ~/.config/orw/config)
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
	set_windows_properties $1

    original_properties=( ${properties[*]} )

	set_orientation_properties $1

	unset edge_border

	properties[1]=$x
	properties[2]=$y

	update_properties

	if [[ $option == tile ]]; then
		original_properties[1]=$x
		original_properties[2]=$y
	fi

	[[ $option != tile ]] && min_point=$((original_min_point + offset))

	get_bar_properties add
}

function set_sign() {
	sign=${1:-+}
	[[ $sign == + ]] && opposite_sign="-" || opposite_sign="+"
}

function resize() {
	edge=$1

	(( properties[$index + 2] ${sign}= value ))
	[[ $edge =~ [lt] ]] && (( properties[$index] ${opposite_sign}= value ))

	[[ $adjacent && $edge =~ [rt] ]] && reverse_adjacent=-r
}

function resize_to_edge() {
	index=$1
	offset=$2

	((index > 1)) && border=$y_border || border=$x_border

	if [[ $argument =~ [BR] ]]; then
		properties[$index + 2]=$((${max:-$end} - offset - ${properties[$index]} - border))
	else
		properties[$index + 2]=$((${properties[$index]} + ${properties[$index + 2]} - max - offset))
		properties[$index]=$((${max:-$start} + offset))
	fi
}


function calculate_size() {
	[[ $denominator -eq 1 ]] && window_margin=0 || window_margin=${margin:-$offset}

	[[ $dimension =~ [[:alpha:]]+ ]] && dimension=${!dimension}

	available_size=$((dimension - bar_vertical_offset - 2 * offset - (denominator - 1) * window_margin - denominator * border))
	window_size=$((available_size / denominator))

	[[ $option == move ]] && ((numerator--))

	size=$(((numerator * window_size) + (numerator - 1) * (window_margin + border)))

	if [[ $option == move ]]; then
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

sort_windows() {
	list_all_windows | awk \
		'{
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

tile() {
	local window_count

	max_point=$original_max_point
	min_point=$((original_min_point + offset))

	while read wid w_min w_max; do
		if [[ $id != $wid ]]; then
			[[ ! $wid =~ ^0x ]] && distance=$offset ||
				distance=$((${margin:-$offset} + border))

			if ((min_point == offset)); then
				if [[ $wid =~ ^0x ]]; then
					if ((w_min == min_point)); then
						min_point=$((w_max + distance))
						((window_count++))
					else
						max_point=$w_min && break
					fi
				else
					#((window_count)) && max_point=$w_min || 
					#	min_point=$((w_max + distance))
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
					bb = ($1 ~ "0x") ? 0 : $NF
					i = (w_index) ? w_index : (l) ? l : 1
					mix_a[i] = $1 " " $pi " " $pi + $(pi + 2) + bb
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
		#((max_point < original_max_point && wid != max_point)) && [[ ! $wid =~ ^0x ]] && 
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

		properties=( $id $win_x $win_y $win_width $win_height )
	else
		properties=( ${original_properties[*]} )
	fi
}

align_adjacent() {
	#((index == 1)) && orientation=h || orientation=v

	old_properties=( ${original_properties[*]} )

	for property_index in {1..4}; do
		new_property=${properties[property_index]}
		old_property=${old_properties[property_index]}
		#((new_property != old_property)) && break
		((new_property != old_property)) &&
			value=$((new_property - old_property)) && break
	done

	#((property_index % 2 == 1)) && index=1 border=$x_border || index=2 border=$y_border
	((property_index % 2 == 1)) && orientation=h || orientation=v
	((property_index > 2)) && ra=-r || dual=true
	value=${value#-}

	#sleep 1
	#~/.orw/scripts/notify.sh "val: $new_property $old_property $value $sign"

	#option=tile
	#set_base_values $orientation

	((window_count)) || set_base_values $orientation

	get_adjacent() {
		local reverse=$2
		local properties=( $1 )

		sort_windows | sort -n $reverse | awk '\
			BEGIN {
				r = "'$reverse'"
				i = '$index' + 2
				si = '$start_index' + 2
				o = '${margin:-$offset}' + '$border'

				id = "'${properties[0]}'"
				cwsp = '${properties[index]}'
				cwep = '${properties[index]}' + '${properties[index + 2]}'
				cws = '${properties[start_index]}'
				cwe = '${properties[start_index]}' + '${properties[start_index + 2]}'

				c = (r) ? cwep + o : cwsp - o
			} {
				if($2 ~ "0x" && $2 != "'$original_id'") {
					if($2 == id) exit
					else {
						ws = $si
						we = ws + $(si + 2)
						cp = (r) ? $i : $i + $(i + 2)

						if((cp == c) &&
							((ws >= cws && ws <= cwe) ||
							(we >= cws && we <= cwe) ||
							(ws <= cws && we >= cwe))) print
					}
				}
			}'
	}

	add_adjacent_window() {
		properties=( $1 )
		id=${properties[0]}
		original_properties=( ${properties[*]} )

		#tile

		if [[ $2 ]]; then
			[[ $dual ]] || local sign=$opposite_sign opposite_sign=$sign
			(( properties[index] ${opposite_sign}= value ))
			(( properties[index + 2] ${sign}= value ))
		else
			(( properties[index + 2] ${opposite_sign}= value ))
		fi

		#update_properties
		adjacent_windows+=( "${properties[*]}" )
	}

	find_neighbour() {
		while read -r c window; do
			if [[ $c ]]; then
				add_adjacent_window "$window" $2

				[[ $2 ]] && ra='' || ra=-r
				original_id=${1%% *}
				find_neighbour "$window" $ra
			fi
		done <<< $(get_adjacent "$1" $2)
	}

	[[ $sign == - ]] &&
		adjacent_windows=( "${properties[*]}" ) ||
			new_original_properties=( "${properties[*]}" )
	find_neighbour "${old_properties[*]}" $ra
	[[ $new_original_properties ]] && adjacent_windows+=( "${new_original_properties[*]}" )

	#~/.orw/scripts/notify.sh "$sign ${adjacent_windows[*]} $ra"

	for window in "${adjacent_windows[@]}"; do
		read id x y w h <<< "$window"
		wmctrl -ir $id -e 0,$x,$y,$w,$h
	done

	exit

	#for window in "${adjacent_windows[@]}"; do
	#	generate_printable_properties "$window"
	#	apply_new_properties
	#done
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

get_optarg() {
	((argument_index++))
	optarg=${!argument_index}
}

get_neighbour_window_properties() {
	local index reverse direction=$1

	[[ $direction =~ [lr] ]] && index=1 || index=2
	[[ $direction =~ [br] ]] && reverse=-r
	[[ $tiling ]] && local first_field=2

	start_index=$((index % 2 + 1))

	read -a second_window_properties <<< \
		$(sort_windows $direction | sort $reverse -nk 1,1 | awk \
			'{ cwp = '${properties[index]}'; cwsp = '${properties[start_index]}'; \
			if("'$direction'" ~ /[br]/) cwp += '${properties[index + 2]}'; \
				wp = $1; wsp = $('$start_index' + 2); xd = (cwsp - wsp) ^ 2; yd = (cwp - wp) ^ 2; \
				print sqrt(xd + yd), $0 }' | sort -nk 1,1 | awk 'NR == 2 \
				{ if(NF > 7) { $6 += ($NF - '$x_border'); $7 += ($NF - '$y_border')}
				print gensub("([^ ]+ ){" '${first_field-3}' "}|" $8 "$)", "", 1) }')
}

print_wm_properties() {
	(( wm_properties[0] -= display_x ))
	(( wm_properties[1] -= display_y ))
	echo $display ${wm_properties[*]}
}

resize_by_ratio() {
	local argument=$1
	local orientation=$2
	local ratio=$3

	#[[ ${!argument_index} =~ ^[1-9] ]] && ratio=${!argument_index} && shift
	#[[ $orientation =~ r$ ]] && orientation=${orientation:0:1} reverse=true ||
	#	reverse=$(awk '/^reverse/ { print $NF }' $config)
	[[ $orientation =~ r$ ]] && orientation=${orientation:0:1} reverse=true

	if [[ ${orientation:0:1} == a ]]; then
		((${properties[3]} > ${properties[4]})) && orientation=h || orientation=v
		((ratio)) || ratio=$(awk '/^(part|ratio)/ { if(!p) p = $NF; else { print p "/" $NF; exit } }' $config)
		#((ratio)) || ratio=$(awk '/^(part|ratio)/ { if(!r) r = $NF; else { print $NF "/" r; exit } }' $config)

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

set_alignment_properties() {
	#[[ $1 == h ]] &&
	#	index=1 opposite_index=2 direction=x opposite_direction=v display_property=$display_x ||
	#	index=2 opposite_index=1 direction=y opposite_direction=h display_property=$display_y
    #
	#border=${direction}_border
	#offset=${direction}_offset
	#separator=$(((${!border} + ${margin:-${!offset}})))

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

#get_alignment() {
#	[[ $1 ]] && local current_direction=$1_
#
#	set_alignment_properties ${1:-$alignment_direction}
#
#	read ${current_direction}alignment_start ${current_direction}alignment_area ${current_direction}alignment_ratio \
#		${current_direction}aligned_window_count ${current_direction}aligned_windows <<< \
#		$(list_all_windows | sort -nk $((index + 1)),$((index + 1)) | \
#			awk '\
#				function is_aligned(win1, win2) {
#					delta = (win1 > win2) ? win1 - win2 : win2 - win1
#					return delta < wc
#				}
#
#				function is_adjacent() {
#					return ($(i + 1) < p) ? ($(i + 1) + $(i + 3) + s == p) : (p + d + s == $(i + 1))
#				}
#
#				BEGIN {
#					i = '$index'
#					s = '$separator'
#					oi = '$opposite_index'
#					wc = '${#all_windows[*]}'
#					p = '${properties[index]}'
#					d = '${properties[index + 2]}'
#					op = '${properties[opposite_index]}'
#					od = '${properties[opposite_index + 2]}'
#				}
#
#				cp = $(oi + 1)
#				cd = $(oi + 3)
#
#				cp >= op && cp + cd <= op + d && is_adjacent() {
#					
#				}
#				
#
#				#$(oi + 1) == p && od == $(oi + 3) && is_aligned(d, $(i + 3)) {
#				#	na = aa && $(i + 1) - s != as + aa
#
#				#	if(!length(aa) || na) {
#				#		if(na && c) exit
#				#		as = $(i + 1)
#				#		aa = $(i + 3)
#				#		aw = ""
#				#		awc = 0
#				#	} else {
#				#		aa += s + $(i + 3)
#				#	}
#
#				#	if($1 == "'$id'") c = 1
#
#				#	aw = aw " \"" $0 "\""
#				#	awc++
#				#} END { print as, aa, aa / od, awc, aw }')
#}

get_alignment() {
	list_all_windows | sort -nk $((opposite_index + 1)),$((opposite_index + 1)) -k $((index + 1)),$((index + 1)) | \
		awk '\
			function sort(a) {
				#removing/unseting variables
				delete cwp
				delete fdw
				#delete pdw
				ai = fdwi = pdwc = min = max = 0

				for(ai in a) {
					split(a[ai], cwp)

					#parse properties
					id = cwp[1]
					cws = cwp[i + 1]
					cwd = cwp[i + 3]
					cwos = cwp[oi + 1]
					cwod = cwp[oi + 3]

					#if this is a first window, assign a min point
					if(!min) min = cws
					#if window end point is greater then max, assigh new max
					if(cws + cwd > max) max = cws + cwd

					if(cwod == wod) {
						#if window opposite dimension is full (same as original), add window to fdw 
						fdw[++fdwi] = id " " cws " " cwd
					} else {
						#add window to partial dimension windows
						pdw = pdw "," id ":" cws "-" cwd
						#calculate window surface
						cwsf = (cwd + s) * (cwod + os)
						csf += cwsf

						#if this is the last window in the row/column, increase total surface by multiplying its dimension with total opposite dimension 
						if(cwos + cwod == wos + wod) tsf += (cwd + s) * (wod + os)
						#if this is the last piece of the surface (last window), add all windows belonging to this surface as one full window
						if(csf == tsf) {
							fdw[++fdwi] = substr(pdw, 2)
							pds = ""
							tsf = 0
						}

						#if(pdwc) {
						#	for(pdwli in pdw) {
						#		split(pdwli, pwp, "-")

						#		hids = pdw[pdwli]

						#		pws = pwp[1]
						#		pwe = pwp[2]
						#		pwd = pwp[3]
						#		pwod = pwp[4]
						#		ip = pwp[5]

						#		if(cws >= pws && cws + cwd <= pwe) {
						#			if(cwos + cwod == pwd) {
						#				if(cws + cwd == pwe) fdw[++fdwi] = hids "," id ":" cws "-" cwd "_" cws + cwd - ip
						#				else pdw[pdwli] = hids "," id ":" cws "-" cwd
						#			} else pdw[pdwli] = hids "," id ":" cws "-" cwd
						#		} else {
						#			if(cws == pwe + s && cwod == pwod) {
						#				pdw[pws "-" pwe + s + cwd "-" pwd "-" cwod "-" cwos] = hids "," id ":" cws "-" cwd
						#				delete pdw[pdwli]
						#			} else pdw[cws "-" cws + cwd "-" pwd "-" cwod "-" ip] = id ":" cws "-" cwd
						#		}
						#	}
						#} else {
						#	pdwc++
						#	pdw[cws "-" cws + cwd "-" wos + wod "-" cwod "-" cws] = id ":" cws "-" cwd
						#}
					}
				}

				#repopulate original array
				delete a
				for(wi in fdw) a[wi] = fdw[wi]

				return min " " max
			}

			BEGIN {
				#i = '$index'
				#s = '$separator'
				#wc = '$window_count'
				#oi = '$opposite_index'
				#ws = '${properties[index]}'
				#wd = '${properties[index + 2]}'
				#wos = '${properties[opposite_index]}'
				#wod = '${properties[opposite_index + 2]}'

				#system("~/.orw/scripts/notify.sh -t 22 \"'"${properties[*]}"'\"")

				#variable assignment
				i = '$index'
				oi = '$opposite_index'
				b = '$border'
				o = '${margin:-$offset}'
				ob = '$opposite_border'
				oo = '${margin:-$opposite_offset}'
				wc = '${#all_windows[*]}'
				ws = '${properties[index]}'
				wd = '${properties[index + 2]}'
				wos = '${properties[opposite_index]}'
				wod = '${properties[opposite_index + 2]}'

				#new window size
				nws = '$new_window_size'

				#separator assignment
				s = b + o
				os = ob + oo

				#full and reverse
				f = "'$full'"
				r = "'$reverse'"

				#closing properties
				c = ("'$1'")
				cp = "'$closing_properties'"

				#align ratio
				if(length("'$align_ratio'")) ar = '${align_ratio:-0}'
				#system("~/.orw/scripts/notify.sh \"" "AR '$align_ratio' " ar "\"")
				#if ("'$align_ratio'") system("~/.orw/scripts/notify.sh \"" "'$align_ratio' " ar "\"")

				#system("~/.orw/scripts/notify.sh -t 22 \"" ws " " wos " " wd " " wod "\"")
			}

			{
				#current window properties assignment
				cws = $(i + 1)
				cwd = $(i + 3)
				cwos = $(oi + 1)
				cwod = $(oi + 3)

				#if(cwos >= wos && cwos + cwod <= wos + wod) {

				#system("~/.orw/scripts/notify.sh -t 22 \" '$id' " $0 " " "'$alignment_direction'" " " i " " ws "\"")

				#if($1 == "'$id'" || (cwos >= wos && cwos + cwod <= wos + wod &&
				#if($1 == "'$id'" || cp || (cwos >= wos && cwos + cwod <= wos + wod &&
				#if((cws == ws && cwd == wd && cwos == wos && cwod == wod) ||
				#filter only windows align with the original one, and add original to eather before or after array
				if($1 == "'$id'" ||
					((cwos >= wos && cwos + cwod <= wos + wod &&
					(cws + cwd < ws || cws > ws + wd)) &&
					!($4 == nws && $5 == nws))) {
					if(cws < ws) bw[++bwi] = $0
					else if(cws > ws) aw[++awi] = $0
					else {
						if(!c) {
							#system("~/.orw/scripts/notify.sh \"r: '$reverse'\"")
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
				#cs = (c) ? s / 2 : s
				# get evenly distributed ratio
				#cs = s / 2
				#wr = od / (cwd + cs)
				#wr = od / (cwd + s)
				wr = (od + s) / (cwd + s)

				#system("~/.orw/scripts/notify.sh \"" wr "\"")
				#cwnd = sprintf("%.0f", nd / wr - cs)
				#cwns = cws + cwnd

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
				#cwnd = sprintf("%.0f", nd / wr - s)
				#system("~/.orw/scripts/notify.sh \"" cns " " wane "\"")
				#cwnd = int((cws + cwd == wae) ? wane - cns : nd / wr - cs)
				# set new window dimension depending on wether window is last or not:
				# if it is, simply subtract its dimention from new end point
				# if not, apply ratio calculated earlier on the new dimension
				#cwnd = sprintf("%.0f", (cws + cwd == wae) ? wane - cns : nd / wr - cs)
				#cwnd = sprintf("%.0f", (cws + cwd == wae) ? wane - cns : nd / wr - s)
				cwnd = sprintf("%.0f", (cws + cwd == wae) ? wane - cns : (nd + s) / wr - s)
				#system("~/.orw/scripts/notify.sh " (cws + cwd == wae))
				cwns = cns + cwnd + s
				# add original/new window start to array
				ns[cws + cwd + s] = cwns
				nsc++

				#print wr, cwd, cwnd

				#cwe = cns + cwnd

				#for(nei in ne) {
				#	ce = ne[nei]
				#	dd = (ce > cwe) ? ce - cwe : cwe - ce

				#	if(dd == 1) {
				#		if(ce > cwe) { cwe++; cwnd++ }
				#		else { cwe--; cwnd-- }

				#		break
				#	}
				#}

				#ne[++nec] = cwe

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
					#cr = (td + p) / cd
					# current ratio (new dimension / old dimension)
					cr = td / cd

					# if window is closing
					if(c) {
						#nd = cd + ((wd + s) / twc * cac)
						#cane = cas + nd
						# new window dimension:
						# new total dimension + original window dimension + padding - new padding
						nd = (td + wd + p - np) / cr
						#system("~/.orw/scripts/notify.sh \"" cane " " nd " " ((wd / (twc - 1) * cac)) " " twc "\"")
					} else {
						nwd = int((td - p) / (twc + 1))
						nd = (td - nwd) / cr
						cane = cas + td - nwd - p

						#nwd = int(td / (twc + 1))
						#nwd = int((td + np - p) / (twc + 1))
						# set alignment ratio if it is enforced, otherwise devide it evenly
						nwdp = (ar) ? ar : twc + 1
						# set new window dimension by deviding total dimension with alignment ratio
						nwd = int((td + np - (twc * s)) / nwdp)
						# calculate new dimension by applying ratio computed earlier
						nd = (td + np - p - nwd) / cr
						#dr = cd / (cd + s)
						#nd *= dr

						# if reverse is enabled (window should open before original window),
						# and there is no widnows before original window, offset all windows to start after new window (after its dimension + separator)
						if(pos && r && !bc) {
							# separator after new window:
							# if full is enabled, separator should have double value because 
							# full window is set to start a separator before first window,
							#fs = (f) ? 2 * s : s

							# if full is enabled, new window is set to start a separator before first window,
							# so this will neutralize it
							#if(f) mns += s
							mns += nwd + s
						}
					}

					#system("~/.orw/scripts/notify.sh \"" nwdp " " nwd "\"")
					#system("~/.orw/scripts/notify.sh -t 11 \"" nwd " " td " " nd " " cd " " cane " " cr "\"")
					#system("~/.orw/scripts/notify.sh -t 11 \"" td " " nwd " " nd "\"")
					# setting new end point according to position regarding original window
					cane = (pos) ? aas + cd : cas + nd
					#print nwd, nd, cd, td, cane, cr
					align(ca, cae, cane, cd, pos)
				}
			}

			END {
				# setting before windows array and its properties
				set_array(bw, nbw)
				bc = length(nbw)
				bas = min; bae = max; bad = max - min

				# setting after windows array and its properties
				set_array(aw, naw)
				ac = length(naw)
				aas = min; aae = max; aad = max - min

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
					nwd = (ac) ? nwd : bas + td - nws
					#nwd = (ac) ? (bc) ? nwd :  : bas + td - nws
					if(bc) {
						nw = "[new]=\"" nws " " nwd "\""
						# increment new minimum start by new window dimension and separator
						mns += nwd + s
					}
				}

				#if(bc) for(i in nbw) print i, nbw[i]
				#if(ac) for(i in naw) print i, naw[i]
				#print aas, aae, aad, nws, nwd

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

		read x y w h <<< ${properties[*]:1}

		#if windows should tile (two step operation)
		if [[ $tiling ]]; then
			#set window which should tile to fill "new" position of new alignment,
			#otherwise, update all_windows array with new properties after alignment, so the next iteration can be calculated with accurate values
			[[ $id == new ]] && id=$original_properties ||
				all_windows[window_index]="$id $x $y $w $h"
			#update properties of the window to which selected window should be tiled to
			[[ $id == $second_window_id ]] && second_window_properties=( $x $y $w $h )
		fi

		#populate all_aligned_windows array
		all_aligned_windows[$id]="$x $y $w $h"
	fi
}

#set_ratio_values() {
#	ratio_values=true
#
#	if [[ $alignment_direction == v ]]; then
#		get_bar_properties
#		local bar_offset=$((bar_top_offset + bar_bottom_offset))
#	fi
#
#	#local window_dimension=$((${properties[index + 2]} + border))
#	#local display_dimension=$((display_dimension - 2 * offset - bar_offset))
#	window_ratio_value=$((${properties[index + 2]} + border))
#	display_ratio_value=$((display_dimension - 2 * offset - bar_offset))
#	#align_ratio=$(echo "$display_dimension / $window_dimension" | bc -l)
#}

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

					#local window_dimension=$((${properties[index + 2]} + border))

					#[[ $alignment_direction == h ]] &&
					#	local window_dimension=$original_width ||
					#	local window_dimension=$original_height

					#getting ratio
					local display_dimension=$((display_dimension - 2 * offset - bar_offset))
					align_ratio=$(echo "$display_dimension / $window_dimension" | bc -l)

					[[ $align_ratio =~ ^1.0+$ ]] && unset align_ratio
					#~/.orw/scripts/notify.sh "$display_dimension $window_dimension $align_ratio"
					#exit
				fi
			else
				align_ratio=$(echo "$ratio / $part" | bc -l)
			fi

			#if [[ $use_ratio == true ]]; then
			#if [[ ! $tiling ]]; then
			#	align_ratio=$(echo "$ratio / $part" | bc -l)
			#else
			#	if [[ $alignment_direction = v ]]; then
			#		get_bar_properties
			#		bar_offset=$((bar_top_offset + bar_bottom_offset))
			#	fi

			#	local window_dimension=$((${properties[index + 2]} + border))
			#	local display_dimension=$((display_dimension - 2 * offset - bar_offset))
			#	align_ratio=$(echo "$display_dimension / $window_dimension" | bc -l)
			#fi
		fi

		#~/.orw/scripts/notify.sh "ar $align_ratio"
	fi

	#storing new window properties after alignment
	eval aligned_windows=( $(get_alignment $action) )

	#[[ $action == close ]] || set_alignment new
	#if new window should be inserted
	[[ $action ]] || set_alignment new

	#if [[ $action == close ]]; then
	#	if ((${#aligned_windows[*]} == 1)); then
	#		[[ $alignment_direction == h ]] && new_alignment_direction=v || alignment_direction=h
	#	fi
	#else
	#	set_alignment new
	#fi

	#echo $action ${#aligned_windows[*]}

	#reversing stored alignment in case this is the only window
	local aligned_window_count=${#aligned_windows[*]}
	([[ $action == close ]] && ((aligned_window_count == 1))) ||
		([[ ! $action ]] && ((aligned_window_count == 2))) && awk -i inplace -F '[: ]' '\
			BEGIN {
				awc = '$aligned_window_count'
				p = gensub(/ /, "|", 1, "'"${!aligned_windows[*]}"'")
			}
			$1 ~ "^(" p ")" {
				d = $NF
				if(awc == 1 || (awc == 2 && d != "'$alignment_direction'"))
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

select_window() {
	~/.orw/scripts/select_window.sh
	second_window_id=$(printf '0x%.8x' $(xdotool getactivewindow))
	second_window_properties=( $(get_windows $second_window_id | cut -d ' ' -f 2-) )
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
			x = '$x_border'
			y = '$y_border'
			$3 -= y - x / 2
			$2 -= x / 2
			print
		}')
}

#align_windows() {
#	local action=$1
#	eval aligned=( "$aligned_windows" )
#	aligned_count="${#aligned[@]}"
#
#	[[ $action == close ]] &&
#		align_size=$(((alignment_area - (aligned_count - 1) * separator) / aligned_count)) ||
#		align_size=$(((alignment_area - aligned_count * separator) / (aligned_count + 1)))
#
#	for window_index in "${!aligned[@]}"; do
#		properties=( ${aligned[window_index]} )
#
#		if ((window_index)); then
#			 properties[index]=$next_window_start
#		 else
#			 #[[ $reverse ]] && (( properties[index] += align_size + separator )) || properties[index]=$alignment_start
#			 [[ ! $reverse || $action == close ]] &&
#				 properties[index]=$alignment_start || (( properties[index] += align_size + separator ))
#		fi
#
#		[[ $action == close || $reverse ]] && ((window_index == aligned_count - 1)) &&
#			original_align_size=$align_size align_size=$((alignment_start + alignment_area - ${properties[index]}))
#
#		properties[index + 2]=$align_size
#		next_window_start=$((${properties[index]} + ${properties[index + 2]} + separator))
#
#		#echo ${properties[*]}
#		generate_printable_properties "${properties[*]}"
#		apply_new_properties
#	done
#
#	if [[ $action != close ]]; then
#		if [[ $reverse ]]; then
#			properties[index]=$alignment_start
#			properties[index + 2]=$original_align_size
#		else
#			properties[index]=$next_window_start
#			properties[index + 2]=$((alignment_area - (aligned_count * (align_size + separator))))
#		fi
#
#		read x y w h <<< ${properties[*]:1}
#	fi
#}

#restore_alignment() {
#	if [[ $mode != auto ]]; then
#		get_alignment h
#		get_alignment v
#	fi
#
#	echo $mode $h_aligned_window_count $v_aligned_window_count
#	exit
#
#	if [[ $mode == auto ]] || ((h_aligned_window_count + v_aligned_window_count <= 2)); then
#		get_closest_windows() {
#			set_alignment_properties $1
#
#			local start=${properties[opposite_index]}
#			local end=$((start + ${properties[opposite_index + 2]}))
#
#			#read $1_size $1_aligned_windows <<< $(list_all_windows | sort -nk $index,$index | awk '\
#			read $1_size $1_aligned_windows <<< $(list_all_windows | sort -nk $index,$index | awk '\
#				function set_current_window() {
#					cp = p
#					cd = d
#					cid = "\"" $0 "\""
#					#system("~/.orw/scripts/notify.sh \"" $0 " " '$index' " " $('$index' + 2) "\"")
#					dis = (p < ws) ? ws - (p + $('$index' + 3)) : p - we
#				}
#
#				BEGIN {
#					ws = '${properties[index]}'
#					we = ws + '${properties[index + 2]}'
#				}
#
#				$1 != "'$id'" {
#					p = $('$index' + 1)
#					s = $('$opposite_index' + 1)
#					d = $('$opposite_index' + 3)
#					e = s + d
#
#					if(s >= '$start' && e <= '$end') {
#						if(cp) {
#							if(cp == p) {
#								cd += d
#								cid = cid " \"" $0 "\""
#							} else if(cd >= max && (!md || dis < md)) {
#								max = cd
#								md = dis
#								id = cid
#								mp = p
#								set_current_window()
#							}
#						} else {
#							set_current_window()
#						}
#					}
#				} END { print (cd >= max && (!md || dis < md)) ? cd " " cid : max " " id }')
#		}
#
#		if [[ $window_action ]]; then
#			if [[ $window_action == move ]]; then
#				#[[ $mode == auto ]] &&
#				#	generate_printable_properties "$properties ${wm_properties[*]}" ||
#				#	generate_printable_properties "${original_properties[0]} $x $y $w $h"
#				#generate_printable_properties "$original_properties $x $y $w $h"
#				generate_printable_properties "$original_properties ${wm_properties[*]}"
#				apply_new_properties
#
#				wmctrl -ir $id -t $current_desktop
#			else
#				wmctrl -ic $id
#			fi
#		fi
#
#		#[[ $window_action == move ]] && local command="r $id -t $current_desktop" || local command="c $id"
#		#wmctrl -i$command
#
#		get_closest_windows h
#		get_closest_windows v
#
#		((h_size > v_size)) &&
#			dominant_alignment=h aligned_windows="$h_aligned_windows" ||
#			ominant_alignment=v aligned_windows="$v_aligned_windows"
#
#		closing_window_properties=( ${properties[*]} )
#
#		set_alignment_properties $dominant_alignment
#		eval aligned=( "$aligned_windows" )
#		#wmctrl -ic $id
#
#		align_size=$((${properties[index + 2]} + separator))
#
#		for window in "${aligned[@]}"; do
#			properties=( $window )
#			id=${properties[0]}
#
#			(( properties[index + 2] += align_size ))
#			((${closing_window_properties[index]} < ${properties[index]})) && (( properties[index] -= align_size ))
#
#			generate_printable_properties "${properties[*]}"
#			apply_new_properties
#		done
#		exit
#	else
#		if ((h_aligned_window_count == v_aligned_window_count)); then
#			dominant_alignment=$(echo $h_alignment_ratio $v_alignment_ratio | awk '{ print ($1 < $2) ? "h" : "v" }')
#		else
#			((h_aligned_window_count > v_aligned_window_count)) && dominant_alignment=h || dominant_alignment=v
#		fi
#	fi
#
#	set_alignment_properties $dominant_alignment
#
#	[[ $dominant_alignment == h ]] &&
#		alignment_start=$h_alignment_start alignment_area=$h_alignment_area aligned_windows=$h_aligned_windows ||
#		alignment_start=$v_alignment_start alignment_area=$v_alignment_area aligned_windows=$v_aligned_windows
#
#	aligned_windows="${aligned_windows/\"${properties[*]}\"/}" 
#
#	if [[ $window_action ]]; then
#		if [[ $window_action == move ]]; then
#			#[[ $mode == auto ]] &&
#			#	generate_printable_properties "$properties ${wm_properties[*]}" ||
#			#	generate_printable_properties "${original_properties[0]} $x $y $w $h"
#			#echo $original_properties $x $y $w $h
#			#exit
#			generate_printable_properties "$original_properties $x $y $w $h"
#			apply_new_properties
#
#			wmctrl -ir $id -t $current_desktop
#		else
#			wmctrl -ic $id
#		fi
#	fi
#}

#read border client padding <<< $(awk '\
#	/^border/ { b = $NF }
#	/^[^m]*height/ { if(/^padding/) p = $NF; else c = $NF }
#	END { print b, c, p }' ~/.orw/themes/theme/openbox-3/themerc)
#
#	font_size=$(awk '\
#		/font.*ActiveWindow/ { nr = NR }
#		nr && NR == nr + 2 {
#			fs = gsub(/[^0-9]*/, "")
#			if(fs == 2 || fs == 6) fs--
#			print fs
#		}' .config/openbox/rc.xml)

#x_border=$((2 * (border + client)))
#y_border=$((3 * (border + client) + padding + font_size))

#align() {
#	#read mode alignment_direction reverse <<< $(\
#	#	awk '{
#	#		if(/^mode/) m = $NF
#	#		else if(/^reverse/) r = ($NF == "true") ? "r" : ""
#	#		else if(/^direction/) d = ("'$alignment_direction'") ? "'$alignment_direction'" : $NF
#	#		} END { print m, d, r }' $config)
#
#	[[ $optarg =~ m$ ]] && window_action=move
#	[[ $optarg =~ c$ ]] && window_action=close
#	#[[ $optarg == full ]] && window_action=full
#	[[ $optarg && ! $window_action ]] && alignment_direction=${optarg:0:1}
#	#[[ $optarg && $optarg != [cm] ]] && alignment_direction=${optarg:0:1}
#
#	#elif [[ $window_action == full ]]; then
#	#	#~/.orw/scripts/tile_terminal.sh
#
#	#	set_windows_properties $display_orientation
#	#	set_orientation_properties $alignment_direction
#	#	set_alignment_properties $alignment_direction
#	#	#set_alignment_properties $alignment_direction
#
#	#	#((index == 1)) && dimension=$width opposite_dimension || dimension=$height
#
#	#	#echo ${properties[*]}
#	#	#properties[0]='none'
#	#	#properties[index]=${!dimension}
#	#	#properties[start_index]=0
#	#	#properties[index + 2]=0
#	#	#properties[start_index + 2]=${!opposite_dimension}
#
#	#	read new_start new_opposite_start new_opposite_dimension <<< \
#	#		$(list_all_windows | awk '\
#	#			BEGIN {
#	#				i = '$index' + 1
#	#				oi = '$start_index' + 1
#	#			}
#	#			
#	#			{
#	#				os = $oi
#	#				oe = $oi + $(oi + 2)
#	#				e = $i + $(i + 2)
#
#	#				if(!mos) mos = os
#	#				if(os < mos) mos = os
#	#				if(oe > moe) moe = oe
#	#				if(e > me) me = e
#	#			} END { print me + 30, mos, moe - mos }')
#
#	#	id=none
#	#	properties[0]=$id
#	#	properties[index]=$new_start
#	#	properties[opposite_index]=$new_opposite_start
#	#	properties[index + 2]=0
#	#	properties[opposite_index + 2]=$new_opposite_dimension
#	#	echo ${properties[*]}
#
#	#	get_alignment
#	#	exit
#
#		#get_bar_properties
#		#read width height <<< $(awk '/^display_'${display-1}' / { print $2, $3 }' $config)
#
#		#border=$(awk '/^border/ { print $NF * 2 }' $theme)
#
#		##~/.orw/scripts/notify.sh "$x_offset $((y_offset + bar_top_offset)) $((width - 2 * x_offset - border)) $((height - (bar_top_offset + bar_bottom_offset) - 2 * y_offset - border))"
#
#		##~/.orw/scripts/notify.sh "-c '\\\*' -x $x_offset -y $((y_offset + bar_top_offset)) \
#		##	-w $((width - 2 * x_offset - border)) -h $((height - (bar_top_offset + bar_bottom_offset) - 2 * y_offset - border))"
#
#		#x=$x_offset
#		#y=$((y_offset + bar_top_offset))
#		#w=$((width - 2 * x_offset - border))
#		#h=$((height - (bar_top_offset + bar_bottom_offset) - 2 * y_offset - border))
#
#		#if [[ $window_action == move ]]; then
#		#	original_properties=( ${properties[*]} )
#
#		#	wmctrl -s $current_desktop
#
#		#	if [[ ${#all_windows[*]} -eq 1 ]]; then
#		#		properties=( ${all_windows[*]} )
#		#	elif [[ $mode != stack ]]; then
#		#		#select_window
#		#		#properties=( ${second_window_properties[*]} )
#		#		
#		#		until
#		#			id=$(printf "0x%.8x" $(xdotool getactivewindow 2> /dev/null))
#		#			[[ $id ]]
#		#		do
#		#			echo $id
#		#			sleep 0.005
#		#		done
#
#		#		properties=( $(get_windows $id) )
#		#		echo ${properties[*]}
#		#		#exit
#		#	fi
#		#fi
#
#	#full=true
#
#	if [[ $mode == selection ]]; then
#		select_window_using_mouse
#
#		(( second_window_properties[0] -= display_x ))
#		(( second_window_properties[1] -= display_y ))
#
#		read x y w h <<< ${second_window_properties[*]}
#		~/.orw/scripts/set_geometry.sh -c '\\\*' -x $x -y $y -w $w -h $h
#	else
#		#((window_count)) || set_windows_properties $display_orientation
#		[[ $id == none ]] || set_windows_properties $display_orientation
#		#[[ $id && ! $window_count ]] && set_windows_properties $display_orientation
#
#		if ((window_count)); then
#			if [[ $mode == auto && $window_action != close ]]; then
#				set_orientation_properties $display_orientation
#
#				ratio=$(awk '/^(part|ratio)/ { if(!p) p = $NF; else { print p "/" $NF; exit } }' $config)
#				resize_by_ratio H $alignment_direction$reverse $ratio
#
#				generate_printable_properties "${properties[*]}"
#				apply_new_properties
#
#				read x y w h <<< ${wm_properties[*]}
#				~/.orw/scripts/set_geometry.sh -c '\\\*' -x $x -y $y -w $w -h $h
#			else
#				if [[ $full && $window_action != close ]]; then
#					set_orientation_properties $alignment_direction
#					set_alignment_properties $alignment_direction
#
#					read new_start new_opposite_start new_opposite_dimension <<< \
#						$(list_all_windows | awk '\
#							BEGIN {
#								i = '$index' + 1
#								oi = '$start_index' + 1
#							}
#							
#							{
#								os = $oi
#								oe = $oi + $(oi + 2)
#								e = $i + $(i + 2)
#
#								if(!mos) mos = os
#								if(os < mos) mos = os
#								if(oe > moe) moe = oe
#								if(e > me) me = e
#							} END { print me + '$separator', mos, moe - mos }')
#
#					id=none
#					properties[0]=$id
#					properties[index]=$new_start
#					properties[opposite_index]=$new_opposite_start
#					properties[index + 2]=0
#					properties[opposite_index + 2]=$new_opposite_dimension
#
#					#echo $separator
#					#echo ${properties[*]}
#					#unset window_action
#				else
#					set_orientation_properties $display_orientation
#
#					if [[ $mode == stack && $window_action != close ]]; then
#						[[ $alignment_direction == h ]] && align_index=3 || align_index=2
#						properties=( $(list_all_windows | sort -nk $align_index,$align_index | tail -1) )
#					fi
#				fi
#
#				((${#all_aligned_windows[*]})) || declare -A all_aligned_windows
#
#				[[ $window_action == close ]] && wmctrl -ic $id
#				#~/.orw/scripts/notify.sh "$alignment_direction ${!all_aligned_windows[*]}"
#				#exit
#
#				align_windows $window_action
#				#for i in ${!all_aligned_windows[*]}; do echo ${all_aligned_windows[$i]}; done
#				#echo $alignment_direction
#				#exit
#
#				for window_id in ${!all_aligned_windows[*]}; do
#					read x y w h <<< "${all_aligned_windows[$window_id]}"
#
#					[[ $window_id == $original_properties ]] &&
#						sed -i "/^$window_id/ s/.$/$alignment_direction/" $alignment_file
#					[[ $window_id =~ ^0x ]] && wmctrl -ir $window_id -e 0,$x,$y,$w,$h ||
#						echo $x $y $w $h $alignment_direction
#						#~/.orw/scripts/set_geometry.sh -c '\\\*' -x $x -y $y -w $w -h $h
#				done
#			fi
#		else
#			get_bar_properties
#			read width height <<< $(awk '/^display_'${display:-1}' / { print $2, $3 }' $config)
#
#			x=$x_offset
#			y=$((y_offset + bar_top_offset))
#			w=$((width - 2 * x_offset - x_border))
#			h=$((height - (bar_top_offset + bar_bottom_offset) - 2 * y_offset - y_border))
#
#			echo $x $y $w $h $alignment_direction
#			#~/.orw/scripts/set_geometry.sh -c '\\\*' -x $x -y $y -w $w -h $h
#		fi
#	fi
#
#	[[ $new_desktop ]] && wmctrl -ir $original_properties -t $new_desktop
#	[[ $tiling ]] && wmctrl -ia $original_properties
#	#echo $alignment_direction
#	#exit
#	[[ $original_properties ]] && properties=( ${original_properties[*]} )
#	return
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#			if [[ $window_action == move ]]; then
#				original_properties=( ${current_properties[*]:-${original_properties[*]}} )
#				id=$original_properties
#				#original_properties=( ${current_properties[*]:-${original_properties[*]}} )
#				#echo p: ${properties[*]}
#				align_windows close
#
#				#for window_properties in "${all_aligned_windows[@]}"; do
#				for window_id in ${!all_aligned_windows[*]}; do
#					#echo ${window_properties%% *} $original_properties
#					#if [[ ${window_properties%% *} != $original_properties ]]; then
#					if [[ $window_id != $original_properties ]]; then
#
#						#if [[ $id == new ]]; then 
#						#	if [[ $2 == move ]]; then
#						#		new_properties=( $x $y $w $h )
#						#	else
#						#		~/.orw/scripts/set_geometry.sh -c '\\\*' -x $x -y $y -w $w -h $h &
#						#	fi
#						#else
#
#						read x y w h d <<< "${all_aligned_windows[$window_id]}"
#						echo wmctrl -ir $window_id -e 0,$x,$y,$w,$h
#						#wmctrl -ir $window_id -e 0,$x,$y,$w,$h
#					fi
#				done
#
#				read id x y w h <<< "${original_properties[0]} ${new_properties[*]}"
#				echo wmctrl -ir $id -e 0,$x,$y,$w,$h
#				#wmctrl -ir $id -e 0,$x,$y,$w,$h
#			fi
#
#
#
#
#
#
#
#
#			exit
#
#			if [[ $window_action == close ]]; then
#				alignment_direction=$(sed -n "s/^$id: //p" $alignment_file)
#				sed -i "/^$id/d" $alignment_file
#			else
#				echo "$id: $alignment_direction" >> $alignment_file
#			fi
#
#			set_alignment_properties $alignment_direction
#
#			declare -A aligned_windows
#			eval aligned_windows=( $(get_alignment $window_action) )
#
#			[[ $window_action == close ]] &&
#				wmctrl -ic $id || set_alignment new
#
#			while read window_id window_properties; do
#				set_alignment $window_id
#			#done <<< $(list_all_windows)
#			done <<< $([[ $2 == apply ]] &&
#				for aw in "${aligned_windows[@]}"; do echo "$aw"; done ||
#				list_all_windows)
#			#while read -r item; do echo $item; done <<< $([[ $var == sola ]] && test || for i in "${test[@]}"; do echo $i; don
#			exit
#
#			#[[ $move ]] && window_action="wmctrl -i -r $original_id -t $current_desktop"
#			#[[ $close ]] && window_action="wmctrl -ic $id"
#
#			#[[ $window_action ]] && restore_alignment || get_alignment
#			[[ $window_action == close ]] && restore_alignment || get_alignment
#
#			#if [[ $window_action ]]; then
#			#	if [[ $window_action == move ]]; then
#			#		previous_desktop_windows=( ${all_windows[*]} )
#
#			#	fi
#			#	restore_alignment || get_alignment
#			#fi
#
#			#[[ $close ]] && close_window || get_alignment
#			align_windows $window_action
#			#echo $x $y $w $h
#			#exit
#
#			#if [[ $window_action != move ]]; then
#			#	~/.orw/scripts/set_geometry.sh -c '\\\*' -x $((x - display_x)) -y $((y - display_y)) -w $w -h $h
#			#else
#			#	generate_printable_properties "${original_properties[0]} $x $y $w $h"
#			#	apply_new_properties
#			#fi
#	#	fi
#	#fi
#
#	if [[ $window_action == move ]]; then
#		unset all_windows
#		properties=( ${original_properties[*]} )
#		set_windows_properties $display_orientation $previous_desktop
#
#		#echo ${original_properties[*]}
#		#echo $x $y $w $h
#		#list_all_windows
#		#exit
#
#		restore_alignment
#		align_windows close
#
#		#[[ $mode != auto ]] && align_windows close
#		#generate_printable_properties "$original_properties ${wm_properties[*]:1}"
#		#apply_new_properties
#	else
#		~/.orw/scripts/set_geometry.sh -c '\\\*' -x $((x - display_x)) -y $((y - display_y)) -w $w -h $h
#	fi
#
#	exit
#
#
#
#	#list_all_windows | sort -nk $((index + 1)),$((index + 1)) | \
#	#	awk '\
#	#		function is_aligned(win1, win2) {
#	#			delta = (win1 > win2) ? win1 - win2 : win2 - win1
#	#			return delta < wc
#	#		}
#
#	#		BEGIN {
#	#			i = '$index'
#	#			s = '$separator'
#	#			oi = '$opposite_index'
#	#			wc = '${#all_windows[*]}'
#	#			d = '${properties[index + 2]}'
#	#			od = '${properties[opposite_index + 2]}'
#	#			p = '${properties[opposite_index]}'
#	#		}
#
#	#		$(oi + 1) == p && od == $(oi + 3) && is_aligned(d, $(i + 3)) {
#	#			na = aa && $(i + 1) - s != as + aa
#
#	#			if($1 == "'$id'") c = 1
#
#	#			if(!length(aa) || na) {
#	#				if(na && c) exit
#	#				as = $(i + 1)
#	#				aa = $(i + 3)
#	#				aw = ""
#	#			} else {
#	#				aa += s + $(i + 3)
#	#			}
#
#	#			aw = aw " \"" $0 "\""
#	#		} END { print as, aa, aw }'
#
#	exit
#
#
#
#
#
#
#
#
#
#
#	#list_all_windows | awk '\
#	#	function is_aligned(win1, win2) {
#	#		d = (win1 > win2) ? win1 - win2 : win2 - win1
#	#		return d < wc
#	#	}
#
#	#	BEGIN {
#	#		w = '${properties[3]}'
#	#		h = '${properties[4]}'
#	#		wc = '${#all_windows[*]}'
#	#	}
#
#	#	$1 != "'$id'" && is_aligned(w, $4) && is_aligned(h, $5)'
#	#exit
#
#
#
#
#
#
#
#	[[ $optarg =~ c$ ]] && close=true
#
#	read mode alignment_direction reverse <<< $(awk '{
#		if(/^mode/) m = $NF
#		else if(/^reverse/) r = ($NF == "true") ? "r" : ""
#		else if(/^direction/) print m, $NF, r }' $config)
#
#	[[ $optarg && $optarg != c ]] && alignment_direction=${optarg:0:1}
#	[[ $alignment_direction == h ]] &&
#		index=1 opposite_index=2 direction=x opposite_direction=v display_property=$display_x ||
#		index=2 opposite_index=1 direction=y opposite_direction=h display_property=$display_y
#
#	#[[ $optarg =~ c$ ]] && resize_argument=D || resize_argument=H
#
#	if [[ $mode == auto || $window_count -eq 1 ]]; then
#		[[ $mode == auto ]] && alignment_direction=a
#		[[ $mode == stack ]] && unset reverse
#		#resize_by_ratio ${resize_argument:-H} ${opposite_direction:-$alignment_direction}$reverse
#		#resize_by_ratio ${resize_argument:-H} $alignment_direction$reverse
#
#		resize_by_ratio ${resize_argument:-H} $alignment_direction$reverse
#
#		generate_printable_properties "${properties[*]}"
#		apply_new_properties
#
#		#(( properties[index + 2] -= separator ))
#		#(( properties[index + 2] /= 2 ))
#
#		read x y w h <<< ${wm_properties[*]}
#		~/.orw/scripts/set_geometry.sh -c '\\\*' -x $((x - display_x)) -y $((y - display_y)) -w $w -h $h
#
#		#generate_printable_properties "${properties[*]}"
#		#apply_new_properties
#
#		#print_wm_properties
#	else
#		if [[ $mode == stack ]]; then
#			align_index=$((opposite_index + 1))
#			properties=( $(list_all_windows | sort -nk $align_index,$align_index | tail -1) )
#		fi
#
#		[[ $close ]] && unset reverse
#
#		#eval aligned=( $(list_all_windows | awk '{
#		#		w = '${properties[3]}'
#		#		h = '${properties[4]}'
#		#		p = '${properties[opposite_index]}'
#		#	}
#		#	$('$opposite_index' + 1) == p && $4 == w && $5 == h { print "\"" $0 "\"" }' | \
#		#		sort -n${reverse}k $((index + 1)),$((index + 1))) )
#
#		#read alignment_start whole_area aligned_windows <<< \
#		#	$(list_all_windows | sort -n${reverse}k $((index + 1)),$((index + 1)) | \
#		#		awk '{
#		#			w = '${properties[3]}'
#		#			h = '${properties[4]}'
#		#			p = '${properties[opposite_index]}'
#		#		}
#		#		$('$opposite_index' + 1) == p && $4 == w && $5 == h {
#		#			if(!length(as)) as = $('$index' + 1)
#		#			aw = aw " \"" $0 "\""
#		#		} END { print as, $('$index' + 3) + $('$index' + 1) - as, aw }')
#
#		read alignment_start aligned_area aligned_windows <<< \
#			$(list_all_windows | sort -nk $((index + 1)),$((index + 1)) | \
#				awk '\
#					BEGIN {
#						i = '$index'
#						oi = '$opposite_index'
#						d = '${properties[index + 2]}'
#						od = '${properties[opposite_index + 2]}'
#						p = '${properties[opposite_index]}'
#					}
#					$(oi + 1) == p && od == $(oi + 3) && $(i + 3) - d <= awc++ {
#						if(!length(as)) as = $(i + 1)
#						aw = aw " \"" $0 "\""
#					} END { print as, $(i + 1) + $(i + 3) - as, aw }')
#
#		#eval aligned=( "${aligned_windows/${properties[*]}}" )
#		if [[ $close ]]; then
#			aligned_windows="${aligned_windows/\"${properties[*]}\"/}" 
#			#close_command="wmctrl -ic $id"
#			wmctrl -ic $id
#		fi
#
#		eval aligned=( "$aligned_windows" )
#
#		aligned_count="${#aligned[@]}"
#		#[[ $optarg =~ c$ ]] &&
#		#	ratio=$((aligned_count + 1))/$aligned_count ||
#		#	ratio=$aligned_count/$((aligned_count + 1))
#
#		if ((!separator)); then
#			border=${direction}_border
#			offset=${direction}_offset
#			separator=$(((${!border} + ${margin:-${!offset}})))
#		fi
#
#		#[[ $optarg =~ ^c ]] &&
#			#d_count=$((aligned_count + 1)) h_count=$aligned_count ||
#			#d_count=$aligned_count h_count=$((aligned_count - 1)) ||
#			#d_count=$((aligned_count - 1)) h_count=$aligned_count
#		#[[ ! $optarg =~ c$ ]] && d_count=$((aligned_count - 1)) h_count=$aligned_count
#		#[[ ! $optarg =~ c$ ]] && count_offset=1
#
#		#align_size=$((aligned_area - (aligned_count - count_offset) * (${properties[index + 2]} + separator)))
#		#align_size=$((aligned_area - (aligned_count - count_offset) * (align_size + separator)))
#
#		[[ $close ]] &&
#			align_size=$(((aligned_area - (aligned_count - 1) * separator) / aligned_count)) ||
#			align_size=$(((aligned_area - aligned_count * separator) / (aligned_count + 1)))
#
#		for window_index in "${!aligned[@]}"; do
#			properties=( ${aligned[window_index]} )
#
#			if ((window_index)); then
#				 properties[index]=$next_window_start
#			 else
#				 [[ $reverse ]] && (( properties[index] += align_size + separator )) || properties[index]=$alignment_start
#			fi
#
#			#if [[ $reverse ]]; then
#			#	original_align_property=${properties[index]}
#			#	[[ $wm_properties ]] && properties[index]=$((${wm_properties[index - 1]} + ${wm_properties[index + 1]} - ${properties[index + 2]}))
#			#else
#			#	#[[ $wm_properties ]] && properties[index]=${wm_properties[index - 1]}
#			#	((window_index)) && properties[index]=$next_window_start || properties[index]=$alignment_start
#			#fi
#
#			#((window_index)) || properties[index]=$alignment_start
#
#			#resize_by_ratio H $alignment_direction${reverse} $ratio
#
#			#(( properties[index + 2] += (aligned_count - count_offset) * (${properties[index + 2]} + separator) ))
#
#			#properties[index + 2]=$aligned_area
#			#resize_by_ratio H $alignment_direction$reverse $((aligned_count + count_offset))
#
#			#((window_index == aligned_count - 1)) &&
#			#	align_size=$((aligned_area - (alignment_start + aligned_area - ${properties[index]})))
#			#	#align_size=$((aligned_area - (window_index * (align_size + separator))))
#
#			[[ $close || $reverse ]] && ((window_index == aligned_count - 1)) &&
#				align_size=$((alignment_start + aligned_area - ${properties[index]}))
#				#align_size=$((aligned_area - ((aligned_count - 1) * (align_size + separator))))
#
#			properties[index + 2]=$align_size
#			next_window_start=$((${properties[index]} + ${properties[index + 2]} + separator))
#
#
#			#if [[ $optarg =~ ^c ]]; then
#			#	(( properties[index + 2] += aligned_count * ${properties[index + 2]} + separator) ))
#			#else
#			#	(( properties[index + 2] += (aligned_count - 1) * (${properties[index + 2]} + separator) ))
#			#	resize_by_ratio H $alignment_direction$reverse $((aligned_count + 1))
#			#	#(( properties[index + 2] -= aligned_count * separator ))
#			#	#(( properties[index + 2] /= aligned_count + 1 ))
#
#
#			##(( properties[index + 2] += (aligned_count - 1) * (${properties[index + 2]} + separator) ))
#			##(( properties[index + 2] -= aligned_count * (${properties[index + 2]} + separator) ))
#
#			#	#resize_by_ratio D $alignment_direction${reverse} $aligned_count
#			##	resize_by_ratio H $alignment_direction${reverse} $((aligned_count + 1))
#			#fi
#
#			#echo ${properties[*]}
#			generate_printable_properties "${properties[*]}"
#			apply_new_properties
#		done
#
#		if [[ ! $close ]]; then
#			if [[ $reverse ]]; then
#				properties[index]=$alignment_start
#				properties[index + 2]=$align_size
#			else
#				properties[index]=$next_window_start
#				properties[index + 2]=$((aligned_area - (aligned_count * (align_size + separator))))
#			fi
#
#			read x y w h <<< ${properties[*]:1}
#			~/.orw/scripts/set_geometry.sh -c '\\\*' -x $((x - display_x)) -y $((y - display_y)) -w $w -h $h
#		fi
#	fi
#
#	#align_size=$((aligned_area - (aligned_count * (align_size + separator))))
#	#echo $next_window_start $align_size
#	exit
#			#align_size=$((aligned_area - (window_index * (align_size + separator))))
#
#		#echo $aligned_count
#		#echo $alignment_start $aligned_area
#		#echo ${properties[index]}
#		#exit
#
#		wm_properties[index + 1]=${properties[index + 2]}
#		[[ $reverse ]] && wm_properties[index - 1]=$original_align_property
#		print_wm_properties
#		$close_command
#	#fi
#}

align() {
	# checking optional arguments
	[[ $optarg =~ m$ ]] && window_action=move
	[[ $optarg =~ c$ ]] && window_action=close
	[[ $optarg && ! $window_action ]] && alignment_direction=${optarg:0:1}

	if [[ $mode == selection ]]; then
		select_window_using_mouse

		(( second_window_properties[0] -= display_x ))
		(( second_window_properties[1] -= display_y ))

		read x y w h <<< ${second_window_properties[*]}
		~/.orw/scripts/set_geometry.sh -c '\\\*' -x $x -y $y -w $w -h $h
	else
		#((window_count)) || set_windows_properties $display_orientation
		#if there is any window/s, get its/their properties

		# set window properties (only in case there is any window opened)
		[[ $id == none ]] || set_windows_properties $display_orientation
		#[[ $id && ! $window_count ]] && set_windows_properties $display_orientation

		# if there are windows
		if ((window_count)); then
			#if [[ $mode == auto && $window_action != close ]]; then
			#	set_orientation_properties $display_orientation

			#	ratio=$(awk '/^(part|ratio)/ { if(!p) p = $NF; else { print p "/" $NF; exit } }' $config)
			#	resize_by_ratio H $alignment_direction$reverse $ratio

			#	generate_printable_properties "${properties[*]}"
			#	apply_new_properties

			#	read x y w h <<< ${wm_properties[*]}
			#	~/.orw/scripts/set_geometry.sh -c '\\\*' -x $x -y $y -w $w -h $h
			#else

			# save all windows before aligning
			#while read -r window_id printable_properties; do
			#	save_properties $window_id
			#done <<< $(list_all_windows)

			# if OPENED window should occupy whole dimension (widthe/height)
			if [[ $full && $window_action != close ]]; then
				set_orientation_properties $alignment_direction
				set_alignment_properties $alignment_direction

				# getting position (start, end, and width/height)
				read new_start new_opposite_start new_opposite_dimension <<< \
					$(list_all_windows | awk '\
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

								#ms = ("'$reverse'") ? '$offset' - '$separator' : me + '$separator'
								ms = ("'$reverse'") ? '$offset' : me + '$separator'
							}
						# set window start after furthest window end
						} END { print ms, mos, moe - mos }')

				#original_properties=( ${properties[*]} )
				#update_properties remove

				id=none
				properties[0]=$id
				properties[index]=$new_start
				properties[opposite_index]=$new_opposite_start
				# if window should be spawned before other windows (reverse), set its dimension to be negative of separtor value, because distance between windows should be equal to separator value, and window end is calculated by adding its dimension to its start, which will in this case be separator before first window's start
				[[ $reverse ]] && new_width=-$separator
				properties[index + 2]=${new_width:-0}
				properties[opposite_index + 2]=$new_opposite_dimension

				#echo $separator
				#echo ${properties[*]}
				#unset window_action
			else
				set_orientation_properties $display_orientation

				if [[ $mode == auto && $window_action != close ]]; then
					#align_ratio=$(echo "$ratio / $part" | bc -l)

					# if mode is equal to auto, select opposite of larger dimension
					((${properties[3]} > ${properties[4]})) &&
						alignment_direction=h || alignment_direction=v
				elif [[ $mode == stack && $window_action != close ]]; then
					# if windows are already splited into main and stack, align it with stack windows 
					if ((window_count > 2)); then
						[[ $alignment_direction == h ]] &&
							alignment_direction=v align_index=3 ||
							alignment_direction=h align_index=2

						((index++))
						#[[ $reverse ]] && stack_reverse=r
						# find last (or first, in case reverse is enabled) stack window
						properties=( $(list_all_windows |
							sort -nk $index,$index -nk $align_index${reverse:1:1},$align_index | tail -1) )
							#sort -nk ${index},${index}r -nk $align_index,$align_index |
							#head -1) )
						#properties=( $(list_all_windows | sort -nk $align_index,$align_index | tail -1) )
						id=${properties[0]}
					fi
				fi
			fi

				#((${#all_aligned_windows[*]})) || declare -A all_aligned_windows

				#[[ $window_action == close ]] && wmctrl -ic $id
				#~/.orw/scripts/notify.sh "$alignment_direction ${!all_aligned_windows[*]}"
				#exit

				# align windows according to corresponding action
				align_windows $window_action
				[[ $window_action == close ]] && wmctrl -ic $id &> /dev/null

				#~/.orw/scripts/notify.sh "aaw: ${!all_aligned_windows[*]}"
				#for i in ${!all_aligned_windows[*]}; do echo $i ${all_aligned_windows[$i]}; done
				#echo ${properties[*]}
				#echo $alignment_direction
				#exit

				#for window_id in ${!all_aligned_windows[*]}; do
				#	read x y w h <<< "${all_aligned_windows[$window_id]}"

				#	[[ $window_id == $original_properties ]] &&
				#		sed -i "/^$window_id/ s/.$/$alignment_direction/" $alignment_file
				#	[[ $window_id =~ ^0x ]] && wmctrl -ir $window_id -e 0,$x,$y,$w,$h ||
				#		echo $x $y $w $h $alignment_direction
				#		#~/.orw/scripts/set_geometry.sh -c '\\\*' -x $x -y $y -w $w -h $h
				#done
			#fi
		else
			# if there is no windows opened
			get_bar_properties
			read width height <<< $(awk '/^display_'${display:-1}' / { print $2, $3 }' $config)

			# set window properties to occupy all space between offsets
			x=$x_offset
			y=$((y_offset + bar_top_offset))
			w=$((width - 2 * x_offset - x_border))
			h=$((height - (bar_top_offset + bar_bottom_offset) - 2 * y_offset - y_border))

			if [[ $tiling ]]; then
				id=$original_properties
				properties=( $id $x $y $w $h )
				return
				#~/.orw/scripts/notify.sh "${!all_aligned_windows[*]}"
				#~/.orw/scripts/notify.sh "${properties[*]}"
				#exit
			else
				echo $x $y $w $h $alignment_direction
				exit
			fi
			#~/.orw/scripts/set_geometry.sh -c '\\\*' -x $x -y $y -w $w -h $h
		fi
	fi

	#[[ $new_desktop ]] && wmctrl -ir $original_properties -t $new_desktop
	#[[ $tiling ]] && wmctrl -ia $original_properties
	#echo $alignment_direction

	# restore original properties
	[[ $original_properties ]] && properties=( ${original_properties[*]} )
}

arguments="$@"
argument_index=1
options='(resize|move|tile)'

config=~/.config/orw/config
offsets_file=~/.config/orw/offsets
alignment_file=~/.config/orw/window_alignment
property_log=~/.config/orw/windows_properties

[[ ! -f $config ]] && ~/.orw/scripts/generate_orw_config.sh
[[ ! $current_desktop ]] && current_desktop=$(xdotool get_desktop)

#read mode part ratio alignment_direction {x,y}_border {x,y}_offset \
#	display_count display_orientation full use_ratio reverse <<< $(awk '\
#		/^(mode|part|ratio|direction|[xy]_(border|offset)) / { p = p " " $NF }
#		/^(full|use_ratio|reverse) / {
#			if($NF != "false") {
#				if(/^full/) f = $NF
#				else if(/^use/) ur = $NF
#				else r = $NF
#			}
#		}
#		/^display_[0-9] / { dc++ }
#		/^orientation / { o = substr($NF, 1, 1) }
#		END { print p, dc, o, f, ur, r }' $config | xargs)

#read mode part ratio full use_ratio reverse alignment_direction \
read mode part ratio use_ratio alignment_direction reverse full \
	{x,y}_border {x,y}_offset display_count display_orientation <<< $(awk '\
		/^(mode|part|ratio|full|use_ratio|reverse|direction|[xy]_(border|offset)) / { p = p " " $NF }
		/^display_[0-9] / { dc++ }
		/^orientation / { o = substr($NF, 1, 1) }
		END { print p, dc, o }' $config)

[[ $full == false ]] && unset full
[[ $reverse == false ]] && unset reverse
[[ $use_ratio == false ]] && unset use_ratio

# getting default size of opening window
new_window_size=$(awk -F '=' '/^new_window_size/ { print $NF }' ~/.orw/scripts/tile_windows.sh)

#read display_count {x,y}_offset display_orientation <<< $(awk '\
#	/^display_[0-9]/ { dc++ } /[xy]_offset/ { offsets = offsets " " $NF } /^orientation/ { o = substr($NF, 1, 1) }
#	END { print dc / 2, offsets, o }' $config)

[[ -f $offsets_file && $(awk '/^offset/ { print $NF }' $config) == true ]] && eval $(cat $offsets_file | xargs)
[[ ! $arguments =~ -[in] ]] && set_window_id $(printf "0x%.8x" $(xdotool getactivewindow))

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
				width=$(awk '/^display/ { width += $2; if ('$window_x' < width) { print $2; exit } }' $config)

				orientations=$(list_all_windows | sort -nk 2,4 -uk 2 | \
					awk '$1 ~ /^0x/ && $1 != "'$id'" {
						xo = '$x_offset'
						xb = '$x_border'
						m = '${margin:-$x_offset}'
						if(!x) x = '$display_x' + xo

						if($2 >= x) {
							x = $2 + $4 + xb + m
							w += $4; c++
						}
					} END {
						mw = '$width' - ((2 * xo) + (c * xb) + (c - 1) * m)
						if(mw - 1 > w && mw > w) print "h v"; else print "v h"
					}')
			fi

			for orientation in $orientations; do
				set_base_values $orientation
				tile
			done
		else
			[[ ! $previous_option =~ (resize|move) ]] && set_base_values $display_orientation
		fi
	else
		optarg=${!argument_index}
		[[ $argument =~ ^[SMCATRBLHDItrblhvjxymoiPdsrcp]$ &&
			! $optarg =~ ^(-[A-Za-z]|$options)$ ]] && ((argument_index++))

		case $argument in
			C) select_window_using_mouse;;
			A)
				((${#all_aligned_windows[*]})) || declare -A all_aligned_windows
				align;;
			[TRBLHD])
				if [[ ! $option ]]; then
					if [[ $argument == R ]]; then
						set_windows_properties $display_orientation

						while read -r id properties; do
							printable_properties=$(backtrace_properties)
							apply_new_properties
						done <<< $(list_all_windows)
						exit
					else
						#specified_desktop=true
						#previous_desktop=$current_desktop
						#current_desktop=$optarg

						#if [[ ! $properties ]]; then
						#	[[ $id ]] || id=$(get_windows | awk 'NR == 1 { print $1 }')
						#		#properties=( $(get_windows $id) ) ||
						#		#id=$(get_windows | awk 'NR == 1 { print $1 }')
						#	set_windows_properties
						#	#echo ${properties[*]}
						#	#exit
						#fi

						[[ $arguments =~ -t ]] &&
							new_desktop=$optarg || current_desktop=$optarg

						if [[ ! $properties ]]; then
							[[ $id ]] || id=$(get_windows | awk 'NR == 1 { print $1 }')
								#properties=( $(get_windows $id) ) ||
								#id=$(get_windows | awk 'NR == 1 { print $1 }')
							set_windows_properties
							#echo ${properties[*]}
							#exit
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
									wm = $i; b = ($2 ~ /^0x/) ? '$border' : $7

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
							resize_by_ratio $argument $optarg $ratio

							#[[ $optarg =~ r$ ]] && optarg=${optarg:0:1} reverse=true ||
							#	reverse=$(awk '/^reverse/ { print $NF }' $config)

							#if [[ ${optarg:0:1} == a ]]; then
							#	((${properties[3]} > ${properties[4]})) && optarg=h || optarg=v
							#	((ratio)) ||
							#		#ratio=$(awk '/^(part|ratio)/ { if(!p) p = $NF; else { print p "/" $NF; exit } }' $config)
							#		ratio=$(awk '/^(part|ratio)/ { if(!r) r = $NF; else { print $NF "/" r; exit } }' $config)

							#	auto_tile=true
							#	argument=H
							#fi

							#set_orientation_properties $optarg

							##[[ ${!argument_index} =~ ^[2-9/]+$ ]] && ratio=${!argument_index} && shift || ratio=2

							##if [[ ${!argument_index} =~ ^[2-9] ]]; then
							##	ratio=${!argument_index}
							##	shift
							##else
							##	ratio=2
							##fi

							#[[ ${ratio:=2} =~ / ]] && part=${ratio%/*} ratio=${ratio#*/}

							#[[ $argument == D ]] && op1=* op2=+ || op1=/ op2=-
							#[[ $optarg == h ]] && direction=x || direction=y

							#border=border_$direction
							#offset=${direction}_offset
							#separator=$(((${!border} + ${margin:-${!offset}})))

							#original_start=${properties[index]}
							#original_property=${properties[index + 2]}
							##total_separation=$(((ratio - 1) * (${!border} + ${!offset})))

							##(( properties[index + 2] $op2= (ratio - 1) * separator ))
							##(( properties[index + 2] $op1= ratio ))

							##[[ $argument == H ]] && (( properties[index + 2] -= (ratio - 1) * separator ))
							##(( properties[index + 2] $op1= ratio ))
							##[[ $argument == D ]] && (( properties[index + 2] += (ratio - 1) * separator ))

							#if [[ $argument == H || $part ]]; then
							#	portion=$((original_property - (ratio - 1) * separator))
							#	(( portion /= ratio ))

							#	#(( properties[index + 2] -= (ratio - 1) * separator ))
							#	#(( properties[index + 2] /= ratio ))

							#	if [[ $part ]]; then
							#		(( portion *= part ))
							#		(( portion += (part - 1) * separator ))
							#	fi

							#	#[[ $argument == D ]] && size_direction=- && (( portion += separator ))

							#	#properties[index + 2]=$portion
							#	#[[ $reverse ]] && (( properties[index] ${size_direction:-+}= original_property - (portion ) ))





							#	if [[ $argument == H ]]; then
							#		properties[index + 2]=$portion
							#		[[ $reverse == true ]] && (( properties[index] += original_property - portion ))
							#	else
							#		#[[ $argument == D ]] && (( properties[index + 2] += separator + original_property ))
							#		(( properties[index + 2] += portion + separator ))
							#		[[ $reverse == true ]] && (( properties[index] -= portion + separator ))
							#	fi





							#	#[[ $reverse ]] && (( properties[index] ${size_direction:-+}= portion + separator ))

							#	#if [[ $argument == H ]]; then
							#	#	[[ $reverse ]] && (( properties[index] += portion + separator ))
							#	#else
							#	#	#[[ $argument == D ]] && (( properties[index + 2] += separator + original_property ))
							#	#	properties[index + 2]=$((portion + separator))
							#	#	[[ $reverse ]] && (( properties[index] -= portion + separator ))
							#	#fi
							#else
							#	#(( properties[index + 2] *= ratio ))
							#	#(( properties[index + 2] += (ratio - 1) * separator ))
							#	portion=$(((original_property + separator) * (ratio - 1)))
							#	(( properties[index + 2] += portion ))
							#	[[ $reverse == true ]] && (( properties[index] -= portion ))
							#fi

							#if [[ $auto_tile ]]; then
							#	#read $reverse tiling_properties <<< $(awk '{
							#	awk '{
							#			d = '$display'
							#			x = '$display_x'
							#			y = '$display_y'
							#			r = "'$reverse'"
							#			s = '$separator'
							#			o = "'$display_orientation'"

							#			$('$index' + 1) -= (o == "h") ? x : y

							#			p = $('$index' + 3) + s
							#			$('$index' + 3) = '$original_property' - p
							#			$('$index' + 1) = (r == "true") ? '$original_start' : $('$index' + 1) + p
							#			sub(/[^ ]* /, "")
							#			print d, $0
							#		}' <<< "${properties[*]}"

							#	#((reverse_property)) && (( properties[index] += reverse_property ))
							#	#echo ${tiling_properties[*]}
							#fi
					esac

					update_properties
					unset max
				fi;;
			I)
				step=120

				properties=( $(get_windows $id) )
				original_properties=( ${properties[*]} )
				get_display_properties $display_orientation
				get_bar_properties

				x_start=$((display_x + x_offset))
				x_end=$((display_x + width - x_offset))
				y_start=$((display_y + y_offset + bar_top_offset))
				y_end=$((display_y + height - (y_offset + bar_bottom_offset)))

				read x y w h <<< ${properties[*]:1}

				source ~/.orw/scripts/window_osd_interaction.sh

				set_geometry
				listen_input
				properties=( $id $x $y $w $h )
				#wmctrl -ir $id -e 0,$x,$y,$w,$h

				update_properties

				[[ $mode != floating ]] && align_adjacent;;
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
						option=move
						calculate_size
						option=resize

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
			i) set_window_id $optarg;;
			P)
				closing_properties=true
				properties=( $id $optarg )
				#(( properties[1] -= x_border ))
				#(( properties[2] -= y_border ))
				all_windows=( "${properties[*]}" );;
			n)
				name="$optarg"
				id=$(wmctrl -lG | awk '$NF ~ "'$name'" { print $1 }')

				if [[ $id ]]; then
					set_window_id $id
					properties=( $(get_windows $id) )
				else
					#set_windows_properties $display_orientation
					#id="$name"
					get_bar_properties add
					properties=( $(list_all_windows | grep "$name") )
					#set_windows_properties $display_orientation
				fi;;
			D) current_desktop=$optarg;;
			d) display=$optarg;;
			[trbl])
				if [[ ! $option ]]; then
					case $argument in
						b) bar_offset=true;;
						r)
							properties=( $id $(backtrace_properties) )
							update_properties;;
						t)
							##alignment_direction=v
							##reverse=true

							##[[ $reverse ]] && reverse_align=-r

							#set_windows_properties $display_orientation
							#set_orientation_properties $display_orientation

							#read mode alignment_direction opposite_direction index opposite_index display_property reverse <<< \
							#	$(awk '{
							#		if(/^mode/) m = $NF
							#		else if(/^reverse/) r = ($NF == "true") ? "r" : ""
							#		else if(/^direction/) {
							#			p = ($NF == "h") ? "v 1 2 '$display_x'" : "h 2 1 '$display_y'"
							#			print m, $NF, p, r
							#		}
							#	}' $config)

							#if [[ $mode == auto || ${#all_windows[*]} -eq 1 ]]; then
							#	[[ $mode == auto ]] && alignment_direction=a
							#	[[ $mode == stack ]] && unset reverse
							#	resize_by_ratio H ${opposite_direction:-$alignment_direction}$reverse

							#	generate_printable_properties "${properties[*]}"
							#	apply_new_properties

							#	print_wm_properties
							#else
							#	if [[ $mode == stack ]]; then
							#		align_index=$((opposite_index + 1))
							#		properties=( $(list_all_windows | sort -nk $align_index,$align_index | tail -1) )
							#	fi

							#	eval aligned=( $(list_all_windows | awk '{
							#			w = '${properties[3]}'
							#			h = '${properties[4]}'
							#			p = '${properties[opposite_index]}'
							#		}
							#		$('$opposite_index' + 1) == p && $4 == w && $5 == h { print "\"" $0 "\"" }' | \
							#			sort -n${reverse}k $((index + 1)),$((index + 1))) )

							#	aligned_count="${#aligned[@]}"
							#	ratio=$aligned_count/$((aligned_count + 1))

							#	for window in "${aligned[@]}"; do
							#		properties=( $window )

							#		if [[ $reverse ]]; then
							#			original_align_property=${properties[index]}
							#			[[ $wm_properties ]] && properties[index]=$((${wm_properties[index - 1]} + ${wm_properties[index + 1]} - ${properties[index + 2]}))
							#		else
							#			[[ $wm_properties ]] && properties[index]=${wm_properties[index - 1]}
							#		fi

							#		resize_by_ratio H $alignment_direction${reverse} $ratio

							#		generate_printable_properties "${properties[*]}"
							#		apply_new_properties
							#	done

							#	wm_properties[index + 1]=${properties[index + 2]}
							#	[[ $reverse ]] && wm_properties[index - 1]=$original_align_property
							#	print_wm_properties
							#	#echo ${wm_properties[*]}
							#fi

							#mode=stack

							#if [[ $specified_desktop ]]; then
							#	wmctrl -s $current_desktop

							#	if [[ $mode == stack ]]; then
							#		echo stack
							#	else
							#		select_window &> /dev/null
							#	fi
							#fi

							#[[ $second_window_properties ]] || get_neighbour_window_properties $optarg

							#original_properties=( ${properties[*]} )
							#second_window_id=${second_window_properties[0]}

							#properties=( ${second_window_properties[*]} )

							#echo ${original_properties[*]}
							#echo ${properties[*]}
							#exit

							tiling=true

							set_windows_properties $display_orientation
							set_orientation_properties $display_orientation

							# assigning optional alignment argument
							[[ $optarg == [hv] ]] && alignment_direction=$optarg

							#optind=${!argument_index}
							#[[ $optind == [hv] ]] && alignment_direction=$optind

#							read mode alignment_direction reverse <<< $(\
#								awk '{
#									if(/^mode/) m = $NF
#									else if(/^reverse/) r = ($NF == "true") ? "r" : ""
#									else if(/^direction/) d = ("'$alignment_direction'") ? "'$alignment_direction'" : $NF
#									} END { print m, d, r }' $config)


							if [[ $mode == tiling ]]; then
								use_ratio=true
								# basking up original properties
								original_properties=( ${properties[*]} )

								declare -A all_aligned_windows
								#align_windows move

								#for wi in ${!all_aligned_windows[*]}; do echo $wi ${all_aligned_windows[$wi]}; done
								#exit

								#if ((new_desktop)); then
								#	unset all_windows
								#	wmctrl -s $new_desktop
								#	set_windows_properties $display_orientation $new_desktop
								#	#list_all_windows
								#	#exit
								#fi

								# if window to which selected window should be tiled to is on a different workspace
								if [[ $new_desktop ]]; then
									# remove original window from the current workspace, and align the rest of the windows
									align_windows move

									# unset windows (ones from the current workspace) and set window properties on the new workspace
									unset all_windows window_count
									wmctrl -s $new_desktop
									set_windows_properties $display_orientation $new_desktop
								fi

								#((new_desktop)) && wmctrl -s $new_desktop

								#full=true

								# check if new workspace is empty
								if ((window_count)); then
									if [[ ! $full && ! $second_window_properties ]]; then
										# let user select window to which should selected window tile to
										select_window

										# if selected window is on the same workspace, remove original window from the workspace, and align the rest of the windows
										[[ $new_desktop ]] || align_windows move

										# set id and properties
										id=$second_window_id
										properties=( $second_window_id ${second_window_properties[*]} )
										#~/.orw/scripts/notify.sh "HERE"
									fi
								else
									id=none
								fi

								#~/.orw/scripts/notify.sh "id: $id, ${properties[*]}"
								#exit

								#for i in ${!all_aligned_windows[*]}; do echo ${all_aligned_windows[$i]}; done
								#exit

								#[[ $new_desktop ]] || align_windows move

								align
								#for i in ${!all_aligned_windows[*]}; do echo ${all_aligned_windows[$i]}; done
								#exit
								continue

								((new_desktop)) && wmctrl -ir $original_properties -t $new_desktop
								exit

								#unset all_windows
								#id=$second_window_id
								##properties=( $second_window_id ${second_window_properties[*]} )
								#set_windows_properties $display_orientation $new_desktop
								##list_all_windows

								#properties=( $second_window_id ${second_window_properties[*]} )
								align_windows

								for window_id in ${!all_aligned_windows[*]}; do
									read x y w h d <<< "${all_aligned_windows[$window_id]}"
									[[ $window_id =~ ^0x ]] && echo wmctrl -ir $window_id -e 0,$x,$y,$w,$h ||
										~/.orw/scripts/set_geometry.sh -c '\\\*' -x $x -y $y -w $w -h $h

									#sed -i "/^$window_id/ s/.$/$d/" $alignment_file
								done
								#for wi in ${!all_aligned_windows[*]}; do echo $wi ${all_aligned_windows[$wi]}; done
								exit
							fi

							if [[ $mode == tiling ]]; then
								window_action=move
								align
								exit
								get_alignment
								align_windows

								generate_printable_properties "$original_properties $x $y $w $h"
								apply_new_properties

								#if [[ $mode == auto ]]; then
								#	ratio=$(awk '/^(part|ratio)/ { if(!p) p = $NF; else { print p "/" $NF; exit } }' $config)
								#	resize_by_ratio H $alignment_direction$reverse $ratio
								#else
								#fi
							else
								[[ $mode == auto ]] &&
									ratio=$(awk '/^(part|ratio)/ { if(!p) p = $NF; else { print p "/" $NF; exit } }' $config)

								resize_by_ratio H $alignment_direction$reverse $ratio

								generate_printable_properties "${properties[*]}"
								apply_new_properties

								generate_printable_properties "$original_properties ${wm_properties[*]}"
								apply_new_properties

								[[ $mode == floating ]] && exit
								#properties=( $original_properties ${wm_properties[*]} )
							fi

							properties=( ${original_properties[*]} )

							restore_alignment
							align_windows close

							exit

							resize_by_ratio H ${alignment_direction:-a}

							generate_printable_properties "${properties[*]}"
							apply_new_properties

							properties=( $original_properties ${wm_properties[*]} )

							[[ $specified_desktop ]] && wmctrl -i -r $original_properties -t $current_desktop

							#new_properties=( $original_id $(align | cut -d ' ' -f 2-) )

							#(( new_properties[1] += display_x ))
							#(( new_properties[2] += display_y ))

							#properties=( ${new_properties[*]} )

							#echo ${properties[*]}

							#new_properties=( $original_id $(align) )

							#properties=( $id ${new_properties[*]:1} )

							#new_properties=( $($0 -i ${second_window_properties[0]} resize -H a$optarg) )
							#properties=( $id ${new_properties[*]:1} )
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
						resize $argument
					fi

					update_properties

					[[ $mode != floating ]] && align_adjacent
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

				get_bar_properties add

				if [[ $second_window_properties ]]; then
					second_window_properties=( ${second_window_properties[*]:1} )
					optind=$optarg
				else
					case $optarg in
						[trbl])
							#get_neighbour_window_properties $optarg;;
							select_window;;
							#second_window_properties=( $(get_neighbour_window_properties $optarg) );;
							#[[ $optarg =~ [lr] ]] && index=1 || index=2
							#[[ $optarg =~ [br] ]] && reverse=-r

							#start_index=$((index % 2 + 1))
							#second_window_properties=( $(sort_windows $optarg | sort $reverse -nk 1,1 | awk \
							#	'{ cwp = '${properties[index]}'; cwsp = '${properties[start_index]}'; \
							#	if("'$optarg'" ~ /[br]/) cwp += '${properties[index + 2]}'; \
							#		wp = $1; wsp = $('$start_index' + 2); xd = (cwsp - wsp) ^ 2; yd = (cwp - wp) ^ 2; \
							#		print sqrt(xd + yd), $0 }' | sort -nk 1,1 | awk 'NR == 2 \
							#		{ if(NF > 7) { $6 += ($NF - '$x_border'); $7 += ($NF - '$y_border')}
							#		print gensub("(.*" $3 "|" $8 "$)", "", "g") }') );;
						*)
							[[ $optarg =~ ^0x ]] && mirror_window_id=$optarg ||
								mirror_window_id=$((wmctrl -l && list_bars) |\
								awk '{
									wid = (/^0x/) ? $NF : $1
									if(wid == "'$optarg'") {
										print $1
										exit
									}
								}')

							second_window_properties=( $(list_all_windows | \
								awk '$1 == "'$mirror_window_id'" {
									if(NF > 5) { $4 += ($NF - '${x_border:=0}'); $5 += ($NF - '${y_border:=0}') }
										print gensub("(" $1 "|" $6 "$)", "", "g") }') )
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
							mirror_border=${specific_mirror_property:0:1}_border

							if [[ $specific_mirror_property =~ ee ]]; then
								mirror_value=$((second_window_properties[second_window_property_index] + (${second_window_properties[second_window_property_index + 2]} - ${properties[second_window_property_index + 3]})))
							else
								[[ ${specific_mirror_property:1:1} == s ]] &&
									mirror_value=$((second_window_properties[second_window_property_index] - (${properties[second_window_property_index + 3]} + ${!mirror_border:-0}))) ||
									mirror_value=$((second_window_properties[second_window_property_index] + (${second_window_properties[second_window_property_index + 2]} + ${!mirror_border:-0})))
							fi
						fi

						if [[ $specific_mirror_property =~ [+-/*] ]]; then
							read operation operand additional_operation additional_operand<<< \
								$(sed 's/\w*\(.\)\([^+-]*\)\(.\)\?\(.*\)/\1 \2 \3 \4/' <<< $specific_mirror_property)
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

					swap_windwow_properties=( $(sort_windows $optarg | sort $reverse -nk 1,1 | \
						awk '{ si = '$start_index'; sp = $(si + 2); csp = '${properties[start_index]}'; \
						print (csp > sp) ? csp - sp : sp - csp, $0 }' | sort $reverse -nk 2,2 -nk 1,1$start_reverse | \
						awk '{ if($3 == "'$id'") { print p; exit } else { gsub(/.*0x/, "0x", $0); p = $0 } }') )

					original_properties=( ${properties[*]} )
					printable_properties="${swap_windwow_properties[*]:1}"

					apply_new_properties
					id=${swap_windwow_properties[0]}
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
				if ((${#properties[*]} > 5)); then
					[[ $display_orientation == h ]] && index=1 || index=2
					get_display_properties $index
					awk '{
						if(NF > 5 && $3 < 0) $3 += '$display_y' + '$height'
						print
					}' <<< ${properties[*]}
				else
					if [[ $second_window_properties ]]; then
						[[ ! $properties ]] && properties=( ${second_window_properties[*]} )

						[[ $display_orientation == h ]] && index=1 || index=2
						get_display_properties $index

						properties=( ${properties[*]:1} )

						(( properties[0] -= display_x ))
						(( properties[1] -= display_y ))
					fi

					echo -n "$x_border $y_border "
					[[ $properties ]] && echo ${properties[*]} ||
						get_windows ${id:-$name} | cut -d ' ' -f 2-
				fi
				exit;;
			o) overwrite=true;;
			a) align_adjacent;;
			?) continue;;
		esac
	fi
done

generate_printable_properties "${properties[*]}"
apply_new_properties

# iterate through all windows which should be aligned, and apply new properties
if ((${#all_aligned_windows[*]})); then
	for window_id in ${!all_aligned_windows[*]}; do
		read x y w h <<< "${all_aligned_windows[$window_id]}"

		#~/.orw/scripts/notify.sh "$window_id $x,$y,$w,$h"

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
