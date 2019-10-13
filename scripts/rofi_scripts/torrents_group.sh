#!/bin/bash

path=~/.orw/scripts/rofi_scripts
${path%/*}/set_rofi_margins.sh

modis+="select_torrent_content:$path/select_torrent_content_with_size.sh"
rofi -modi "$modis" -show $1 -theme large_list
