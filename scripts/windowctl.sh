#!/bin/bash

blacklist="Keyboard Status Monitor,DROPDOWN"

set_window_id() {
	id=$1

	read border_x border_y <<< $([[ $id =~ ^0x ]] && xwininfo -id $id | awk '\
		/Relative/ { if(/X/) x = $NF; else y = $NF + x } END { print 2 * x, y }')
}

function get_windows() {
	wmctrl -lG | awk '$2 == '$current_desktop' && ! /('"${blacklist//,/|}"')$/ && $1 ~ /'$1'/ \
		{ print $1, $3 - '${border_x:=0}', $4 - ('${border_y:=0}' - '$border_x' / 2) * 2, $5, $6 }'
}

function set_windows_properties() {
	[[ ! $properties ]] && properties=( $(get_windows $id) )

	[[ $1 == h ]] && index=1 || index=2
	get_display_properties $index

	if [[ ! $all_windows ]]; then
		while read -r wid wx wy ww wh; do
			if ((wx > display_x && wx + ww < display_x + width && wy > display_y && wy + wh < display_y + height)); then
				all_windows+=( "$wid $wx $wy $ww $wh" )
			fi
		done <<< $(get_windows)
	fi
}

function update_properties() {
	for window_index in "${!all_windows[@]}"; do
		[[ ${all_windows[window_index]%% *} == $id ]] && all_windows[window_index]="${properties[*]}"
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
	echo $id $printable_properties >> $property_log
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
		border=${edge_border:-$border_x}
		bar_vertical_offset=0
	else
		index=2
		dimension=height
		offset=$y_offset
		step=$font_height
		start=$display_y
		opposite_dimension=width
		opposite_start=$display_x
		border=${edge_border:-$border_y}
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

	[[ $adjucent && $edge =~ [rt] ]] && reverse_adjucent=-r
}

function resize_to_edge() {
	index=$1
	offset=$2

	((index > 1)) && border=$border_y || border=$border_x

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

tile_adjucent() {
	((index == 1)) && orientation=h || orientation=v

	old_properties=( ${original_properties[*]} )

	for property_index in {1..4}; do
		new_property=${properties[property_index]}
		old_property=${old_properties[property_index]}
		((new_property != old_property)) && break
	done

	((property_index > 2)) && ra=-r

	option=tile
	set_base_values $orientation

	get_adjucent() {
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

						#system("~/.orw/scripts/notify.sh " c)

						if((cp == c) &&
							((ws >= cws && ws <= cwe) ||
							(we >= cws && we <= cwe) ||
							(ws <= cws && we >= cwe))) print
					}
				}
			}'
	}

	add_adjucent_window() {
		properties=( $1 )
		id=${properties[0]}
		original_properties=( ${properties[*]} )

		tile

		update_properties
		adjucent_windows+=( "${properties[*]}" )
	}

	find_neighbour() {
		while read -r c window; do
			if [[ $c ]]; then
				add_adjucent_window "$window"

				[[ $2 ]] && ra='' || ra=-r
				original_id=${1%% *}
				find_neighbour "$window" $ra
			fi
		done <<< $(get_adjucent "$1" $2)
	}

	find_neighbour "${old_properties[*]}" $ra
	for window in "${adjucent_windows[@]}"; do
		generate_printable_properties "$window"
		apply_new_properties
	done
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
	fi
}

get_optarg() {
	((argument_index++))
	optarg=${!argument_index}
}

arguments="$@"
argument_index=1
options='(resize|move|tile)'

config=~/.config/orw/config
offsets_file=~/.config/orw/offsets
property_log=~/.config/orw/windows_properties

[[ ! -f $config ]] && ~/.orw/scripts/generate_orw_config.sh
[[ ! $current_desktop ]] && current_desktop=$(xdotool get_desktop)

#read x_offset y_offset <<< $(awk '/offset/ {print $NF}' $config | xargs)

#display_count=$(awk '/^display_[0-9]/ { dc++ } END { print dc / 2 }' $config)
#display_orientation=$(awk '/^orientation/ { print substr($NF, 1, 1) }' $config)

read display_count {x,y}_offset orientation <<< $(awk '\
	/^display_[0-9]/ { dc++ } /offset/ { offsets = offsets " " $NF } /^orientation/ { o = substr($NF, 1, 1) }
	END { print dc / 2, offsets, o }' $config)

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
						xb = '$border_x'
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
		[[ $argument =~ ^[SRMTRBLHDtrblhvjxymoidsrcp]$ &&
			! $optarg =~ ^(-[A-Za-z]|$options)$ ]] && ((argument_index++))

		case $argument in
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
						current_desktop=$optarg

						if [[ ! $properties ]]; then
							id=$(get_windows | awk 'NR == 1 { print $1 }')
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
					((!max)) && offset=${!offset_orientation} ||
						offset=${margin:-${!offset_orientation}}

					case $argument in
						L) [[ $option == resize ]] && resize_to_edge 1 $offset || 
							properties[1]=$((${max:-$start} + offset));;
						T) [[ $option == resize ]] && resize_to_edge 2 $offset || 
							properties[2]=$((${max:-$start} + offset));;
						R) [[ $option == resize ]] && resize_to_edge 1 $offset ||
							properties[1]=$((${max:-$end} - offset - ${properties[3]} - border_x));;
						B) [[ $option == resize ]] && resize_to_edge 2 $offset ||
							properties[2]=$((${max:-$end} - offset - ${properties[4]} - border_y));;
						*)
							if [[ $optarg == a ]]; then
								((${properties[3]} > ${properties[4]})) && optarg=h || optarg=v
								auto_tile=true
								argument=H
							fi

							set_orientation_properties $optarg

							#[[ ${!argument_index} =~ ^[2-9/]+$ ]] && ratio=${!argument_index} && shift || ratio=2

							#if [[ ${!argument_index} =~ ^[2-9] ]]; then
							#	ratio=${!argument_index}
							#	shift
							#else
							#	ratio=2
							#fi

							[[ ${!argument_index} =~ ^[1-9] ]] && ratio=${!argument_index} && shift || ratio=2
							[[ $ratio =~ / ]] && multiplier=${ratio%/*} ratio=${ratio#*/}

							[[ $argument == D ]] && op1=* op2=+ || op1=/ op2=-
							[[ $optarg == h ]] && direction=x || direction=y

							border=border_$direction
							offset=${direction}_offset
							separator=$(((${!border} + ${!offset})))
							original_property=${properties[index + 2]}
							#total_separation=$(((ratio - 1) * (${!border} + ${!offset})))

							#(( properties[index + 2] $op2= (ratio - 1) * separator ))
							#(( properties[index + 2] $op1= ratio ))

							#[[ $argument == H ]] && (( properties[index + 2] -= (ratio - 1) * separator ))
							#(( properties[index + 2] $op1= ratio ))
							#[[ $argument == D ]] && (( properties[index + 2] += (ratio - 1) * separator ))

							if [[ $argument == H || $multiplier ]]; then
								(( properties[index + 2] -= (ratio - 1) * separator ))
								(( properties[index + 2] /= ratio ))

								if [[ $multiplier ]]; then
									(( properties[index + 2] *= multiplier ))
									(( properties[index + 2] += (multiplier - 1) * separator ))

									[[ $argument == D ]] && (( properties[index + 2] += separator + original_property ))
								fi
							else
								(( properties[index + 2] *= ratio ))
								(( properties[index + 2] += (ratio - 1) * separator ))
							fi

							if [[ $auto_tile ]]; then
								#awk '{ $('$index' + 1) += $('$index' + 3) + '$total_separation'; print }' <<< "${properties[*]}"
									#$('$index' + 1) += $('$index' + 3) + '$total_separation'
									#$('$index' + 1) = '$original_propertiy' + ($('$index' + 3) + '${!border}' + '${!offset}')
									#print "'$0' move -h " $2 " -v " $3 " resize -h " $4 " -v " $5 }' <<< "${properties[*]}"
								awk '{
									p = $('$index' + 3) + '${!border}' + '${!offset}'
									$('$index' + 3) = '$original_property' - p
									$('$index' + 1) += p
									sub(/[^ ]* /, "")
									print
								}' <<< "${properties[*]}"
							fi
					esac

					update_properties
					unset max
				fi;;
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
						properties[1]=$((display_x + (width - (${properties[3]} + border_x)) / 2))
					else
						y=$((display_y + bar_top_offset))
						bar_vertical_offset=$((bar_top_offset + bar_bottom_offset))
						properties[2]=$((y + ((height - bar_vertical_offset) - (${properties[4]} + border_y)) / 2))
					fi
				done

				update_properties;;
			i) set_window_id $optarg;;
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
					window_y=$((display_y + bar_top_offset + y_offset + row * (window_height + border_y + ${margin:-$y_offset})))

					if ((row + 1 == middle_row)); then
						row_columns=$middle_row_columns
						x_start=$middle_start
					else
						row_columns=$columns
						x_start=$x_offset
					fi

					for column in $(seq 0 $((row_columns - 1))); do
						id=${grid_windows[window_index]%% *}

						window_x=$((display_x + x_start + column * (window_width + border_x + ${margin:-$x_offset})))

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

				case $optarg in
					[trbl])
						[[ $optarg =~ [lr] ]] && index=1 || index=2
						[[ $optarg =~ [br] ]] && reverse=-r

						start_index=$((index % 2 + 1))
						mirror_window_properties=( $(sort_windows $optarg | sort $reverse -nk 1,1 | awk \
							'{ cwp = '${properties[index]}'; cwsp = '${properties[start_index]}'; \
							if("'$optarg'" ~ /[br]/) cwp += '${properties[index + 2]}'; \
								wp = $1; wsp = $('$start_index' + 2); xd = (cwsp - wsp) ^ 2; yd = (cwp - wp) ^ 2; \
								print sqrt(xd + yd), $0 }' | sort -nk 1,1 | awk 'NR == 2 \
								{ if(NF > 7) { $6 += ($NF - '$border_x'); $7 += ($NF - '$border_y')}
								print gensub("(.*" $3 "|" $8 "$)", "", "g") }') );;
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

						mirror_window_properties=( $(list_all_windows | \
							awk '$1 == "'$mirror_window_id'" {
								if(NF > 5) { $4 += ($NF - '${border_x:=0}'); $5 += ($NF - '${border_y:=0}') }
									print gensub("(" $1 "|" $6 "$)", "", "g") }') )
				esac

				if [[ $optind =~ ^[xseywh,+-/*0-9]+$ ]]; then
					for specific_mirror_property in ${optind//,/ }; do 
						unset operation operand additional_{operation,operand} mirror_value

						case $specific_mirror_property in
							x*) mirror_window_property_index=0;;
							y*) mirror_window_property_index=1;;
							w*) mirror_window_property_index=2;;
							h*) mirror_window_property_index=3;;
						esac

						if [[ ${specific_mirror_property:1:1} =~ [se] ]]; then
							mirror_border=border_${specific_mirror_property:0:1}

							if [[ $specific_mirror_property =~ ee ]]; then
								mirror_value=$((mirror_window_properties[mirror_window_property_index] + (${mirror_window_properties[mirror_window_property_index + 2]} - ${properties[mirror_window_property_index + 3]})))
							else
								[[ ${specific_mirror_property:1:1} == s ]] &&
									mirror_value=$((mirror_window_properties[mirror_window_property_index] - (${properties[mirror_window_property_index + 3]} + ${!mirror_border:-0}))) ||
									mirror_value=$((mirror_window_properties[mirror_window_property_index] + (${mirror_window_properties[mirror_window_property_index + 2]} + ${!mirror_border:-0})))
							fi
						fi

						if [[ $specific_mirror_property =~ [+-/*] ]]; then
							read operation operand additional_operation additional_operand<<< \
								$(sed 's/\w*\(.\)\([^+-]*\)\(.\)\?\(.*\)/\1 \2 \3 \4/' <<< $specific_mirror_property)
							((operand)) &&
								mirror_value=$((${mirror_value:-${mirror_window_properties[mirror_window_property_index]}} $operation operand))
							((additional_operand)) &&
								mirror_value=$((${mirror_value:-${mirror_window_properties[mirror_window_property_index]}} $additional_operation additional_operand))

							if [[ $specific_mirror_property =~ [+-]$ ]]; then
								((properties[mirror_window_property_index + 1] ${specific_mirror_property: -1}= ${mirror_value:-${mirror_window_properties[mirror_window_property_index]}}))
								continue
							fi
						fi

						properties[mirror_window_property_index + 1]=${mirror_value:-${mirror_window_properties[mirror_window_property_index]}}
					done

					shift
				elif ((${#mirror_window_properties[*]})); then
					index_property=${properties[index]}

					properties=( $id )
					properties+=( ${mirror_window_properties[*]:0:index - 1} )
					properties+=( $index_property )
					properties+=( "${mirror_window_properties[*]:index}" )
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

					if [[ $argument == S ]]; then
						while read -r id printable_properties; do
							save_properties
						done <<< $(list_all_windows)
					else
						generate_printable_properties "${properties[*]}"
						save_properties
					fi
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
					echo -n "$border_x $border_y "

					[[ $properties ]] && echo ${properties[*]} ||
						get_windows ${id:-name} | cut -d ' ' -f 2-
				fi
				exit;;
			o) overwrite=true;;
			a) adjucent=true;;
			?) continue;;
		esac
	fi
done

generate_printable_properties "${properties[*]}"
apply_new_properties

if [[ $adjucent ]]; then
	tile_adjucent
fi
