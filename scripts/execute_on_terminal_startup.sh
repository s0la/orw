#!/bin/bash

title=$1
(($(sed -n '/class.*\*/=' ~/.config/openbox/rc.xml))) &&
	close='&& ~/.orw/scripts/get_window_neighbours.sh'

#until [[ $(wmctrl -l | awk '$NF == "'$1'" { print "running" }') ]]; do continue; done
until [[ $(wmctrl -l | awk '$NF == "'$title'"') ]]; do continue; done
shift
#eval "$@" $close
#~/.orw/scripts/notify.sh "command: $@"
eval "$@"
