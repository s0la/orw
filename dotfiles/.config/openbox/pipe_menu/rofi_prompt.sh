#!/bin/bash

[[ $1 == prompt ]] && prompt='prompt -c'
~/.config/openbox/pipe_menu/generate_menu.sh -c "~/.orw/scripts/toggle.sh rofi $prompt" -i dmenu window
