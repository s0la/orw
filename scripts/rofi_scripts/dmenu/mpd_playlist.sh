#!/bin/bash

indicator=''
indicator='●'

song_index=$(mpc current -f %position%)
current_song="$(mpc current -f "%artist% - %title%")"
[[ $current_song ]] && empty='  '

#song=$(mpc playlist | awk '{
#	p = ($0 == "'"$current_song"'") ? "'$indicator' " : "'"$empty"'"
#	print p $0 }' | rofi -dmenu -i -selected-row $((song_index - 1)) -theme large_list)

list_songs() {
	mpc playlist | awk '
		BEGIN { print "'"$empty"'options\n'"$empty"'━━━━━━━" }
		{ p = ($0 == "'"$current_song"'") ? "'$indicator' " : "'"$empty"'"; print p $0 }'
}

get_item() {
	item=$(list_songs | rofi -dmenu -i -selected-row $((song_index + 1)) -theme large_list)
}

#while true; do
	get_item

	if [[ ${item#$empty} == options ]]; then
		option=$(echo -e 'back\nload\nsave\nclear\nrefresh' | rofi -dmenu -theme large_list)

		case $option in
			refresh) set_options;;
			clear|save*)
				mpc -q $option
				action="${option%% *}ed"
				[[ $option =~ ' ' ]] && playlist="${option#* }";;
			load)
				playlist=$(mpc lsplaylists | grep -v .*.m3u | rofi -dmenu -theme large_list)
				action="loaded"
				mpc load "$playlist" > /dev/null
		esac

		[[ $@ != load ]] && ~/.orw/scripts/notify.sh -p "<b>$playlist</b> playlist ${action//ee/e}."
		get_item
	fi

	[[ $item ]] && ~/.orw/scripts/play_song_from_playlist.sh "${item:${#empty}}"
	#~/.orw/scripts/play_song_from_playlist.sh "${item:${#empty}}"
#done

#[[ ${item#* } == refresh ]] && get_item
#[[ $item ]] && ~/.orw/scripts/play_song_from_playlist.sh "${item:${#empty}}"
#[[ $song ]] && ~/.orw/scripts/play_song_from_playlist.sh "${song:${#empty}}"

#if [[ -z $@ ]]; then
#	mpc playlist | awk '{
#		p = ($0 == "'"$current_song"'") ? "'$indicator' " : "'"$empty"'"
#		print p $0 }'
#else
#	~/.orw/scripts/play_song_from_playlist.sh "${song:${#empty}}"
#fi
