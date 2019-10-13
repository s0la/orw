#!/bin/bash

statusline=~/.config/nvim/plugin/statusline.vim

vim() {
	while getopts :c:m: flag; do
		case $flag in
			c)
				module=${OPTARG%%\.*}
				settings=${OPTARG#*\.}

				sed -i "s/\(let.*settings.*'${module#i}p\?i\?\.\)[^,']*/\1${settings//\//\\\/}/" $statusline;;
			m) sed -i "/let.*:active/ s/'.*'/'$OPTARG'/" $statusline;;
		esac
	done
}

bash() {
	while getopts :c:m: flag; do
		case $flag in
			c)
				module=${OPTARG:0:1}
				settings=${OPTARG:2}

				pattern="${module}\w*_";;
			m) settings="$OPTARG";;
		esac

		sed -i "/^\s*${pattern}modules\?=/ s/\".*\"/\"$settings\"/" ~/.orw/dotfiles/.bashrc
	done
}

$@
