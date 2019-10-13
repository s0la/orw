#!/bin/bash

while read -r propcess; do
	top_processes+="$propcess\n"
done <<< $(ps axch -o cmd,%$1 --sort=-%$1 | \
	awk 'NR < 10 {cmds[$1] += $NF} END {for (cmd in cmds) printf("%-30s %5s\n", cmd, cmds[cmd])}' | sort -rnk 2)

~/.orw/scripts/notify.sh -p "<b>${1^} usage:</b>\n\n$top_processes"
