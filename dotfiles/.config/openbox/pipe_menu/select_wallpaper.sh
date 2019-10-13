#!/bin/bash

directory=$(sed -n 's/^directory //p' ~/.config/orw/config)

#walls="$(find "$directory" -type f -printf "%f:%p ")"
while read -r wall; do
	name="${wall%:*}"
	path="${wall#*:}"
	walls+=( "${name// /_}:\"$path\"" )
done <<< "$(find "$directory" -type f -printf "%f:%p\n")"

~/.config/openbox/pipe_menu/generate_menu.sh -c '~/.orw/scripts/wallctl.sh -s' -i "${walls[@]}"
