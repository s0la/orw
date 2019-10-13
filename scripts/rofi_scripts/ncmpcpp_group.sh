#!/bin/bash

path=~/.orw/scripts/rofi_scripts
${path%/*}/set_rofi_margins.sh

modis+="ncmpcpp:$path/ncmpcpp.sh,"
modis+="playback:$path/playback.sh,"
modis+="play:$path/playlist.sh,"
modis+="library:$path/mpd_library.sh,"
modis+="ncmpcpp_colors:$path/colors.sh ncmpcpp"
rofi -modi "$modis" -show $1 -theme main
