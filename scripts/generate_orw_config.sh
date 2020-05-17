#!/bin/bash

conf=~/.config/orw/config

wm() {
	x_offset=20
	y_offset=10

	#echo "#general\nx_offset $x_offset\ny_offset $y_offset\n\n"
	echo "#wm\nmode floating\nratio 2\nx_offset $x_offset\ny_offset $y_offset\n"
}

display() {
	full_resolution=$(xrandr -q | awk -F '[x, ]' '/current/ { print "full_resolution " $10 " " $13 }')
	no_primary=$(xrandr -q | awk '/primary/ { print $2 == "disconnected" }')

	local width height

	while read -r is_primary x y width height display_name; do
		((index++))
		((x_sum += x))

		display=$display_name
		displays+="display_${index}_xy $x $y\n"
		displays+="display_$index $width $height\n"

		if ((no_primary && index == 1)); then
			xrandr --output $display --primary
			is_primary=true
		fi

		((is_primary)) && primary=$display primary_index=$index primary_width=$width primary_height=$height
	done <<< $(xrandr --listmonitors | awk -F '[x/+ ]' 'NR > 1 { print $4 ~ /^*/, $9, $10, $5, $7, $NF }')

	primary_display="primary display_${primary_index:-$index}"

	if ((index > 1)); then
		((x_sum)) && orientation=horizontal || orientation=vertical
	else
		((primary_width > primary_height)) && orientation=horizontal || orientation=vertical
	fi

	echo "#display\n$full_resolution\norientation $orientation\n$primary_display\n${displays%\\*}\n"
}

wallpapers() {
	display_count=$(xrandr -q | grep -w connected | wc -l)
	displays=$(eval "echo \\\"{1..$display_count}\\\"")

	for desktop in $(wmctrl -d | awk '{print $1}'); do
		desktops+="desktop_$desktop $displays\n"
	done

	echo "#wallpapers\ndepth 0\ndirectory \n${desktops%\\n}"
}

if [[ -f $conf ]]; then
	for arg in $@; do
		line_number=$(sed -n "/^#$arg/=" $conf)
		sed -i "/^#$arg/,/^$/d" $conf

		((line_number > $(wc -l < $conf))) && echo -e $($arg) >> $conf || sed -i "${line_number}i$($arg)" $conf
	done
else
	echo -e "$(wm)\n$(display)\n$(wallpapers)" > $conf
fi
