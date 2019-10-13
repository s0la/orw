#!/bin/bash

path=~/.orw/scripts/rofi_scripts
${path%/*}/set_rofi_margins.sh

modis+="apps:$path/apps.sh,"
modis+="execute:$path/execute.sh,run"
rofi -modi "$modis" -show $1 -theme main
