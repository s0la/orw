#!/bin/bash

nvr=$(which nvr)
plugins="~/.config/nvim/plugin/statusline.vim"

#comm -12 <($nvr --nostart --serverlist) <(ls /run/user/$UID/nvim*)
#exit

ls /run/user/$UID/nvim* |
	xargs -rI {} $nvr --nostart --servername {} -cc "silent so $plugins" &
exit

$nvr --nostart --serverlist |
	xargs -rI {} $nvr --nostart --servername {} -cc "silent so $plugins" &
