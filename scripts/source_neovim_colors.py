#!/usr/bin/python

import glob
import neovim

sockets = glob.glob('/tmp/nvim*/0', recursive=False)

if sockets:
    for socket in sockets:
        nvim_instance = neovim.attach('socket', path=socket)
        nvim_instance.command(':source ~/.config/nvim/plugin/statusline.vim')
