#!/bin/bash

config=~/.config/orw/config
read depth directory <<< $(awk '\
		/^directory|depth/ { sub("[^ ]* ", ""); print }' $config | xargs -d '\n')
root="${directory%/\{*}"

empty='   '
indicator='●'
indicator=''

current_desktop=$(xdotool get_desktop)
current_wallpaper=$(grep "^desktop_$current_desktop" $config | cut -d '"' -f 2)

((depth)) && maxdepth="-maxdepth $depth"

while read -r wall; do
	name="${wall%:*}"
	path="${wall#*:}"

	walls+=( "${name// /_}:$path" )
done <<< "$(eval find $directory/ "$maxdepth" -type f -iregex "'.*\(jpe?g\|png\)'" | \
				awk 'BEGIN {
					r = "'"${root//\'}"'"
				} {
					i = (/'"${current_wallpaper##*/}"'$/) ? "'$indicator'" : "___"
					w = gensub("'"${root//\'}"'/?", "", 1)
					print i "_" w ":" r "/" w
				}')"

~/.config/openbox/pipe_menu/generate_menu.sh -c '~/.orw/scripts/wallctl.sh -s' -i "${walls[@]}"
