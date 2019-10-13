#!/bin/bash

path=~/.orw/scripts/rofi_scripts
${path%/*}/set_rofi_margins.sh

modis+="library:$path/mpd_library.sh,"
modis+="play:$path/mpd_playlist.sh"
rofi -modi "$modis" -show $1 -theme large_list
