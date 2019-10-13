#!/bin/bash

start_wall="$1"

while read -r wallpaper; do
	((index++))
	walls+=( $wallpaper )
	[[ "$wallpaper" == "$start_wall" ]] && start_wall_index=$index
done <<< $(find "${start_wall%/*}" -type f -iregex ".*\(jpe?g\|png\)" | sort)

sxiv -n $start_wall_index ${walls[*]}
