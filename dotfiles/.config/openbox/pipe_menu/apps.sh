#!/bin/bash

~/.config/openbox/pipe_menu/generate_menu.sh \
    -m '<menu id="ncmpcpp"/>' \
    -i 'tile ~/.orw/scripts/tile_terminal_mouse.sh' \
	'terminal:termite' 'menu' 'dropdown:~/.orw/scripts/dropdown.sh' 'file_manager:thunar' 'web_browser:firefox'
