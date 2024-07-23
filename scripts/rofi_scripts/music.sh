#!/bin/bash

while
	prompt=$(mpc current -f '%title%\n%artist%\n%album%' |
		awk '{ print (length($0) > 20) ? substr($0, 0, 20) ".." : $0 }')
	album=$(mpc current -f %album% | sed 's/[()]//g')
	cover="$HOME/Music/covers/${album// /_}.jpg"

	if [[ ! -f $cover ]]; then
		root=$(sed -n "/music_directory/ s/[^\"]*\"\(.*\)\/\?\".*/\1/p" ~/.config/mpd/mpd.conf)
		file=$(mpc current -f %file%)
		full_path="$root/$file"
		eval ffmpeg -loglevel quiet -i \"$full_path\" -vf scale=300:300 \"$cover\"
	fi

	[[ -f $cover ]] && ln -sf $cover /tmp/rofi_cover_art.png

	read {volume_{up,down},prev,next,play,stop,pause,repeat,shuffle}_icon <<< \
		$(sed -n '/^Workspace/! s/\(.*circle_empty\|repeat\|shuffle\).*=//p' ~/.orw/scripts/icons | xargs)

	toggle_icon=$(mpc | awk -F '[][]' '
							NR == 2 { s = $2 }
							END { print (s == "playing") ? "'$pause_icon'" : "'$play_icon'" }')

	read index action <<< \
		$(cat <<- EOF | rofi -dmenu -format 'i s' -selected-row ${index:-2} -p "$prompt" -theme music_player
			$volume_up_icon
			$prev_icon
			$toggle_icon
			$next_icon
			$volume_down_icon
		EOF
		)

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
