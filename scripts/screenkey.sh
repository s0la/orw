#!/bin/bash

[[ $1 == -k ]] && killall screenkey ||
	screenkey -g 500x400+710+650 -t 1.2 -s medium --bg-color \#303030 --font-color \#a0a0a0
