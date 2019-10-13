#!/bin/bash

if [[ -z $@ ]]; then
	echo -e 'default\nvertical\nsplit\ncover\ndual horizontal\ndual vertical\nset cover art\nncmpcpp'
else
	killall rofi
	ncmpcpp=~/.orw/scripts/ncmpcpp.sh

	arguments="$@"
	layout="${arguments%%-*}"
	flags="${arguments#$layout}"

	case "$layout" in
		default*) flags+=' -i';;
		split*) flags+=' -s -i';;
		set*) flags+=' -R';;
		cover*) flags+=' -c -i';;
		dual*h*) flags+=' -d';;
		dual*v*) flags+=' -V -d';;
		vertical*) flags+=' -w 55 -h 37 -i';;
	esac

	eval $ncmpcpp "$flags"
fi
