#!/bin/bash

ocs_root=$HOME/.config/orw/colorschemes

vim_colors=$(awk '
	$2 ~ "g:[svc]?[bf]g" { gsub("'\''", "", $NF); c = c "\\n.*" $NF }
	END { print substr(c, 3) }' ~/.config/nvim/colors/orw.vim)

ocs_root=~/.config/orw/colorschemes
current_ocs=$(grep -zlP "#vim\n$vim_colors" $ocs_root/*.ocs | sed 's/[()]/\\&/g')

command='wall="$(sed "s/.ocs.png//" <<< "${element##*/}")";'
command+='~/.orw/scripts/wallctl.sh -s ~/Downloads/"$wall"* & '
command+='~/.orw/scripts/rice_and_shine.sh -tC "$wall"'

(
	echo "$command"
	ls $ocs_root/wall_previews/* | awk '
		/'"${current_ocs##*/}"'.png/ { a = NR - 1 } { ac = ac "\n" $0 }
		END { print a ac }'
) | ${0%/*}/dmenu.sh image_preview
