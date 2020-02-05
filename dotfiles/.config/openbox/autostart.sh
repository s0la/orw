#!/bin/bash

xset s off -dpms
xset s blank
xset s 1000

compton &
mpd &

path=~/.orw/scripts
$path/wallctl.sh -r &
$path/mpd_notifier.sh &
#$path/barctl.sh -b sep_test,lau,apps sep_test
