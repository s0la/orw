#!/bin/bash

path=~/.orw/scripts/rofi_scripts
theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)
[[ $theme =~ icons|dmenu ]] && ${path%/*}/set_rofi_geometry.sh window_$1
#${path%/*}/set_rofi_width.sh window_$1
#${path%/*}/set_rofi_margins.sh

modis+="actions:$path/window_actions.sh,"
#modis+="ratio:$path/window_ratio.sh,"
#modis+="offset:$path/window_offset.sh,"
modis+="managment:$path/window_managment.sh"
rofi -modi "$modis" -show $1 -theme main
