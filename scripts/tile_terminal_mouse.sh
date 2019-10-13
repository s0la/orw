#!/bin/bash

read x y <<< $(xdotool getmouselocation --shell | awk -F '=' 'NR < 3 { print $NF }' | xargs)

~/.orw/scripts/set_class_geometry.sh -c custom_position -x $x -y $y

termite --class=custom_position -e "bash -c '~/.orw/scripts/windowctl.sh fill;bash'" &> /dev/null &
