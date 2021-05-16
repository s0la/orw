#!/bin/bash

#read x_border y_border x y <<< $(~/.orw/scripts/windowctl.sh -p | cut -d ' ' -f 1-4)
#read display display_x display_y width height <<< \
#	$(~/.orw/scripts/get_display.sh $x $y | cut -d ' ' -f 1-5)

orw_config=~/.config/orw/config
#read border offset <<< \ $(awk '/^'$1'_(border|offset)/ { print $NF }' $orw_config | xargs)
#read {x,y}_border {x,y}_offset <<< \
#	$(awk '/^[xy]_(border|offset)/ { print $NF }' $orw_config | xargs)

read {x,y}_border {x,y}_offset is_offset limiter_index <<< $(awk '
	$1 ~ "^(([xy]_)?(border|offset))$" { print $NF }
	$1 == "orientation" { print ($NF ~ "^h") ? 2 : 3 }' $orw_config | xargs)
y_border=$(((y_border - x_border / 2) * 2))

[[ $is_offset == true ]] && eval $(grep offset ~/.config/orw/offsets)

#[[ $is_offset == true ]] && offset=$(awk -F '=' '/'$1'_offset/ { print $NF }' ~/.config/orw/offsets)

current_desktop=$(xdotool get_desktop)

eval windows=( $(wmctrl -lG | awk '$NF != "DROPDOWN" {
				w = "\"" $1 " " $3 " " $4 " " $5 " " $6 "\""
				if($2 == '$current_desktop') cd = cd "\n" w
				else od = od "\n" w
				} END {
					print substr(cd, 2)
					print substr(od, 2)
				}') )

#eval windows=( $(wmctrl -lG | awk '$NF != "DROPDOWN" { print "\"" $1, $3, $4, $5, $6 "\"" }') )

list_windows() {
	for window in "${windows[@]}"; do
		echo "$window"
	done
}

offset_direction() {
	[[ $1 == x ]] && index=3 || index=4

	sign=${2%%[0-9]*}
	value=${2#"$sign"}

	#[[ $value ~= ',' ]] && multiple_values="${value//,/ }"
	[[ $value =~ ',' ]] && values="${value//,/ }"

	eval offset=\${$1_offset}

	if [[ $sign ]]; then
		[[ $sign == + ]] && opposite_sign=- || opposite_sign=+
	else
		echo -e "No sign specified, exiting..\nPlease prefix value with the sign next time!"
		exit
	fi

	while read index properties; do
		windows[index]="$properties"
	done <<< $(while read display_start display_end limit_start limit_end top_offset bottom_offset; do
			#list_windows | sort -nk $index,$index | awk '\
			list_windows | awk '\
				BEGIN {
					i = '$index' - 1
					li = '$limiter_index'
					xb = '$x_border'
					yb = '$y_border'
					b = '$1'b
					o = '$offset'
					ls = '$limit_start'
					le = '$limit_end'
					to = '${top_offset:-0}'
					bo = '${bottom_offset:-0}'
					ds = '$display_start' + o + to
					de = '$display_end' - o - bo

					#system("~/.orw/scripts/notify.sh \"'"$values"'\"")
					if("'"$values"'") split("'"$values"'", vs)
					else v = "'$value'"
				} {
					$2 -= xb
					$3 -= yb
					ws = $i
					we = ws + $(i + 2)
					wls = $li
					wle = wls + $(li + 2)

					if(wls >= ls && wle <= le) {
						if(v) {
							if(ws == ds) {
								$(i + 2) '$opposite_sign'= v
								$i '$sign'= v
							}

							if(we + b == de) $(i + 2) '$opposite_sign'= v
						} else {
							for(vi in vs) {
								cv = vs[vi]

								#if(ws '$sign' cv == ds) {
								#	$(i + 2) '$opposite_sign'= v
								#	$i '$sign'= v
								#}

								if(ws '$opposite_sign' cv == ds) {
									$i '$opposite_sign'= cv
									$(i + 2) '$sign'= cv
								}

								if(we + b '$sign' cv == de) $(i + 2) '$sign'= cv
							}
						}

						$2 += xb
						$3 += yb
						print NR - 1, $0
					}
				}' 
			#| while read index properties; do
			#			#wmctrl -ir $id -e 0,${props// /,} &
			#			#echo $1 $index $id ${props// /,}
			#			#echo $1 $index $start $dimension
			#			#echo "$properties"
			#			offset_windows[$index]="$properties"
			#		done
		done <<< $(awk -F '[_ ]' '/^display_[0-9]+_(xy|size|offset)/ {
				if($3 == "xy") {
					de = $('$index' + 1)
					le = $('$limiter_index' + 2)
				} else if($3 == "size") {
					de = de " " $('$index' + 1)
					le = le " " $('$limiter_index' + 2)
				} else {
					if("'$1'" == "y") bo = $(NF - 1) " " $NF
					print de, le, bo
				}
		}' $orw_config))
}

while getopts :x:y: direction; do
	offset_direction $direction $OPTARG
done

#wmctrl -k on

for win in "${windows[@]}"; do
	read id x y w h <<< "$win"
	wmctrl -ir $id -e 0,$((x - x_border)),$((y - y_border)),$w,$h
done

#wmctrl -k off
exit

#sign=$2
#value=$3
#[[ $2 =~ ^[+-] ]] && sign=${2:0:1} value
[[ $1 == x ]] && index=3 || index=4

sign=${2%%[0-9]*}
value=${2#"$sign"}

if [[ $sign ]]; then
	[[ $sign == + ]] && opposite_sign=- || opposite_sign=+
else
	echo -e "No sign specified, exiting..\nPlease prefix value with the sign next time!"
	exit
fi

offset_direction y
offset_direction x
exit

#list_windows | sort -nk $index,$index | awk '{ print $1, $2, $3, $4, $5 }'
#exit

#while read display display_start display_end; do
while read display_start display_end limit_start limit_end top_offset bottom_offset; do
	#if [[ $1 == y ]]; then
	#	while read name position bar_x bar_y bar_widht bar_height adjustable_width frame; do
	#		if ((adjustable_width)); then
	#			read bar_width bar_height bar_x bar_y < ~/.config/orw/bar/geometries/$bar_name
	#		fi

	#		current_bar_height=$((bar_y + bar_height + frame))

	#		if ((position)); then
	#			((current_bar_height > top_offset)) && top_offset=$current_bar_height
	#		else
	#			((current_bar_height > bottom_offset)) && bottom_offset=$current_bar_height
	#		fi
	#	done <<< $(~/.orw/scripts/get_bar_info.sh $display)
	#fi

	#echo de $display_start $display_end
	#echo mmp $min_point $max_point
	#echo bo $top_offset $bottom_offset
	#continue

	list_windows | sort -nk $index,$index | awk '\
		BEGIN {
			v = '$value'
			i = '$index' - 1
			li = '$limiter_index'
			xb = '$x_border'
			yb = '$y_border'
			myb = (yb - xb / 2) * 2
			b = '$1'b
			o = '$offset'
			ls = '$limit_start'
			le = '$limit_end'
			to = '${top_offset:-0}'
			bo = '${bottom_offset:-0}'
			ds = '$display_start' + o + to
			de = '$display_end' - o - bo
		} {
			$2 -= xb
			$3 -= myb
			ws = $i
			we = ws + $(i + 2)
			wls = $li
			wle = wls + $(li + 2)

			#if(ws >= ds && we <= de) {
			if(wls >= ls && wle <= le) {
				if(ws == ds) {
					$(i + 2) '$opposite_sign'= v
					$i '$sign'= v
				}

				if(we + b == de) $(i + 2) '$opposite_sign'= v

				#system("~/.orw/scripts/notify.sh -t 22 \"" ws " " ds " " $0 "\"")
				#system("wmctrl -ir " $1 " -e 0," $2 "," $3 "," $4 "," $5 " &")
				#print $1, $2, $3, $4, $5
				print
			}
		}' | while read id props; do
				wmctrl -ir $id -e 0,${props// /,} &
			done
done <<< $(awk -F '[_ ]' '/^display_[0-9]+_(xy|size|offset)/ {
		if($3 == "xy") {
			de = $('$index' + 1)
			le = $('$limiter_index' + 2)
		} else if($3 == "size") {
			de = de " " $('$index' + 1)
			le = le " " $('$limiter_index' + 2)
		} else {
			#if("'$1'" == "y") o = o " " $(NF - 1) " " $NF
			if("'$1'" == "y") bo = $(NF - 1) " " $NF
			print de, le, bo
		}
		#printf "\n"
		#else if($3 == "size") e = $('$index' + 1)
		#else print s, e, $(NF - 1), $NF
	}' $orw_config)

#done <<< $(awk -F '[_ ]' '/^display_[0-9]+/ && $3 != "name" {

#done <<< $(awk -F '[_ ]' '/^display_[0-9]+_(xy|size)/ {
#	if($3 == "xy") s = $('$index' + 1)
#	else print $2, s, $('$index' + 1) }' $orw_config)
