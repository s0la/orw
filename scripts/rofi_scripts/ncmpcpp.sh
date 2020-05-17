#!/bin/bash

if [[ -z $@ ]]; then
	indicator=''
	indicator='●'

	running="$(wmctrl -lG | awk '\
		{
			m = $NF
			if(m == "ncmpcpp") { n = ($5 > $6) ? "default" : "vertical"; r = r " " n "=\"'$indicator' \"" }
			else if(m == "visualizer") {
				r = r " visualizer=\"'$indicator' \""
				v[1] = $3; v[2] = $4; v[3] = $5; v[4] = $6
			}
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

	cat <<- EOF
		${default-$empty}default
		${vertical-$empty}vertical
		${split-$empty}split
		${cover-$empty}cover
		${visualizer-$empty}visualizer
		${dual_h-$empty}dual horizontal
		${dual_v-$empty}dual vertical
		${empty}ncmpcpp
	EOF
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
		*visualizer*) flags+=' -v -i';;
		*dual*h*) flags+=' -S yes -d';;
		*dual*v*) flags+=' -S yes -Vd';;
		*vertical*) flags+=' -w 450 -h 600 -i';;
	esac

	#read mode ratio <<< $(awk '/^(mode|ratio)/ { print $NF }' ~/.config/orw/config | xargs)
	read mode ratio <<< $(awk '/^(mode|part|ratio)/ {
			if(/mode/) m = $NF
			else if(/part/ && $NF) p = $NF
			else if(/ratio/) r = p "/" $NF
		} END { print m, r }' ~/.config/orw/config | xargs)

	if [[ $mode == tiling ]]; then
		class="-C tiling"
		read x y width height <<< $(~/.orw/scripts/windowctl.sh resize H a $ratio)
		~/.orw/scripts/set_class_geometry.sh -c tiling -x $x -y $y -w $width -h $height
		#properties=$(~/.orw/scripts/windowctl.sh resize -H a 3)
		#tile_layout="\"-L ${properties#* }\""
	fi

	eval $ncmpcpp "$class" "$flags"
	#eval $ncmpcpp "$tile_layout" "$flags"
fi
