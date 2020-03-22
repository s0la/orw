#!/bin/bash

path=~/.orw/scripts/rofi_scripts
${path%/*}/set_rofi_margins.sh

modis+="wallpapers:$path/wallpapers.sh,"
modis+="wallpaper_categories:$path/wallpaper_categories.sh"
rofi -modi "$modis" -show $1 -theme main
