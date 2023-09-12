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

#mode=$(awk '/^mode/ { print $NF }' ~/.config/orw/config)
desktop=$(xdotool get_desktop)
is_tiling=$(awk '/^tiling_workspaces/ { print (/\s'$desktop'\s/) }' \
	~/.orw/scripts/spy_windows.sh)

#if [[ ! $mode =~ floating|selection ]]; then
if ((is_tiling)); then
	#~/.orw/scripts/windowctl.sh -A
	#~/.orw/scripts/run.sh sxiv -tb "$@"
	#~/.orw/scripts/notify.sh "$@"
	#echo sxiv -tb "$@"
	#exit
	geometry='100x100'
	#xdotool search --name 'sxiv' set_window --name 'wallctl'
	#wmctrl -r :ACTIVE: -T wallctl
else
	#id=$(xdotool getactivewindow)
	#read x y <<< $(wmctrl -lG | awk '$1 == sprintf("0x%.8x", "'$id'") { print $3, $4 }')
	##read -a window_properties <<< $(~/.orw/scripts/windowctl.sh -p)
	##geaometry=$(~/.orw/scripts/get_display.sh ${window_properties[3]} ${window_properties[4]} |\
	#geaometry=$(~/.orw/scripts/get_display.sh $x $y |
	#	awk '\
	#		BEGIN {
	#			wp = '${width:-28}'
	#			hp = '${height:-60}'
	#		} {
	#			w = int($4 * wp / 100)
	#			h = int($5 * hp / 100)
	#			print " -g " w "x" h
	#		}')
	geometry="${width:-450}x${height:-600}"
fi

eval sxiv -tbg $geometry "$@" &
