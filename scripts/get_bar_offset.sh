#!/bin/bash

while getopts :podc: flag; do
	case $flag in
		d) delta=true;;
		p) print=true;;
		o) offset=true;;
		#c) count=$OPTARG;;
		c)
			until (($(ps -C lemonbar -o pid= | wc -l) == OPTARG)); do
				sleep 0.1
			done;;
	esac
done

#if [[ $flag ]]; then
#	if [[ $flag == d ]]; then
#		bar_name=$OPTARG
#	else
#		[[ $flag == p ]] && print=true || offset=true
#	fi
#fi

#[[ $print || $offset || $bar_name ]] || sleep 1
#[[ $print || $offset || $delta ]] || sleep 1

config=~/.config/orw/config

eval $(awk -F '[_ ]' '/^display/ {
		if($3 == "xy") o = o " [" $2 "]=\"" $4
		else if($3 == "size") o = o " " $4 "\""
	} END { print "displays=( " o " )" }' $config)

eval bars=( $(ps -C lemonbar -o args= | awk '{ ab = ab " \"" $0 "\"" } END { print ab }') )

for display in ${!displays[*]}; do
	top_offset=0 bottom_offset=0
	read min max <<< ${displays[$display]}

	while read name position bar_x bar_y bar_widht bar_height frame; do
		#if ((adjustable_width)); then
		#	echo here $name
		#	read bar_width bar_height bar_x bar_y < ~/.config/orw/bar/geometries/$name
		#fi

		current_bar_height=$((bar_y + bar_height + frame))

		#[[ $bar_name == $name ]] && delta_min=$current_bar_height delta_position=$position

		if ((position)); then
			((current_bar_height > top_offset)) && top_offset=$current_bar_height
		else
			((current_bar_height > bottom_offset)) && bottom_offset=$current_bar_height
		fi

		[[ $print && $name ]] && echo $name $position $bar_x $bar_y $bar_widht $bar_height $frame
	done <<< $(for bar in "${bars[@]}"; do
		awk -F '[- ]' '{
			p = ($(NF - 6) == "b") ? 0 : 1
			split($(NF - 3), g, "[x+]")
			x = g[3]; y = g[4]; w = g[1]; h = g[2]
			ff = (p) ? 7 : 9
			fw = ($(NF - ff) == "r") ? $(NF - (ff - 1)) * 2 : 0
			bn = $NF
		} {
			#if(nr && NR == nr + 1 && x >= '$bar_min' && x + w <= '$bar_max') {
			if(x >= '$min' && x + w <= '$max') {
				#aw = (/-w [a-z]/) ? 1 : 0
				#print bn, p, x, y, w, h, aw, fw
				print bn, p, x, y, w, h, fw
			}
		}' <<< "$bar"; done)

	#if ((delta_min)); then
	#	((delta_position)) && delta_max=$top_offset || delta_max=$bottom_offset
	#	echo $((delta_max - delta_min))
	#fi

	[[ $offset ]] && echo display_$display $top_offset $bottom_offset

	[[ $print ]] ||
		awk -i inplace '
			BEGIN {
				to = '${top_offset:-0}'
				bo = '${bottom_offset:-0}'
			}

			/display_'$display'_offset/ {
									if("'$delta'") {
										#td = ($2 > to) ? $2 - to : to - $2
										#bd = ($3 > bo) ? $3 - bo : bo - $3

										#td = gensub("^-", "", 1, $2 - to)
										#bd = gensub("^-", "", 1, $3 - bo)

										#ts = ($2 > to) ? "+" : "-"
										#bs = ($3 > bo) ? "+" : "-"

										#if($2 > to) ts = "+"
										#if($3 > bo) bs = "+"

										td = $2 - to
										bd = $3 - bo
										if(td > 0) ts = "+"
										if(bd > 0) bs = "+"
									}

									$2 = to
									$3 = bo
								} { print } END { print ts td, bs bd }' $config

	unset current_bar_height {top,bottom}_offset delta_{min,max,position}
done
exit

	#done | awk '{ ab = ab " " $0 } END { print ab }')

	eval read -a bar_properties <<< $(for bar in "${bars[@]}"; do
		awk -F '[- ]' '{
			p = ($(NF - 6) == "b") ? 0 : 1
			split($(NF - 3), g, "[x+]")
			x = g[3]; y = g[4]; w = g[1]; h = g[2]
			ff = (p) ? 7 : 9
			fw = ($(NF - ff) == "r") ? $(NF - (ff - 1)) * 2 : 0
			bn = $NF
		} {
			#if(nr && NR == nr + 1 && x >= '$bar_min' && x + w <= '$bar_max') {
			if(x >= '$min' && x + w <= '$max') {
				aw = (/-w [a-z]/) ? 1 : 0
				print "\"" bn, p, x, y, w, h, aw, fw "\""
			}
		}' <<< "$bar"
	done | awk '{ ab = ab " " $0 } END { print ab }')

		#}' <<< "$bar" | \

		echo ${#bar_properties[*]}
		exit
			while read name position bar_x bar_y bar_widht bar_height adjustable_width frame; do
				if ((adjustable_width)); then
					read bar_width bar_height bar_x bar_y < ~/.config/orw/bar/geometries/$bar_name
				fi

				current_bar_height=$((bar_y + bar_height + frame))

				if ((position)); then
					((current_bar_height > top_offset)) && top_offset=$current_bar_height
				else
					((current_bar_height > bottom_offset)) && bottom_offset=$current_bar_height
				fi

				echo -n to $top_offset, bo $bottom_offset
			done
		done

	echo $display:
	echo $top_offset
	echo $bottom_offset

	unset current_bar_height {top,bottom}_offset
done

#echo ${#bars[*]}
#echo ${bars[1]}
