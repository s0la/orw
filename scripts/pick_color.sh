#!/bin/bash

while getopts :af: arg; do
	case $arg in
		a) adjust_color=true;;
		f) fifo=$OPTARG;;
	esac
done

preview=/tmp/color_preview.png
colorctl=~/.orw/scripts/convert_colors.sh

read x y <<< $(xwininfo -int -id $(xdotool getactivewindow) | awk '
		/Absolute/ { if(/X/) x = $NF; else y = $NF }
		/Relative/ { if(/X/) xb = $NF; else yb = $NF }
		/Width/ { w = $NF }
		/Height/ { print x - 2 * xb + w - 100, y }')

~/.orw/scripts/set_geometry.sh -t image_preview -x $x -y $y

while
	color=$(colorpicker --short --one-shot)

	magick -size 100x100 xc:$color $preview
	feh -g 100x100 --title 'image_preview' $preview &
	preview_pid=$!

	if [[ $adjust_color ]]; then
		read -srn 1 -p $'Adjust color? [y/N]\n' adjust

		if [[ $adjust == y ]]; then
			preview_pid=$!
			current_color_fifo=/tmp/current_color.fifo
			final_color_fifo=/tmp/final_color.fifo

			[[ -e $current_color_fifo ]] || mkfifo $current_color_fifo
			[[ -e $final_color_fifo ]] || mkfifo $final_color_fifo

			while [[ -e $current_color_fifo ]]; do
				read color < $current_color_fifo
				magick -size 100x100 xc:$color $preview

				kill $! &> /dev/null

				feh -g 100x100 --title 'image_preview' $preview &
				preview_pid=$!
			done &

			while_pid=$!

			$colorctl -hPf $current_color_fifo,$final_color_fifo $color
			read color < $final_color_fifo

			last_preview_pid=$(ps aux | awk '$NF == "'$preview'" { print $2 }')
			kill $while_pid $last_preview_pid
		fi
	fi

	read -srn 1 -p $'Keep color? [Y/n]\n' keep_color

	kill $! &> /dev/null

	[[ $keep_color == n ]]
do
	continue
done

rm $preview
echo $color > ${fifo:-/dev/stdout} &
