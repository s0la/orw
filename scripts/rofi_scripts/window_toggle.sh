#!/bin/bash

theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)

if [[ $theme != icons ]]; then
	wm_mode=wm_mode offset=offset reverse=reverse sep=' '
fi

if [[ -z $@ ]]; then
	cat <<- EOF
		$sep$wm_mode
		$sep$offset
		$sep$reverse
	EOF
else
	[[ $@ =~  ]] && option=offset
	[[ $@ =~  ]] && option=reverse
	[[ $@ =~  ]] && mode="${@#*$sep$wm_mode }"

	~/.orw/scripts/toggle.sh wm $option $mode

	list_options
fi

