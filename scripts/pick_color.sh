#!/bin/bash

while getopts :af: arg; do
	case $arg in
		a) adjust_color=true;;
		#f) fifo="> $OPTARG";;
		f) fifo=$OPTARG;;
	esac
done

preview=/tmp/color_preview.png
#colorctl=~/.orw/scripts/colorctl.sh
colorctl=~/.orw/scripts/convert_colors.sh

#border=$(awk '/^x_border/ { print $NF }' ~/.config/orw/config)
#read x y <<< $(~/.orw/scripts/windowctl.sh -p | awk '\
#		{ print $3 + ($5 - 100) - '$border', $4 + ($2 - $1) + '$border' }')

read x y <<< $(xwininfo -int -id $(xdotool getactivewindow) | awk '
		/Absolute/ { if(/X/) x = $NF; else y = $NF }
		/Relative/ { if(/X/) xb = $NF; else yb = $NF }
		/Width/ { w = $NF }
		/Height/ { print x - 2 * xb + w - 100, y }')

		#BEGIN { b = '$border' } { print $3 + ($5 - 100) - b, $4 + ($2 - $1) - b }')

~/.orw/scripts/set_geometry.sh -t image_preview -x $x -y $y

#get_color() {
#	while [[ -e $color_fifo ]]; do
#		read color < $color_fifo
#		convert -size 100x100 xc:$color $preview
#
#		kill ${preview_pid:-$!} &> /dev/null
#
#		feh -g 100x100 --title 'image_preview' $preview &
#		preview_pid=$!
#	done
#
#	echo $color $preview_pid
#}

while
	color=$(colorpicker -od)
	#[[ $pick_offset ]] && color=$($colorctl -o $pick_offset -h $color)
	#[[ $pick_offset ]] && color=$($colorctl -hv $pick_offset $color)

	convert -size 100x100 xc:$color $preview
	feh -g 100x100 --title 'image_preview' $preview &
	preview_pid=$!



	#read -srn 1 -p $'Offset color? [y/N]\n' offset_color

	#if [[ $offset_color == y ]]; then
	#	read -rsn 1 -p $'Whole/properties/done? [w/p/D]\n' offset_type
	if [[ $adjust_color ]]; then
		read -srn 1 -p $'Adjust color? [y/N]\n' adjust

		if [[ $adjust == y ]]; then
			preview_pid=$!
			current_color_fifo=/tmp/current_color.fifo
			final_color_fifo=/tmp/final_color.fifo

			[[ -e $current_color_fifo ]] || mkfifo $current_color_fifo
			[[ -e $final_color_fifo ]] || mkfifo $final_color_fifo

			while [[ -e $current_color_fifo ]]; do
			#while read color; do
				#echo reading color
				read color < $current_color_fifo
				#echo color: $color
				convert -size 100x100 xc:$color $preview

				#echo killing $!
				#~/.orw/scripts/notify.sh "killing: $preview_pid"
				#kill ${preview_pid:-$!} 
				kill $! &> /dev/null

				feh -g 100x100 --title 'image_preview' $preview &
				preview_pid=$!
				#~/.orw/scripts/notify.sh "new_pid: $preview_pid"
			done &

			#final_color_fifo=/tmp/final_color.fifo
			#[[ -e $final_color_fifo ]] || mkfifo $final_color_fifo
			#get_color > $final_color_fifo &

			while_pid=$!

			$colorctl -hPf $current_color_fifo,$final_color_fifo $color
			read color < $final_color_fifo

			last_preview_pid=$(ps aux | awk '$NF == "'$preview'" { print $2 }')
			kill $while_pid $last_preview_pid
		fi
		#color=$final_color
		#[[ -e $final_color_fifo ]] && rm $final_color_fifo

		#wait $while_pid
		#read color preview_pid < $final_color_fifo

		#[[ -e $final_color_fifo ]] && rm $final_color_fifo

		#last_color=$(wait $while_pid)
		#echo last color: $last_color

		#[[ $while_pid ]] && kill $while_pid && kill ${preview_pid:-$!} 
	fi




	read -srn 1 -p $'Keep color? [Y/n]\n' keep_color

	#kill ${preview_pid:-$!} &> /dev/null
	kill $! &> /dev/null

	[[ $keep_color == n ]]
do
	continue
done

rm $preview
echo $color > ${fifo:-/dev/stdout} &
#eval echo $color $fifo
#$colorctl -hd ';' $color
