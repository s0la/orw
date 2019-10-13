#!/bin/bash

while read -r dev model; do
	items+=( "'${model// /_} $dev \"$model\"'" )
done <<< $(lsblk -lpo +model | awk '{ if($1 ~ /sd.$/ && $7) { model=""; for(f=7; f<=NF; f++) model=model$f" " }; \
	if($7 ~ /^\/.+/ && $7 !~ /(boot|home)/) printf("%s %-20s %s\n", $1, model, $4)}')

eval "~/.config/openbox/pipe_menu/generate_menu.sh -c '~/.orw/scripts/mount.sh' -i ${items[*]}"
