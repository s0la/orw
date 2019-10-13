#!/bin/bash

if [[ -z $@ ]]; then
	for module in ob gtk bar vim rofi lock term tmux bash dunst firefox ncmpcpp; do
		echo $module
	done
	echo 'rice and shine'
else
	if [[ ! $@ =~ ' ' ]]; then
		~/.orw/scripts/rofi_scripts/colors.sh $@
	else
		killall rofi

		if [[ $@ =~ "rice and shine" ]]; then
			command=${@#* shine}
		else
			colorscheme=${@%% *}
			[[ -f ~/.config/orw/colorschemes/$colorscheme.ocs ]] && command="-m ${colorscheme%%_*} -C $@" || command="-m $@"
		fi

		eval "~/.orw/scripts/rice_and_shine.sh $command"
	fi
fi
