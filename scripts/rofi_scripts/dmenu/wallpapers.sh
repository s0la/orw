#!/bin/bash

config=~/.config/orw/config
theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)
[[ $theme =~ dmenu|icons ]] && ~/.orw/scripts/set_rofi_geometry.sh wallpapers

get_directory() {
	read depth directory <<< $(awk '\
		/^directory|depth/ { sub("[^ ]* ", ""); print }' $config | xargs -d '\n')
	root="${directory%/\{*}"
}

if [[ $theme == icons ]]; then
	#auto=$(systemctl --user status change_wallpaper.timer | awk '/Active/ { print ($2 == "active") ? "" : "" }')
	#auto=$(systemctl --user status change_wallpaper.timer | awk '/Active/ { if($2 == "active") print "-a 5" }')
	active=$(systemctl --user is-active change_wallpaper.timer | awk '{ if(/^active/) print "-a 6" }')
	prev= next= rand= restore= view= 
	prev= next= rand= restore= view= select= auto=
	prev= next= rand= restore= view= select= auto=
	prev= next= rand= restore= view= select= auto=
	prev= next= rand= restore= view= select= auto=
	prev= next= rand= restore= view= select= auto=
	prev= next= rand= restore= view= select= auto=
else
	next=next prev=prev rand=rand restore=restore view=view_all select=select auto=autochange nl=\n
fi

#action=$(echo -e "$prev\n$next\n$rand\n$view\n$index$nl$restore\n$interval$nl$auto" | rofi -dmenu $active -theme main)
#action=$(cat <<- EOF | rofi -dmenu -selected-row 1 $active -theme main
#	$prev
#	$rand
#	$next
#	$view
#	$restore
#	$select
#	$auto
#EOF
#)

list_actions() {
	read row action <<< $(cat <<- EOF | rofi -dmenu -format 'i s' -selected-row ${row:-1} $active -theme main
		$prev
		$rand
		$next
		$view
		$restore
		$select
		$auto
	EOF
	)
}

wallctl=~/.orw/scripts/wallctl.sh

#if [[ $action == $select ]]; then
#else
#	case "$@" in
#		$next*) $wallctl -o next ${@#*$next };;
#		$prev*) $wallctl -o prev ${@#*$prev };;
#		$rand*) $wallctl -o rand ${@#*$rand };;
#		$restore*) $wallctl -r;;
#		$auto*) $wallctl -A;;
#		$view*) $wallctl -v;;
#		$interval*) $wallctl -I ${@#* };;
#		$index*) $wallctl -i ${@##* };;
#		*) $wallctl -o $@;;
#	esac
#fi
#fi

list_actions

if [[ $action == $select ]]; then
	indicator='●'
	indicator=''

	get_directory

	current_desktop=$(xdotool get_desktop)
	current_wallpaper=$(grep "^desktop_$current_desktop" $config | cut -d '"' -f 2)

	((depth)) && maxdepth="-maxdepth $depth"

	selected_wallpaper=$(eval find $directory/ "$maxdepth" -type f -iregex "'.*\(jpe?g\|png\)'" | sort -t '/' -k 1 |\
		awk '{ i = (/'"${current_wallpaper##*/}"'$/) ? "'$indicator'" : "  "
			sub("'"${root//\'}"'/?", ""); print i, $0 }' | rofi -dmenu -theme large_list)

	[[ $selected_wallpaper ]] && eval $wallctl -s "$root/${selected_wallpaper:2}"
else
	while
		if [[ $action ]]; then
			case "$action" in
				$next*) $wallctl -o next ${action#*$next } &;;
				$prev*) $wallctl -o prev ${action#*$prev } &;;
				$rand*) $wallctl -o rand ${action#*$rand } &;;
				$restore*) $wallctl -r;;
				$auto*) $wallctl -A;;
				$view*) $wallctl -v;;
				$interval*) $wallctl -I ${action#* };;
				$index*) $wallctl -i ${action##* };;
				*) $wallctl -o $action;;
			esac
		fi

		[[ $action =~ $prev|$next|$rand ]]
	do
		list_actions
	done
fi
