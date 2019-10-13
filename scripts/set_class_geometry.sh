#!/bin/bash

set_value() {
	sed -i "/\(class\|name\|title\)=.*${class-input}/,/^$/ { /$1/ s/[0-9]\+/$2/ }" ~/.config/openbox/rc.xml
}

while getopts :c:x:y:w:h: flag; do
	case $flag in
		c) class=$OPTARG;;
		x) set_value x $OPTARG;;
		y) set_value y $OPTARG;;
		d) set_value decor $OPTARG;;
		w) set_value width $OPTARG;;
		h) set_value height $OPTARG;;
	esac
done

openbox --reconfigure
