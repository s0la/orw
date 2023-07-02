#!/bin/bash

#get_rofi_width() {
#	read x y <<< $(xdotool getactivewindow getwindowgeometry |
#		sed -n '2s/.*\s\([0-9]*\),\([0-9]*\).*/\1 \2/p')
#
#
#	rofi_width=$(awk '
#			function get_value() {
#				return gensub(".* ([0-9]+).*", "\\1", 1)
#			}
#
#			{
#				if (NR == FNR) {
#					if (/^\s*font/) f = get_value()
#					if (/^\s*window-width/) ww = get_value()
#					if (/^\s*switcher-width/) sw = get_value()
#					if (/^\s*window-padding/) wp = get_value()
#					if (/^\s*element-padding/) ep = get_value()
#				} else {
#					if ($1 == "orientation") {
#						if ($2 == "horizontal") {
#							p = '$x'
#							pf = 2
#						} else {
#							p = '$y'
#							pf = 2
#						}
#					}
#
#					if (/^display_[0-9]_size/) { w = $2 }
#					if (/^display_[0-9]_xy/ && $pf > p) {
#						rw = int(w * (ww - sw - 2 * wp) / 100)
#						rw -= 2 * ep
#						print int(rw / (f - 2) / 2 - 1)
#						exit
#					}
#				}
#			}' ~/.config/{rofi/sidebar_new.rasi,orw/config})
#}

#get_rofi_width
#dashed_separator=$(printf '━ %.0s' $(eval echo {0..$rofi_width}))

path=~/.orw/scripts/rofi_scripts/dmenu
#theme=$(awk -F '[".]' 'END { print $(NF - 2) }' ~/.config/rofi/main.rasi)

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
		}' ~/.config/{rofi/sidebar_new.rasi,orw/config})

dashed_separator=$(printf '━% .0s' $(eval echo {0..$rofi_width}))
#~/.orw/scripts/notify.sh -p "$dashed_separator"




#[[ $theme =~ dmenu ]] && ${path%/*}/set_rofi_geometry.sh
#${path%/*}/set_rofi_margins.sh

#                       

modis+=":$path/mpd_playlist.sh $dashed_separator,"
modis+=":$path/mpd_library.sh $dashed_separator"
#modis+=":$path/mpd_playlist.sh,"
#modis+=":$path/mpd_library.sh"
rofi -modi "$modis" -show  -theme sidebar_new
exit

modis+="library:$path/mpd_library.sh $dashed_separator,"
modis+="play:$path/mpd_playlist.sh $dashed_separator"
rofi -modi "$modis" -show $1 -theme ${2:-large_list}
