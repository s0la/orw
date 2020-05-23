#!/bin/bash

id=$1
ids_to_tile="$2"

while [[ $(wmctrl -l | awk '$1 == "'$id'"') ]]; do continue; done
#while
#	wmctrl -l | grep $id
#do
#	sleep 0.1
#done

for id in $ids_to_tile; do
	~/.orw/scripts/windowctl.sh -i $id tile $orientation
done
