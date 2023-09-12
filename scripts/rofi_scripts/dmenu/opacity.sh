#!/bin/bash

icon_x_down=
icon_x_up=
icon_y_up=
icon_y_down=

toggle_rofi
trap toggle_rofi EXIT

while
	index=$(echo -e '\n' | rofi -dmenu -format i -selected-row $index -theme main)
	((index)) &&
		direction=- || direction=+
	[[ $index ]]
do
	~/.orw/scripts/opacityctl.sh term ${direction}4
done
