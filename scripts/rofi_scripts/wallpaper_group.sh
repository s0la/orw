#!/bin/bash

path=~/.orw/scripts/rofi_scripts
${path%/*}/set_rofi_width.sh $1
${path%/*}/set_rofi_margins.sh

modis+="wallpapers:$path/wallpapers.sh,"
modis+="category_selection:$path/wallpaper_category_selection.sh,"
modis+="wallpaper_categories:$path/wallpaper_categories.sh"
rofi -modi "$modis" -show $1 -theme main
