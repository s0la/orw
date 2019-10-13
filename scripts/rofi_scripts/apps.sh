#!/bin/bash

if [[ -z $@ ]]; then
	echo -e "lock\ntile\nterminal\ndropdown\nfile manager\nweb browser"
else
	killall rofi 2> /dev/null

    case "$@" in
		lock) ~/.orw/scripts/lock_screen.sh;;
        web*) firefox ${@#*browser};;
        file*) thunar ${@#*manager};;
        terminal) termite -t termite $@;;
        dropdown*) ~/.orw/scripts/dropdown.sh ${@#* };;
		tile*) ~/.orw/scripts/tile_terminal.sh ${@#* };;
    esac
fi
