#!/bin/bash

path=/sys/class/backlight/*/
read brightness_step <<< $(awk '{ print int($1 / 100) }' $path/max_brightness)
read brightness_level <<< $(awk '{ print int($1 / '$brightness_step') }' $path/brightness)

[[ $1 =~ [+-] ]] && new_level=$((brightness_level $1)) || new_level=$1
((new_level *= brightness_step))

sudo echo "$new_level" > $path/brightness
