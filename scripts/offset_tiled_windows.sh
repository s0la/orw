#!/bin/bash

#read x_border y_border x y <<< $(~/.orw/scripts/windowctl.sh -p | cut -d ' ' -f 1-4)
#read display display_x display_y width height <<< \
#	$(~/.orw/scripts/get_display.sh $x $y | cut -d ' ' -f 1-5)

orw_config=~/.config/orw/config
#read border offset <<< \ $(awk '/^'$1'_(border|offset)/ { print $NF }' $orw_config | xargs)
#read {x,y}_border {x,y}_offset <<< \
#	$(awk '/^[xy]_(border|offset)/ { print $NF }' $orw_config | xargs)
read {x,y}_border offset is_offset <<< \
	$(awk '/^([xy]_border|('$1'_)?offset)/ { print $NF }' $orw_config | xargs)

[[ $is_offset == true ]] && offset=$(awk -F '=' '/'$1'_offset/ { print $NF }' ~/.config/orw/offsets)

eval windows=( $(wmctrl -lG | awk '$NF != "DROPDOWN" { print "\"" $1, $3, $4, $5, $6 "\"" }') )

list_windows() {
	for window in "${windows[@]}"; do
		echo "$window"
	done
}

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

while read display display_start display_end; do
	if [[ $1 == y ]]; then
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
		done <<< $(~/.orw/scripts/get_bar_info.sh $display)
	fi

	list_windows | sort -nk $index,$index | awk '\
		BEGIN {
			v = '$value'
			i = '$index' - 1
			xb = '$x_border'
			yb = '$y_border'
			myb = (yb - xb / 2) * 2
			b = '$1'b
			o = '$offset'
			to = '${top_offset:-0}'
			bo = '${bottom_offset:-0}'
			ds = '$display_start' + o + to
			de = '$display_end' - o - bo
		} {
			$2 -= xb
			$3 -= myb
			ws = $i
			we = ws + $(i + 2)

			if(ws == ds) {
				$(i + 2) '$opposite_sign'= v
				$i '$sign'= v
			}

			if(we + b == de) $(i + 2) '$opposite_sign'= v

			#system("~/.orw/scripts/notify.sh -t 22 \"" ws " " ds " " $0 "\"")
			system("wmctrl -ir " $1 " -e 0," $2 "," $3 "," $4 "," $5)
		}'
#done <<< $(awk -F '[_ ]' '/^display_[0-9]+/ && $3 != "name" {
done <<< $(awk -F '[_ ]' '/^display_[0-9]+_(xy|size)/ {
	if($3 == "xy") s = $('$index' + 1)
	else print $2, s, $('$index' + 1) }' $orw_config)
