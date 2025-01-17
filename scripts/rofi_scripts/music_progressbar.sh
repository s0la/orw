#!/bin/bash

while
	IFS=$'\n' read -d '' artist title active_indices progressbar <<< $(
		awk '
			NR == FNR {
				if (/art-width|window-padding|font/) {
					v = $0
					gsub("^[^0-9]*|(px|\").*", "", v)

					switch ($1) {
						case /padding/: wp = v; break
						case /width/: w = v; break
						case /font/: f = v; break 
					}
				}

				if ($1 == "}") nextfile
			} 

			NR > FNR && FNR < 3 {
				if (FNR == 1) {
					l = int(sprintf("%.0f", (w - 2 * wp) / (f / 1.1)))
					so = ($1 == "0%")
				}

				i = (so) ? "no track is playing" : $0

				print (length(i) > l) ? substr(i, 0, l - 2) ".." : \
					sprintf("%*s", l - int((l - length(i)) / 2), i)

				if (so) exit
			}

			END {
				sub("%", "")
				s = 100 / l

				e = int(sprintf("%.0f", $1 / s))
				ai = 0

				for (ps=1; ps<=l; ps++) {
					if (ps <= e) ai = ai "," ps
					pb = pb "\n━"
				}

				if (so) print "\n "

				print ai pb
			}' ~/.config/rofi/cover_art.rasi \
				<(
					mpc current -f '%artist%\n%title%'
					mpc status '%percenttime%'
				))

	length=$(wc -w <<< "${progressbar//\\n}")
	theme_str="* { lines: $length; }"
	prompt="$artist"$'\n'"$title"

	[[ $active_indices == *,* ]] &&
		active="-a ${active_indices%,*}" || unset active

	album=$(mpc current -f %album% | sed 's/[()]//g')
	cover="$(~/.orw/scripts/get_cover_art.sh)"
	[[ -f $cover ]] && ln -sf $cover /tmp/rofi_cover_art.png

	index=$(echo -e "$progressbar" | rofi -dmenu -format 'i' \
		-selected-row ${active_indices##*,} $active \
		-p "$prompt" -theme-str "$theme_str" -theme music_progressbar)

	[[ $index ]]
do
	mpc -q seek $((index * 100 / length))%
done
