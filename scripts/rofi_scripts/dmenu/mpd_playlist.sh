#!/bin/bash

indicator='●'

#song_index=$(mpc current -f %position%)
current_song="$(mpc current -f "%artist% - %title%")"

#read index current_song <<< "$(mpc current -f "%position% %artist% - %title%")"
[[ $current_song ]] && empty='  '

empty=''

list_songs() {
	mpc playlist | awk '
		BEGIN { print "'"$empty"'options\n'"$empty"'━━━━━━━" }
		{ p = ($0 == "'"$current_song"'") ? "'$indicator' " : "'"$empty"'"; print p $0 }'
}

#	mpc playlist | awk '
#		BEGIN { print "options\n'"$dashed_separator"'" }
#		{
#			#p = ($0 == "'"$current_song"'") ? "\0active\x1f1\n" : "'"$empty"'"
#
#			print ($0 == "'"$current_song"'"), $0
#		}'
#	exit

#rofi_width=$(awk '
#		function get_value() {
#			return gensub(".* ([0-9]+).*", "\\1", 1)
#		}
#
#		/^\s*font/ { f = get_value() }
#		/^\s*window-width/ { ww = get_value() }
#		/^\s*switcher-width/ { sw = get_value() }
#		/^\s*window-padding/ { wp = get_value() }
#		/^\s*element-padding/ { ep = get_value() }
#		END {
#			#rw = int('$display_width' * ww / 100)
#			#iw = rw - sw - 2 * (wp + ep)
#
#			rw = int('$display_width' * (ww - sw - 2 * wp) / 100)
#			rw -= 2 * ep
#			print int(rw / (f - 2) / 2 - 1)
#		}' ~/.config/rofi/sidebar_new.rasi)
#
#dashed_separator=$(printf '━ %.0s' $(eval echo {0..$rofi_width}))

get_rofi_width() {
	read x y <<< $(xdotool getactivewindow getwindowgeometry |
		sed -n '2s/.*\s\([0-9]*\),\([0-9]*\).*/\1 \2/p')

	rofi_width=$(awk '
			function get_value() {
				return gensub(".* ([0-9]+).*", "\\1", 1)
			}

			{
				if (NR == FNR) {
					if (/^\s*font/) f = get_value()
					if (/^\s*window-width/) ww = get_value()
					if (/^\s*switcher-width/) sw = get_value()
					if (/^\s*window-padding/) wp = get_value()
					if (/^\s*element-padding/) ep = get_value()
				} else {
					if ($1 == "orientation") {
						if ($2 == "horizontal") {
							p = '${x:-1}'
							pf = 2
						} else {
							p = '${y:-1}'
							pf = 3
						}
					}

					if (/^display_[0-9]_size/) { w = $2 }
					if (/^display_[0-9]_xy/ && $pf > p) {
						rw = int(w * (ww - sw - 2 * wp) / 100)
						rw -= 2 * ep
						print int(rw / (f - 2) / 2 - 1)
						exit
					}
				}
			}' ~/.config/{rofi/sidebar_new.rasi,orw/config})

	dashed_separator=$(printf '━ %.0s' $(eval echo {0..$rofi_width}))
	#echo -e $rofi_width, $dashed_separator
}

get_rofi_width
#exit
#dashed_separator="$1"
#shfit

list_songs() {
	local index="$(mpc current -f "%position%")"
	((index)) && echo -en "\0active\x1f$index\n"

	mpc playlist | awk '
		BEGIN { print "options\n'"$dashed_separator"'" }
		{
			#as = as "\n" $0
			print $0
			if ($0 == "'"$current_song"'") nr = NR + 1
		} END {
			if (nr) printf "\0active\x1f%d\n", nr
			#if (nr) print nr "\n\0active\x1f%d\n" nr
			#print as
		}'
}

list_songs() {
	#read index current_song <<< "$(mpc current -f "%position% %artist% - %title%")"
	local index="$(mpc current -f "%position%")"
	((index)) && echo -en "\0active\x1f$((index + 1))\n"
	echo -e "options\n$dashed_separator"
	mpc playlist
	#~/.orw/scripts/notify.sh "IND: $index" &

	#mpc playlist | awk '
	#	BEGIN { print "options\n'"$dashed_separator"'" }
	#	{ print $0 }
	#	END { if ('${index:-0}') printf "\0active\x1f%d\n", '${index}' }'

	#mpc playlist | awk '
	#	BEGIN { print "options\n'"$dashed_separator"'" }
	#	{ print $0 }'
}

set_options() {
	sed -i "/^options/ s/\w*$/$1/" $0
	options=$1
}

options=

#if [[ -z $@ ]]; then
#	IFS=$'\n' read -d '' num songs <<< $(list_songs)
#	echo "$songs"
#else

#echo -en "\0active\x1f$index\n",

if [[ -z $@ ]]; then
	list_songs
else
#if [[ $@ ]]; then
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
				#ind=$(sed -n "/${item//[\(\)]/\.}/d;=")

				#item_stripped="${item:2}"
				#echo item "${item//\//\\/}"
				#item_index=$(mpc playlist | awk '
				#	/'"${item_stripped//\//\\/}"'/ { print NR; exit }')

				item_index=$(mpc playlist | awk '/'"${item//[()]/\.}"'/ { print NR; exit }')
				mpc -q play $item_index
				#~/.orw/scripts/play_song_from_playlist.sh "${item:${#empty}}"
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
