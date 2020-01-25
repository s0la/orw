#!/bin/bash

(($# > 2)) && command=mount mount_point="on $3" || command=umount

sudo $command $1 $3 &> /dev/null &&
	~/.orw/scripts/notify.sh -p "<b>${2%%  *}</b> succesfully ${command}ed <b>$mount_point</b>"
