#!/bin/bash

while
	prompt=$(
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
				el = length($2)
				rl = length($3)
				s = 100 / (l - (el + rl + 2 * 2 + 1))

				e = int(sprintf("%.0f", $1 / s))
				r = sprintf("%.0f", (100 - $1) / s)

				ep = sprintf("%*s", e, "")
				rp = sprintf("%*s", r, "")

				gsub(" ", "━", ep)
				gsub(" ", "━", rp)

				printf "\n\n%s  %s%s%s  %s", $2, ep, "•", rp, $3
			}' ~/.config/rofi/cover_art.rasi \
				<(
					mpc current -f '%artist%\n%title%'
					mpc status '%percenttime% %currenttime% %totaltime%'
				))

	album=$(mpc current -f %album% | sed 's/[()]//g')
	cover="$(~/.orw/scripts/get_cover_art.sh)"
	[[ -f $cover ]] && ln -sf $cover /tmp/rofi_cover_art.png

	include='.*circle_empty\|repeat\|shuffle'
	exclude='Workspace\|arrow_\(left\|right\)\|x\|\(.*us_circle\)'
	read {volume_{up,down},prev,next,play,stop,pause,repeat,shuffle}_icon <<< \
		$(sed -n "/^\($exclude\)/! s/\($include\).*=//p" ~/.orw/scripts/icons | xargs)

	toggle_icon=$(mpc | awk -F '[][]' '
					NR == 2 { s = $2 }
					END { print (s == "playing") ? "'$pause_icon'" : "'$play_icon'" }')

	read index action <<< \
		$(cat <<- EOF | rofi -dmenu -format 'i s' -selected-row ${index:-2} -p "$prompt" -theme music_controls
			$volume_up_icon
			$prev_icon
			$toggle_icon
			$next_icon
			$volume_down_icon
		EOF
		)

	#index=0
	#read index action <<< $(
	#	(
	#		for e in $prompt $volume_up_icon $prev_icon $toggle_icon $next_icon $volume_down_icon; do
	#			((index)) &&
	#				printf "$e\n" || printf "\x00prompt\x1f$e\n"
	#			#echo -ne "\x1f$e\n"
	#		done
	#	) | rofi -dmenu -format 'i s' -selected-row ${index:-2} -p "$prompt" -theme music2
	#)

	[[ $action ]]
do
	case $action in
		$prev_icon) mpc_action=prev;;
		$next_icon) mpc_action=next;;
		$toggle_icon) mpc_action=toggle;;
		$repeat_icon) mpc_action=repeat;;
		$random_icon) mpc_action=random;;
		$volume_up_icon|$volume_down_icon)
			[[ $action == $volume_up_icon ]] && direction=+ || direction=-
			mpc -q volume ${direction}5
			~/.orw/scripts/system_notification.sh mpd_volume osd &
			continue
	esac

	mpc -q $mpc_action

	[[ $action == $toggle_icon ]] && break
done
