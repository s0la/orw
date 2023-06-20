#!/bin/bash

conf=~/.config/orw/config

wm() {
	part=1
	ratio=2
	x_offset=20
	y_offset=10
	offset=false
	reverse=false

	read x_border y_border <<< $(~/.orw/scripts/print_borders.sh)

	#echo "#general\nx_offset $x_offset\ny_offset $y_offset\n\n"

	#cat <<- EOF
	#	#wm
	#	part $part
	#	ratio $ratio
	#	x_offset $x_offset
	#	y_offset $y_offset
	#	offset $offset
	#	reverse $reverse
	#EOF

	#cat <<- EOF
	#	#wm
	#	margin 10
	#	x_border $x_border
	#	y_border $y_border
	#	x_offset 50
	#	y_offset 50
	#	mode tiling
	#	full false
	#	reverse false
	#	direction auto
	#	interactive true

	#EOF

	properties=(
		"#wm"
		"margin 10"
		"x_border $x_border"
		"y_border $y_border"
		"x_offset 50"
		"y_offset 50"
		"mode tiling"
		"full false"
		"reverse false"
		"direction auto"
		"interactive true"
	)

	printf '%s\\n' "${properties[@]}"

	#echo "#wm\n margin 10\nx_border $x_border\ny_border $y_border\nx_offset 50\ny_offset 50\nmode tiling\nfull false\nreverse false\ndirection auto\ninteractive true\n"

	#echo "#wm\nmode floating\npart 1\nratio 2\nuse_ratio false\ndirection h\nreverse false\nfull false\nx_border $x_border\ny_border $y_border\nx_offset $x_offset\ny_offset $y_offset\noffset false\n"
}

display() {
	while read -r name primary width height x y; do
		((index++))
		((last_x += x))
		((last_y += y))
		last_width=$width
		last_height=$height

		displays+="display_${index}_name $name\n"
		displays+="display_${index}_xy $x $y\n"
		displays+="display_${index}_size $width $height\n"
		displays+="display_${index}_offset 0 0\n"

		((index == 1)) && first_display_name=$name first_display_index=$index
		((primary)) && primary_display_name=$name primary_display_index=$index
	done <<< $(xrandr | awk -F '[ x+]' '$2 == "connected" {
											p = $3 == "primary"
											i = 3 + p
											print $1, p, $i, $(i + 1), $(i + 2), $(i + 3) }')

	((primary_display_index)) || xrandr --output $first_display_name --primary

	primary_display="primary display_${primary_display_index:-$first_display_index}"

	x_size=$((last_x + last_width))
	y_size=$((last_y + last_height))
	((x_size > y_size)) && orientation=horizontal || orientation=vertical

	echo "#display\norientation $orientation\n$primary_display\n${displays%\\*}\n"
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

~/.orw/scripts/signal_windows_event.sh update
