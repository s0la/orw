#!/bin/bash

modules=( ob gtk bar vim rofi lock term tmux bash dunst firefox ncmpcpp )

~/.config/openbox/pipe_menu/generate_menu.sh -c "~/.orw/scripts/rice_and_shine.sh -C $1 -m" -i "all " ${modules[*]}
