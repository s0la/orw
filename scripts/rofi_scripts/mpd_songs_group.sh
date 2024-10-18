#!/bin/bash

path=~/.orw/scripts/rofi_scripts

read x y <<< $(xdotool getactivewindow getwindowgeometry |
	sed -n '2s/.*\s\([0-9]*\),\([0-9]*\).*/\1 \2/p')

rofi_width=$(awk '
		function get_value() {
			return gensub(".* ([0-9]+).*", "\\1", 1)
		}

		{
			if (NR == FNR) {
				if (!f && /^\s*font/) f = get_value()
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
				if (/^display_[0-9]_xy/ && p > $pf) {
					rw = int(w * (ww - sw - 2 * wp) / 100)
					rw -= 2 * ep
					print int((rw / f) * 1.13) + 0
					exit
				}
			}
		}' ~/.config/{rofi/sidebar.rasi,orw/config})

dashed_separator=$(printf '━% .0s' $(eval echo {0..$rofi_width}))

read playlist library <<< \
	$(sed -n 's/^\(list\|library\)=//p' ~/.orw/scripts/icons | xargs)

modis+="$playlist:$path/mpd_playlist.sh $dashed_separator,"
modis+="$library:$path/mpd_library.sh $dashed_separator"
rofi -modi "$modis" -show $playlist -theme sidebar
