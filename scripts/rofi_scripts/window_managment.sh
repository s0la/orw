#!/bin/bash

if [[ -z $@ ]]; then
	echo -e 'fill\nmove\nresize\nevenly\ncenter\nleft half\nright half\nfullscreen\nsave window\nrestore window'
else
	windowctl=~/.orw/scripts/windowctl.sh

	case "$@" in
		fill) $windowctl $@;;
		center*) $windowctl -c;;
		evenly*) $windowctl resize -h ${@#* } -v ${@#* };;
		left*) $windowctl move -v 1/1 -h 1/1 resize -h 1/2 -v 1/1;;
		right*) $windowctl move -v 1/1 -h 2/2 resize -h 1/2 -v 1/1;;
		fullscreen*) $windowctl move -v 1/1 -h 1/1 resize -h 1/1 -v 1/1;;
		save*) $windowctl -s;;
		restore*) $windowctl -r;;
		*) eval "$windowctl $@";;
	esac
fi
