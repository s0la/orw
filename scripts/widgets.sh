#!/bin/bash

check_visualizer() {
	visualizer_running=$(wmctrl -l | awk '$NF == "visualizer" { print "true" }')
}

check_controls() {
	#controls_running=$(ps aux | awk '/lemonbar/ && $NF == "mwc" { print "true" }')
	controls_running=$(ps aux | awk '/lemonbar/ && $NF ~ "^(n_)?mwc$" { print "true" }')
}

check_cover() {
	read cover_pid geometry bg <<< $(ps -C feh -o pid=,args= --sort=+start_time | awk '\
		/cover_art_widget/ { print $1, gensub(".*-.g ([^ ]*).* (#\\w*).*", "\\1 \\2", 1); exit }')
	size=${geometry%x*}
}

toggle_input() {
	[[ $input == true ]] && new_state=false || new_state=true
	[[ ${1:-$new_state} == true ]] && state=p || state=s

	awk -i inplace '/L[ps]fg/ {
		cs = (/Lpfg/) ? "p" : "s"
		gsub(cs, "'$state'")
	} { print }' ~/.orw/scripts/bar/launchers

	sed -i "/^input/ s/\w*$/${1:-$new_state}/" $0
}

get_geometry_input() {
	fifo=/tmp/input.fifo
	mkfifo $fifo

	[[ $1 == cover ]] && args=s
	for arg in x y ${args:-w h}; do
		command+="read -p \"$arg: \" $arg; [[ \$$arg ]] && input+=\"-$arg \$$arg \"; clear; "
	done

	command+="echo \$input; echo \"\$input\" > $fifo"

	~/.orw/scripts/termite_geometry.sh -c input -w 400 -h 100
	termite -t geometry_input -e "bash -c '$command'" &> /dev/null &

	read input < $fifo
	rm $fifo

	[[ $input ]] && eval set_cover_geometry $1 $input
}

set_cover_geometry() {
	local widget=$1
	local previous_{size,x,y}

	shift

	previous_size=${previous_geometry%x*}
	previous_x=${previous_geometry#*+} previous_x=${previous_x%+*}
	previous_y=${previous_geometry##*+}

	while getopts :s:x:y:w:h: flag; do
		if [[ $widget == cover ]]; then
			case $flag in
				s) property=size;;
				x) property=x;;
				y) property=y;;
			esac

			eval local $property=$OPTARG
			[[ ${!property} =~ ^[+-] ]] && eval $property=$((previous_$property ${!property}))
		else
			value=$OPTARG
			[[ $value == r ]] && value+=" ${!OPTIND}" && shift
			~/.orw/scripts/barctl.sh -b n_mw* -n -e $flag $value
		fi
	done

	geometry=${size:-$previous_size}x${size:-$previous_size}+${x:-$previous_x}+${y:-$previous_y}
}

get_window_properties() {
	#xwininfo -int -id $(wmctrl -l | awk '$NF == "'$1'" { print $1 }') |
	wmctrl -l | awk '$NF == "'$1'" { print $1 }' |
		xargs -r xwininfo -id | awk '
			/Absolute/ { if(/X/) x = $NF; else y = $NF }
			/Relative/ { if(/X/) xb = $NF; else yb = $NF }
			/Width/ { w = $NF }
			/Height/ { print x - xb, y - yb, w, $NF }'
}

cover() {
	write() {
		sed -i "/^\s*previous_$1/ s/'.*'/'${!1}'/" $0
	}

	replace() {
		sed -i "/<application name.*\*.*>/,/\/position/ \
			{ /<[xy]>/ s/>.*</>${1:-center}</ }" ~/.config/openbox/rc.xml
		openbox --reconfigure
	}

	previous_geometry='63x63+770+952'
	previous_bg='#e80a0a0a'

	check_cover

	if [[ $1 != -k ]]; then
		cover="$(~/.orw/scripts/get_cover_art.sh)"

		if [[ ! -f $cover ]]; then
			cover=~/Music/covers/placeholder.png
			convert -size ${size}x${size} xc:$bg $cover
		fi

		if [[ ! $geometry ]]; then
			check_controls

			if [[ $controls_running ]]; then
				border=$(awk '/^border/ { print $NF * 2 }' ~/.orw/themes/theme/openbox-3/themerc)
				size=$(awk '{
					for(fi = 1; fi <= 3; fi++)
						s += gensub("([^-]*([^Ffh]*[^0-9]*)([0-9]*)){" fi "}.*", "\\3", 1)
					} END { print s - '$border' }' ~/.config/orw/bar/configs/n_mw*)

				#read x y <<< $(~/.orw/scripts/windowctl.sh -n mwi -p |\
				#	awk '{ print ($4 >= 300) ? $2 : $2 - '$(($size / 3 * 2))', $3 }')

				#read x y size <<< $(~/.orw/scripts/windowctl.sh -n n_mwc -p | awk '{ print $2, $3, $5 - '$border' }')
				read x y size <<< $(get_window_properties n_nwc | awk '{ print $1, $2, $4 - '$border' }')
				#read x y size <<< $(~/.orw/scripts/windowctl.sh -n n_mwc -p | awk '{ print $2 - $5, $3, $5 - '$border' }')
				geometry="${size}x${size}+${x}+${y}"
			else
				[[ $input == true ]] && get_geometry_input cover
			fi
		fi

		[[ ! $bg ]] && bg=$(sed -n 's/^bg //p' ~/.config/orw/colorschemes/bar_n_mw.ocs)

		replace default

		feh --title cover_art_widget -.g ${geometry:-$previous_geometry} --image-bg $bg "$cover" &

		write geometry
		write bg
		sleep 0.1
		replace
	fi

	[[ $cover_pid ]] && kill $cover_pid
}

get_display() {
	#read -a window_properties <<< $(~/.orw/scripts/windowctl.sh -n $1 -p)
	#display=$(~/.orw/scripts/get_display.sh ${window_properties[3]} ${window_properties[4]} | awk '{ print $1 }')
	read -a window_properties <<< $(get_window_properties $1)
	display=$(~/.orw/scripts/get_display.sh \
		${window_properties[2]} ${window_properties[3]} | cut -d ' ' -f 1)
}

layout() {
	if [[ $2 == -k ]]; then
		tmux -S /tmp/tmux_hidden kill-session -t $1
	else
		check_cover
		check_controls

		[[ $1 == visualizer ]] && height=2 || height=5

		if ((cover_pid)); then
			border=$(awk '/^border/ { print $NF * 2 }' ~/.orw/themes/theme/openbox-3/themerc)

			get_display cover_art_widget

			if [[ ! $controls_running && $1 == visualizer ]]; then
				layout="-d $display -M cover_art_widget xe,y,h,w*3"
			else
				if [[ ! $controls_running ]]; then
					local mirror=visualizer
					local delta="+$border"
				else
					local mirror=n_mwc
					local delta=$(get_window_properties n_nwc |
						awk '{ s = '$size'; d = ($3 >= 300) ? s : s - int(s / 3 * 2); print "-" d }')
					#local delta=$(~/.orw/scripts/windowctl.sh -n n_mwc -p |
					#	awk '{ s = '$size'; d = ($4 >= 300) ? s : s - int(s / 3 * 2); print "-" d }')

					[[ $1 == playlist ]] && progressbar=no status=no
				fi

				layout="-d $display -M cover_art_widget x,w,h*$height,ys-10 -M $mirror w$delta+"
			fi
		else
			if [[ $controls_running ]]; then
				get_display n_mwi
				layout="-d $display -M n_mwi x,h*15,ys-10,w"
			else
				#get_display ncmpcpp_playlist
				#[[ $(wmctrl -l | awk '$NF == "ncmpcpp(_playlist)?"') ]] &&
				#	layout="-d $display -M ncmpcpp_playlist x,ye+10,w"

				get_display ncmpcpp
				[[ $(wmctrl -l | awk '$NF == "ncmpcpp"') ]] &&
					layout="-d $display -M ncmpcpp x,ye+10,w"
			fi
		fi

		[[ ! $layout ]] &&
			~/.orw/scripts/ncmpcpp.sh -w 450 -h 400 -P yes -V${1:0:1}i ||
			~/.orw/scripts/ncmpcpp.sh -w 100 -h 100 -V${1:0:1} -P ${progressbar-yes} -L "-n $1 $layout" -i
	fi
}

playlist() {
	layout playlist $@
}

visualizer() {
	layout visualizer $@
}

controls() {
	if [[ $1 == -k ]]; then
		~/.orw/scripts/barctl.sh -b n_mw* -k &
	else
		[[ $input == true ]] && get_geometry_input controles 
		~/.orw/scripts/barctl.sh -b n_mw*
	fi
}

weather() {
	~/.orw/scripts/barctl.sh -b ww* $1
}

input=false

$@
