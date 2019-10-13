#!/bin/bash

path=~/.orw/scripts/rofi_scripts
${path%/*}/set_rofi_margins.sh

modis+="colors:$path/colors.sh,"
modis+="color_modules:$path/color_modules.sh"
rofi -modi "$modis" -show $1 -theme main
