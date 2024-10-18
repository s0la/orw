#!/bin/bash

pid=$$

get_display_properties() {
	[[ ! $x && ! $y ]] &&
		read default_{x,y}_offset {vertical_,}{x,y} display_width display_height <<< \
				$(awk -F '[_ ]' '
					/^orientation/ && $NF ~ /^v/ { v = 1 }

					$1 == "primary" {
						x = vx = vy = 0
						s = '${screen-0}'
						d = (s) ? s : $NF
					}

					$2 == "offset" { o = o $NF " " }

					/^display.*size/ {
						if($2 < d) {
							x += $4

							if(v) {
								vx += $4
								vy += $5
							}
						} else {
							print o vx, vy, x, 0, $4, $5
							exit
						}
					}' ~/.config/orw/config)
}

set_x() {
	local bar_width="${1:-$bar_width}"

	if ((center_width)); then
		bar_x=$((x + display_width / 2 - center_width))
	elif [[ $bar_x ]]; then
		((bar_x+=x))
	else
		if ((bar_width)); then
			[[ $reverse_x == *[0-9] ]] &&
				local reverse_offset=$reverse_x

			if [[ $center_x ]]; then
				if [[ $center_x == *[0-9] ]]; then
					bar_x=$((x + display_width / 2 + center_x))
				else
					[[ ! $reverse_x ]] &&
						bar_x=$((x + ((display_width - (bar_width + 2 * bar_frame_width)) / 2))) ||
						bar_x=$((x + display_width / 2 - reverse_offset - (bar_width + 2 * bar_frame_width)))
				fi
			fi

			if ((!bar_x)); then
				[[ ! $reverse_x ]] &&
					bar_x=$((x + default_x_offset)) ||
					bar_x=$((x + display_width - ${reverse_offset:-$default_x_offset} - bar_width))
			fi
		else
			#bar_x=$default_x_offset
			bar_x=$((x + default_x_offset))
		fi
	fi
}

get_icon() {
	local icon="$1"

	#icon="$(awk -F '=' '/^[^#]/ && /'"$icon"'/ {
	#	p = (/bar/) ? "T3" : "I"
	#	printf "%{%s}%s%{%s-}\n", p, $NF, substr(p, 2, 1)
	#}' $icons_file)"

	#icon="$(awk -F '=' '/^[^#]/ && /'"$icon"'/ { print $NF }' $icons_file)"
	#echo "%{I}$icon%{I}"

	awk -F '=' '/^[^#]/ && /'"$icon"'/ {
		p = (/bar/) ? "T3" : "I"
		printf "%{%s}%s%{%s-}\n", p, $NF, substr(p, 1, 1)
	}' $icons_file
}

singles=( rec tiling power )
multiframe_modules=( workspaces windows launchers )
labeled_modules=( rss emails volume counter vanter torrents \
	network power display rec bluetooth battery weather )

set_module_colors() {
	local module_short=$1
	eval ${module_short}pfc="\${${module_short}pfc:-\$pfc}"
	eval ${module_short}sfc="\${${module_short}sfc:-\$sfc}"
	eval ${module_short}pbg="\${${module_short}pbg:-\$pbg}"
	eval ${module_short}sbg="\${${module_short}sbg:-\$sbg}"
	eval ${module_short}pfg="\${${module_short}pfg:-\$pfg}"
	eval ${module_short}sfg="\${${module_short}sfg:-\$sfg}"
}

set_module_frame() {
	local short_module=$1 frame_type=${2:-$frame_type}
	local frame_mode="\${${short_module}pfc:-\$${short_module}sfc}"
	local frame_mode="\${${short_module}_fc:-\$${short_module}sfc}"

	if [[ $frame_type == all ]]; then
		module_frame_start="%{B\$${short_module}sfc}%{U\$${short_module}sfc}$frame_start"
		module_active_frame_start="%{B\$${short_module}pfc}%{U\$${short_module}pfc}$frame_start"
		module_frame_end="%{B\$${short_module}sfc}$frame_end%{B-}"
		#module_frame_start="%{B${frame_mode//_/s}}%{U${frame_mode//_/s}}$frame_start"
		#module_active_frame_start="%{B${frame_mode//_/p}}%{U${frame_mode//_/p}}$frame_start"
		#module_frame_end="%{B${frame_mode//_/s}}$frame_end%{B-}"
	else
		module_frame_start="%{U\$${short_module}sfc}$frame_start"
		module_active_frame_start="%{U\$${short_module}pfc}$frame_start"
		module_frame_end="$frame_end%{B-}"
	fi
}

self_kill() {
	kill -9 $pid &> /dev/null
	killall run.sh lemonbar
	remove_fifos
}

loading_icon=''
root_dir="${0%/*}"
fifo_dir=/tmp/fifos
bar_config=$root_dir/config
modules_dir=$root_dir/modules
icons_file=${root_dir%/*}/icons
colorscheme_dir=~/.orw/dotfiles/config/orw/colorschemes

[[ -d $fifo_dir ]] || mkdir $fifo_dir

get_module() {
	case $1 in
		m) module=mpd;;
		d) module=date;;
		C) module=counter;;
		N) module=network;;
		V) module=vanter;;
		A) module=windows;;
		W) module=workspaces;;
		T) module=torrents;;
		R) module=rss;;
		L) module=launchers;;
		v) module=volume;;
		e) module=emails;;
		P) module=power;;
		t) module=tiling;;
		D) module=display;;
		X) module=rec;;
		B) module=bluetooth;;
		b) module=battery;;
		E) module=weather;;
	esac
}

bar_separator='%{B-}%{O10}'
padding='%{O20}'

make_module() {
	local module_file=$modules_dir/${module}.sh
	local module_pbg="${opt}pbg" module_sbg="${opt}sbg"
	local full_module module_frame_{start,end} {p,s}bg mf{s,e} single_color_type

	if [[ ! ${joiner_modules[$opt]} ]]; then
		set_module_frame $opt
		mfs="$module_frame_start" mfe="$module_frame_end"
		pbg="\$$module_pbg" sbg="\$$module_sbg"
		eval ${module}_padding=$padding
	fi

	if [[ ${labeled_modules[*]} =~ $module ]]; then
		[[ $icons ]] &&
			local label='$icon' || local label='$label'
	fi

	[[ -f $module_file ]] && source $module_file
	type -t make_${module}_content &> /dev/null

	if ((!$?)); then
		make_${module}_content "$args"
		[[ $label ]] || full_module="\$${module}_content"
	fi

	if [[ ! $full_module ]]; then
		if [[ ! $label || (${singles[*]} == *$module* || $icons == only) ]]; then
			[[ $label ]] &&
				local single_content=$label || local single_content="\$$module"

			[[ ${singles[*]} == *$module* && ! ${joiner_modules[$opt]} ]] &&
				single_color_type=p mfs="$module_active_frame_start" mfe="${mfe/?fc/pfc}" || single_color_type=s
			local single_fg="\${cjffg:-\${cj${single_color_type}fg:-\$${opt}${single_color_type}fg}}"

			full_module="$pbg$single_fg\$${module}_padding%{T2}"
			full_module+="$single_content\$${module}_padding"
		else
			[[ ${!module_pbg} == ${!module_sbg} ]] &&
				inner='%{O2}' || inner='%{O3}'
			full_module="$sbg\${cjsfg:-\$${opt}sfg}\$${module}_padding%{T2}$label$inner"
			full_module+="$pbg\${cjpfg:-\$${opt}pfg}$inner%{T2}\$$module\$${module}_padding"
		fi

		#[[ $module == rec ]] && ~/.orw/scripts/notify.sh -t 11 "REC: $full_module"
		full_module="\$mfs${full_module//\$/\\\$}\$mfe"
	fi

	eval ${module}_content="$full_module"
}

get_joiner_frame() {
	local module="$1" switch_bg="$2"
	local joiner_sbg="\$${module}sbg"
	local frame_mode="\${${module}sfc:-\${${module}pfc:-\$pfc}}"
	local joiner_fc="%{B$frame_mode}"

	joiner_start="$joiner_fc%{U$frame_mode}$joiner_frame_start"
	joiner_end="%{B$frame_mode}$joiner_frame_end%{B-}"

	if [[ $switch_bg ]]; then
		((${#new_active_modules} > 0 && ${#switch_bg} > 2)) &&
			local bg_distance="%{O${switch_bg:2}}"

		#[[ ${switch_bg:1:1} == f ]] &&
		#	joiner_next_bg="$bg_distance$joiner_fc$joiner_padding" ||
		#	joiner_next_bg="$joiner_padding$joiner_sbg$bg_distance"

		if [[ ${switch_bg:1:1} == f ]]; then
			local ffg
			joiner_next_bg="$bg_distance$joiner_fc$joiner_padding"
			eval ffg="\$(~/.orw/scripts/convert_colors.sh -hB $frame_mode | grep -o '[^ ]*$')"
			jffg="%{F$ffg}"
			#~/.orw/scripts/notify.sh "$frame_mode, $jffg, $ffg"
		else
			joiner_next_bg="$joiner_padding$joiner_sbg$bg_distance"
		fi
	fi

	[[ ${switch_bg:1:1} == b ]] ||
		joiner_start+="$joiner_sbg"

	joiner_start+="$joiner_padding"
	joiner_end="$joiner_padding$joiner_end"
}

reload_module() {
	local module_index=$1

	if [[ ${new_active_modules: $module_index:1} ]]; then
		local current_module=$module current_output=$output_content
		local current_label=$label current_icon=$icon

		get_module ${new_active_modules: $module_index:1}
		local $module actions_{start,end}
		get_$module

		type -t set_${module}_actions &> /dev/null && set_${module}_actions

		[[ ${!module} ]] && print_module $module $module_index

		module=$current_module output_content="$current_output"
		label=$current_label icon=$current_icon 
	fi
}

reload_modules() {
	local module_index=$1 reload=$2

	if [[ ($new_active_modules != $active_modules &&
		(($short != [$active_modules] &&
		$short == ${new_active_modules: $module_index:1}) ||
		($short == ${active_modules: $module_index:1} &&
		$short != [$new_active_modules])) || $reload) ]]; then
			((module_index < 0)) && local sign=-

			[[ $reload || ($short != [$active_modules] &&
				$short == ${new_active_modules:$module_index:1}) ]] &&
				local start_position=$((module_index ${sign:-+} 1)) ||
				local start_position=$module_index

			if ((module_index < 0)); then
				reload_module $start_position
			else
				((module_index)) &&
					((module_index--)) &&
					((start_position--)) &&
					print_current=true

				if ((start_position == module_index)) && [[ $switch_bg == *[0-9]* ]]; then
					reload_module $((start_position + 1))
				fi

				[[ ! $print_current ]] &&
					reload_module $start_position ||
					eval modules_to_print+=( \"${module^^}:"${output_content//\"/\\\"}"\" )

				if ((start_position > module_index)) && [[ $switch_bg == *[0-9]* ]]; then
					reload_module $((start_position + 1))
				fi
			fi
	fi

	((!module_index)) && [[ ! $print_current ]] && return

	local $short="${new_active_modules: $module_index:1}"
	if [[ ! ${reloaded_modules[*]} =~ (^| )$short( |$) ]]; then
		eval modules_to_print+=( \"${module^^}:"${output_content//\"/\\\"}"\" )
		reloaded_modules+=( $short )
	fi

	return
}

print_module() {
	local module=$1 content=${1}_content short=${shorts[$1]}
	local output_content new_active_modules
	[[ $2 ]] ||
		local modules_to_print reloaded_modules

	#[[ $module == rec ]] && ~/.orw/scripts/notify.sh -t 11 "REC: $content - ${!content}"

	[[ "${!module}" ]] &&
		output_content="$actions_start${!content}$actions_end"

	if [[ ${!joiner_modules[*]} == *$short* ]]; then
		{
			flock -x 11

			local joiner_group_index=${joiner_modules[$short]}
			local joiner_group="${joiner_groups[joiner_group_index - 1]}"

			local active_modules=$(sed -n "${joiner_group_index}p" $joiner_modules_file)
			local new_active_modules=$active_modules

			[[ ${active_modules: -1} == $short ]] && local end_module=true
			[[ ${active_modules::1} == $short ]] && local start_module=true

			[[ $short == [$active_modules] && ! "${!module}" ]] &&
				new_active_modules="${active_modules/$short}"
			[[ $short != [$active_modules] && "${!module}" ]] &&
				new_active_modules="${joiner_group//[^$active_modules$short]}"

			if [[ ! $2 ]]; then
				[[ $new_active_modules != $active_modules ]] &&
					sed -i "$joiner_group_index s/.*/$new_active_modules/" $joiner_modules_file
			fi

		} 11< $joiner_modules_file

		local joiner_{distance,{frame_,}{start,end},padding,next_bg} cj{f,p,s}fg switch_bg
		read joiner_{distance,padding,frame_{start,end}} switch_bg <<< \
			"${joiners[joiner_group_index - 1]}"

		[[ ($new_active_modules &&
			$new_active_modules != $active_modules &&
			(($short == ${new_active_modules::1} && ! $start_module) ||
			($start_module && $short != ${new_active_modules::1})) ||
			($switch_bg && $short == [${new_active_modules:1:1}${new_active_modules: -1}])) ||
			($short == ${new_active_modules::1} && $updated) ]] &&
				get_joiner_frame ${new_active_modules::1} $switch_bg

		[[ $new_active_modules &&
			${joiner_group: -1} != $last_module ]] &&
			local joiner_separator=$bar_separator

		[[ ($joiner_start && $joiner_end) ||
			(! $new_active_modules && $new_active_modules != $active_modules) ]] &&
			echo "JOINER_${joiner_group_index}_START:$joiner_start" > $fifo &&
			echo "JOINER_${joiner_group_index}_END:$joiner_end$joiner_separator" > $fifo

		if [[ $output_content ]]; then
			local module_distance="%{O$joiner_distance}"

			if [[ ${switch_bg::2} == sb ]]; then
				if [[ $short == ${new_active_modules::1} ]]; then
					unset module_distance
				else
					[[ $short == ${new_active_modules:1:1} ]] &&
						joiner_next_bg+="$module_distance"
				fi
			elif [[ ${switch_bg::2} == eb ]]; then
				if [[ $short == ${new_active_modules: -2:1} ]]; then
					unset module_distance
				else
					[[ $short == ${new_active_modules: -1} ]] &&
						joiner_next_bg+="$module_distance"
				fi
			fi

			[[ $short != ${new_active_modules: -1} ]] &&
				output_content+="$module_distance"

			[[ $joiner_next_bg &&
				(${switch_bg::1} == s && $short == ${new_active_modules:1:1}) ||
				(${switch_bg::1} == e && $short == ${new_active_modules: -1}) ]] &&
				output_content="$joiner_next_bg$output_content"

			[[ (${switch_bg::1} == s &&
				(${switch_bg:1:1} == b && $short == ${new_active_modules::1}) ||
				(${switch_bg:1:1} == f && $short != ${new_active_modules::1})) ||
				(${switch_bg::1} == e &&
				(${switch_bg:1:1} == b && $short != ${new_active_modules: -1}) ||
				(${switch_bg:1:1} == f && $short == ${new_active_modules: -1})) ]] &&
				cjsfg="$jsfg" cjpfg="$jpfg" cjffg="$jffg"

			[[ ${multiframe_modules[*]} == *$module* ]] &&
				local is_multiframe=true

			[[ $joiner_next_bg == *%{O[0-9]*}* ]] &&
				local has_bg_distance=true

			[[ ($cjsfg && $cjpfg) && ! $labeled ]] &&
				eval "output_content=\"$output_content\""
		fi

		local module_index modules_to_reload reload_mode

		if [[ ${switch_bg::2} == eb &&
			((${#new_active_modules} > 2) &&
			$short == ${new_active_modules: -2:1}) ]]; then
				reload_modules -2 reload
		elif [[ ! $2 &&
			(${#new_active_modules} -gt 1 &&
			($switch_bg || $short == ${new_active_modules: -1}) ||
			(${#new_active_modules} -eq 1 &&
			$new_active_modules != $active_modules)) ]]; then
				[[ ${switch_bg::1} == s ]] &&
					modules_to_reload='0 1'

				for module_index in $modules_to_reload -1; do
					reload_modules $module_index #$reload_mode
				done
		else
			if [[ ! ${reloaded_modules[*]} =~ (^| )$short( |$) ]]; then
				eval modules_to_print+=( \"${module^^}:"${output_content//\"/\\\"}"\" )
				reloaded_modules+=( $short )
			fi
		fi

		#[[ $module == date ]] &&
		#	~/.orw/scripts/notify.sh -t 11 "T: $output_content, $active_modules"
		#[[ $module == power ]] &&
		#	~/.orw/scripts/notify.sh -t 11 "P: $output_content, $cjpfg, $cjsfg, $cjffg"

		#[[ $module == rec ]] && ~/.orw/scripts/notify.sh -t 11 "REC: $output_content"

		if [[ ! $2 ]]; then
			for module_to_print in "${modules_to_print[@]}"; do
				echo "$module_to_print" > $fifo
			done
		fi
	else
		[[ $short != $last_module && ${!module} ]] && local separator="$bar_separator"
		[[ ${!module} && $frame_type && ! ${multiframe_modules[*]} =~ $module ]] &&
			output_content="$module_frame_start$output_content$module_frame_end"
		eval echo \"${module^^}:"$output_content$separator"\" > $fifo
	fi
}

set_colors() {
	[[ $colorscheme ]] ||
		colorscheme=~/.config/orw/colorschemes/${1:-auto_generated}.ocs

	color_variables="$(set | awk -F '=' '$1 ~ "[bf][gc]$" { print $1 }' | xargs)"
	unset $color_variables

	eval $(awk '\
		/#bar/ { nr = NR }

		nr && NR > nr && /^[^#]/ {
			if ($1 ~ "^(b?bg|.*c)$") c = $2
			else {
				l = length($1)
				p = substr($1, l - 1, 1)
				c = "%{" toupper(p) $2 "}"
			}

			if ($1) print $1 "=\"" c "\""
		}

		nr && (/^$/) { exit }' $colorscheme)

	[[ $bottom_y ]] && bg=$bbg
	[[ $bar_frame_width ]] && bar_frame="-R$bfc -r $bar_frame_width"
}

set_frame() {
	if [[ $args ]]; then
		arg=${args%%:*}

		case $arg in
			a) 
				side_frame="%{O$frame_size}"
				frame_start="%{+u}%{+o}$side_frame"
				frame_end="$side_frame%{-u}%{-o}"
				frame_type=all
				;;
			*)
				frame_start="%{+$arg}" frame_end="%{-$arg}"
				frame_type=single
		esac

		((frame_size > largest_frame_size)) &&
			largest_frame_size=$frame_size
	else
		unset frame_type {module_,}frame_{start,end}
	fi
}

declare -A shorts joiner_modules

assign_args() {
	if [[ $args ]]; then
		for arg in ${args//,/ }; do
			[[ $arg =~ ':' ]] &&
				value="${arg#*:}" arg="${arg%:*}" ||
				value=""

			assign_${1}_args
		done
	fi
}

assign_joiner_args() {
	case $arg in
		p) joiner_padding="%{O$value}";;
		d) joiner_distance=$value;;
		s) switch_bg=$value;;
	esac
}

assign_x_args() {
	case $arg in
		c)
			[[ $value ]] &&
				center_x=$value || center_x=true
			;;
		r)
			[[ $value ]] &&
				reverse_x=$value || reverse_x=true
			;;
		*) bar_x=$arg
	esac
}

assign_y_args() {
	case $arg in
		b) bottom_y=true;;
		*) bar_y=$arg
	esac
}

assign_font_args() {
	case $arg in
		o) font_offset=$value;;
		*) font_size=$arg
	esac
}

assign_width_args() {
	case $arg in
		a)
			bar_width=$display_width
			width=adjustable
			;;
		*) bar_width=$arg
	esac
}

while getopts :xywhspcrafFSjinemdvtDNPTCVOWARLXBbE opt; do
	args=''
	if [[ ${!OPTIND} != -[[:alpha:]] ]]; then
		args="${!OPTIND}"
		((joiner_start_index)) && ((joiner_start_index--))
		shift 1
	fi

	case $opt in
		a) assign_args font;;
		a) font_size=$args;;
		r) bar_content+='%{r}';;
		c)
			[[ $colorscheme ]] &&
				bar_content+='%{c}' ||
				set_colors $args
			;;
		[xy]) assign_args $opt;;
		w) assign_args width;;
		h) bar_height=$args;;
		s) bar_separator="%{B-}%{O$args}";;
		p) padding="%{O$args}";;
		f)
			frame_size=${args#*:}
			set_frame
			;;
		F) bar_frame_width="$args";;
		n)
			bar_name="$args"

			ls /tmp/${bar_name}*joiner* 2> /dev/null | xargs -r rm

			fifo=$fifo_dir/${bar_name}.fifo
			[[ -e $fifo ]] && rm $fifo
			mkfifo $fifo

			fifos_to_remove=( $fifo )
			;;
		S) screen="$args";;
		O)
			[[ $joiner ]] || bar_content+='%{-u}%{-o}%{B-}'
			bar_content+="%{O$args}"
			;;
		j)
			if [[ $args ]]; then
				joiner=start
				joiner_start_index=$OPTIND
				joiner_group=$(sed "s/-j.*//; s/\( [^-]*\)\?\(-[iOps]\?\|$\)//g" <<< \
					"${@:joiner_start_index}")

				joiner_start="%{B\$${joiner_group::1}sfc}%{U\$${joiner_group::1}fsc}$frame_start"
				joiner_end="%{B\$${joiner_group::1}sfc}$frame_end%{B-}"

				joiner_fc="%{B\$${joiner_group::1}sfc}"
				joiner_sbg="%{B\$${joiner_group::1}sbg}"

				joiner_fc="%{B\$${joiner_group::1}sfc}"
				joiner_sbg="\$${joiner_group::1}sbg"

				assign_args joiner
				[[ $joiner_padding ]] ||
					joiner_padding="$padding"

				joiner_groups+=( "${joiner_group//[- ]}" )
				joiners+=( "$joiner_distance $joiner_padding $frame_start $frame_end $switch_bg" )
				unset switch_bg joiner_{distance,padding,next_bg}

				[[ $joiner_modules_file ]] ||
					joiner_modules_file=/tmp/${bar_name}_joiner_modules
				[[ $joiner_lock_file ]] ||
					joiner_lock_file=/tmp/${bar_name}_joiner.lock
				echo >> $joiner_modules_file

				module_index=0

				while
					joiner_module=${joiner_group:module_index:1}
					[[ $joiner_module ]]
				do
					joiner_modules[$joiner_module]=${#joiner_groups[*]}
					((module_index++))
				done

				joiner_position=start
			else
				unset joiner{,_{group,{start,end}_index,distance,position}}
			fi

			bar_content+="\$joiner_${#joiner_groups[*]}_${joiner_position:-end}"
			;;
		i)
			if [[ $args ]]; then
				icons=$args
			else
				[[ $icons ]] &&
					unset icons ||
					icons=true
			fi
			;;
		C)
			adjust_center=center_width
			bar_content+='%{C}'
			;;
		*)
			get_module $opt
			set_module_colors $opt

			shorts[$module]="$opt"
			make_module

			bar_content+="\$${module}"
			[[ $opt == [LW] ]] &&
				fifos_to_remove+=( $fifo_dir/$module.fifo )

			shorts[$module]="$opt"
			modules+=( $module )
			last_module=$opt
	esac
done

bar_content+='%{B-}'

get_display_properties
set_x

[[ $bar_y ]] ||
	bar_y=$default_y_offset

[[ $bottom_y ]] &&
	bar_y=$((y + display_height - (bar_y + bar_height + 2 * bar_frame_width)))

[[ $width != adjustable && $bar_width -eq 0 ]] &&
	bar_width=$((display_width - 2 * (bar_x - x + bar_frame_width)))

geometry="${bar_width}x${bar_height}+${bar_x}+${bar_y}"

#assign_args power
[[ $bar_content == *power* ]] && make_power_bar_script

#fonts
[[ $font_size ]] || font_size=8
icon_size=$((font_size + font_size / 2))

font="SFMono:style=Medium:size=$font_size"
bold_font="SFMono:style=Heavy:size=$font_size"

font="SFMono:style=Medium:size=$font_size"
bold_font="SFMono:style=Bold:size=$font_size"
font="Iosevka Orw:style=Medium:size=$font_size"
bold_font="Iosevka Orw:style=Heavy:size=$font_size"
icon_font="material:size=$icon_size"
bar_font="SFMono-Medium:size=11"
bar_font="SFMono-Medium:size=$icon_size"
bar_font="SFMono:style=Medium:size=11"

font_offset=${font_offset:--2}

remove_fifos() {
	local fifo
	for fifo in ${fifos_to_remove[*]}; do
		[[ -e $fifo ]] && rm $fifo
	done
}

trap self_kill INT
trap remove_fifos INT EXIT KILL TERM

run_modules() {
	[[ $running_modules ]] && kill $running_modules
	running_modules=''

	for module in ${modules[*]}; do
		set_module_colors ${shorts[$module]}
		if [[ ! $module =~ windows|tiling ]]; then
			check_$module > $fifo &
			running_modules+="$! "
		fi
	done
}

bar_options='(A([0-9]?:?.*:$|$)|[BFU][#-]|[TO][0-9-]+$|[lcr]$|[+-][ou])'

adjust_bar_width() {
	while read content; do
		if [[ $width == adjustable ]]; then

			old_width=$content_width
			read content_width $adjust_center <<< \
				$(awk -F '%{|}' '
					{
						fs = sprintf("%.0f", '$font_size' / 1.4)
						is = sprintf("%.0f", '$icon_size' * 1.8)
						is = sprintf("%.0f", '$icon_size' * 1.3)

						for(f = 1; f < NF; f++) {
							if($f ~ /O[0-9]+$/) {
								co = substr($f, 2)
								if (c) cl += co
								o += co
							}
							else if($f == "C") {
								if (c) cl = int(l - cl / 2 + o)
								c = !c
							} else if($f !~ /^'$bar_options'/) {
								if ($f ~ "^I[0-9-]?$") i = !i
								else {
									ml = length($f) * ((i) ? is : ($f ~ "━") ? 9 : fs)
									if (c) cl += ml
									l += ml
								}
							}
						}
					} END { print int(o + l), cl }' <<< "$content")

			if ((old_width != content_width)); then
				unset bar_x
				set_x $content_width
				xdotool search --name "^$bar_name$" \
					windowsize $content_width $bar_height \
					windowmove $bar_x $bar_y
			fi
		fi

		echo -e "$content"
	done
}

waiting_icon=$(get_icon 'waiting_icon')
run_modules

main_pid=$$

while IFS=':' read module content; do
	eval ${module,,}=\""$content"\"
	#[[ ${module,,} == rec ]] && eval echo "${module,,}=\""$content"\"" >> ~/bar.log
	#(($?)) && eval echo "${module,,}: "$content"" >> ~/bar.log
	#eval echo -e \""$bar_content"\" >> b.log
	eval echo -e \""$bar_content"\"
done < $fifo | adjust_bar_width |
	lemonbar -d -B$bg -F$fg -u 0 \
	-f "$font" -o $font_offset \
	-f "$bold_font" -o $font_offset \
	-f "$bar_font" -o $((font_offset + 1)) \
	-f "$icon_font" -o $((font_offset + 0)) \
	-a 150 -u ${largest_frame_size:-0} $bar_frame \
	-g "$geometry" -n "$bar_name" | bash &

sleep 0.5
xdo lower -N Bar

wait
