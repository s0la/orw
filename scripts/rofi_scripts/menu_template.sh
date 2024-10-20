#!/bin/bash

icons_template="$1"
items=( $(sed -n "s/$icons_template//p" $icons) )
item_count=${#items[*]}
set_theme_str

toggle

tr ' ' '\n' <<< ${items[*]} | rofi -dmenu -format i -theme-str "$theme_str" -theme main
