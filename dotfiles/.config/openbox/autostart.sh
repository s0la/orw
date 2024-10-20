#!/bin/bash

xrandr --output eDP-1 --below HDMI-1

xset s off -dpms
xset s blank
xset s 500

#~/Downloads/picom/build/src/picom -b --animations \
#	--animation-window-mass 0.5 --animation-for-open-window zoom --animation-stiffness 500
#picom --experimental-backends -b &> /dev/null
#~/Downloads/picom/build/src/picom --experimental-backends -b &> /dev/null
#~/Downloads/picom/build/src/picom -b &> /dev/null
picom --config ~/.config/picom/picom_animations.conf -b &> /dev/null
mpd &

path=~/.orw/scripts
$path/wallctl.sh -r &
$path/barctl.sh
$path/spy_windows.sh &>> ~/w.log &

xrdb -load ~/.config/X11/xresources
