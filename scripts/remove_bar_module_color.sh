#!/bin/bash

modules="$1"
[[ ! $1 =~ '^' ]] && modules="${1//\*/\.\*}"

sed -i "/^$modules=/d" ~/.orw/scripts/bar/module_colors

~/.orw/scripts/barctl.sh -d
