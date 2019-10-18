#!/bin/bash

awk '
	function get_value(position) {
		pattern = (position == "f") ? "[^0-9]" : "."
		return gensub(pattern "*([0-9]+).*", "\\1", 1)
	}

	/padding/ && !p { p = get_value("f") }
	/border/ { b = get_value("l") }
	/font/ {
	print get_value("f") + 2 * (p + b + 1)
		exit
	}' ~/.config/rofi/{dmenu,theme}.rasi
