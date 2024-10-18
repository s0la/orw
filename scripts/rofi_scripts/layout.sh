#!/bin/bash

item_count=8
set_theme_str

toggle

sed -n 's/^\(.*_side\|rotate\|tile\|move\|resize\)=//p' ~/.orw/scripts/icons |
	rofi -dmenu -format i -theme-str "$theme_str" -theme main
