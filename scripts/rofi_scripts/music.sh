#!/bin/bash

while
	#prompt=$(mpc current -f '%artist%\n%title%')
	#prompt=$(mpc current -f '%artist% - %title%\n%album%' |
	#	awk '{ print (length($0) > 25) ? substr($0, 0, 25) ".." : $0 }')

	prompt=$(
		(
			mpc current -f '%artist%\n%title%'
			mpc status '%percenttime% %currenttime% %totaltime%'
		) | awk '
			BEGIN { l = 31 }
			NR < 3 {
				print (length($0) > l) ? substr($0, 0, l - 2) ".." : \
					sprintf("%*s", l - int((l - length($0)) / 2), $0)
			}

			END {
				sub("%", "")
				el = length($2)
				rl = length($3)
				s = 100 / (l - (el + rl + 2 * 2 + 1))
				#s = 6

				e = int($1 / s)
				r = int((100 - $1) / s)

				ep = sprintf("%*s", e, "")
				rp = sprintf("%*s", r, "")

				#gsub(" ", "■", ep)
				#gsub(" ", "━", rp)
				gsub(" ", "━", ep)
				gsub(" ", "━", rp)
				#gsub(" ", "―", ep)
				#gsub(" ", "―", rp)

				#printf "\x1f<b>%s</b>%s", ep, rp
				printf "\n\n %s  %s%s%s  %s", $2, ep, "•", rp, $3
			}')

	album=$(mpc current -f %album% | sed 's/[()]//g')
	#cover="$HOME/Music/covers/${album// /_}.jpg"

	#if [[ ! -f $cover ]]; then
	#	root=$(sed -n "/music_directory/ s/[^\"]*\"\(.*\)\/\?\".*/\1/p" ~/.config/mpd/mpd.conf)
	#	[[ -d $root/covers ]] || mkdir $root/covers
	#	file=$(mpc current -f %file%)
	#	full_path="$root/$file"
	#	eval ffmpeg -loglevel quiet -i \"$full_path\" -vf scale=300:300 \"$cover\"
	#fi

	cover="$(~/.orw/scripts/get_cover_art.sh)"
	[[ -f $cover ]] && ln -sf $cover /tmp/rofi_cover_art.png

	include='.*circle_empty\|repeat\|shuffle'
	exclude='Workspace\|arrow_\(left\|right\)\|x\|\(.*us_circle\)'
	read {volume_{up,down},prev,next,play,stop,pause,repeat,shuffle}_icon <<< \
		$(sed -n "/^\($exclude\)/! s/\($include\).*=//p" ~/.orw/scripts/icons | xargs)

	echo $play_icon, $pause_icon

	toggle_icon=$(mpc | awk -F '[][]' '
					NR == 2 { s = $2 }
					END { print (s == "playing") ? "'$pause_icon'" : "'$play_icon'" }')

	read index action <<< \
		$(cat <<- EOF | rofi -dmenu -format 'i s' -selected-row ${index:-2} -p "$prompt" -theme music
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
	esac

	mpc -q $mpc_action

	[[ $action == $toggle_icon ]] && break
done
