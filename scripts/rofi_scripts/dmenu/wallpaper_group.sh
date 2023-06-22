#!/bin/bash

path=~/.orw/scripts/rofi_scripts/dmenu
theme=$(awk -F '[".]' 'END { print $(NF - 2) }' ~/.config/rofi/main.rasi)
#[[ $theme =~ icons|dmenu ]] && ${path%/*}/set_rofi_geometry.sh $1
#${path%/*}/set_rofi_width.sh $1
#${path%/*}/set_rofi_margins.sh

#    
modis+=":$path/select_wallpaper.sh,"
modis+=":$path/wallpaper_categories.sh,"
rofi -modi "$modis" -show  -theme sidebar_new
exit

modis+="wallpapers:$path/wallpapers.sh,"
modis+="category_selection:$path/wallpaper_category_selection.sh,"
modis+="wallpaper_categories:$path/wallpaper_categories.sh"
rofi -modi "$modis" -show $1 -theme sidebar_new
