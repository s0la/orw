#!/bin/bash

function populate_menu() {
	toggle=$(echo -e $1 | rofi -dmenu -theme main)
}

populate_menu 'rofi\nbash\ntmux\nbuttons\nfolders\ntitlebar'

[[ $toggle ]] && case $toggle in
	rofi)
		while [[ $toggle ]]; do
			case $toggle in
				rofi) populate_menu 'mode\nprompt';;
				mode) populate_menu 'list\ndmenu\nfullscreen';;
				prompt) prompt='prompt -c' && populate_menu 'menu\ndmenu';;
				*)
					~/.orw/scripts/toggle.sh rofi $prompt $toggle
					exit;;
			esac
		done;;
	titlebar) ~/.orw/scripts/toggle.sh titlebar;;
	buttons)
		populate_menu 'box\nbars\nturq\ndots\nplus\nslim\nsmall\nnumix\nround\nsharp\nelegant'
		[[ $toggle ]] && ~/.orw/scripts/toggle.sh buttons $toggle;;
	folders) ~/.orw/scripts/toggle.sh folders;;
	*) ~/.orw/scripts/toggle.sh $toggle;;
esac
