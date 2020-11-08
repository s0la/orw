#!/bin/bash

rofi='rofi -dmenu -theme main'

option=$(echo -e '  play\n  stop\n  next\n  prev\n  volume up\n  volume down\n  toggle controls\nplaylist' | $rofi)

if [[ $option =~ playlist ]]; then
	song=$(mpc playlist | $rofi)
	~/.orw/scripts/play_song_from_playlist.sh "$song"
else
	case "$option" in
		*play*) mpc -q toggle;;
		*up) mpc -q volume +5;;
		*down) mpc -q volume -5;;
		*controls*)
			mode=$(awk -F '=' '/^current_mode/ { if ($2 == "controls") print "song_info"; else print "controls"}' ~/.orw/bar/mpd.sh)
			sed -i "/^current_mode/ s/=.*/=$mode/" ~/.orw/bar/mpd.sh;;
		*)
			mpc -q ${@#* }
			[[ ${@##* } == stop ]] && cat <<- EOF > ~/.orw/bar/main_bar.fifo
				PROGRESSBAR
				SONG_INFO not playing
				MPD_VOLUME
			EOF
	esac
fi
