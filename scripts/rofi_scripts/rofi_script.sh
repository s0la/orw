#!/bin/bash

path=${0%/*}
${path%/*}/set_rofi_margins.sh

modis+="window_action:$path/window_actions.sh,"
modis+="bar_launchers:$path/bar_launchers.sh,"
modis+="move_to:$path/workspaces.sh move,"
modis+="wall:$path/workspaces.sh wall,"
modis+="workspaces:$path/workspaces.sh,"
modis+="wallpapers:$path/wallpapers.sh,"
modis+="windows:$path/list_windows.sh,"
modis+="bar_icons:$path/bar_icons.sh,"
modis+="playback:$path/playback.sh,"
modis+="playlist:$path/playlist.sh,"
modis+="execute:$path/execute.sh,"
modis+="colors:$path/colors.sh,"
modis+="volume:$path/volume.sh,"
modis+="apps:$path/apps.sh,run,"
modis+="power:$path/power.sh,"
modis+="files:$path/files.sh,"
modis+="rec:$path/rec.sh"

#if [[ $2 ]]; then
#	theme=$2
#else
#	${path%/*}/set_rofi_width.sh $1
#if [[ $1 =~ apps|playback|power|wallpapers|window_action|workspaces ]]; then

#[[ $2 ]] && theme=$2 || ${path%/*}/set_rofi_width.sh $1

[[ $2 ]] && theme=$2 || theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)

if [[ $theme == icons ]]; then
	[[ $1 =~ apps|playback|power|wallpapers|window_action|workspaces ]] && ${path%/*}/set_rofi_width.sh $1 || theme=list
fi

#[[ $2 ]] && theme=$2 ||
#	theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)
#
#if [[ $theme == icons ]]; then
#	if [[ $1 =~ apps|playback|power|wallpapers|window_action|workspaces ]]; then
#		item_count=$($path/$1.sh | wc -l)
#
#		width=$(awk '
#			BEGIN { ic = '$item_count' }
#
#			function get_value() {
#				return gensub(/.* ([0-9]+).*/, "\\1", 1)
#			}
#
#			/font/ { fs = get_value() }
#			/spacing/ { s = get_value() }
#			/padding/ { if(wp) ep = get_value(); else wp = get_value() }
#			END { print 2 * wp + int(ic * (2 * ep + s + fs * 1.45)) - fs }' ~/.config/rofi/icons.rasi)
#
#		echo $width
#		sed -i "/width/ s/[0-9]\+/$width/" ~/.config/rofi/icons.rasi
#	else
#		theme=list
#	fi
#fi

rofi -modi "$modis" -show $1 -theme ${theme-main}
