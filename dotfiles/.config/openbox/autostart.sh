#!/bin/bash

xset s off -dpms
xset s blank
xset s 1000

compton --config /dev/null &
mpd &

path=~/.orw/scripts
$path/wallctl.sh -r &
$path/mpd_notifier.sh &
$path/barctl.sh
