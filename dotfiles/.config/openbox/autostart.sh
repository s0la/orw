#!/bin/bash

xset s off -dpms
xset s blank
xset s 1000

mpd &
compton &

path=~/.orw/scripts
$path/wallctl.sh -r &
$path/barctl.sh -b orw &
