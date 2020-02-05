#!/bin/bash

while : ; do
	change=$(mpc idle)

	if [[ $change == player ]]; then
		status=$(mpc status | awk -F '[][]' 'NR == 2 { s = $2 } END { print s ? s : "stopped" }')

		#~/.orw/scripts/notify.sh "$status"

		case $status in
			stopped)
				all_bars=( $(ps aux | awk -F '[- ]' '!/awk/ && /generate_bar.* -m [^ ]*[ip-]/ {
					b = gensub(".*-n (\\w*).*", "\\1", 1)
					if(ab !~ "\\<" b "\\>") {
						ab = ab " " b
					}
				} END { print ab }') )

				[[ $all_bars ]] && for bar in ${all_bars[*]}; do
					cat <<- EOF > ~/.config/orw/bar/fifos/$bar.fifo
						PROGRESSBAR
						SONG_INFO not playing
						MPD_VOLUME
					EOF
				done;;
			playing)
				~/.orw/scripts/get_cover_art.sh > /dev/null
				~/.orw/scripts/song_notification.sh

				cover=$(ps aux | awk '!/awk/ && /title cover_art_widget/ { c = 1 } END { print c }')
				((cover)) && ~/.orw/scripts/widgets.sh cover show
		esac
	fi
done
