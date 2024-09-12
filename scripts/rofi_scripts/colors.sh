#!/bin/bash

ocs_root=$HOME/.config/orw/colorschemes

vim_colors=$(awk '
	$2 ~ "g:[svc]?[bf]g" { gsub("'\''", "", $NF); c = c "\\n.*" $NF }
	END { print substr(c, 3) }' ~/.config/nvim/colors/orw.vim)

ocs_root=~/.config/orw/colorschemes
current_ocs=$(grep -zlP "#vim\n$vim_colors" $ocs_root/*.ocs)
ISF=$'\n' read -d '' active colorschemes <<< $(ls $ocs_root/previews/* |
	awk '/'"${current_ocs##*/}"'.png/ { a = NR - 1 } { ac = ac "\n" $0 } END { print a ac }')

(
	echo '~/.orw/scripts/rice_and_shine.sh -tC "$(sed "s/.ocs.png//" <<< "${element##*/}")"'
	ls $ocs_root/previews/* | awk '
		/'"${current_ocs##*/}"'.png/ { a = NR - 1 } { ac = ac "\n" $0 }
		END { print a ac }'
) | ${0%/*}/dmenu.sh image_preview
exit

while read preview; do
	echo -en "${preview##*/}\x00icon\x1f${preview}\n"
done <<< $(ls $ocs_root/previews/*) |
	rofi -dmenu -show-icons -l 5 -theme list \
	-theme-str 'element-icon { size: 100px; } element { padding: 0; margin: 10px; }' |
	sed "s/.png$//" | xargs echo ~/.orw/scripts/rice_and_shine.sh -tC
