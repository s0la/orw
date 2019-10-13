#!/bin/bash

echo "<openbox_pipe_menu>"

while read -r dev model; do
	echo -e "<menu execute='~/.config/openbox/pipe_menu/mount_points.sh $dev \"$model\"' id='$dev' label='${model//_/ }'/>"
done <<< $(lsblk -lpo +model | awk '{ if($1 ~ /sd.$/ && $7) { model=""; for(f=7; f<=NF; f++) model=model$f" " };\
	if($6 == "part" && $4 ~ /[0-9]G/ && $7 !~ /^\//) printf("%s %-20s %s\n", $1, model, $4)}')

echo "</openbox_pipe_menu>"
