#!/bin/bash

#cat <<- EOF | ~/.orw/scripts/auto.sh
#	_ _ _ alacritty -e tmux
#	less h 7 alacritty -e top
#	greater k 4 ~/.orw/scripts/ncmpcpp.sh -i
#	less k 3 ~/.orw/scripts/ncmpcpp.sh -v -i
#EOF

cat <<- EOF | ~/.orw/scripts/auto.sh
	_ _ _ alacritty -e tmux
	less h 0 alacritty -e top
	less h 3 ~/.orw/scripts/ncmpcpp.sh -i
	less k 6 ~/.orw/scripts/ncmpcpp.sh -v -i
EOF
