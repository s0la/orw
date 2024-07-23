#!/bin/bash

set_value() {
	sed -i "/$property=.*${!property}/,/application/ { /<$1>/ s/>.*</>$2</ }" ~/.orw/dotfiles/.config/openbox/rc.xml
}

while getopts :c:t:n:x:y:w:h:m: flag; do
	case $flag in
		[ctn])
			case $flag in
				n) property=name;;
				t) property=title;;
				c) property=class;;
			esac

			eval $property=$OPTARG;;
		x) set_value x $OPTARG;;
		y) set_value y $OPTARG;;
		d) set_value decor $OPTARG;;
		w) set_value width $OPTARG;;
		h) set_value height $OPTARG;;
		m) set_value monitor $OPTARG;;
	esac
done

openbox --reconfigure
