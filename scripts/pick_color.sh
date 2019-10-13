#!/bin/bash

pick_offset=$1

preview=/tmp/color_preview.png
colorctl=~/.orw/scripts/colorctl.sh

while
	color=$(colorpicker -os)
	[[ $pick_offset ]] && color=$($colorctl -o $pick_offset -h $color)
	convert -size 100x100 xc:$color $preview

	read x y <<< $(~/.orw/scripts/windowctl.sh -p | awk '{ print $3 + ($5 - 100), $4 + ($2 - $1) }')
	~/.orw/scripts/set_class_geometry.sh -c image_preview -x $x -y $y
	feh -g 100x100 --title 'image_preview' $preview &

	read -srn 1 -p $'Keep color? [Y/n]\n' keep_color

	kill $! &> /dev/null

	[[ $keep_color == n ]]
do
	continue
done

rm $preview
echo $color
