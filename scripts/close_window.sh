#!/bin/bash

id=$2
ids="$3"
mode=$1

while [[ $(wmctrl -l | awk '$1 == "'$id'"') ]]; do continue; done
#while
#	wmctrl -l | grep $id
#do
#	sleep 0.1
#done

if [[ $mode == auto ]]; then
	for id in $ids; do
		~/.orw/scripts/windowctl.sh -i $id tile $orientation &> /dev/null
	done
else
	[[ $4 == h ]] && direction=L || direction=T
	#~/.orw/scripts/notify.sh "${ids%% *} move -$direction -A ${4}c"
	~/.orw/scripts/windowctl.sh -i ${ids%% *} move -$direction -A ${4}c &> /dev/null
fi
