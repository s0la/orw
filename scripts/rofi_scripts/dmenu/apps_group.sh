#!/bin/bash

path=~/.orw/scripts/rofi_scripts
theme=$(awk -F '[".]' 'END { print $(NF - 2) }' ~/.config/rofi/main.rasi)
#[[ $theme =~ icons|dmenu ]] && ${path%/*}/set_rofi_geometry.sh $1
#${path%/*}/set_rofi_width.sh $1
#${path%/*}/set_rofi_margins.sh

modis+="apps:$path/apps.sh,"
modis+="execute:$path/execute.sh,run"
rofi -modi "$modis" -show $1 -theme main
