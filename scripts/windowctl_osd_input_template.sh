#!/bin/bash

color_bar() {
	printf "$1%.0s$3" $(seq 1 $2)
}

calculate() {
	#printf '%.0f' $(bc <<< "scale=2; $@")
	local value=$(($1 / step))
	local reminder=$(($1 % step))
	((step - reminder < (step * 30 / 100))) && ((value++))

	echo $value
}

adjust_values() {
	x_start=$((display_x + x_offset))
	y_start=$((display_y + bar_top_offset + y_offset))
	x_end=$((display_x + width - x_offset))
	y_end=$((display_y + height - (bar_top_offset + y_offset)))

	#osd_window_x=$(calculate $x)
	#osd_window_x_end=$(calculate $((x + w)))
	#osd_window_y=$(calculate $y)
	#osd_window_y_end=$(calculate $((y + h)))
	#osd_window_w=$(calculate $w)
	#osd_window_h=$(calculate $h)

	#osd_x_start=$(calculate $x_start)
	#osd_y_start=$(calculate $y_start)
	#osd_x_end=$(calculate $x_end)
	#osd_y_end=$(calculate $y_end)
	##osd_y_end=$(calculate $((y_end - y_start)))

	#x_before=$((osd_window_x - osd_x_start))
	##x_size=$(calculate $w)
	#x_size=$((osd_window_x_end - osd_window_x))
	#x_after=$((osd_x_end - osd_window_x_end))
	##x_after=$((osd_x_end - (osd_window_x + osd_window_w)))

	x_before=$(calculate $((x - x_start)))
	x_size=$(calculate $w)
	x_after=$(calculate $((x_end - (x + w))))

	#y_before=$((osd_window_y - osd_y_start))
	##y_size=$(calculate $h)
	#y_size=$((osd_window_y_end - osd_window_y))
	#y_after=$((osd_y_end - osd_window_y_end))
	##y_after=$((osd_y_end - (osd_window_y + osd_window_h)))

	y_before=$(calculate $((y - y_start)))
	y_size=$(calculate $h)
	y_after=$(calculate $((y_end - (y + h))))

	#echo $y_before $y_size $y_after $h
	#echo $osd_window_y $osd_y_start $osd_y_end

	#echo $x_start $x_end $x $w
	#echo $x_before $x_size $x_after $h
	#echo $osd_window_x $osd_x_start $osd_x_end

	icon=' '
	icon=''
	icon='█▊'
	icon=' '
	icon='▆▆'
	icon=' '
	local filled_{x,y}
	#empty_x=$(color_bar ' ' $((x_before + x_size + x_after)))
	empty_x="<span foreground='\$sbg'>$(color_bar "$icon" $((x_before + x_size + x_after)))</span>"

	((x_before)) && filled_x="<span foreground='\$sbg'>$(color_bar "$icon" $x_before)</span>"
	filled_x+="<span foreground='\$pbfg'>$(color_bar "$icon" $x_size)</span>"
	((x_after)) && filled_x+="<span foreground='\$sbg'>$(color_bar "$icon" $x_after)</span>"

	((y_before)) && filled_y="$(color_bar "$empty_x\n" $y_before)\n"
	filled_y+="$(color_bar "$filled_x\n" $y_size)"
	((y_after)) && filled_y+="\n$(color_bar "$empty_x\n" $y_after)"

	~/.orw/scripts/notify.sh -r 222 -s windows_osd \
		"<span font='Iosevka Orw $font_size'>\n$filled_y\n</span>" &
}

evaluate() {
	input=$1

	if [[ $input == d ]]; then
		stop=true
	else
		case $input in
			m)
				moved=true
				option=move;;
			r) option=resize;;
			#[<>])
			"<"|">")
				option=resize
				[[ $input == "<" ]] && sign=- || sign=+;;
			[A-Z])
				local default_step=$step
				local step sign

				case $input in
					K) step=$((y - y_start));;
					H) step=$((x - x_start));;
					J) step=$((y_end - (y + h + ${real_y_border:-$y_border})));;
					L) step=$((x_end - (x + w + x_border)));;
				esac

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
			case $input in
				j) ((h $sign= step));;
				l) ((w $sign= step));;
				[hk])
					[[ $input == h ]] && properties='w x' || properties='h y'
					[[ $sign == - ]] && opposite_sign=+ || opposite_sign=-

					((${properties% *} $sign= step))
					((${properties#* } $opposite_sign= step))
			esac

			((default_step)) && step=$default_step
		fi

		adjust_values
	fi
}

execute() {
	#[[ "${BASH_SOURCE[0]}" == "$0" ]] && wmctrl -ir $id -e 0,$x,$y,$w,$h
	#[[ "${BASH_SOURCE[0]}" =~ windowctl.sh ]] || wmctrl -ir $id -e 0,$x,$y,$w,$h
	[[ ! $source ]] && wmctrl -ir $id -e 0,$x,$y,$w,$h
}

set_geometry() {
	total_width=$((x_end - x_start))
	column_count=$((total_width / step))
	osd_width=$((column_count * font_size))
	osd_x=$(((width - (osd_width + 2 * 10 * font_size)) / 2))

	awk -i inplace '\
		function replace(position, value) {
			$0 = gensub("([0-9]+)", value, position)
		}

		/^\s*geometry/ {
			replace(3, '$osd_x')
			replace(1, '$osd_width' * 3)
			#replace(1, '$osd_width' * 2.5)
		} { print }' ~/.config/dunst/windows_osd_dunstrc

	adjust_values
}

step=120
font_size=8

[[ $1 == source ]] && source=true

#if [[ ! "${BASH_SOURCE[0]}" =~ windowctl.sh ]]; then
#if [[ $1 == apply ]]; then
if [[ ! $source ]]; then
	id=$(printf '0x%.8x' $(xdotool getactivewindow))

	read {x,y}_border {x,y}_offset offset <<< $(awk '/^([xy]_|offset)/ { print $NF }' ~/.config/orw/config | xargs)
	real_y_border=$y_border
	y_border=$(((y_border - x_border / 2) * 2))

	[[ $offset == true ]] && eval $(cat ~/.config/orw/offsets)

	read x y w h <<< $(wmctrl -lG | awk '$1 == "'$id'" {
		print $3 - '$x_border', $4 - '$y_border', $5, $6 }')

	read display display_x display_y width height rest <<< $(~/.orw/scripts/get_display.sh $x $y)

	while read name position bar_x bar_y bar_widht bar_height rest; do
		current_bar_height=$((bar_y + bar_height))

		if ((position)); then
			((current_bar_height > bar_top_offset)) && bar_top_offset=$current_bar_height
		else
			((current_bar_height > bar_bottom_offset)) && bar_bottom_offset=$current_bar_height
		fi
	done <<< $(~/.orw/scripts/get_bar_info.sh $display)

	x_start=$((display_x + x_offset))
	x_end=$((display_x + width - x_offset))
	y_start=$((display_y + y_offset + bar_top_offset))
	y_end=$((display_y + height - (y_offset + bar_bottom_offset)))
fi

set_geometry
