#!/bin/bash

rofi='rofi -dmenu -theme main'

[[ $@ ]] && dev=$1 ||
	dev=$(lsblk -lpo +model | awk '{
		if($1 ~ /sd.$/ && $7) {
			m=""
			for(f = 7; f <= NF; f++) m = m $f " "
		}
		if($6 == "part" && $4 ~ /[0-9]G/ && $7 !~ /^\//) printf("%-45s %-20s %s\n", m, $4, $1)}' | $rofi)

mount() {
	~/.orw/scripts/mount.sh ${dev##* } "${dev% *}" "$mount_point"
}

if ! $(mount); then
	mount_point=$(find /mnt -maxdepth 1 -type d | $rofi | sed "s|^\~|$HOME|")

	if [[ ! -d $mount_point ]]; then
		confirmation=$(echo -e 'yes\nno' |\
			$rofi -p "Mount point doesn't exist, would you like to create it?")

		if [[ $confirmation == yes ]]; then
			[[ $mount_point =~ ^(/home|~/) ]] || sudo=sudo
			eval mkdir $sudo $mount_point
		else
			exit
		fi
	fi

	mount
fi
