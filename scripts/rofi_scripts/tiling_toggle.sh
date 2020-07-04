#!/bin/bash

theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)

if [[ $theme != icons ]]; then
	wm_mode=wm_mode offset=offset reverse=reverse direction=direction sep=' '
fi

read wm_icon offset_icon reverse_icon direction_icon <<< \
	$(awk '{
		if(/^mode/) {
			wm = ($NF == "floating") ? "" : ""
		} else if(/^offset/) {
			o = ($NF == "true") ? "" : ""
		} else if(/^reverse/) r = ""
		else if(/^direction/) {
			d = ($NF == "h") ? "" : ""
		}
	} END {
		print wm, o, r, d
	}' ~/.config/orw/config)

if [[ -z $@ ]]; then
	cat <<- EOF
		$wm_icon$sep$wm_mode
		$offset_icon$sep$offset
		$reverse_icon$sep$reverse
		$direction_icon$sep$direction
	EOF
else
	[[ $@ =~ $offset_icon ]] && option=offset
	[[ $@ =~ $reverse_icon ]] && option=reverse
	[[ $@ =~ $direction_icon ]] && option=direction
	[[ $@ =~ $wm_icon ]] && mode="${@#*$wm_icon$sep$wm_mode}"

	~/.orw/scripts/toggle.sh wm $option $mode

	list_options
fi
