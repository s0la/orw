#!/bin/bash

icon_x_down=
icon_x_up=
icon_y_up=
icon_y_down=

toggle
trap toggle EXIT

#item_count=2
#set_theme_str

while
	index=$(echo -e '\n' |
		rofi -dmenu -format i -theme-str "$theme_str" -selected-row $index -theme main)
	((index)) &&
		direction=- || direction=+
	[[ $index ]]
do
	~/.orw/scripts/opacityctl.sh term ${direction}2
done
