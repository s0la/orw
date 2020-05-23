#!/bin/bash

(($(sed -n '/class.*\*/=' ~/.config/openbox/rc.xml))) &&
	close='&& ~/.orw/scripts/get_window_neighbours.sh'

#until [[ $(wmctrl -l | awk '$NF == "'$1'" { print "running" }') ]]; do continue; done
until [[ $(wmctrl -l | awk '$NF == "'$1'"') ]]; do continue; done
shift
eval "$@" $close
