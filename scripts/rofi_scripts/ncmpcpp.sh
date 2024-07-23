#!/bin/bash

running="$(wmctrl -lG | awk '\
	{
		m = $NF
		if(m == "ncmpcpp") {
			n = ($5 > $6) ? "default" : "vertical"
			a = ($5 > $6) ? a ",0" : a ",1"
			r = r " " n "=\"'$indicator' \""
		} else if(m == "visualizer") {
			r = r " visualizer=\"'$indicator' \""
			v[1] = $3; v[2] = $4; v[3] = $5; v[4] = $6
			a = a ",4"
		} else if(m == "ncmpcpp_split") {
			r = r " split=\"'$indicator' \""
			a = a ",2"
		} else if(m == "ncmpcpp_playlist") { p[1] = $3; p[2] = $4; p[3] = $5; p[4] = $6 }
		else if(m == "ncmpcpp_with_cover_art") {
			r = r " cover=\"'$indicator' \""
			a = a ",3"
		}
	} END {
		if(length(p)) {
			if(length(v)) {
				if(v[1] + v[3] < p[1] || v[1] > p[1] + p[3]) {
					r = r " dual_h=\"'$indicator' \""
					a = a ",5"
				} else {
					r = r " dual_v=\"'$indicator' \""
					a = a ",6"
					pl = (p[3] > p[4]) ? 0 : 1
					a = a "," pl
				}
			}
		}

		print r, a
	}')"

if [[ $style =~ icons|dmenu ]]; then
	[[ $running ]] && active="-a ${running#*,}"
	default_label= vertical_label= split_label= cover_label= visualizer_label= dual_h_label= dual_v_label= 
else
	indicator='●'
	[[ $running ]] && eval "$running empty='  '"
	default_label=default vertical_label=vertical split_label=split cover_label=cover visualizer_label=visualizer dual_h_label='dual horizontal' dual_v_label='dual vertical'
fi

toggle
trap toggle EXIT

item_count=7
set_theme_str

mode=$(cat <<- EOF | rofi -dmenu -theme-str "$theme_str" $active -theme main
	${default-$empty}${default_label}
	${vertical-$empty}${vertical_label}
	${split-$empty}${split_label}
	${cover-$empty}${cover_label}
	${visualizer-$empty}${visualizer_label}
	${dual_h-$empty}${dual_h_label}
	${dual_v-$empty}${dual_v_label}
EOF
)

ncmpcpp=~/.orw/scripts/ncmpcpp.sh

layout="${mode%%-*}"
flags="${mode#$layout}"

if [[ $mode ]]; then
	case "$mode" in
		*$default_label*) flags+=' -i';;
		*$split_label*)
			flags+=' -s -i'
			title=ncmpcpp_split;;
		*$cover_label*)
			flags+=' -c -i'
			title=ncmpcpp_with_cover_art;;
		*$visualizer_label*)
			flags+=' -Vv -i'
			title=visualizer;;
		*$dual_h_label*) flags+=' -S yes -d';;
		*$dual_v_label*) flags+=' -S yes -Vd';;
		*$vertical_label*) flags+=' -w 450 -h 600 -i';;
	esac

	eval $ncmpcpp "$flags" &
fi
