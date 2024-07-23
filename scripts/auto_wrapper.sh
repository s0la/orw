#!/bin/bash

cat <<- EOF | ~/files/scripts/auto.sh
	less h 7 ~/.orw/scripts/ncmpcpp.sh -i
	less k 6 ~/.orw/scripts/ncmpcpp.sh -v -i
EOF
