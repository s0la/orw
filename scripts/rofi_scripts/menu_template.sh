#!/bin/bash

[[ "$1" == *= ]] &&
	icons_template="$1" &&
	items=( $(sed -n "s/$icons_template//p" $icons) ) ||
	eval "items=( "$1" )"

[[ $2 ]] && positions="$2"

item_count=${#items[*]}
set_theme_str

#toggle

tr ' ' '\n' <<< ${items[*]} |
	rofi -dmenu -format i $positions -theme-str "$theme_str" -theme main
