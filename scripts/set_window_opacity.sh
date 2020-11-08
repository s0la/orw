#!/bin/bash

set_opacity() {
	local opacity_hex=$(printf '0x%.2xffffff' $((0xff * $1 / 100)))
	xprop -id ${id:-$2} -format _NET_WM_WINDOW_OPACITY 32c -set _NET_WM_WINDOW_OPACITY $opacity_hex
	echo xprop -id ${id:-$2} -format _NET_WM_WINDOW_OPACITY 32c -set _NET_WM_WINDOW_OPACITY $opacity_hex >> ~/Desktop/opac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	#[[ $1 =~ ^0x ]] &&
	#	id=$1 || id=$(printf '0x%.8x' $(xdotool getactivewindow))

	[[ $2 ]] || id=$(printf '0x%.8x' $(xdotool getactivewindow))
	set_opacity ${2:-$1} $1
fi
