#!/bin/bash

get_directory() {
	read depth directory <<< $(awk '\
		/^directory|depth/ { sub("[^ ]* ", ""); print }' $config | xargs -d '\n')
	root="${directory%/\{*}"
}

config=~/.config/orw/config
get_directory

if [[ -z $@ ]]; then
	current_desktop=$(xdotool get_desktop)
	current_wallpaper=$(grep "^desktop_$current_desktop" $config | cut -d '"' -f 2)

	((depth)) && maxdepth="-maxdepth $depth"

	eval find $directory/ "$maxdepth" -type f -iregex "'.*\(jpe?g\|png\)'" |
		sort -t '/' -k 1 | awk '{
						if (/'"${current_wallpaper##*/}"'$/) i = NR - 1
						sub("'"${root//\'}"'/?", "")
						print $0
					} END { printf "\0active\x1f%d\n", i }'

	#indicator='●'
	#indicator=''
	#eval find $directory/ "$maxdepth" -type f -iregex "'.*\(jpe?g\|png\)'" | sort -t '/' -k 1 |\
	#	awk '{ i = (/'"${current_wallpaper##*/}"'$/) ? "'$indicator'" : "  "
	#		sub("'"${root//\'}"'/?", ""); print i, $0 }'
else
	wall="$@"
	eval ~/.orw/scripts/wallctl.sh -s "$root/$wall"
	#eval ~/.orw/scripts/wallctl.sh -s "$root/${wall:2}"
fi
