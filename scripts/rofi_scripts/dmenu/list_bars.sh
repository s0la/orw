#!/bin/bash

config_root=~/.config/orw/bar/configs
bar=$(ls $config_root/* | sed 's/.*\///' | rofi -dmenu -theme list)
[[ $bar ]] && ~/.orw/scripts/barctl.sh -b $bar &
