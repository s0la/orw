#!/bin/bash

if [[ -z $@ ]]; then
	indicator=''
	indicator='●'

	running="$(wmctrl -lG | awk '\
		{
			m = $NF
			if(m == "ncmpcpp") { n = ($5 > $6) ? "default" : "vertical"; r = r " " n "=\"'$indicator' \"" }
			else if(m == "visualizer") { v[1] = $3; v[2] = $4; v[3] = $5; v[4] = $6 }
			else if(m == "ncmpcpp_split") r = r " split=\"'$indicator' \""
			else if(m == "ncmpcpp_playlist") { p[1] = $3; p[2] = $4; p[3] = $5; p[4] = $6 }
			else if(m == "ncmpcpp_with_cover_art") r = r " cover=\"'$indicator' \""
		} END {
			if(length(v) && length(p)) {
				if(v[1] + v[3] < p[1] || v[1] > p[1] + p[3]) r = r " dual_h=\"'$indicator' \""
				else r = r " dual_v=\"'$indicator' \""
			}

			print r
		}')"

	[[ $running ]] && eval "$running empty='  '"

	echo -e "${default-$empty}default\
		\n${vertical-$empty}vertical\
		\n${split-$empty}split\
		\n${cover-$empty}cover\
		\n${dual_h-$empty}dual horizontal\
		\n${dual_v-$empty}dual vertical\
		\n${empty}set cover art\n${empty}ncmpcpp"
else
	killall rofi
	ncmpcpp=~/.orw/scripts/ncmpcpp.sh

	arguments="$@"
	layout="${arguments%%-*}"
	flags="${arguments#$layout}"

	case "$layout" in
		*default*) flags+=' -i';;
		*split*) flags+=' -s -i';;
		*set*) flags+=' -R';;
		*cover*) flags+=' -c -i';;
		*dual*h*) flags+=' -d';;
		*dual*v*) flags+=' -V -d';;
		*vertical*) flags+=' -w 450 -h 600 -i';;
	esac

	eval $ncmpcpp "$flags"
fi
