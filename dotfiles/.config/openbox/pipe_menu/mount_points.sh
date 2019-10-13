#!/bin/bash

mount_points=$(find /mnt -maxdepth 1 -type d)
~/.config/openbox/pipe_menu/generate_menu.sh -c "~/.orw/scripts/mount.sh $1 '$2'" -i ${mount_points[*]}
