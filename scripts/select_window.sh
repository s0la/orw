#!/bin/bash

xdotool keydown Super + Shift sleep 0.200 key h + l

~/.orw/scripts/listen_input.py

xdotool keyup Shift+Super
sleep 0.1
