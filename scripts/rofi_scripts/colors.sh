#!/bin/bash

first_arg=${@%% *}
[[ $@ && ! -f ~/.config/orw/colorschemes/$first_arg.ocs ]] && module=$first_arg && shift

if [[ -z $@ || ($# -eq 1 && $module) ]]; then
	for color in ~/.config/orw/colorschemes/$module*.ocs; do
		color=${color##*/}
		echo ${color%.*}
	done
else
	killall rofi
	colorscheme=${@%% *}
	~/.orw/scripts/rice_and_shine.sh -C $@
fi
