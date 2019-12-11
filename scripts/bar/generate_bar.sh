#!/bin/bash

path=~/.orw/scripts/bar/
config_path=~/.config/orw/bar

inner="%{O5}"
padding="%{O20}"
separator="%{O5}"

bar_height=16
main_font_offset=1

bar_name='main_bar'

bg="#303030"
fc="#303030"
bfc="#303030"
bbg="#303030"

pbg="%{B#3a3a3a}"
pfg="%{F#abaeb2}"
sbg="%{B#3a3a3a}"
sfg="%{F#797c80}"

get_mpd() {
    echo -e "MPD $($path/mpd.sh $fifo ${mpd_modules-c,p,S,i,s20,T,d3,v} $label)"
}

get_apps() {
	[[ $single_line ]] && app_lines=single
	echo -e "APPS $($path/apps.sh $apps_args ${app_lines:-${lines-false}})"
}

get_workspaces() {
	for arg in ${workspaces_args//,/ }; do
		if [[ $arg =~ ^o ]]; then
			value=${arg:1}

			if [[ $value =~ [0-9] ]]; then
				offset="%{O$value}"
			else
				[[ $value == p ]] && offset=$padding || offset=$inner
			fi
		else
			workspaces_label=$arg
		fi
	done

	if [[ ! $offset ]]; then
		[[ "${Wsbg:-$sbg}" =~ "${Wpbg:-${Wsbg:-$pbg}}" ]] && offset=$inner || offset=$padding
	fi

	echo -e "WORKSPACES $($path/workspaces.sh ${workspaces_label-i} $offset ${single_line-false})"
}

get_full_usage() {
	echo -e "USAGE $($path/system_info.sh Usage $order $label)"
}

get_temp() {
	echo -e "TEMP $($path/system_info.sh Temp $label)"
}

get_cpu_usage() {
	echo -e "CPU $($path/system_info.sh Cpu $label $1)"
}

get_ram_usage() {
	echo -e "RAM $($path/system_info.sh Ram $label $1)"
}

get_disk_usage() {
	echo -e "DISK $($path/system_info.sh Disk $label $1)"
}

get_network() {
	echo -e "NETWORK $($path/system_info.sh network $label)"
}

get_email() {
	echo -e "EMAIL $($path/system_info.sh email $label ${lines-false})"
}

get_volume() {
	echo -e "VOLUME $($path/system_info.sh volume $label)"
}

get_weather() {
	echo -e "WEATHER $($path/system_info.sh Weather ${weather_info-t,s} $label $city ${lines-false})"
}

get_hidden() {
	echo -e "HIDDEN $($path/system_info.sh Hidden ${apps-all} $label ${lines-false})"
}

get_battery() {
	echo -e "BATTERY $($path/system_info.sh Battery ${battery_info-p,t} $label)"
}

get_torrents() {
	echo -e "TORRENTS $($path/system_info.sh torrents ${torrents_info-c,p} $label ${lines-false})"
}

get_date() {
	echo -e "DATE $($path/system_info.sh date $date_format)"
}

get_updates() {
	echo -e "UPDATES $($path/system_info.sh updates $label ${lines-false})"
}

config=~/.config/orw/config
[[ ! -f $config ]] && ~/.orw/scripts/generate_orw_config.sh

read x_offset y_offset <<< $(awk -F '[_ ]' '/offset/ { if($1 == "x") xo = $NF; else yo = $NF } END { print xo, yo }' $config)

get_display_properties() {
	[[ ! $x && ! $y ]] &&
		read x y display_width display_height real_x real_y <<< \
		$(awk -F '[_ ]' '{ if(/^orientation/ && $NF ~ /^v/) v = 1; \
		if($1 == "primary") { s = '${1-0}'; d = (s) ? s : $NF; x = 0 }; \
			if($1 == "display" && NF == 4) if($2 < d) { x += $3; if(v) { rx += $3; ry += $4 } } \
			else { print x, 0, $3, $4, rx, ry; exit } }' $config)
}

check_arg() {
    [[ $2 && ! $2 == -[[:alpha:]] ]] && eval $1=$2
}

add_lines() {
    echo "${start_line:-$left_frame}${1}${end_line:-$right_frame}"
}

set_frame_color() {
	module_frame_color="${flag}fc"
	frame_color=${!module_frame_color:-$fc}
	module_frame_width="${flag}fw"

	if [[ $all_lines && ! $left_side_frame ]]; then
		[[ $frame_color == $bg ]] && side_width=$frame_width
		left_side_frame=%{O${side_width:-0}}
	fi

	[[ $frame_color == $bg ]] && eval "$module_frame_width=0"
}

format() {
	set_frame_color

	left_line=$(eval echo -e "${start_line:-$left_frame}")
	right_line=$(eval echo -e "${end_line:-$right_frame}")
    modules+="%{U$frame_color}$left_line\${$1% *}$right_line%{B$bg}\${$1##* }"
}

set_lines() {
	lines=true

	if [[ ${frame_style-a} == a ]]; then
		all_lines=true

		bar_side_frame="%{B\$frame_color}%{O\${!module_frame_width:-\${frame_width-0}}}"
		left_frame="%{+u}%{+o}$bar_side_frame"
		right_frame="$bar_side_frame%{-o}%{-u}"
	else
		single_line=true

		start_line="%{+$frame_style}"
		end_line="%{-$frame_style}"
		frame_count=1

		if [[ ! $optimised_offset ]]; then
			optimised_offset=true
			[[ $frame_style == u ]] && direction=- || direction=+
			((main_font_offset $direction= $(($frame_width / 2))))
		fi
	fi
}

get_fifo() {
	if [[ ! $fifo ]]; then
		fifo="$config_path/fifos/$bar_name.fifo"
		[[ ! -d ${fifo%/*} ]] && mkdir -p ${fifo%/*}
		[[ ! -p $fifo ]] && mkfifo $fifo
	fi
}

run_function() {
	get_fifo

	time=${@: -1}

	while true; do
		${@%time}
		sleep ${@: -1}
	done > "$fifo" &
}

all_arguments="$@"

while getopts :bicrx:y:w:h:p:f:ls:S:MmAtWNevduF:HLEUTCRDBO:n:oa: flag; do
	case $flag in
		b)
			bg=$bbg
			bottom=-b;;
		i) label=icon;;
		c) modules+='%{c}';;
		r) modules+='%{r}';;
		x)
			if [[ $OPTARG == r ]]; then
				align_right=true
				check_arg x_offset ${!OPTIND} && shift
			elif [[ $OPTARG == c ]]; then
				align_center=true
			else
				x_offset=$OPTARG
			fi;;
		y) y_offset=$OPTARG;;
		w) bar_width=$OPTARG;;
		h) bar_height=$OPTARG;;
		p) padding="%{O$OPTARG}";;
		f)
			frame_width=$OPTARG
			check_arg frame_style ${!OPTIND} && shift;;
		l)
			[[ $lines ]] && unset lines all_lines single_line {start,end}_line {left,right}_frame || set_lines;;
		M) source $path/module_colors;;
        F)
			bar_frame_width=$OPTARG
			bar_frame="-R$bfc -r $bar_frame_width"

			[[ $bottom ]] && ((y_offset += 2 * bar_frame_width));;
		s) separator="%{O$OPTARG}";;
		S) get_display_properties $OPTARG;;
		L)
			format Logout
			get_display_properties
			Logout=$(eval "echo -e \"$($path/system_info.sh Logout ${display_width}x$display_height)\"");;
		m)
			format mpd
			check_arg mpd_modules ${!OPTIND} && shift

			run_function get_mpd 1;;
        A)
			modules+='$apps'

			check_arg apps_args ${!OPTIND} && shift

			run_function get_apps 1;;
		t)
			set_frame_color
			modules+='$torrents'

			check_arg torrents_info ${!OPTIND} && shift

			run_function get_torrents 30;;
        W)
			[[ $single_line ]] && modules+='$workspaces' || format workspaces

			check_arg workspaces_args ${!OPTIND} && shift

			run_function get_workspaces 1;;
        N)
			format network
			run_function get_network 100;;
        e)
			set_frame_color
			modules+='$email'

			run_function get_email 100;;
        v)
            format volume
            run_function get_volume 1;;
        d)
            format date

            check_arg date_format ${!OPTIND} && shift

            run_function get_date 60;;
		u)
			set_frame_color
			modules+='$updates'

			run_function get_updates 1000;;
        H)
			set_frame_color
			modules+='$hidden'

            check_arg apps ${!OPTIND} && shift

            run_function get_hidden 1;;
        E)
			set_frame_color
			modules+='$weather'

            check_arg weather_info ${!OPTIND} && shift
            check_arg city ${!OPTIND} && shift

            run_function get_weather 1000;;
		U)
			format usage
			check_arg order ${!OPTIND} && shift

			order=${order-c,r,d}

			run_function get_full_usage 1

			for item in ${order//,/ }; do
				case $item in
					c) run_function get_cpu_usage trim 10;;
					r) run_function get_ram_usage trim 10;;
					d) run_function get_disk_usage trim 10;;
				esac
			done;;
		T)
			format temp
			run_function get_temp 10;;
		C)
			format cpu
			run_function get_cpu_usage 10;;
		R)
			format ram
			run_function get_ram_usage 10;;
		D)
			format disk
			run_function get_disk_usage 10;;
		B)
			format battery
			check_arg battery_info ${!OPTIND} && shift
			run_function get_battery 10;;
		O) modules+=%{O$OPTARG};;
		n) bar_name="$OPTARG";;
		o)
			overwrite=true
			flags="$path/generate_bar.sh ${all_arguments%-o*}${all_arguments#*-o}";;
		a) font_size=$OPTARG;;
	esac
done

[[ ! -f $config_path/configs/$bar_name || $overwrite ]] && echo "${flags:-$path/generate_bar.sh $all_arguments}" > $config_path/configs/$bar_name

get_display_properties

[[ $@ =~ -l ]] && set_lines

if [[ ! $font_size ]]; then
	font_size=$((bar_height / 2))
	((font_size > 8)) && ((font_size--))
fi

if ((bar_height < 20)); then
	((bar_height % 2 == 1)) && ((main_font_offset++)) && icomoon_offset=$((main_font_offset - 2))
fi

font_offset=$((main_font_offset - 1))

font1="Roboto Mono Medium:size=$font_size"
font1="Iosevka Orw:style=Medium:size=$font_size"
font2="icomoon_fa:size=$font_size"
font3="Font Awesome 5 Free:style=Solid:size=$((font_size - 1))"
font4="DejaVu Sans Mono:size=$font_size"
font5="orw_fi:size=$font_size"

ends_with_line=$(awk -F '-l' '{ if((NF - 1) % 2) print "true" }' <<< "$all_arguments")

if [[ $ends_with_line && $all_lines ]]; then
	[[ $frame_color == $bg ]] && side_width=$frame_width || side_width=0
	right_side_frame="%{O${side_width:-0}}"
fi

if [[ $bar_width =~ [a-z] ]]; then
	adjustable_width=true

	[[ $align_center ]] && bar_width=$display_width || 
		bar_width=$((display_width - x_offset))

	((bar_width -= 2 * bar_frame_width))

	geometry_file="$config_path/geometries/$bar_name"
	[[ -f $geometry_file ]] && rm $geometry_file
	[[ ! -d ${geometry_file%/*} ]] && mkdir -p ${geometry_file%/*}

	bar_options='(A([0-9]?:?.*:$|$)|[BFU][#-]|I-|[TO][0-9-]+$|[lcr]$|[+-][ou])'
fi

if [[ $align_center ]]; then
	[[ $adjustable_width ]] && x_offset=0 || x_offset=$(((display_width - bar_width) / 2))
fi

if [[ $align_right ]]; then
	right_x_offset=$x_offset
	x_offset=$((display_width - right_x_offset - (bar_width + 2 * bar_frame_width)))
fi

bar_x=$((x + x_offset))
bar_y=$((y + y_offset))

if [[ ! $bar_width ]]; then
	bar_width=$((display_width - 2 * x_offset - 2 * bar_frame_width))
fi

bar_height=$((bar_height + ${frame_count-2} * frame_width))

geometry="${bar_width}x${bar_height}+${bar_x}+${bar_y}"

get_fifo

calculate_width() {
	apply_geometry() {
		[[ $align_center ]] && bar_x=$((x - real_x + (display_width - (current_width + 2 * bar_frame_width)) / 2))
		[[ $align_right ]] && bar_x=$((x - real_x + display_width - right_x_offset - (current_width + 2 * bar_frame_width)))

		xdotool search --name "^$bar_name$" windowsize $current_width $bar_height windowmove $bar_x $bar_y

		echo $current_width $bar_height $bar_x $bar_y > $geometry_file
	}

	while read content; do
		if [[ $adjustable_width ]]; then
			current_width=$(awk -F '%{|}' \
				'{ fs = '$((font_size - 2))'; fw = fs; \
				for(f = 1; f < NF; f++) \
					{ if($f ~ /O[0-9]+$/) o += substr($f, 2); \
						if($f ~ /I-[0-9A-Za-z]?$/) { is = substr($f, 3); \
							if(is ~ /[0-9]/) iw = is; \
							else if(is == "n") iw = 5; \
							else if(is == "b") iw = 6; \
							else if(is == "B") iw = 7; \
							else if(is == "s") iw = 1; \
							else if(is == "S") iw = 3; \
							else icon = 0; \
								if(is) { icon = 1; l += (is ~ /[Ss]/) ? fs - iw : fs + iw } } \
								else if($f !~ /^'$bar_options'/) if(!icon) l += length($f) * fw } } 
									END { print int(o + l) }' <<< "$content")

			if [[ ! -f $geometry_file ]]; then
				other_geometry_parameters=${geometry#*x}
				read bar_height bar_x bar_y <<< ${other_geometry_parameters//+/ }

				[[ $bottom ]] && bar_y=$((display_height - (bar_y + bar_height + 0 * bar_frame_width)))
				(( bar_y += real_y ))

				apply_geometry
			else
				read bar_width bar_height bar_x bar_y < $geometry_file

				((current_width != bar_width)) && apply_geometry
			fi
		fi

		echo -e "$content"
	done
}

while read -r module; do
	case $module in
		SONG_INFO*) song_info=$(eval "echo -e \"${module:10}\"");;
		PROGRESSBAR*) progressbar=$(eval "echo -e ${module:12}");;
		CONTROLS*) controls=$(eval "echo -e \"${module:9}\"");;
		MPD_VOLUME*) mpd_volume=$(eval "echo -e \"${module:11}\"");;
		#MPD*) mpd=$(eval "sed 's/\([^}]*}\)\([^}]*}\)/\2\1/' <<< \"${module:4}\"");;
		MPD*) mpd=$(eval "sed 's/\(\(%[^}]*}\)*\)\(%{B[^}]*}\)/\3\1/' <<< \"${module:4}\"");;
		APPS*) apps=$(eval "echo -e \"${module:5}\"");;
		TORRENTS*) torrents=$(eval "echo -e \"${module:9}\"");;
		WORKSPACES*) workspaces=$(eval "echo -e ${module:11}");;
		RAM*) ram=$(eval "echo -e ${module:4}");;
		CPU*) cpu=$(eval "echo -e ${module:4}");;
		TEMP*) temp=$(eval "echo -e \"${module:5}\"");;
		DISK*) disk=$(eval "echo -e \"${module:5}\"");;
		USAGE*) usage=$(eval "echo -e \"${module:6}\"");;
		EMAIL*) email=$(eval "echo -e \"${module:6}\"");;
		VOLUME*) volume=$(eval "echo -e \"${module:7}\"");;
		NETWORK*) network=$(eval "echo -e \"${module:8}\"");;
		WEATHER*) weather=$(eval "echo -e \"${module:8}\"");;
		DATE*) date=$(eval "echo -e \"${module:5}\"");;
		UPDATES*) updates=$(eval "echo -e \"${module:8}\"");;
		NOTIFICATIONS*) notifications=$(eval "echo -e \"${module:14}\"");;
		HIDDEN*) hidden=$(eval "echo -e \"${module:7}\"");;
		BATTERY*) battery=$(eval "echo -e \"${module:8}\"");;
	esac

	all_modules=$(eval "echo -e \"$modules\"")

	[[ $all_modules ]] && last_offset="%${all_modules##*%}"
	[[ $last_offset == $separator ]] && all_modules="${all_modules%\%*}" || all_modules="${all_modules%\%*\%*}$last_offset"

	echo -e "%{l}%{U$fc}$left_side_frame$all_modules%{B$bg}$right_side_frame"
done < "$fifo" | calculate_width | lemonbar -d -p -B$bg \
	-f "$font1" -o $main_font_offset \
	-f "$font2" -o ${icomoon_offset:-$((font_offset - 0))} \
	-f "$font4" -o $main_font_offset \
	-f "$font5" -o $((font_offset - 0)) \
	-a 70 -u ${frame_width-0} $bar_frame $bottom -g $geometry -n "$bar_name" | bash &

sleep 0.5
xdo lower -N Bar
