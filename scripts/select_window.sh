#!/bin/bash

xdotool keyup Shift+Super
xdotool keydown Super + Shift #sleep 0.1 key h sleep 0.1 key l

parent=$(ps -p $$ -o ppid= |
	xargs ps -o args= -p | awk '{ print $0 !~ "bash$" }')

#~/.orw/scripts/listen_input.py
~/.orw/scripts/listen_key.sh $parent $1 #&> /dev/null

xdotool keyup Shift+Super
sleep 0.1
