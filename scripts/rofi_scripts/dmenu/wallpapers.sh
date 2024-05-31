#!/bin/bash

config=~/.config/orw/config
#theme=$(awk -F '[".]' 'END { print $(NF - 2) }' ~/.config/rofi/main.rasi)
#[[ $theme =~ dmenu|icons ]] && ~/.orw/scripts/set_rofi_geometry.sh wallpapers

get_directory() {
	read depth directory <<< $(awk '\
		/^directory|depth/ { sub("[^ ]* ", ""); print }' $config | xargs -d '\n')
	root="${directory%/\{*}"
}

if [[ $style =~ icons|dmenu ]]; then
	#auto=$(systemctl --user status change_wallpaper.timer | awk '/Active/ { print ($2 == "active") ? "" : "" }')
	#auto=$(systemctl --user status change_wallpaper.timer | awk '/Active/ { if($2 == "active") print "-a 5" }')
	active=$(systemctl --user is-active change_wallpaper.timer | awk '{ if(/^active/) print "-a 4" }')
	prev= next= rand= restore= view= 
	prev= next= rand= restore= view= select= auto=
	prev= next= rand= restore= view= select= auto=
	prev= next= rand= restore= view= select= auto=
	prev= next= rand= restore= view= select= auto=
	prev= next= rand= restore= view= select= auto=
	prev= next= rand= restore= view= select= auto=
	prev= next= rand= restore= view= select= auto=
	prev= next= rand= restore= select= categories= view= auto=
	prev= next= rand= restore= select= categories= view= auto=
	prev= next= rand= restore= select= categories= view= auto=
	prev= next= rand= restore= select= categories= view= auto=
	prev= next= rand= restore= select= categories= view= auto=
	prev= next= rand= restore= select= categories= view= auto=
	prev= next= rand= restore= select= categories= view= auto=
	prev= next= rand= restore= select= categories= view= auto=
	prev= next= rand= restore= select= categories= view= auto=
	prev= next= rand= restore= select= categories= view= auto=
	prev= next= rand= restore= select= categories= view= auto=
	prev= next= rand= restore= select= categories= view= auto=
	prev= next= rand= restore= select= categories= view= auto=
	prev= next= rand= restore= select= categories= view= auto=
	prev= next= rand= restore= select= categories= view= auto=
	prev= next= rand= restore= select= categories= view= auto=
	prev= next= rand= restore= select= categories= view= auto=
	prev= next= rand= restore= select= categories= view= auto=
	prev= next= rand= restore= select= categories= view= auto=
else
	next=next prev=prev rand=rand restore=restore select=select categories=categories view=view auto=autochange nl=\n
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
	#echo $item_count: $theme_str
	read row action <<< $(cat <<- EOF | rofi -dmenu -format 'i s' -theme-str "$theme_str" -selected-row ${row:-1} $active -theme main
		$prev
		$rand
		$next
		$restore
		$auto
		$categories
		$select
		$view
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


#toggle() {
#	#~/.orw/scripts/notify.sh "SIG" &
#	~/.orw/scripts/signal_windows_event.sh rofi_toggle
#}

toggle
trap toggle EXIT

#~/.orw/scripts/notify.sh "a: ^$action^ ^$categories^"
#exit

#if [[ $action == $select ]]; then
#	indicator=''
#	indicator='●'
#
#	get_directory
#
#	current_desktop=$(xdotool get_desktop)
#	current_wallpaper=$(grep "^desktop_$current_desktop" $config | cut -d '"' -f 2)
#	current_wallpaper=$(sed -n "/^desktop_$current_desktop/ { s/[()]/\\\&/g; s/[^\"]*.\([^\"]*\).*/\1/p }" $config)
#
#	((depth)) && maxdepth="-maxdepth $depth"
#	read row wallpapers <<< $(eval find $directory/ "$maxdepth" -type f -iregex "'.*\(jpe?g\|png\)'" | \
#		sort -t '/' -k 1 | \
#		awk '{
#				if(/'"${current_wallpaper##*/}"'$/) {
#					r = NR - 1
#					i = "'$indicator'"
#				} else i = " "
#
#				sub("'"${root//\'}"'/?", "")
#				aw = aw "\\\\n" i " " $0
#			} END { print r, substr(aw, 2) }')
#
#	#~/.orw/scripts/notify.sh "here: $current_wallpaper"
#	#exit
#	selected_wallpaper=$(echo -e "$wallpapers" | rofi -dmenu -selected-row $row -i -theme large_list)
#	[[ $selected_wallpaper ]] && eval $wallctl -s "$root/'${selected_wallpaper:2}'"
#	exit
#
#	selected_wallpaper=$(eval find $directory/ "$maxdepth" -type f -iregex "'.*\(jpe?g\|png\)'" | sort -t '/' -k 1 |\
#		awk '{ i = (/'"${current_wallpaper##*/}"'$/) ? "'$indicator'" : " "
#			sub("'"${root//\'}"'/?", ""); print i, $0 }' | rofi -dmenu -i -theme large_list)
#
#	[[ $selected_wallpaper ]] &&  eval $wallctl -s "$root/'${selected_wallpaper:2}'"
#else

item_count=8
set_theme_str
list_actions

while
	if [[ $action ]]; then
		case "$action" in
			$select)
				indicator=''
				indicator='●'

				get_directory

				current_desktop=$(xdotool get_desktop)
				current_wallpaper=$(grep "^desktop_$current_desktop" $config | cut -d '"' -f 2)
				current_wallpaper=$(sed -n "/^desktop_$current_desktop/ { s/[()]/\\\&/g; s/[^\"]*.\([^\"]*\).*/\1/p }" $config)

				((depth)) && maxdepth="-maxdepth $depth"
				read row wallpapers <<< $(eval find $directory/ "$maxdepth" -type f -iregex "'.*\(jpe?g\|png\)'" | \
					sort -t '/' -k 1 | \
					awk '{
							if(/'"${current_wallpaper##*/}"'$/) {
								r = NR - 1
								i = "'$indicator'"
							} else i = " "

							sub("'"${root//\'}"'/?", "")
							aw = aw "\\\\n" i " " $0
						} END { print r, substr(aw, 2) }')

				#~/.orw/scripts/notify.sh "here: $current_wallpaper"
				#exit
				selected_wallpaper=$(echo -e "$wallpapers" | rofi -dmenu -selected-row $row -i -theme large_list)
				[[ $selected_wallpaper ]] && eval $wallctl -s "$root/'${selected_wallpaper:2}'";;
				#exit

				#selected_wallpaper=$(eval find $directory/ "$maxdepth" -type f -iregex "'.*\(jpe?g\|png\)'" | sort -t '/' -k 1 |\
				#	awk '{ i = (/'"${current_wallpaper##*/}"'$/) ? "'$indicator'" : " "
				#		sub("'"${root//\'}"'/?", ""); print i, $0 }' | rofi -dmenu -i -theme large_list)

				#[[ $selected_wallpaper ]] &&  eval $wallctl -s "$root/'${selected_wallpaper:2}'";;
			$next*) $wallctl -o next ${action#*$next } &;;
			$prev*) $wallctl -o prev ${action#*$prev } &;;
			$rand*) $wallctl -o rand ${action#*$rand } &;;
			$restore*) $wallctl -r;;
			$auto*) $wallctl -A;;
			$view*) $wallctl -v;;
			$categories*)
				killall rofi
				rofi -modi "categories:${0%/*}/wallpaper_category_selection.sh" -show categories -theme large_list;;
			$index*) $wallctl -i ${action##* };;
			*) $wallctl -o $action;;
		esac
	fi

	[[ $action =~ $select|$prev|$next|$rand ]]
do
	list_actions
done
#fi
