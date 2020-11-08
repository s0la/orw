#!/bin/bash

path=~/.orw/scripts/rofi_scripts
theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)
[[ $theme =~ dmenu ]] && ${path%/*}/set_rofi_geometry.sh
#${path%/*}/set_rofi_margins.sh

modis+="library:$path/mpd_library.sh,"
modis+="play:$path/mpd_playlist.sh"
rofi -modi "$modis" -show $1 -theme ${2:-large_list}
