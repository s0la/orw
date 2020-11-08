#!/bin/bash

if [[ -z $@ ]]; then
	echo -e 'load\nsave\nclear'
else
	case $@ in
		clear|save*)
			mpc -q $@
			action="${@%% *}ed"
			[[ $@ =~ ' ' ]] && playlist="${@#* }";;
		load) mpc lsplaylists | grep -v .*.m3u;;
		*)
			playlist="$@"
			action="loaded"
			mpc load "$playlist" > /dev/null;;
	esac

	[[ $@ != load ]] && ~/.orw/scripts/notify.sh -p "<b>$playlist</b> playlist ${action//ee/e}."
fi
