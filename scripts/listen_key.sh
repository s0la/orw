#!/bin/bash

#xinput test-xi2 --root 10 | awk '/detail/ { print; fflush() }' |
#	while read key; do
#		echo $key - $pid
#	done &
#	pid=$!
#exit

initial=$1

#(($# > 1)) && keys="${@:2}" #&& keys="${keys// / key }" && echo "$keys" && exit
#(($# > 1)) && keys="${@:2}" && echo $initial: xdotool key ${keys// / key }
((initial && $# > 1)) && keys="${@:2}" && xdotool key ${keys// / sleep 0.05 key }
#initial=0
#parent=$(ps -p $$ -o ppid= |
#	xargs -I {} ps -o args= -p {} | awk '{ print $0 ~ "select_window" }')

#[[ $1 ]] &&
#	input_id=$1 ||
#	input_id=$(xinput list | awk -F '\t' '
#		p && $1 ~ /Receiver|(keyboard|K\/B)/ {
#			sub(".*=", "", $2)
#			id = $2
#			if (/USB/) exit
#		}
#
#		/XTEST keyboard/ { p = 1 }
#		END { print id }')

#input_id=$(xinput list | awk -F '\t' '
#			/XTEST keyboard/ { p = 1 }
#			p && $1 ~ /Receiver|(keyboard|K\/B)/ {
#				sub(".*=", "", $2)
#				id = $2
#				if (/USB/ || "'"$2"'") exit
#			} END { print id }')
##input_id=10
#
#input_id=$(xinput list | awk -F '\t' '
#	/Virtual core keyboard/,/^$/ { if (/'"${2:-USB}"'/) id = $2 }
#	END { sub(".*=", "", id); print id }')

#xinput test $input_id | awk '/release/ { print $NF; fflush() }' |
xinput test-xi2 --root "Virtual core keyboard" |
	awk '/RawKeyRelease/,/detail/ { if (/detail/) print $NF; fflush() }' |
	while read key; do
		#~/.orw/scripts/notify.sh -t 5 "ID: $key"
		((key == 36 && initial++)) && pidof -x $0 | xargs -r kill
	done
exit

while read key; do
	if ((key == 36)); then
		((initial++)) && pidof -x $0 | xargs -r kill -9
	fi

	#echo $key
done < <(xinput test $input_id | awk '/release/ { print $NF; fflush() }')
	#awk '/RawKeyRelease/ { getline; getline; print $2; fflush() }') &
#done < <(xinput test-xi2 --root 10 | awk '/detail/ { print $NF; fflush() }') &
