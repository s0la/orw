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
	current_wallpapers="$(awk -F '"' '
		$1 ~ "^desktop_'$current_desktop'" {
			for (i=2; i<NF; i++) if (!(i % 2)) cw = cw "|" $i
			print substr(cw, 2)
		}' $config)"

	#current_wallpapers="$(awk -F '"' '
	#	$1 ~ "^desktop_'$current_desktop'" {
	#		for (i=2; i<NF; i++) {
	#			if (!(i % 2)) {
	#				sub(".*/", "", $i)
	#				sw = sw "|" $i
	#			}
	#		}
	#		print substr(sw, 2)
	#	}' $config)"

	((depth)) && maxdepth="-maxdepth $depth"

	##works with rofi sidebar theme (Alt + Shift + s)
	#eval find $directory/ "$maxdepth" -type f -iregex "'.*\(jpe?g\|png\)'" |
	#	sort -t '/' -k 1 | awk '{
	#					#if ("('"$current_wallpapers"')$") i = i "," NR - 1
	#					if ($0 ~ "('"${current_wallpapers//\|/\\\\\\\\|}"')$") i = i "," NR - 1
	#					sub("'"${root//\'}"'/?", "")
	#					print $0
	#				} END { printf "\0active\x1f%s\n", substr(i, 2) }'

	#works with rofi image preview
	(
		echo '~/.orw/scripts/wallctl.sh -s "$element"'
		eval find $directory/ "$maxdepth" -type f -iregex "'.*\(jpe?g\|png\)'" |
			sort -t '/' -k 1 | awk '{
					if ($0 ~ "('"${current_wallpapers//\|/\\\\\\\\|}"')$") i = i "," NR - 1
					aw = aw "\n" $0
				} END { print substr(i, 2) aw }'
				#} END { print substr(i, 2) aw }' | ${0%/*}/image_preview.sh
	) | ${0%/*}/dmenu.sh image_preview
else
	wall="$@"
	eval ~/.orw/scripts/wallctl.sh -s "$root/'$wall'"
fi
