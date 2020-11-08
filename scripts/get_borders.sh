#!/bin/bash

id=$(printf '0x%.8x' $(xdotool getactivewindow))
read border_x border_y <<< $([[ $id =~ ^0x ]] && xwininfo -id $id | awk '\
	/Relative/ { if(/X/) x = $NF; else y = $NF + x } END { print 2 * x, y }')

echo $border_x $border_y
