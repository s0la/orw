#!/bin/bash

awk -i inplace '{
		if (NR == FNR) {
			if (NR > 16 && NR < 256) {
				ac = ac ",\n{ index: " NR - 1 ", color: '\''" $NF "'\'' }"
			}

			print
		} else {
			if (ic && /\]/) {
				ic = 0
				p = $0

				sub("]", "  ", p)
				gsub("\n", "\n" p, ac)

				print substr(ac, 3)
			}

			if (!ic) print

			if (/indexed_colors/) ic = 1
		}
	}' ~/.config/{orw/colorschemes/colors,alacritty/alacritty.yml}
