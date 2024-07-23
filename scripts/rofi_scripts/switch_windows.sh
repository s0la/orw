#!/bin/bash

icons=~/.orw/scripts/bar/icons
workspaces=$(awk '
		NR == FNR && /<\/?names>/ { wn = !wn }

		wn && /<name>/ {
			gsub("\\s*<[^>]*>", "")
			awn = awn "|" $0
		}

		NR != FNR && $0 ~ "Workspace_(" substr(awn, 2) ")_icon" {
			if (!wii) wii = NR
			gsub("(^|%)[^}]*.", "")
			awi[NR - wii] = $0
		} END { for (i in awi) printf "[%s]=%d ", awi[i], i }
		' ~/.config/openbox/rc.xml $icons)

		
eval declare -A workspaces=( "$workspaces" )

if [[ $@ ]]; then
	if [[ "${!workspaces[*]}" == *$@* ]]; then
		desktop="${workspaces[$1]}"
		id=$(printf '0x%.8x' $(xdotool getactivewindow))

		IFS=$'\n' read -d '' current_window all <<< \
			$(wmctrl -l | awk '
				$2 ~ "'"$desktop"'" && $2 >= 0 {
					aw[$2] = aw[$2] " " $NF
					if ($1 == "'"$id"'") i = wc
					wc++
				} END {
					i = (i) ? i : " "
					for (w in aw) {
						gsub(" ", "\n", aw[w])
						print i aw[w]
					}
				}')

		echo -ne "\0active\x1f$current_window\n${all/ /\n}"
	else
		window="$@"
		wmctrl -l | sed -n "s/\s.*${window##* }$//p" | xargs wmctrl -ia
	fi
else
	desktop=$(xdotool get_desktop)

	while read index icon; do
		modis+="$icon:$0 $icon,"
		((desktop == index)) && current_desktop=$icon
	done <<< $(
		for workspace in ${!workspaces[*]}; do
			echo "${workspaces[$workspace]} $workspace"
		done | sort -nk 1,1
	)

	rofi -modi "${modis%,}" -show $current_desktop -theme sidebar
fi
