#!/bin/bash

if [[ -z $@ ]]; then
	echo -e '  close\n  minimize\n  maximize'
else
	case "$@" in
		*close*) wmctrl -c :ACTIVE:;;
		*min*) xdotool getactivewindow windowminimize;;
		*max*) wmctrl -r :ACTIVE: -b toggle,maximized_vert,maximized_horz;;
	esac
fi
