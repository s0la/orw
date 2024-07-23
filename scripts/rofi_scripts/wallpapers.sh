#!/bin/bash

config=~/.config/orw/config

get_directory() {
	read depth directory <<< $(awk '\
		/^directory|depth/ { sub("[^ ]* ", ""); print }' $config | xargs -d '\n')
	root="${directory%/\{*}"
}

if [[ $style =~ icons|dmenu ]]; then
	active=$(systemctl --user is-active change_wallpaper.timer | awk '{ if(/^active/) print "-a 4" }')
	icons='arrow_\(left\|right\).*empty\|random\|reload\|list\|categories\|grid\|time'
	read prev next categories select restore random view auto <<< \
		$(sed -n "s/^\($icons\)=//p" ~/.orw/scripts/icons | xargs)
else
	next=next prev=prev rand=rand restore=restore select=select categories=categories view=view auto=autochange nl=\n
fi

list_actions() {
	read row action <<< $(cat <<- EOF | rofi -dmenu -format 'i s' -theme-str "$theme_str" -selected-row ${row:-1} $active -theme main
		$prev
		$random
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

toggle
trap toggle EXIT

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

				selected_wallpaper=$(echo -e "$wallpapers" | rofi -dmenu -selected-row $row -i -theme large_list)
				[[ $selected_wallpaper ]] && eval $wallctl -s "$root/'${selected_wallpaper:2}'";;
			$next*) $wallctl -o next ${action#*$next } &;;
			$prev*) $wallctl -o prev ${action#*$prev } &;;
			$random*) $wallctl -o rand ${action#*$random } &;;
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

	[[ $action =~ $select|$prev|$next|$random ]]
do
	list_actions
done
