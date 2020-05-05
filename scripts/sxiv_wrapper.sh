#!/bin/bash

while getopts :w:h: flag; do
	case $flag in
		w) width=$OPTARG;;
		h) height=$OPTARG;;
		*) continue
	esac

	(( arg_count += 2 ))
done

((arg_count)) && shift $arg_count

read -a window_properties <<< $(~/.orw/scripts/windowctl.sh -p)
geaometry=$(~/.orw/scripts/get_display.sh ${window_properties[3]} ${window_properties[4]} |\
	awk '\
		BEGIN {
			wp = '${width:-28}'
			hp = '${height:-60}'
		} {
			w = int($4 * wp / 100)
			h = int($5 * hp / 100)
			print w "x" h
		}')

eval sxiv -tbg $geaometry "$@"
