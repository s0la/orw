#!/bin/bash

rofi='rofi -dmenu -theme main'

[[ $@ ]] && dev=$1 || dev=$(lsblk -lpo +model | awk '{ if($1 ~ /sd.$/ && $7) { model=""; for(f=7; f<=NF; f++) model=model$f" " };\
	if($6 == "part" && $4 ~ /[0-9]G/ && $7 !~ /^\//) printf("%-45s %-20s %s\n", model, $4, $1)}' | $rofi)

mount() {
	~/.orw/scripts/mount.sh ${dev##* } "${dev% *}" "$mount_point"
}

if ! $(mount); then
	mount_point=$(find /mnt -maxdepth 1 -type d | $rofi)
	if [[ ! -d $mount_point ]]; then
		confirmation=$( echo -e 'yes\nno' | rofi -dmenu -p "Mount point doesn't exist, would you like to create it?")
		[[ $confirmation == yes ]] && sudo mkdir $mount_point || exit
	fi

	mount
fi
