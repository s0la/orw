#!/bin/bash

path=~/.orw/scripts/rofi_scripts
theme=$(awk -F '[".]' 'END { print $(NF - 2) }' ~/.config/rofi/main.rasi)

read wallpaper{s,_categories} <<< \
	$(sed -n 's/^\(wallpapers\|categories\)=//p' ~/.orw/scripts/icons | xargs)

modis+="$wallpapers:$path/select_wallpaper.sh,"
modis+="$wallpaper_categories:$path/wallpaper_categories.sh,"
rofi -modi "$modis" -show $wallpapers -theme sidebar
