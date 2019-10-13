#!/bin/bash

~/.config/openbox/pipe_menu/generate_menu.sh -m '<menu id="select_wall"/>' -c '~/.orw/scripts/wallctl.sh' -i 'auto:-A' 'next:-o n' 'prev:-o p' 'random:-o' menu
