#!/bin/bash

script=~/.orw/scripts/rofi_scripts/$1.sh
theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)

if [[ $theme == icons ]]; then
	#if [[ $1 =~ apps|playback|power|wallpapers|window_action|workspaces ]]; then
	item_count=$($script | wc -l)

	width=$(awk '
		BEGIN { ic = '$item_count' }

		function get_value() {
			return gensub(/.* ([0-9]+).*/, "\\1", 1)
		}

		/font/ { fs = get_value() }
		/spacing/ { s = get_value() }
		/padding/ { if(wp) ep = get_value(); else wp = get_value() }
		END { print 2 * wp + int(ic * (2 * ep + s + fs * 1.37)) - s }' ~/.config/rofi/icons.rasi)

	#~/.orw/scripts/notify.sh "ic: $item_count   w: $width    $script"
	sed -i "/width/ s/[0-9]\+/$((width + 0))/" ~/.config/rofi/icons.rasi
#fi
fi
