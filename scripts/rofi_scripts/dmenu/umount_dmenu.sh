#!/bin/bash

dev=$(lsblk -lpo +model | awk '{ if($1 ~ /sd.$/ && $7) { model=""; for(f=7; f<=NF; f++) model=model$f" " }; \
    if($7 ~ /^\/.+/ && $7 !~ /(boot|home)/) printf("%-45s %-20s %s\n", model, $4, $1)}' | rofi -dmenu -theme main)

~/.orw/scripts/mount.sh ${dev##* } "${dev% *}"
