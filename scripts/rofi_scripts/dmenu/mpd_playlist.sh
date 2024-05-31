#!/bin/bash

current_song="$(mpc current -f "%artist% - %title%")"

[[ $current_song ]] && empty='  '

empty=''

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
						#print int(rw / (f - 2) / 2 - 1)
						print int(rw / (f - 2)) - 1
						exit
					}
				}
			}' ~/.config/{rofi/large_list.rasi,orw/config})

	dashed_separator=$(printf '━% .0s' $(eval echo {0..$rofi_width}))
}

list_songs() {
	local index="$(mpc current -f "%position%")"
	((index)) && echo -en "\0active\x1f$index\n"

	mpc playlist | awk '
		BEGIN { print "options\n'"$dashed_separator"'" }
		{
			print $0
			if ($0 == "'"$current_song"'") nr = NR + 1
		} END {
			if (nr) printf "\0active\x1f%d\n", nr
		}'
}

list_songs() {
	local index="$(mpc current -f "%position%")"
	((index)) && echo -en "\0active\x1f$((index + 1))\n"
	echo -e "options\n$dashed_separator"
	mpc playlist
}

set_options() {
	sed -i "/^options/ s/\w*$/$1/" $0
	options=$1
}

options=

set_dashed_separator() {
	sed -i "/^dashed_separator/ s/''/'$dashed_separator'/" $0
}

if [[ -z $@ ]]; then
	get_rofi_width
	list_songs
else
	[[ $@ == ━* ]] &&
		separator=dashed_separator
	read $separator arg <<< "$@"

	[[ $arg ]] &&
		case $arg in
			"options")
				set_options true
				#sed -i '/^options/ s/\w*$/true/' $0
				echo -e 'back\nload\nsave\nclear\nrefresh'
				;;
			refresh) set_options;;
			clear|save*)
				set_options

				mpc -q $arg
				action="${arg%% *}ed"
				[[ $arg =~ ' ' ]] && playlist="${arg#* }"
				;;
			load)
				echo back
				mpc lsplaylists | grep -v .*.m3u
				set_options load
				;;
			back)
				[[ $options == load ]] &&
					set_options true &&
					echo -e 'back\nload\nsave\nclear\nrefresh' ||
					set_options
				;;
			*)
				if [[ $options ]]; then
					set_options

					playlist="$arg"
					action="loaded"
					mpc load "$playlist" > /dev/null
				else
					item="$arg"
					item_index=$(mpc playlist | awk '/'"${item//[()]/\.}"'/ { print NR; exit }')
					mpc -q play $item_index
				fi;;
		esac

	[[ $dashed_separator ]] || exit
	[[ $action && $action != load ]] && ~/.orw/scripts/notify.sh -p "<b>$playlist</b> playlist ${action//ee/e}."
	[[ $options ]] || list_songs
fi
