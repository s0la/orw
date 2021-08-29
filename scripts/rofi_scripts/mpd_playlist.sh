#!/bin/bash

indicator='●'

song_index=$(mpc current -f %position%)
current_song="$(mpc current -f "%artist% - %title%")"
[[ $current_song ]] && empty='  '

list_songs() {
	mpc playlist | awk '
		BEGIN { print "'"$empty"'options\n'"$empty"'━━━━━━━" }
		{ p = ($0 == "'"$current_song"'") ? "'$indicator' " : "'"$empty"'"; print p $0 }'
}

set_options() {
	sed -i "/^options/ s/\w*$/$1/" $0
	options=$1
}

options=

if [[ -z $@ ]]; then
	list_songs
else
	case $@ in
		"${empty}options")
			set_options true
			sed -i '/^options/ s/\w*$/true/' $0
			echo -e 'load\nsave\nclear\nrefresh';;
		refresh) set_options;;
		clear|save*)
			set_options

			mpc -q $@
			action="${@%% *}ed"
			[[ $@ =~ ' ' ]] && playlist="${@#* }";;
		load) mpc lsplaylists | grep -v .*.m3u;;
		*)
			if [[ $options ]]; then
				set_options
				playlist="$@"
				action="loaded"
				mpc load "$playlist" > /dev/null
			else
				item="$@"
				~/.orw/scripts/play_song_from_playlist.sh "${item:${#empty}}"
			fi;;
	esac

	[[ $action && $action != load ]] && ~/.orw/scripts/notify.sh -p "<b>$playlist</b> playlist ${action//ee/e}."
	[[ $options ]] || list_songs
fi

#current_song="$(mpc current -f "%artist% - %title%")"
#[[ $current_song ]] && empty='  '
#
#if [[ -z $@ || $@ == refresh ]]; then
#	#mpc playlist | awk '$0 == "'"$current_song"'" { $0 = "'$indicator' " $0 } { print }'
#	echo -e 'refresh\n━━━━━━━'
#	mpc playlist | awk '{ p = ($0 == "'"$current_song"'") ? "'$indicator' " : "'"$empty"'"; print p $0 }'
#else
#	item="$@"
#	[[ $item != refresh ]] && ~/.orw/scripts/play_song_from_playlist.sh "${item:${#empty}}"
#	#~/.orw/scripts/play_song_from_playlist.sh "${@#$indicator }"
#fi
