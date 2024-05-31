#!/bin/bash

read -a buttons <<< $(awk '
	b { gsub(".*\\(|\\).*", ""); print; exit }
	/^buttons/ { b = 1 }' ~/.orw/scripts/toggle.sh)

~/.config/openbox/pipe_menu/generate_menu.sh -c '~/.orw/scripts/toggle.sh buttons' -i ${buttons[*]}
