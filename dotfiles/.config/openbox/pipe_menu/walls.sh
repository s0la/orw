#!/bin/bash

~/.config/openbox/pipe_menu/generate_menu.sh -m '<menu id="select_wall"/>' -c '~/.orw/scripts/xwallctl.sh' -i 'auto:-A' 'next:-o n' 'prev:-o p' 'rand:-o' 'restore:-r' 'view_all:-v' menu
