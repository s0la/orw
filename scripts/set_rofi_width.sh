#!/bin/bash

script=~/.orw/scripts/rofi_scripts/$1.sh
theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)

count_items() {
	awk '/s*'"$1"'/ { wc = gensub(/[\0-\177]/, "", "g"); print length(wc) }' $script
}

if [[ $theme == icons ]]; then
	#item_count=$($script | wc -l)

	if [[ $2 ]]; then
		item_count=$2
	else
		case $1 in
			wallpapers) item_count=$(count_items icons);;
			workspaces)
				extend=8
				item_count=$(count_items 'workspaces=\(.*\)');;
			*) item_count=$(awk '/<<-/ { start = 1; nr = NR + 1 } /^\s*EOF/ && start { print NR - nr; exit }' $script)
		esac
	fi

	width=$(awk '
		BEGIN { ic = '$item_count' }

		function get_value() {
			return gensub(/.* ([0-9]+).*/, "\\1", 1)
		}

		/font/ { fs = get_value() }
		/spacing/ { s = get_value() }
		/padding/ { if(wp) ep = get_value(); else wp = get_value() }
		END { print 2 * wp + int(ic * (2 * ep + s + fs * 1.4'$extend')) - s }' ~/.config/rofi/icons.rasi)

	#~/.orw/scripts/notify.sh "ic: $item_count   w: $width    $script"
	sed -i "/width/ s/[0-9]\+/$((width + 0))/" ~/.config/rofi/icons.rasi
#fi
fi
