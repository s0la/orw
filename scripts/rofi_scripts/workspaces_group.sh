#!/bin/bash

path=~/.orw/scripts/rofi_scripts
${path%/*}/set_rofi_margins.sh

modis+="wall:$path/workspaces.sh wall,"
modis+="workspaces:$path/workspaces.sh,"
modis+="move_to:$path/workspaces.sh move"
rofi -modi "$modis" -show $1 -theme main
