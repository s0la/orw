#!/bin/bash

ocs_root=~/.config/orw/colorschemes
ocs_previews_root=$ocs_root/previews
colorshceme="$1"

[[ -d $ocs_previews_root ]] || mkdir $ocs_previews_root

for ocs in $ocs_root/${colorshceme##*/}*; do
	awk '
		c && /^$/ { c = 0 }
		$1 ~ "#(term|tmux|vim)" { c = substr($1, 2) }

		c == "term" && $1 == "bg" { ac[1] = "#" substr($NF, length($NF) - 5) }
		c == "tmux" && $1 ~ "^[cw]bg$" { ac[++i - 4] = $NF }
		c == "vim" && $1 ~ "^[cfisv]fg$" { ac[++i + 3] = $NF }

		END { for (c in ac) printf "\\\\( -size 100x12 xc:%s \\\\) ", ac[c] }' $ocs |
			xargs -I {} bash -c "magick {} -append $ocs_previews_root/${ocs##*/}.png"
done
