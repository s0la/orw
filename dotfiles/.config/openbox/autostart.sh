#!/bin/bash

xset s off -dpms
xset s blank
xset s 1000

#compton --config /dev/null &
picom -b
#picom --experimental-backends -b &> /dev/null
mpd &

path=~/.orw/scripts
$path/wallctl.sh -r &
$path/mpd_notifier.sh &
$path/barctl.sh

mode=$(awk '/^mode/ { print $NF }' ~/.config/orw/config)
[[ $mode == floating ]] || $path/tile_windows.sh &

xrdb -load ~/.config/X11/xresources
