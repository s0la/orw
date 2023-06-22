#!/bin/bash

path=${0%/*}
#${path%/*}/set_rofi_margins.sh

#modis+="bar_launchers:$path/bar_launchers.sh,"
#modis+="bar_icons:$path/bar_icons.sh,"
#modis+="playback:$path/playback.sh,"
#modis+="playlist:$path/playlist.sh,"
#modis+="execute:$path/execute.sh,"
#modis+="colors:$path/colors.sh,"
#modis+="files:$path/files.sh,"
#modis+="rec:$path/rec.sh"

[[ $2 ]] &&
	theme=$2 ||
	theme=$(awk -F '"' 'END {
			t = $(NF - 1)
			sub("\\..*", "", t)
			print t
		}' ~/.config/rofi/main.rasi)
[[ $theme == icons && $1 =~ bar|execute|files|library|playlist|torrent ]] && theme=list

#rofi -modi "$modis" -show $1 -theme $theme
#rofi -modi "$1:$path/$1.sh" -show $1 -theme $theme
rofi -modi "$1:$path/$1.sh" -show $1 -theme $theme
