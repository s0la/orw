#!/bin/bash

path=~/.orw/scripts/rofi_scripts
${path%/*}/set_rofi_margins.sh

pidof transmission-daemon &> /dev/null || (transmission-daemon; sleep 0.5)

modis="torrents:$path/torrents.sh,"
modis+="select_torrent_content:$path/select_torrent_content_with_size.sh"

[[ $1 == select_torrent_content ]] && theme=large_list

rofi -modi "$modis" -show $1 -theme ${theme-main}
