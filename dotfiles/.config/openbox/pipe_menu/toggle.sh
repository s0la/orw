#!/bin/bash

~/.config/openbox/pipe_menu/generate_menu.sh -m '<menu id="rofi"/>,<menu id="buttons"/>' \
	-c '~/.orw/scripts/toggle.sh' -i menu icons titlebar menu
