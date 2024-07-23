#!/bin/bash

nvr=$(which nvr)
plugins="~/.config/nvim/plugin/statusline.vim"

ls /run/user/$UID/nvim* |
	xargs -rI {} $nvr --nostart --servername {} -cc "silent so $plugins" &
