#!/bin/bash

theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)
[[ $theme =~ dmenu|icons ]] && ~/.orw/scripts/set_rofi_geometry.sh window_management

[[ $theme == icons ]] &&
	#tile=  left= right= center= fullscreen=  save=  restore=  ||
	tile=  left=  right=  center= fullscreen=  save=  restore=  ||
	tile=tile left=left right=right center=center fullscreen=fullscreen save=save restore=restore

id=$(printf "0x%.8x" $(xdotool getactivewindow))
saved=$(awk '$1 == "'$id'" { print "-a 1" }' ~/.config/orw/windows_properties)

action=$(cat <<- EOF | rofi -dmenu $saved -theme main
	$tile
	$left
	$right
	$center
	$fullscreen
	$save
	$restore
EOF
)

windowctl=~/.orw/scripts/windowctl.sh

if [[ $action ]]; then
	case "$action" in
		$tile*) $windowctl tile;;
		$center*) $windowctl -c;;
		$left*) $windowctl move -v 1/1 -h 1/1 resize -h 1/2 -v 1/1;;
		$right*) $windowctl move -v 1/1 -h 2/2 resize -h 1/2 -v 1/1;;
		$fullscreen*) $windowctl move -v 1/1 -h 1/1 resize -h 1/1 -v 1/1;;
		$save*) $windowctl -s;;
		$restore*) $windowctl -r;;
		$*) eval "$windowctl $action";;
	esac
fi
