#!/bin/bash

read fg bg <<< $(awk '\
	$1 == "background" {
		argb = gensub(".*\\(([0-9,]*),(.*[0-9]).*", "\\2,\\1", 1)
		split(argb, argba, ",")
		printf "#%.2x%.2x%.2x\n", argba[2], argba[3], argba[4]
	}
	$1 == "foreground" { print $NF }' ~/.config/termite/config | xargs)

[[ $1 == -k ]] && killall screenkey ||
	screenkey -g 500x400+710+650 -t 1.2 -s medium --bg-color $bg --font-color $fg
