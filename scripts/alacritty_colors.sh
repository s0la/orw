#!/bin/bash

awk -i inplace '{
		if (NR == FNR && NR > 16 && NR < 256) {
			ac = ac "\n\n[[colors.indexed_colors]]\ncolor = \"" $NF "\"\nindex = " NR - 1
		} else if (/indexed_color/) {
			print substr(ac, 3)
			exit
		}

		{ print }
	}' ~/.orw/dotfiles/.config/{orw/colorschemes/colors,alacritty/alacritty.toml}
