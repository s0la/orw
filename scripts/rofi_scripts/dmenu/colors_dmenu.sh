#!/bin/bash

rofi='rofi -dmenu -theme main'

get_colorscheme() {
	for color in ~/.config/orw/colorschemes/$module*.ocs; do
		color=${color##*/}
		echo ${color%.*}
	done | $rofi
}

get_module() {
	for module in all ob gtk dunst notify terminal vim bar ncmpcpp tmux rofi bash firefox wall; do
		echo $module
	done | $rofi
}

colorscheme=$(get_colorscheme)
[[ $colorscheme ]] || exit

module=$(get_module)
[[ $module ]] || exit

[[ $module == all ]] && unset module
~/.orw/scripts/rice_and_shine.sh -C $colorscheme -m $module
