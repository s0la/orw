#!/bin/bash

#theme=$(awk -F '"' 'END { m = $(NF - 1); print (m == "icons") ? "list" : m }' ~/.config/rofi/main.rasi)

path=~/.config/rofi
theme=$(awk -F '[".]' 'END { print $(NF - 2) }' $path/main.rasi)
[[ $theme == icons ]] && list_theme=list

function populate_menu() {
	toggle=$(echo -e $1 | rofi -dmenu -theme ${list_theme:-$theme})
}

populate_menu 'rofi\nbash\ntmux\nbuttons\nfolders\ntitlebar'

[[ $toggle ]] && case $toggle in
	rofi)
		while [[ $toggle ]]; do
			case $toggle in
				rofi)
					options='mode\nprompt'
					[[ $theme == icons ]] && options+='\nlocation\norientation';;
				location)
					#orientation=$(awk -F '[; ]' '/^\s*window-orientation/ { print $(NF - 1) }' $path/icons.rasi)
					location=location
					options=$(awk -F '[; ]' '/^\s*window-orientation/ {
							wo = $(NF - 1)
							print (wo == "horizontal") ? "north\\nsouth\\ncenter" : "west\\neast"
						}' $path/icons.rasi);;
					#[[ $orientation == horizontal ]] &&
					#	options='north\nsouth\ncenter' || options='west\neast';;
				orientation)
					orientation=orientaion
					options='horizontal\nvertical';;
				mode) options='list\ndmenu\nfullscreen';;
				prompt) prompt='prompt -c' && populate_menu 'list\nicons\ndmenu';;
				*)
					~/.orw/scripts/toggle.sh rofi $orientation $location $prompt $toggle
					exit;;
			esac

			populate_menu "$options"
		done;;
	titlebar) ~/.orw/scripts/toggle.sh titlebar;;
	buttons)
		populate_menu 'box\nbars\nturq\ndots\nplus\nslim\nsmall\nnumix\nround\nsharp\nelegant\nsurreal'
		[[ $toggle ]] && ~/.orw/scripts/toggle.sh buttons $toggle;;
	folders) ~/.orw/scripts/toggle.sh folders;;
	*) ~/.orw/scripts/toggle.sh $toggle;;
esac
