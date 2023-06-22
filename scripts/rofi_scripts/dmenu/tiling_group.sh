#!/bin/bash

path=~/.orw/scripts/rofi_scripts/dmenu
theme=$(awk -F '[".]' 'END { print $(NF - 2) }' ~/.config/rofi/main.rasi)
#[[ $theme =~ icons|dmenu ]] && ~/.orw/scripts/set_rofi_geometry.sh tiling_$1
#${path%/*}/set_rofi_width.sh tiling_$1
#${path%/*}/set_rofi_margins.sh

#modis+="toggle:$path/tiling_toggle.sh,"
modis+="offset:$path/tiling_offset.sh,"
modis+="ratio:$path/tiling_ratio.sh"
rofi -modi "$modis" -show $1 -theme main
