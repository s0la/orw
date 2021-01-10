#!/bin/bash

color_bar() {
	printf "$1%.0s$3" $(seq 1 $2)
}

calculate() {
	#printf '%.0f' $(bc <<< "scale=2; $@")
	local value=$(($1 / $3))
	local reminder=$(($1 % $3))
	(($3 - reminder < ($3 / 100 * 20))) && ((value++))

	echo $value
}

adjust_values() {
	osd_window_x=$(calculate $x / $step)
	osd_window_y=$(calculate $y / $step)
	osd_window_w=$(calculate $w / $step)
	osd_window_h=$(calculate $h / $step)

	osd_x_start=$(calculate $x_start / $step)
	osd_y_start=$(calculate $y_start / $step)
	osd_x_end=$(calculate $x_end / $step)
	osd_y_end=$(calculate $((y_end - y_start)) / $step)

	x_before=$((osd_window_x - osd_x_start))
	x_size=$(calculate $w / $step)
	x_after=$((osd_x_end - (osd_window_x + osd_window_w)))

	y_before=$((osd_window_y - osd_y_start))
	y_size=$(calculate $h / $step)
	y_after=$((osd_y_end - (osd_window_y + osd_window_h)))

	#echo $w $step $y_start $y_end $h
	#echo $osd_y_end $osd_window_y $osd_window_h
	#echo $y_before $y_size $y_after

	local filled_{x,y}
	#empty_x=$(color_bar ' ' $((x_before + x_size + x_after)))
	empty_x="<span foreground='\$sbg'>$(color_bar ' ' $((x_before + x_size + x_after)))</span>"

	((x_before)) && filled_x="<span foreground='\$sbg'>$(color_bar ' ' $x_before)</span>"
	filled_x+="<span foreground='\$pbfg'>$(color_bar ' ' $x_size)</span>"
	((x_after)) && filled_x+="<span foreground='\$sbg'>$(color_bar ' ' $x_after)</span>"

	((y_before)) && filled_y="$(color_bar "$empty_x\n" $y_before)\n"
	filled_y+="$(color_bar "$filled_x\n" $y_size)"
	((y_after)) && filled_y+="\n$(color_bar "$empty_x\n" $y_after)"

	~/.orw/scripts/notify.sh -r 222 -s windows_osd \
		"<span font='Iosevka Orw $font_size'>\n$filled_y\n</span>" &
}

evaluate() {
	if [[ $input =~ [A-Z] ]]; then
		local step sign

		case $input in
			K) step=$((y - y_start));;
			H) step=$((x - x_start));;
			J) step=$((y_end - (y + h + ${real_y_border:-$y_border})));;
			L) step=$((x_end - (x + w + x_border)));;
		esac

		sign=+
		input=${input,}
	fi

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
	fi
}

read_input() {
	read_command="read -rsn ${argument_count:-1} input && echo \$input > $named_pipe"
	termite -t input --class=input -e "bash -c '$read_command'" &> /dev/null &

	read input < $named_pipe
}

listen_input() {
	while
		#read -rsn 1 input
		read_input

		[[ $input == m ]] && option=move
		[[ $input == r ]] && option=resize

		if [[ $input =~ ["<"|">"] ]]; then
			[[ $input == "<" ]] && sign=- || sign=+
			option=resize
			continue
		fi

		[[ $input != d ]]
	do
		evaluate
		adjust_values
	done
}

set_geometry() {
	total_width=$((x_end - x_start))
	column_count=$((total_width / step))
	osd_width=$((column_count * font_size))
	osd_x=$(((width - (osd_width + 2 * 10 * font_size)) / 2))

	awk -i inplace '/^\s*geometry/ {
		sub("\\+[0-9]+", "+'$osd_x'")
	} { print }' ~/.config/dunst/windows_osd_dunstrc

	~/.orw/scripts/set_geometry.sh -c input \
		-x $(((width - 100) / 2)) -y $(((height - 100) / 2)) -w 100 -h 100

	#~/.orw/scripts/notify.sh -r 222 -s windows_osd \
	#	"<span font='Iosevka Orw $osd_width'></span>"

		#-x $(((width - osd_width) / 2)) -y $((height / 2)) -w 100 -h 100

	adjust_values
}

font_size=8

named_pipe=/tmp/keyboard_input
[[ -p $named_pipe ]] && rm $named_pipe
mkfifo $named_pipe

#~/.orw/scripts/notify.sh -r 222 -s windows_osd -i   'interactive mode'

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	step=120

	id=$(printf '0x%.8x' $(xdotool getactivewindow))

	config=~/.config/orw/config
	read {x,y}_border {x,y}_offset offset <<< $(awk '/^([xy]_|offset)/ { print $NF }' $config | xargs)
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

	set_geometry

	listen_input

	wmctrl -ir $id -e 0,$x,$y,$w,$h
fi
