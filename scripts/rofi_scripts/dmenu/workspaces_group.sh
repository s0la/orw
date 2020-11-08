#!/bin/bash

path=~/.orw/scripts/rofi_scripts
theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)
[[ $theme =~ icons|dmenu ]] && ${path%/*}/set_rofi_geometry.sh workspaces
#${path%/*}/set_rofi_width.sh workspaces
#${path%/*}/set_rofi_margins.sh

modis+="wall:$path/workspaces.sh wall,"
modis+="workspaces:$path/workspaces.sh,"
modis+="move_to:$path/workspaces.sh move"
rofi -modi "$modis" -show $1 -theme main
