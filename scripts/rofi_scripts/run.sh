#!/bin/bash

#toggle
#trap toggle EXIT

[[ $style =~ horizontal|dmenu ]] &&
	theme=dmenu || theme=list
theme=list

rofi -show run -theme $theme.rasi
