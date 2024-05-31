#!/bin/bash

#xrandr --output HDMI-2 --rotate left

xset s off -dpms
xset s blank
xset s 500

#compton --config /dev/null &
#picom -b
#~/Downloads/picom/build/src/picom -b --animations \
#	--animation-window-mass 0.5 --animation-for-open-window zoom --animation-stiffness 500
#picom --experimental-backends -b &> /dev/null
#~/Downloads/picom/build/src/picom --experimental-backends -b &> /dev/null
~/Downloads/picom/build/src/picom -b &> /dev/null
mpd &

path=~/.orw/scripts
$path/wallctl.sh -r &
#$path/mpd_notifier.sh &
$path/barctl.sh
$path/spy_windows.sh &>> ~/w.log &

#mode=$(awk '/^mode/ { print $NF }' ~/.config/orw/config)
#[[ $mode == floating ]] || $path/tile_windows.sh &
#[[ $mode == floating ]] || $path/spy_windows.sh &
#[[ $mode == floating ]] || $path/swb.sh &

xrdb -load ~/.config/X11/xresources
