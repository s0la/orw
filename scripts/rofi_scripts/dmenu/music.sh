#!/bin/bash

while
	#prompt=$(mpc current -f '%title%\n%artist%\n%album%')
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

	#icons=          
	icon_prev=
	icon_next=
	icon_repeat=
	icon_shuffle=
	icon_volume_up=
	icon_volume_down=
	icon_toggle=$(mpc | awk -F '[][]' 'NR == 2 { s = $2 } END { print (s == "playing") ? "" : "" }')

	#echo -e "$icon_prev $icon_toggle $icon_next" | rofi -dmenu -sele
	#echo -e "  $icon_toggle  " | rofi -dmenu -selected_row 2 -p "$prompt" -theme music
	#echo -e "\n\n$icon_toggle\n\n" | rofi -dmenu -selected_row 2 -p "$prompt" -config ~/.config/rofi/music.rasi

	#action=$(cat <<- EOF | rofi -dmenu -selected-row 2 -p "$prompt" -config ~/.config/rofi/music.rasi
	read index action <<< \
		$(cat <<- EOF | rofi -dmenu -format 'i s' -selected-row ${index:-2} -p "$prompt" -theme music_player
			$icon_volume_up
			$icon_prev
			$icon_toggle
			$icon_next
			$icon_volume_down
		EOF
		)

	[[ $action ]]
do
	case $action in
		$icon_prev) mpc_action=prev;;
		$icon_next) mpc_action=next;;
		$icon_toggle) mpc_action=toggle;;
		$icon_repeat) mpc_action=repeat;;
		$icon_random) mpc_action=random;;
		$icon_volume_up|$icon_volume_down)
			[[ $action == $icon_volume_up ]] && direction=+ || direction=-
			mpc -q volume ${direction}5
			~/.orw/scripts/system_notification.sh mpd_volume osd &
	esac

	mpc -q $mpc_action

	[[ $action == $icon_toggle ]] && break
done
