#!/bin/bash

xdotool keydown Super + Shift sleep 0.1 key h sleep 0.1 key l

~/.orw/scripts/listen_input.py

xdotool keyup Shift+Super
sleep 0.1
