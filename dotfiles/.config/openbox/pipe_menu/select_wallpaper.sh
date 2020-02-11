#!/bin/bash

#directory=$(sed -n 's/^directory //p' ~/.config/orw/config)
config=~/.config/orw/config
read depth directory <<< $(awk '\
		/^directory|depth/ { sub("[^ ]* ", ""); print }' $config | xargs -d '\n')

empty='   '
indicator='●'
indicator=''

current_desktop=$(xdotool get_desktop)
current_wallpaper=$(grep "^desktop_$current_desktop" $config | cut -d '"' -f 2)

while read -r wall; do
	name="${wall%:*}"
	path="${wall#*:}"

	#echo "^$wall$"
	#echo "${name// /_}:\"$path\""
	#[[ $i == '#' ]] && start="$indicator " || start='  '
	walls+=( "${name// /_}:$path" )
done <<< "$(eval find $directory/ -maxdepth $depth -type f -iregex "'.*\(jpe?g\|png\)'" | awk '\
				BEGIN {
					d = ("'"$directory"'" ~ "\\{.*\\}") ? "'"${directory%/*}"'" : "'"$directory"'"
				} {
					i = (/'"${current_wallpaper##*/}"'$/) ? "'$indicator'" : "___"
					w = gensub(".*/(.*(/.*){" '$depth' - 1 "})$", "\\1", 1)
					print i "_" w ":" d "/" w
				}')"

#done <<< "$(find "$directory" -type f -printf "%f:%p\n")"
#done <<< "$(eval find $directory/ -maxdepth $depth -type f -iregex "'.*\(jpe?g\|png\)'"  -printf "%f:%p\n" |\
			#awk '{ print gensub(".*/(.*(/.*){" '$depth' - 1 "})$", "\\1", 1) }'

~/.config/openbox/pipe_menu/generate_menu.sh -c '~/.orw/scripts/wallctl.sh -s' -i "${walls[@]}"
