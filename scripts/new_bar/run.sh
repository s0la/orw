#!/bin/bash

pid=$$

get_display_properties() {
	[[ ! $x && ! $y ]] &&
		#read x y vertical_x vertical_y display_width display_height <<< \
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
	elif ((bar_x)); then
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
						bar_x=$((x + ((display_width - bar_width) / 2))) ||
						bar_x=$((x + display_width / 2 - reverse_offset - bar_width))
				fi
			fi

			if ((!bar_x)); then
				[[ ! $reverse_x ]] &&
					bar_x=$((x + default_x_offset)) ||
					bar_x=$((x + display_width - ${reverse_offset:-$default_x_offset} - bar_width))
			fi
		else
			bar_x=$default_x_offset
		fi
	fi
}

#set_x() {
#	if ((bar_x)); then
#		((bar_x+=x))
#	else
#		if ((bar_width)); then
#			if [[ $center_x ]]; then
#				if [[ $center_x == true ]]; then
#					bar_x=$((x + ((display_width - bar_width) / 2)))
#				else
#					bar_x=$((x + display_width / 2 + center_x))
#					[[ $reverse_x ]] &&
#						((bar_x -= reverse_x + bar_width))
#				fi
#			elif [[ $reverse_x ]]; then
#				[[ $reverse_x == *[0-9] ]] &&
#					local reverse_offset=$reverse_x ||
#					local reverse_offset=$default_x_offset
#
#				bar_x=$((x + display_width - reverse_offset - bar_width))
#			fi
#		else
#			bar_x=$((x + default_x_offset))
#		fi
#	fi
#}

get_icon() {
	local icon="$1"
	#sed -n "s/$icon[^}]*.\([^%]*\).*/\\$group/p" $icons_file
	sed -n "s/^[^#]*$icon[^%]*//p" $icons_file
}

singles=( rec tiling power )
multiframe_modules=( workspaces windows launchers )
labeled_modules=( rss emails volume counter vanter torrents network power display rec )

set_module_colors() {
	local module_short=$1
	eval ${module_short}fc="\${${module_short}fc:-\$fc}"
	eval ${module_short}pbg="\${${module_short}pbg:-\$pbg}"
	eval ${module_short}sbg="\${${module_short}sbg:-\$sbg}"
	eval ${module_short}pfg="\${${module_short}pfg:-\$pfg}"
	eval ${module_short}sfg="\${${module_short}sfg:-\$sfg}"
}

set_module_colors() {
	local module_short=$1
	eval ${module_short}fc="\${${module_short}fc:-\$fc}"
	eval ${module_short}pbg="\${${module_short}pbg:-\$pbg}"
	eval ${module_short}sbg="\${${module_short}sbg:-\$sbg}"
	eval ${module_short}pfg="\${${module_short}pfg:-\$pfg}"
	eval ${module_short}sfg="\${${module_short}sfg:-\$sfg}"
	#eval ${module_short}pfg="\${cjpfg:-\${${module_short}pfg:-\$pfg}}"
	#eval ${module_short}sfg="\${cjsfg:-\${${module_short}sfg:-\$sfg}}"
}

set_module_colors() {
	local module_short=$1
	eval ${module_short}pfc="\${${module_short}pfc:-\$pfc}"
	eval ${module_short}sfc="\${${module_short}sfc:-\$sfc}"
	eval ${module_short}pbg="\${${module_short}pbg:-\$pbg}"
	eval ${module_short}sbg="\${${module_short}sbg:-\$sbg}"
	eval ${module_short}pfg="\${${module_short}pfg:-\$pfg}"
	eval ${module_short}sfg="\${${module_short}sfg:-\$sfg}"
	#eval ${module_short}pfg="\${cjpfg:-\${${module_short}pfg:-\$pfg}}"
	#eval ${module_short}sfg="\${cjsfg:-\${${module_short}sfg:-\$sfg}}"
}

set_module_frame() {
	local short_module=$1 frame_type=${2:-$frame_type}
	local frame_mode="\${${short_module}pfc:-\$${short_module}sfc}"

	#if [[ $frame_type == all ]]; then
	#	module_frame_start="%{B\$${short_module}fc}%{U\$${short_module}fc}$frame_start"
	#	module_frame_end="%{B\$${short_module}fc}$frame_end%{B-}"
	#else
	#	module_frame_start="%{U\$${short_module}fc}$frame_start"
	#	module_frame_end="$frame_end%{B-}"
	#fi

	if [[ $frame_type == all ]]; then
		module_frame_start="%{B\$${short_module}sfc}%{U\$${short_module}sfc}$frame_start"
		module_active_frame_start="%{B\$${short_module}pfc}%{U\$${short_module}pfc}$frame_start"
		module_frame_end="%{B\$${short_module}sfc}$frame_end%{B-}"
	else
		module_frame_start="%{U\$${short_module}sfc}$frame_start"
		module_active_frame_start="%{U\$${short_module}pfc}$frame_start"
		module_frame_end="$frame_end%{B-}"
	fi

	#if [[ $frame_type == all ]]; then
	#	module_frame_start="%{B$frame_mode}%{U$frame_mode}$frame_start"
	#	module_frame_end="%{B$frame_mode}$frame_end%{B-}"
	#else
	#	module_frame_start="%{U$frame_mode}$frame_start"
	#	module_frame_end="$frame_end%{B-}"
	#fi

	#[[ $short_module == L ]] &&
	#	~/.orw/scripts/notify.sh "$frame_type: $module_frame_start, $module_frame_end"
}

self_kill() {
	[[ -p $fifo ]] && rm $fifo
	kill $pid &> /dev/null
	killall run.sh lemonbar
}

update_colors() {
	local all_pids=$(ps -C run.sh -o pid=,args= | awk '/"'"$bar_name"'"/ { print $1 }')
	~/.orw/scripts/notify.sh -t 5 "SIG RELOAD: $all_pids"

	bash ~/.config/orw/bar/configs/$bar_name

	kill "$all_pids"
	return

	set_colors

	#~/.orw/scripts/notify.sh -t 5 "SIG RELOAD"

	#ps -C ${0##*/} --sort=start_time -o pid= | sed '1d' | xargs kill
	#ps -C ${0##*/} --sort=start_time -o pid= | grep -v $main_pid | xargs kill
	ps -C ${0##*/} -o pid=,ppid= |
		awk '$2 == "'"$main_pid"'" { print $1 }' | xargs kill

	local updated=true
	run_modules
}

update_colors() {
	local all_pids=$(ps -C run.sh -o pid=,args= | awk '/'"$bar_name"'/ { print $1 }' | xargs)
	#local lemonbar_pid=$(ps -C run.sh -o pid=,args= | awk '/'"$bar_name"'/ { print $1 }')
	#~/.orw/scripts/notify.sh -t 5 "SIG RELOAD: $all_pids"

	bash ~/.config/orw/bar/configs/$bar_name &

	#echo "$lemonbar_pid $all_pids" >> kill.log
	kill $lemonbar_pid $all_pids
	return

	set_colors

	#~/.orw/scripts/notify.sh -t 5 "SIG RELOAD"
	echo UPDATE

	ps -C ${0##*/} -o pid=,ppid= |
		awk '$2 == "'"$main_pid"'" { print $1 }' | xargs kill

	local updated=true
	run_modules #reload
}

#files/dirs
loading_icon=''
root_dir="${0%/*}"
icons_file=$root_dir/icons
bar_config=$root_dir/config
modules_dir=$root_dir/modules
colorscheme_dir=~/.orw/dotfiles/config/orw/colorschemes
#echo $root_dir, $fifo, $bar_name
#exit

#joiner_modules=/tmp/${bar_name}_joiner_modules
#active_joiner_modules=/tmp/active_joiner_modules
#missing_joiner_modules=/tmp/missing_joiner_modules
#joiner_start_modules=/tmp/joiner_start_modules
#joiner_end_modules=/tmp/joiner_end_modules

#ls /tmp/*joiner* | xargs -r rm
#for joiner_file in /tmp/*joiner*; do
#	[[ -f $joiner_file ]] && rm $joiner_file
#done

#[[ -f $active_joiner_modules ]] && rm $active_joiner_modules
#[[ -f $missing_joiner_modules ]] && rm $missing_joiner_modules


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
	esac
}

bar_separator='%{B-}%{O10}'
padding='%{O20}'
inner='%{O3}'

make_module() {
	local module_file=$modules_dir/${module}.sh
	local full_module module_frame_{start,end} {p,s}bg mf{s,e} single_color_type

	if [[ ! ${joiner_modules[$opt]} ]]; then
	#	single_color_type=s
	#else
	#	single_color_type=p
		set_module_frame $opt
		mfs="$module_frame_start" mfe="$module_frame_end"
		pbg="\$${opt}pbg" sbg="\$${opt}sbg"
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

	#[[ $module == power ]] &&
	#	~/.orw/scripts/notify.sh -t 11 "$module, $label, $full_module"

	if [[ ! $full_module ]]; then
		#[[ ${joiner_modules[$opt]} ]] && local padding

		#[[ ${joiner_modules[$opt]} ]] ||
		#eval ${module}_padding=$padding

		#[[ $module == network ]] &&
		#~/.orw/scripts/notify.sh -t 11 "$module: $network_padding, $full_module"

		#if [[ ! $label || ($label && $icons == only) ]]; then
		if [[ ! $label || (${singles[*]} == *$module* || $icons == only) ]]; then
			[[ $label ]] &&
				local single_content=$label || local single_content="\$$module"
			#full_module="$pbg\$${opt}pfg$padding%{T2}$single_content$padding"

			#[[ $icons != only ]] &&
			#	local single_fg="\$${opt}sfg" ||
			#	local single_fg="\${cjpfg:-\$${opt}pfg}"

			[[ ${singles[*]} == *$module* ]] &&
				single_color_type=s || single_color_type=s
			local single_fg="\${cj${single_color_type}fg:-\$${opt}${single_color_type}fg}"
			#local single_fg="\${cjpfg:-\${cjsfg:-\$${opt}sfg}}"

			#[[ $module == power ]] &&
			#	~/.orw/scripts/notify.sh -t 11 "$module: $single_fg, $cjsfg, $Psfg"
			##	~/.orw/scripts/notify.sh -t 11 "$module: $mfs, $pbg, $single_fg, $Psfg, $mpbg"

			#full_module="$pbg\${cjpfg:-\$${opt}pfg}$padding%{T2}$single_content$padding"
			full_module="$pbg$single_fg\$${module}_padding%{T2}"
			full_module+="$single_content\$${module}_padding"
		else
			#full_module="$sbg\$${opt}sfg$padding%{T2}$label$inner"
			#full_module+="$pbg\$${opt}pfg$inner%{T2}\$$module$padding"
			full_module="$sbg\${cjsfg:-\$${opt}sfg}\$${module}_padding%{T2}$label$inner"
			full_module+="$pbg\${cjpfg:-\$${opt}pfg}$inner%{T2}\$$module\$${module}_padding"
		fi

		#~/.orw/scripts/notify.sh -t 11 "$module: $full_module"

		full_module="\$mfs${full_module//\$/\\\$}\$mfe"
	fi

	eval ${module}_content="$full_module"

	#[[ $module == power ]] &&
	#	~/.orw/scripts/notify.sh -t 11 "$power_content"

	#if [[ $module == launchers ]]; then
	#	load_launchers
	#	get_launchers
	#	eval echo $launchers_content
	#	exit
	#	~/.orw/scripts/notify.sh "HERE $launchers_frame_start"
	#	return
	#	echo $Lpbg, $Lpfg, $Lsbg, $Lsfg
	#	echo Ls:
	#	echo $launchers_content
	#	load_launchers
	#	get_launchers
	#	echo $launchers
	#	print_module launchers
	#	exit
	#	IFS=':' read m l <<< $(print_module launchers)
	#	eval echo "$l"
	#	exit
	#fi
}

get_joiner_frame() {
	#local module="$1" switch_bg="$2"
	#local joiner_sbg="\$${module}sbg"
	#local joiner_fc="%{B\$${module}fc}"

	#joiner_start="$joiner_fc%{U\$${module}fc}$joiner_frame_start"
	#joiner_end="%{B\$${module}fc}$joiner_frame_end%{B-}"

	local module="$1" switch_bg="$2"
	local joiner_sbg="\$${module}sbg"
	local frame_mode="\${${module}sfc:-\$${module}pfc}"
	local joiner_fc="%{B$frame_mode}"
	#local joiner_fc="%{B\$${module}fc}"

	joiner_start="$joiner_fc%{U$frame_mode}$joiner_frame_start"
	joiner_end="%{B$frame_mode}$joiner_frame_end%{B-}"

	#if [[ $switch_bg == s ]]; then
	#	joiner_next_bg="$joiner_sbg%{B-}"
	#else
	#	#~/.orw/scripts/notify.sh "HERE $switch_bg, $module"
	#	[[ $switch_bg ]] &&
	#		joiner_next_bg="$joiner_fc"
	#	joiner_start+="$joiner_sbg"
	#fi

	#if [[ $switch_bg ]]; then
	#	((${#switch_bg} > 1)) &&
	#		local bg_distance="%{O${switch_bg:1}}"

	#	[[ $switch_bg == e* ]] &&
	#		joiner_next_bg="$bg_distance$joiner_fc" ||
	#		joiner_next_bg="$joiner_sbg$bg_distance"
	#fi

	#[[ $joiner_padding ]] &&
	#	local joiner_padding="%{O$joiner_padding}"

	if [[ $switch_bg ]]; then
		((${#new_active_modules} > 0 && ${#switch_bg} > 2)) &&
			local bg_distance="%{O${switch_bg:2}}"

		#[[ $switch_bg == e* ]] &&
		[[ ${switch_bg:1:1} == f ]] &&
			joiner_next_bg="$bg_distance$joiner_fc$joiner_padding" ||
			joiner_next_bg="$joiner_padding$joiner_sbg$bg_distance"
			#joiner_next_bg="$bg_distance$joiner_fc" ||
			#joiner_next_bg="$joiner_sbg$bg_distance"

			#joiner_next_bg="$bg_distance$joiner_fc\$${module}_padding" ||
			#joiner_next_bg="\$${module}_padding$joiner_sbg$bg_distance"
	fi

	#~/.orw/scripts/notify.sh "HERE $module, $switch_bg, $joiner_next_bg"

	[[ ${switch_bg:1:1} == b ]] ||
		joiner_start+="$joiner_sbg"

	joiner_start+="$joiner_padding"
	joiner_end="$joiner_padding$joiner_end"
	#[[ $module == time ]] &&
	#~/.orw/scripts/notify.sh "HERE $module, $joiner_start, $joiner_end"

}

print_module() {
	local module=$1 action=$2 module_to_reset=$3 reset update_{before,after}_print
	local content=${1}_content output_content short=${shorts[$1]}
	local module_actions_start=${module}_actions_start
	local module_actions_end=${module}_actions_end

	[[ ${!module} ]] &&
		output_content="${!module_actions_start}${!content//%\{O+([0-9])\}}${!module_actions_end}"
		#output_content="$actions_start${!content//%\{O+([0-9])\}}$actions_end"
		#output_content="${module}_actions_start${!content//%\{O+([0-9])\}}${module}_actions_end"

	#[[ ${joiner_modules[$short]} ]] ||
	#	~/.orw/scripts/notify.sh "HERE $module, $short"
	if [[ ${joiner_modules[$short]} ]]; then
		local joiner_group_index=${joiner_modules[$short]}
		local joiner_group="${joiner_groups[joiner_group_index - 1]}"
		local active_modules=$(sed -n "${joiner_group_index}p" $active_joiner_modules)
		local missing_modules=$(sed -n "${joiner_group_index}p" $missing_joiner_modules)

		#echo "ACTIVE: $@ ^$active_modules^ $(date +'%M:%S')" >> join.log

		[[ ${active_modules: -1} == $short ]] && local end_module=true
		[[ ${active_modules::1} == $short ]] && local start_module=true

		#[[ $start_module && $end_module ]] &&
		#	~/.orw/scripts/notify.sh -t 8 "SINGLE $module: ^$active_modules^, $short"
			#~/.orw/scripts/notify.sh -t 8 "SINGLE $module: $3, $4"

		if [[ $short == [$active_modules] && ! ${!module:-$action} ]]; then
			missing_modules+="$short"
			local update_active=true

			[[ $start_module ]] &&
				local update_after_print="${active_modules:1:1}"
			[[ $end_module ]] &&
				local update_after_print="${active_modules: -2:1}"

			#[[ $update_after_print ]] &&
			#~/.orw/scripts/notify.sh -t 8 "$short ACTive: $active_modules"
		elif [[ $short == [$missing_modules] && (${!module} || $2 == reload) ]]; then
			missing_modules="${missing_modules/$short}"
			local update_active=true
		fi

		#if [[ $3 ]]; then
		#	local line=${3::1} joiner_file="joiner_${3:1}_modules"
		#	local module_{value,actions_{start,end}}
		#	IFS=';' read module_{value,actions_{start,end}} <<< \
		#		$(sed -n "${line}p" ${!joiner_file})

		#	eval $value=\""$module_value"\"
		#	local output_content="$module_actions_start${!content}$module_actions_end"
		#	#~/.orw/scripts/notify.sh "IN $module"
		#fi

		if [[ $action == reload ]]; then
			#~/.orw/scripts/notify.sh "getting $module.."
			local label icon module_action_{start,end}
			get_$module

			[[ ${!module} ]] &&
			local output_content="$module_actions_start${!content}$module_actions_end"
			#[[ $mdoule == vanter ]] &&
		fi

		if [[ $update_active ]]; then
			active_modules="${joiner_group//[${missing_modules// }]}"

			sed -i "${joiner_group_index} s/.*/$active_modules/" $active_joiner_modules
			sed -i "${joiner_group_index} s/.*/$missing_modules/" $missing_joiner_modules

			[[ (${active_modules: -1} == $short && ! $end_module) ]] &&
				local update_before_print="${active_modules: -2:1}"
			[[ ${active_modules::1} == $short && ! $start_module ]] &&
				local update_before_print="${active_modules:1:1}"
		fi

		#[[ $module == counter ]] &&
		#	echo "CNT $update_active:$update_before_print ^$active_modules^,$short,$module: ${!module}" >> join.log
			
		local joiner_{distance,{frame_,}{start,end},next_bg} switch_bg
		#read joiner_{distance,start,end,next_bg} switch_bg <<< "${joiners[joiner_group_index - 1]}"
		read joiner_{distance,frame_{start,end}} switch_bg <<< "${joiners[joiner_group_index - 1]}"
		get_joiner_frame ${active_modules::1} $switch_bg

		[[ $joiner_group_index < ${#joiner_groups[*]} ]] &&
			local joiner_end="$joiner_end$bar_separator"

		if [[ $output_content ]]; then
			#echo "HERE ^$active_modules^ ^$short^" >> join.log
			#[[ $module == rss ]] &&
			#	~/.orw/scripts/notify.sh -t 11 "RSS: $output_content"

			case $short in
				$active_modules) output_content="$joiner_start$output_content$joiner_end";;
					#echo "WHOLE $module, $joiner_start, $joiner_end, $joiner_content" >> join.log
					#;;
				${active_modules::1})
					#[[ ! $start_module ]] && update_before_print="${active_modules: -1}"
					#if [[ ! $start_module ]]; then
					#	update_before_print="${active_modules: -1}"
					#	~/.orw/scripts/notify.sh "ubp: $update_before_print"
					#fi

					#[[ $update_before_print || $update_after_print ]] &&
					#	local update_opposite_end="${active_modules: -1}"
					#~/.orw/scripts/notify.sh "uoe: $module, $update_opposite_end"
					[[ $update_before_print ]] &&
						local opposite_end="${active_modules: -1}"
					output_content="$joiner_start$output_content%{O$joiner_distance}"
					;;
				${active_modules: -1})
					#[[ ! $end_module ]] && update_before_print="${module::1}"
					#[[ $update_before_print || $update_after_print ]] &&
					#	local update_opposite_end="${active_modules::1}"
					#~/.orw/scripts/notify.sh "uoe: $module, $update_opposite_end"
					[[ $update_before_print ]] &&
						local opposite_end="${active_modules::1}"
					output_content+="$joiner_end"
					;;
				*) output_content+="%{O$joiner_distance}"
			esac

			if [[ ${active_modules:1:1} == $short ]]; then
				[[ $joiner_next_bg ]] && output_content="$joiner_next_bg$output_content"
			fi
		elif [[ ! $module_to_reset ]]; then
			[[ $start_module ]] && local output_content="$joiner_start" reset=$module
			[[ $end_module ]] && local output_content="$joiner_end" reset=$module
			#[[ $module == counter ]] &&
			#~/.orw/scripts/notify.sh -t 8 "MISSING $module: ^$active_modules^, $start_module, $end_module"
			#[[ $reset ]] &&
			#	~/.orw/scripts/notify.sh -t 2 "${module^^} is going.." &&
			#	sleep 2 &&
			#	~/.orw/scripts/notify.sh -t 1 "continuing $update_after_print"
		fi

		unset {start,end}_module

		if [[ $update_after_print ]]; then
			case $update_after_print in
				${active_modules::1}) local opposite_end=${active_modules: -1};;
				${active_modules: -1}) local opposite_end=${active_modules::1};;
			esac

			#~/.orw/scripts/notify.sh "upd: $update_after_print, $opposite_end, $active_modules"
			#echo "upd: $update_after_print, $opposite_end, $active_modules" >> jn.log
		fi

		#if [[ $update_before_print || $update_after_print ]]; then
		#	[[ $short == "${active_modules: -1}" ]] &&
		#		local update_opposite_end="${active_modules::1}"
		#	[[ $short == "${active_modules::1}" ]] &&
		#		local update_opposite_end="${active_modules: -1}"

		#	~/.orw/scripts/notify.sh "uoe: $module, ${active_modules: -1}, ${active_modules::1}, $short, $update_opposite_end"

		#	if [[ $update_opposite_end ]]; then
		#		get_module $update_opposite_end
		#		unset update_opposite_end
		#		print_module $module #"reload"
		#	fi
		#fi

		#if [[ $update_active || ${!value:-$3} ]]; then
		if [[ $update_active || ${output_content} || $action == reset ]]; then
			unset update_active
			local printing_module="$module"

			#if [[ $update_opposite_end ]]; then
			#	#local opposite_end_module=$update_oppos
			#	get_module $update_opposite_end
			#	unset update_opposite_end
			#	print_module $module "reload"
			#fi

			#[[ $action == reset ]] &&
			#	~/.orw/scripts/notify.sh "RESET $module"

			if [[ $update_before_print ]]; then
				#local joiner_file=$update_before_print
				local update_module_short=$update_before_print
				unset update_before_print

				#if [[ $module_to_reset ]]; then
				#	local update_module_short=${shorts[$module_to_reset]}
				#	unset module_to_reset update_after_print
				#	#~/.orw/scripts/notify.sh -t 8 "MAIN $module, $update_module_short"
				#	get_module $update_module_short
				#	echo "BEFORE $active_modules, $module: $printing_module, $output_content" >> join.log
				#	print_module $module "reset"
				#	echo "AFTER $active_modules, $module: $printing_module, $output_content" >> join.log
				#else
				#	[[ $joiner_file == *start ]] &&
				#		local update_module_short=${active_modules:1:1} ||
				#		local update_module_short=${active_modules: -2:1}
				#		get_module $update_module_short
				#		echo "before $active_modules, $module: $printing_module" >> join.log
				#		print_module $module "reload" $reset
				#fi

				#[[ $joiner_file == *start ]] &&
				#	local update_module_short=${active_modules:1:1} ||
				#	local update_module_short=${active_modules: -2:1}

				get_module $update_module_short
				#~/.orw/scripts/notify.sh "BEFORE"
				print_module $module "reload"
				#print_module $module "" "$((joiner_group_index * 2))$joiner_file" $reset

				#[[ $module_to_reset ]] &&
				#~/.orw/scripts/notify.sh "MODULE_TO_RESET: $module, $module_to_reset"
			fi

			if [[ $opposite_end ]]; then
				#~/.orw/scripts/notify.sh -t 8 "$module: $output_content, $action: $update_after_print, $update_before_print, $opposite_end"
				get_module $opposite_end
				#echo "OE: $printing_module > $module: $output_content, $action: $update_after_print, $update_before_print, $opposite_end" >> jn.log
				unset opposite_end
				print_module $module "reload"
			fi

			#[[ $printing_module =~ rss|counter ]] &&
			#	~/.orw/scripts/notify.sh -t 8 "PRINT $module: $output_content"

			#echo "PRINT: $action $printing_module, $output_content" >> jn.log

			eval echo \"${printing_module^^}:"$output_content$module_separator"\"

			#[[ $printing_module =~ rss|counter ]] &&
			#echo "PRINT: $printing_module: $output_content" >> join.log
			#[[ $module =~ vanter|counter ]] &&
			#[[ $printing_module =~ rss|counter ]] &&
			#	~/.orw/scripts/notify.sh -t 8 "PRINT $module: $output_content"
			#print_content "$printing_module"

			if [[ $update_after_print || $module_to_reset ]]; then
				#~/.orw/scripts/notify.sh "$module: $update_after_print"
				#sleep 5
				#local update_module_short=$update_after_print
				#unset update_after_print

				if [[ $module_to_reset ]]; then
					#local update_module_short=${shorts[$module_to_reset]}
					#unset module_to_reset update_before_print
					#~/.orw/scripts/notify.sh -t 8 "MAIN $module, $update_module_short"
					get_module ${shorts[$module_to_reset]}
					unset module_to_reset
					#echo "BEFORE $active_modules, $module: $printing_module, $output_content" >> join.log
					print_module $module "reset"
					#echo "AFTER $active_modules, $module: $printing_module, $output_content" >> join.log
				else
					#[[ $joiner_file == *start ]] &&
					#	local update_module_short=${active_modules::1} ||
					#	local update_module_short=${active_modules: -1}

					get_module $update_after_print
					#echo "before $active_modules, $module: $printing_module" >> join.log
					#~/.orw/scripts/notify.sh "AFTER $update_after_print"
					print_module $module "reload" $reset
				fi

				#[[ $joiner_file == *start ]] &&
				#	local update_module_short=${active_modules::1} ||
				#	local update_module_short=${active_modules: -1}

				#get_module $update_module_short
				#echo "after: $printing_module, $module" >> join.log
				#print_module $module "reload" $reset
			fi
		fi
	else
		[[ ${!module} && $frame_type && ! ${multiframe_modules[*]} =~ $module ]] &&
			output_content="$module_frame_start$output_content$module_frame_end"
		[[ $short != $last_module ]] && local separator=$bar_separator
		eval echo \"${module^^}:"$output_content$separator"\"
	fi

	#echo "DONE" >> jn.log
	#sleep 25
}

print_module() {
	local module=$1 content=${1}_content short=${shorts[$1]}
	local output_content new_active_modules

	[[ ${!module} ]] &&
		output_content="$actions_start${!content}$actions_end"

	if [[ ${joiner_modules[$short]} ]]; then
		local joiner_group_index=${joiner_modules[$short]}
		local joiner_group="${joiner_groups[joiner_group_index - 1]}"
		local active_modules=$(sed -n "${joiner_group_index}p" $joiner_modules)
		local new_active_modules=$active_modules

		[[ ${active_modules: -1} == $short ]] && local end_module=true
		[[ ${active_modules::1} == $short ]] && local start_module=true

		[[ $short == [$active_modules] && ! ${!module} ]] &&
			new_active_modules="${active_modules/$short}"
		[[ $short != [$active_modules] && ${!module} ]] &&
			new_active_modules="${joiner_group//[^$active_modules$short]}"

		#[[ $new_active_modules ]] &&
		#	~/.orw/scripts/notify.sh "NEW: $module, $active_moudles, $joiner_group, $new_active_modules"

		#[[ $new_active_modules ]] &&
		#	echo "NEW: $module, $active_modules, $joiner_group, $new_active_modules" >> log

		#[[ ${new_active_modules:-$active_modules} != $active_modules ]] &&
		#[[ $new_active_modules && $new_active_modules != $active_modules ]] &&
		[[ $new_active_modules != $active_modules ]] &&
			#active_modules=$new_active_modules &&
			sed -i "$joiner_group_index s/.*/$new_active_modules/" $joiner_modules

		local joiner_{distance,{frame_,}{start,end},next_bg} switch_bg cj{p,s}fg
		read joiner_{distance,frame_{start,end}} switch_bg <<< "${joiners[joiner_group_index - 1]}"

		#[[ $2 ]] && echo "PRE $module $joiner_next_bg: ^$new_active_modules^, ^$active_modules^" >> bar.log
		#[[ $2 && $new_active_modules != $active_modules ]] && echo "DIFF" >> bar.log

		#[[ ($new_active_modules &&
		[[ $new_active_modules != $active_modules &&
			(($short == ${new_active_modules::1} && ! $start_module) ||
			#($start_module && $short != ${new_active_modules::1})) ]] &&
			($start_module && $short != ${new_active_modules::1})) ||
			($switch_bg && $short == ${new_active_modules:1:1}) ]] &&
				get_joiner_frame ${new_active_modules::1} $switch_bg

		#[[ $2 ]] && echo "POST $joiner_next_bg: $new_active_modules, $active_modules" >> bar.log

		#[[ $joiner_start && $joiner_end ]] &&
		#[[ ${new_active_modules:-$active_modules} != $active_modules ]] &&
		#[[ $new_active_modules && $new_active_modules != $active_modules ]] &&
		[[ ($joiner_start && $joiner_end) ||
			(! $new_active_modules && $new_active_modules != $active_modules) ]] &&
			#local shr="${joiner_next_bg:1:4}" &&
			#echo "JOINERS: $module > $new_active_modules, $joiner_next_bg, $joiner_start, $joiner_end" >> bar.log &&
			echo "JOINER_${joiner_group_index}_START:$joiner_start" > $fifo &&
			echo "JOINER_${joiner_group_index}_END:$joiner_end" > $fifo

		if [[ $output_content ]]; then
			#output_content="${output_content//%\{O+([0-9])\}}"
			[[ $short != ${new_active_modules: -1} ]] &&
				output_content+="%{O$joiner_distance}"

			[[ ${new_active_modules:1:1} == $short && $joiner_next_bg ]] &&
				output_content="$joiner_next_bg$output_content"

			eval "out=\"$output_content\""
			~/.orw/scripts/notify.sh -t 11 "$module: $out"

			#[[ $2 && ${new_active_modules:1:1} == $short && $joiner_next_bg ]] &&
			#	echo "RELOADED $module: $output_content" >> bar.log

			#[[ $2 && ${new_active_modules:1:1} == $short && $joiner_next_bg ]] &&
			#	~/.orw/scripts/notify.sh -t 11 "HERE $module, $new_active_modules, $joiner_next_bg, $output_content"

			#~/.orw/scripts/notify.sh "HERE $module, $switch_bg, $joiner_next_bg"

			#if [[ ${new_active_modules:1:1} == $short && $joiner_next_bg ]]; then
			#	output_content="$joiner_next_bg$output_content"
			#	#~/.orw/scripts/notify.sh "HERE $module, $switch_bg, $joiner_next_bg"
			#fi
		fi

		#[[ $module == counter ]] &&
		#	~/.orw/scripts/notify.sh -t 11 "COUNTER, $short, $active_modules, $new_active_modules, $switch_bg"

		if [[ $new_active_modules != $active_modules &&
			($short == [${new_active_modules::2}] || $short == [${active_modules::2}]) &&
			$switch_bg && ${#new_active_modules} -gt 1 ]]; then
				local current_module=$module current_output=$output_content
				local current_label=$label current_icon=$icon
				local current_module_action_end=$module_action_end
				local current_module_action_start=$module_action_start

		#if [[ $new_active_modules != $active_modules &&
		#	#($short == ${new_active_modules::1} || $short == ${active_modules::1} ||
		#	#($short == ${active_modules:1:1} && $short != [$new_active_modules])) &&
		#	($short == [${new_active_modules::2}] || $short == [${active_modules::2}]) ||
		#	$switch_bg && ${#new_active_modules} -gt 1 ]]; then
		#	#$switch_bg && ${#new_active_modules} -gt 1 ]]; then
		#		local current_module=$module current_output=$output_content

				#if [[ $short == ${new_active_modules::1} ||
				#	($short == ${new_active_modules:1:1} && $short != [$active_modules]) ]]; then
				#	get_module ${new_active_modules:2:1}
				#	#~/.orw/scripts/notify.sh "RELOADING $new_active_modules: $module, $current_module"
				#	local $module
				#	get_$module
				#	print_module $module
				#else
				#	get_module ${new_active_modules::1}
				#	local $module
				#	get_$module
				#	print_module $module
				#fi

				##if [[ $short == ${active_modules::1} || $short == ${new_active_modules::1} ]]; then
				#get_module ${new_active_modules:1:1}
				#local $module
				#get_$module
				#[[ ${!module} ]] && print_module $module reload

				#if [[ $short == ${new_active_modules::1} ||
				#	($short == ${new_active_modules:1:1} && $short != [$active_modules]) ]]; then
				#	get_module ${new_active_modules:2:1}
				#	#~/.orw/scripts/notify.sh "RELOADING $new_active_modules: $module, $current_module"
				#	#~/.orw/scripts/notify.sh "RELOADING $module, $current_module, $main_module"
				#	local $module #third=true
				#	get_$module
				#	[[ ${!module} ]] && print_module $module
				#	#~/.orw/scripts/notify.sh "RELOADED $module, $current_module, $main_module"
				#else
				#	get_module ${new_active_modules::1}
				#	local $module
				#	get_$module
				#	[[ ${!module} ]] && print_module $module
				#fi





				#get_module ${new_active_modules:1:1}
				#local $module
				#get_$module
				#[[ ${!module} ]] && print_module $module reload

				#[[ $short == ${new_active_modules::1} ||
				#	($short == ${new_active_modules:1:1} && $short != [$active_modules]) ]] &&
				#	get_module ${new_active_modules:2:1} || get_module ${new_active_modules::1}

				#local $module
				#get_$module
				#[[ ${!module} ]] && print_module $module

				if [[ $short == ${new_active_modules::1} ||
					($short == ${new_active_modules:1:1} && $short != [$active_modules]) ]]; then
					get_module ${new_active_modules:2:1}

					local $module third=true
					get_$module
					[[ ${!module} ]] && print_module $module
				fi

				get_module ${new_active_modules:1:1}
				local $module
				get_$module
				[[ ${!module} ]] && print_module $module reload

				if [[ $third ]]; then
					get_module ${new_active_modules::1}

					local $module
					get_$module
					[[ ${!module} ]] && print_module $module
				fi
				#~/.orw/scripts/notify.sh "RELOADED $current_module, $module"




				#if [[ $short == ${new_active_modules::1} ||
				#	($short == ${new_active_modules:1:1} && $short != [$active_modules]) ]]; then
				#	local main_module=$module main_output=$output_content
				#	get_module ${new_active_modules:2:1}
				#	#~/.orw/scripts/notify.sh "RELOADING $new_active_modules: $module, $current_module"
				#	~/.orw/scripts/notify.sh "RELOADING $module, $current_module, $main_module"
				#	local $module #third=true
				#	get_$module
				#	print_module $module
				#	~/.orw/scripts/notify.sh "RELOADED $module, $current_module, $main_module"
				#fi

				#get_module ${new_active_modules:1:1}
				#local $module
				#get_$module
				#print_module $module reload

				#if [[ ! $third ]]; then
				#	get_module ${new_active_modules::1}
				#	local $module
				#	get_$module
				#	print_module $module
				#fi




				#echo "$current_module: $current_output" >> bar.log

				#~/.orw/scripts/notify.sh "RELOADING $module, $current_module"

				#if [[ ! $third ]]; then
				#	get_module ${new_active_modules::1}
				#	local $module
				#	get_$module
				#	print_module $module
				#fi

				#if [[ $short == ${active_modules::1} ]]; then
				#	get_module ${new_active_modules::1}
				#	local $module
				#	get_$module
				#	print_module $module
				#fi

				module=$current_module output_content="$current_output"
				label=$current_label icon=$current_icon 
				module_action_end=$module_module_action_end
				module_action_start=$current_module_action_start
		fi

		#[[ $switch_bg ]] &&
		#	~/.orw/scripts/notify.sh -t 11 "$module: $switch_bg, $joiner_next_bg, $output_content\n$short, $active_modules, ${joiners[joiner_group_index - 1]}"
	else
		[[ ${!module} && $frame_type && ! ${multiframe_modules[*]} =~ $module ]] &&
			output_content="$module_frame_start$output_content$module_frame_end"
		[[ $short != $last_module ]] && output_content+="$bar_separator"
		#[[ $module != $last_module ]] && local separator=$bar_separator
		#eval echo \"${module^^}:"$output_content$separator"\"
	fi

	#eval echo \"${current_module:-${module^^}}:"$output_content"\"
	#echo "$2 PRINT ${current_module:-${module^^}}: $output_content" >> bar.log
	eval echo \"${module^^}:"$output_content"\"
	#[[ $2 ]] && echo "$joiner_next_bg: $new_active_modules, $active_modules" >> bar.log
	#echo "$2 PRINT ${module^^}: $output_content" >> bar.log
	#[[ $2 ]] &&
	#	~/.orw/scripts/notify.sh -t 11 "RELOADED $current_module: $module, $output_content" && sleep 3
}

reload_module() {
	local module_index=$1
	local current_module=$module current_output=$output_content
	#local current_module_action_start=$module_action_start
	#local current_module_action_end=$module_action_end
	local current_label=$label current_icon=$icon

	~/.orw/scripts/notify.sh "$module, $module_index, $start_position"

	get_module ${new_active_modules: $module_index:1}
	local $module actions_{start,end}
	get_$module
	type -t set_${module}_actions &> /dev/null && set_${module}_actions
	#local actions=$?

	#if ((!actions)); then
	#	#set_${module}_actions
	#	[[ $module == volume ]] &&
	#		echo "VA: $actions_start,       ${!module}" >> v.log
	#fi

	[[ ${!module} ]] && print_module $module $module_index

	module=$current_module output_content="$current_output"
	#module_action_start=$current_module_action_start
	#module_action_end=$module_module_action_end
	label=$current_label icon=$current_icon 
}

reload_modules() {
	local module_index=$1

	#~/.orw/scripts/notify.sh "MOD $module"

	if [[ ! $2 && (($short != [$active_modules] &&
		$short == ${new_active_modules:$module_index:1}) ||
		($short == ${active_modules:$module_index:1} &&
		$short != [$new_active_modules])) ]]; then
			#((module_index++))

			[[ $short != [$active_modules] &&
				$short == ${new_active_modules:$module_index:1} ]] &&
				local start_position=$((module_index + 1)) || local start_position=$module_index

			((module_index)) &&
				((module_index--)) &&
				((start_position--)) &&
				print_current=true

			#((module_index)) &&
			#[[ $reload_current == false ]] &&
			#	~/.orw/scripts/notify.sh "RELOAD $module, $module_index, $start_position, $new_active_modules, ${new_active_modules:start_position+1:1}"

			if ((start_position == module_index)) && [[ $switch_bg == *[0-9]* ]]; then
				reload_module $((start_position + 1))
			fi

			#~/.orw/scripts/notify.sh "RELOAD $module"
			#((!module_index)) &&
			[[ ! $print_current ]] &&
				reload_module $start_position ||
				#eval modules_to_print[$start_position]=\"${module^^}:"$output_content"\"
				eval modules_to_print+=( \"${module^^}:"${output_content//\"/\\\"}"\" )
				#eval modules_to_print[$start_position]=\"${module^^}:"${output_content//\"/\\\"}"\"
				#eval echo \"${module^^}:"$output_content"\"

			if ((start_position > module_index)) && [[ $switch_bg == *[0-9]* ]]; then
				reload_module $((start_position + 1))
			fi
	elif ((module_index)); then
		#~/.orw/scripts/notify.sh "NORM $module"
		#eval echo \"${module^^}:"$output_content"\"
		eval modules_to_print+=( \"${module^^}:"${output_content//\"/\\\"}"\" )
		#eval modules_to_print[$module_index]=\"${module^^}:"${output_content//\"/\\\"}"\"
	fi
}

print_module() {
	local module=$1 content=${1}_content short=${shorts[$1]}
	local output_content new_active_modules
	[[ $2 ]] || local modules_to_print
	#[[ $2 ]] || declare -A modules_to_print

	[[ ${!module} ]] &&
		output_content="$actions_start${!content}$actions_end"
		#output_content="\$${module}_actions_start${!content}\$${module}_actions_end"

	#[[ $module == volume && $2 ]] &&
	#	echo "START: $actions_start" >> v.log

	#[[ $module == volume ]] &&
	#	~/.orw/scripts/notify.sh "VOL: $actions_start"

	if [[ ${joiner_modules[$short]} ]]; then
		local joiner_group_index=${joiner_modules[$short]}
		local joiner_group="${joiner_groups[joiner_group_index - 1]}"
		local active_modules=$(sed -n "${joiner_group_index}p" $joiner_modules)
		local new_active_modules=$active_modules

		[[ ${active_modules: -1} == $short ]] && local end_module=true
		[[ ${active_modules::1} == $short ]] && local start_module=true

		[[ $short == [$active_modules] && ! ${!module} ]] &&
			new_active_modules="${active_modules/$short}"
		[[ $short != [$active_modules] && ${!module} ]] &&
			new_active_modules="${joiner_group//[^$active_modules$short]}"

		#[[ $new_active_modules ]] &&
		#	~/.orw/scripts/notify.sh "NEW: $module, $active_moudles, $joiner_group, $new_active_modules"

		#[[ $new_active_modules ]] &&
		#	echo "NEW: $module, $active_modules, $joiner_group, $new_active_modules" >> log

		#[[ ${new_active_modules:-$active_modules} != $active_modules ]] &&
		#[[ $new_active_modules && $new_active_modules != $active_modules ]] &&
		[[ $new_active_modules != $active_modules ]] &&
			sed -i "$joiner_group_index s/.*/$new_active_modules/" $joiner_modules

		local joiner_{distance,{frame_,}{start,end},next_bg} cj{p,s}fg switch_bg
		read joiner_{distance,frame_{start,end}} switch_bg <<< "${joiners[joiner_group_index - 1]}"

		#[[ $2 ]] && echo "PRE $module $joiner_next_bg: ^$new_active_modules^, ^$active_modules^" >> bar.log
		#[[ $2 && $new_active_modules != $active_modules ]] && echo "DIFF" >> bar.log

		#[[ ($new_active_modules &&
		[[ $new_active_modules != $active_modules &&
			(($short == ${new_active_modules::1} && ! $start_module) ||
			#($start_module && $short != ${new_active_modules::1})) ]] &&
			($start_module && $short != ${new_active_modules::1})) ||
			#($switch_bg &&
			#((${switch_bg::1} == s && $short == [${new_active_modules:1:1}]) ||
			#(${switch_bg::1} == e && $short == ${new_active_modules: -2:1}))) ]] &&
			($switch_bg && $short == [${new_active_modules:1:1}${new_active_modules: -1}]) ]] &&
			#($switch_bg && $short == [${new_active_modules:1:1}${new_active_modules: -2:1}) ]] &&
				get_joiner_frame ${new_active_modules::1} $switch_bg

		#[[ $2 ]] && echo "POST $joiner_next_bg: $new_active_modules, $active_modules" >> bar.log

		#[[ $joiner_start && $joiner_end ]] &&
		#[[ ${new_active_modules:-$active_modules} != $active_modules ]] &&
		#[[ $new_active_modules && $new_active_modules != $active_modules ]] &&
		[[ ($joiner_start && $joiner_end) ||
			(! $new_active_modules && $new_active_modules != $active_modules) ]] &&
			#local shr="${joiner_next_bg:1:4}" &&
			#echo "JOINERS: $module > $new_active_modules, $joiner_next_bg, $joiner_start, $joiner_end" >> bar.log &&
			echo "JOINER_${joiner_group_index}_START:$joiner_start" > $fifo &&
			echo "JOINER_${joiner_group_index}_END:$joiner_end" > $fifo

		if [[ $output_content ]]; then
			[[ $short != ${new_active_modules: -1} ]] &&
				output_content+="%{O$joiner_distance}"

			#[[ ${new_active_modules:1:1} == $short && $joiner_next_bg ]] &&
			#	output_content="$joiner_next_bg$output_content"

			[[ $joiner_next_bg &&
				(${switch_bg::1} == s && $short == ${new_active_modules:1:1}) ||
				(${switch_bg::1} == e && $short == ${new_active_modules: -1}) ]] &&
				output_content="$joiner_next_bg$output_content"

			#[[ $module == workspaces ]] &&
			#	~/.orw/scripts/notify.sh -t 11 "HERE $module: ${switch_bg:1:1}, $short, ${new_active_modules::1}, $joiner_next_bg"
			#[[ $short == ${new_active_modules::1} && $switch_bg == s* ]] &&
			#	~/.orw/scripts/notify.sh -t 11 "HERE $module: ${switch_bg:1:1}, $short, ${new_active_modules::1}"

			#[[ (${switch_bg::1} == s && $short == ${new_active_modules::1}) ||
			#	(${switch_bg::1} == e && $short != ${new_active_modules::1}) ]] &&
			#	cjsfg="$jsfg" cjpfg="$jpfg"

			[[ (${switch_bg::1} == s &&
				(${switch_bg:1:1} == b && $short == ${new_active_modules::1}) ||
				(${switch_bg:1:1} == f && $short != ${new_active_modules::1})) ||
				(${switch_bg::1} == e &&
				(${switch_bg:1:1} == b && $short != ${new_active_modules: -1}) ||
				(${switch_bg:1:1} == f && $short == ${new_active_modules: -1})) ]] &&
				cjsfg="$jsfg" cjpfg="$jpfg"

			#[[ (${switch_bg::1} == s && $short == ${new_active_modules::1}) ||
			#	(${switch_bg::1} == e && $short != ${new_active_modules::1}) ]] &&
			#	~/.orw/scripts/notify.sh -t 11 "HERE $module: $cjsfg, $cjpfg"

			#[[ $module == time ]] &&
			#	~/.orw/scripts/notify.sh -t 11 "HERE $module: $cjsfg, $cjpfg"

			[[ ($cjsfg && $cjpfg) && $labeled_modules != *$module* ]] &&
				eval "output_content=\"$output_content\"" #&&
				#~/.orw/scripts/notify.sh -t 22 "HERE $module: $cjsfg, $cjpfg, $out"

			#[[ $short == ${new_active_modules::1} && $switch_bg == s* ]] &&
			#	~/.orw/scripts/notify.sh -t 11 "HERE $module: $cjsfg, $cjpfg > $jsfg, $jpfg"

			#eval "out=\"$output_content\""
			#[[ $module == rss ]] && ~/.orw/scripts/notify.sh -t 11 "$module: $cjsfg, $cjpfg, $Rsfg, $Rpfg"
		fi

		#[[ $2 ]] &&
		#	~/.orw/scripts/notify.sh -t 11 "$2, $3 JBG: $module, $output_content"

		#if [[ $new_active_modules != $active_modules &&
		#	$switch_bg && ${#new_active_modules} -gt 1 ]]; then
		#			local current_module=$module current_output=$output_content
		#			local current_label=$label current_icon=$icon
		#			local current_module_action_end=$module_action_end
		#			local current_module_action_start=$module_action_start

		#			[[ $short == ${new_active_modules::1} && $short != [$active_modules] ]] &&
		#				local start_position=1 || local start_position=0

		#			#if [[ $short == ${new_active_modules::1} && $short != [$active_modules] ]]; then
		#			#	get_module ${new_active_modules:1:1}
		#			#	local $module
		#			#	get_$module
		#			#	[[ ${!module} ]] && print_module $module
		#			#fi

		#			if ((!start_position)) && [[ $switch_bg == *[0-9]* ]]; then
		#				get_module ${new_active_modules:$start_position+1:1}
		#				local $module
		#				get_$module
		#				#[[ $short == R ]] &&
		#				#	~/.orw/scripts/notify.sh "THIRD $current_module, $module"
		#				[[ ${!module} ]] && print_module $module 1 2
		#				#[[ $short == R ]] && sleep 3
		#			fi

		#			#if [[ $short == ${active_modules::1} && $short != [$new_active_modules] ]]; then
		#			if [[ $start_position ]]; then
		#				get_module ${new_active_modules:$start_position:1}
		#				local $module
		#				get_$module
		#				#[[ $short == R ]] &&
		#				#	~/.orw/scripts/notify.sh "SECOND $current_module, $module"
		#				[[ ${!module} ]] && print_module $module 1
		#			fi

		#			if ((start_position)) && [[ $switch_bg == *[0-9]* ]]; then
		#				get_module ${new_active_modules:$start_position+1:1}
		#				local $module
		#				get_$module
		#				#[[ $short == R ]] &&
		#				#	~/.orw/scripts/notify.sh "THIRD $current_module, $module"
		#				[[ ${!module} ]] && print_module $module 1 2
		#				#[[ $short == R ]] && sleep 3
		#			fi

		#			#($short == ${active_modules::1} && $short != ${new_active_modules::1}) &&

		#			module=$current_module output_content="$current_output"
		#			label=$current_label icon=$current_icon 
		#			module_action_end=$module_module_action_end
		#			module_action_start=$current_module_action_start
		#fi

		#if [[ $new_active_modules != $active_modules &&
		#	$switch_bg && ${#new_active_modules} -gt 1 ]]; then
		#			reload_modules 0
		#fi

		#if [[ $new_active_modules != $active_modules &&
		#	($short == [${new_active_modules::2}] || $short == [${active_modules::2}]) &&
		#	$switch_bg && ${#new_active_modules} -gt 1 ]]; then
		#		local current_module=$module current_output=$output_content
		#		local current_label=$label current_icon=$icon
		#		local current_module_action_end=$module_action_end
		#		local current_module_action_start=$module_action_start

		#		if [[ $short == ${new_active_modules::1} ||
		#			($short == ${new_active_modules:1:1} && $short != [$active_modules]) ]]; then
		#			get_module ${new_active_modules:2:1}

		#			local $module third=true
		#			get_$module
		#			[[ ${!module} ]] && print_module $module
		#		fi

		#		get_module ${new_active_modules:1:1}
		#		local $module
		#		get_$module
		#		[[ ${!module} ]] && print_module $module reload

		#		if [[ $third ]]; then
		#			get_module ${new_active_modules::1}

		#			local $module
		#			get_$module
		#			[[ ${!module} ]] && print_module $module
		#		fi
		#		#~/.orw/scripts/notify.sh "RELOADED $current_module, $module"

		#		module=$current_module output_content="$current_output"
		#		label=$current_label icon=$current_icon 
		#		module_action_end=$module_module_action_end
		#		module_action_start=$current_module_action_start
		#fi

		local module_index

		#for module_index in 0 1; do
		#	if [[ $new_active_modules != $active_modules &&
		#		$switch_bg && ${#new_active_modules} -gt 1 ]]; then
		#				reload_modules $module_index
		#	else
		#		#[[ $module == volume ]] &&
		#		#	~/.orw/scripts/notify.sh "VOL: $volume_actions_start"

		#		#[[ $module == volume ]] && echo "VOL: $output_content" >> v.log
		#		#eval echo \"${module^^}:"$output_content"\"
		#		eval modules_to_print+=( \"${module^^}:"$output_content"\" )
		#	fi
		#done

		#if [[ $new_active_modules != $active_modules &&
		#		($short == [${active_modules::2}] ||
		#		$short == [${new_active_modules::2}]) &&
		#		$switch_bg && ${#new_active_modules} -gt 1 ]]; then
		#			for module_index in 0 1; do
		#				reload_modules $module_index
		#			done

		if [[ $new_active_modules != $active_modules &&
				(${switch_bg::1} == s &&
				($short == [${active_modules::2}] ||
				$short == [${new_active_modules::2}])) &&
				${#new_active_modules} -gt 1 ]]; then
					for module_index in 0 1; do
						reload_modules $module_index
					done

					#[[ $2 ]] ||
					#	while read module_index; do
					#		echo "${modules_to_print[$module_index]}" > $fifo
					#	done <<< $(tr ' ' '\n' <<< "${!modules_to_print[*]}" | sort -n)

					#[[ $2 ]] ||
					#	for module_to_print in "${modules_to_print[@]}"; do
					#		echo "$module_to_print" >> rel.log
					#		echo "$module_to_print" > $fifo
					#	done
		else
			#[[ $module == volume ]] &&
			#	~/.orw/scripts/notify.sh "VOL: $volume_actions_start"
			#~/.orw/scripts/notify.sh "$module: ${2:-1}"

			#[[ $module == volume ]] && echo "VOL: $output_content" >> v.log
			#eval echo \"${module^^}:"$output_content"\"
			#eval modules_to_print+=( \"${module^^}:"$output_content"\" )
			#eval echo \"${module^^}:"$output_content"\"
			#eval modules_to_print[${2:-1}]=\"${module^^}:"${output_content//\"/\\\"}"\"
			eval modules_to_print+=( \"${module^^}:"${output_content//\"/\\\"}"\" )
		fi

		#[[ $2 ]] ||
		#	while read module_index; do
		#		echo "${modules_to_print[$module_index]}" > $fifo
		#	done <<< $(tr ' ' '\n' <<< "${!modules_to_print[*]}" | sort -n)

		[[ $2 ]] ||
			for module_to_print in "${modules_to_print[@]}"; do
				#echo "$module_to_print" >> rel.log
				echo "$module_to_print" > $fifo
			done

		#if [[ $new_active_modules != $active_modules &&
		#	$switch_bg && ${#new_active_modules} -gt 1 ]]; then
		#			reload_modules 0
		#fi

		#if [[ $new_active_modules != $active_modules &&
		#	$switch_bg && ${#new_active_modules} -gt 1 ]]; then
		#			reload_modules 1
		#fi

	else
		[[ ${!module} && $frame_type && ! ${multiframe_modules[*]} =~ $module ]] &&
			output_content="$module_frame_start$output_content$module_frame_end"
		[[ $module != $last_module ]] && output_content+="$bar_separator"
		eval echo \"${module^^}:"$output_content"\"
		#eval modules_to_print=( \"${module^^}:"$output_content"\" )
	fi

	#echo "$2 PRINT ${current_module:-${module^^}}: $output_content" >> bar.log

	#eval echo \"${module^^}:"$output_content"\"

	#[[ $2 ]] && echo "$joiner_next_bg: $new_active_modules, $active_modules" >> bar.log
	#echo "$2 PRINT ${module^^}: $output_content" >> bar.log
}

reload_module() {
	local module_index=$1

	if [[ ${new_active_modules: $module_index:1} ]]; then
		local current_module=$module current_output=$output_content
		local current_label=$label current_icon=$icon

		get_module ${new_active_modules: $module_index:1}
		local $module actions_{start,end}
		get_$module

		#((module_index < 0)) &&
		#~/.orw/scripts/notify.sh "$module, $module_index, ${!module}"

		type -t set_${module}_actions &> /dev/null && set_${module}_actions

		[[ ${!module} ]] && print_module $module $module_index

		module=$current_module output_content="$current_output"
		label=$current_label icon=$current_icon 
	fi
}

reload_modules() {
	local module_index=$1 reload=$2

	#if [[ (($short != [$active_modules] &&
	#	$short == ${new_active_modules:$module_index:1}) ||
	#	($short == ${active_modules:$module_index:1} &&
	#	$short != [$new_active_modules])) ]]; then

	#echo "$module $sec RLD: $module_index, ${new_active_modules}: ${new_active_modules: $module_index:1}" >> j.log

	if [[ ($new_active_modules != $active_modules &&
		(($short != [$active_modules] &&
		$short == ${new_active_modules: $module_index:1}) ||
		($short == ${active_modules: $module_index:1} &&
		$short != [$new_active_modules])) || $reload) ]]; then
			((module_index < 0)) && local sign=-

			#echo "RLD PASSED: $module_index, ${new_active_modules}: ${new_active_modules: $module_index:1}" >> j.log

			[[ $reload || ($short != [$active_modules] &&
				$short == ${new_active_modules:$module_index:1}) ]] &&
				local start_position=$((module_index ${sign:-+} 1)) ||
				local start_position=$module_index

			if ((module_index < 0)); then
				#~/.orw/scripts/notify.sh "$module, $module_index, $start_position"
				#echo "$module $sec RELOAD: $module, $start_position: ${new_active_modules: $start_position:1}" >> j.log
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
					#eval modules_to_print[$start_position]=\"${module^^}:"${output_content//\"/\\\"}"\"
					#eval echo \"${module^^}:"$output_content"\"

				if ((start_position > module_index)) && [[ $switch_bg == *[0-9]* ]]; then
					reload_module $((start_position + 1))
				fi
			fi
	fi

	((!module_index)) && [[ ! $print_current ]] && return

	#echo "$module $sec ADDING: $module" >> j.log

	local $short="${new_active_modules: $module_index:1}"
	if [[ ! ${reloaded_modules[*]} =~ (^| )$short( |$) ]]; then
		eval modules_to_print+=( \"${module^^}:"${output_content//\"/\\\"}"\" )
		reloaded_modules+=( $short )
	fi

	return

	#elif ((module_index)); then
	#	eval modules_to_print+=( \"${module^^}:"${output_content//\"/\\\"}"\" )
	#	#eval modules_to_print[$module_index]=\"${module^^}:"${output_content//\"/\\\"}"\"
	#	#eval echo \"${module^^}:"$output_content"\"
	#fi
}

print_module() {
	local module=$1 content=${1}_content short=${shorts[$1]}
	local output_content new_active_modules
	[[ $2 ]] ||
		local modules_to_print reloaded_modules

	[[ "${!module}" ]] &&
		output_content="$actions_start${!content}$actions_end"

	#~/.orw/scripts/notify.sh -t 11 "LNCH: $launchers"

	#[[ $module == volume ]] &&
	#	~/.orw/scripts/notify.sh "VOL: ${!joiner_modules[*]},    $short"

	#[[ ${joiner_modules[$short]} ]] || 
	#	~/.orw/scripts/notify.sh "MODULE: $module, $short, ${!joiner_modules[*]}"

	#if [[ ${joiner_modules[$short]} ]]; then
	if [[ ${!joiner_modules[*]} == *$short* ]]; then
		#while
		#	pid=$(fuser $joiner_modules | awk '{ print $NF }')
		#	((pid))
		#do
		#	echo "FILE IN USE" >> j.log
		#	sleep 0.1
		#done

		if [[ ! $2 ]]; then
			while [[ -f $joiner_lock_file ]]; do
				#echo "$module: FILE IN USE" >> j.log
				sleep 0.05
			done

			[[ $module ]] && echo $module > $joiner_lock_file
			#echo $module >> lock.log
		fi

		#[[ ${joiner_modules[$short]} ]] || 
		#~/.orw/scripts/notify.sh "MODULE: $module, $short, ${!joiner_modules[*]}"

		#echo "Locked by $module" >> j.log
		local joiner_group_index=${joiner_modules[$short]}
		local joiner_group="${joiner_groups[joiner_group_index - 1]}"
		local active_modules=$(sed -n "${joiner_group_index}p" $joiner_modules_file)
		local new_active_modules=$active_modules

		#((joiner_group_index == 3)) &&
		#	~/.orw/scripts/notify.sh "3 HERE"

		#((joiner_group_index == 3)) &&
		#echo "$short ${module^^}: $active_modules, $new_active_modules" >> j.log

		[[ ${active_modules: -1} == $short ]] && local end_module=true
		[[ ${active_modules::1} == $short ]] && local start_module=true

		[[ $short == [$active_modules] && ! "${!module}" ]] &&
			new_active_modules="${active_modules/$short}"
		[[ $short != [$active_modules] && "${!module}" ]] &&
			new_active_modules="${joiner_group//[^$active_modules$short]}"

		#if ((joiner_group_index == 3)); then
		#	(echo "$module: $new_active_modules, $2: $active_modules, ${new_active_modules: $2:1}"
		#	cat $joiner_modules) >> j.log
		#fi

		#[[ $new_active_modules != $active_modules ]] &&
		#	sed -i "$joiner_group_index s/.*/$new_active_modules/" $joiner_modules

		if [[ ! $2 ]]; then
			if [[ $new_active_modules != $active_modules ]]; then
				#echo > /tmp/lock
				sed -i "$joiner_group_index s/.*/$new_active_modules/" $joiner_modules_file
				#rm /tmp/lock
			fi
			#[[ -f $joiner_lock && $(cat $joiner_lock) == $module ]] && echo "Unlocked by $module" >> j.log
			#[[ -f $joiner_lock_file && $(cat $joiner_lock_file) == $module ]] && rm $joiner_lock_file
			if [[ -f $joiner_lock_file ]]; then
				[[ -f $joiner_lock_file ]] && sed -i "/$module/d" $joiner_lock_file
				[[ $(cat $joiner_lock_file) ]] || rm $joiner_lock_file
			else
				~/.orw/scripts/notify.sh "WRONG: $module"
			fi
			#[[ ! $(cat $joiner_lock_file) ]] && rm $joiner_lock_file || echo "BAD: $module" >> lock.log
		fi

		local joiner_{distance,{frame_,}{start,end},padding,next_bg} cj{p,s}fg switch_bg
		read joiner_{distance,frame_{start,end},padding} switch_bg <<< \
			"${joiners[joiner_group_index - 1]}"

		#local joiner_padding="%{O20}"

		[[ ($new_active_modules != $active_modules &&
			(($short == ${new_active_modules::1} && ! $start_module) ||
			($start_module && $short != ${new_active_modules::1})) ||
			($switch_bg && $short == [${new_active_modules:1:1}${new_active_modules: -1}])) ||
			($short == ${new_active_modules::1} && $updated) ]] &&
				get_joiner_frame ${new_active_modules::1} $switch_bg

		#[[ $joiner_start && $updated ]] &&
		#~/.orw/scripts/notify.sh "UPDATED $module $joiner_group_index: $joiner_start"

		#[[ $module == time ]] &&
		#~/.orw/scripts/notify.sh "UPD: $short, ${new_active_modules::1}, ${active_modules::1}, $updated"

		#[[ $short == ${new_active_modules::1} && $updated ]] &&
		#~/.orw/scripts/notify.sh "UPDATED $module $joiner_group_index: $joiner_start"

		[[ ${joiner_group: -1} != $last_module ]] &&
			local joiner_separator=$bar_separator

		[[ ($joiner_start && $joiner_end) ||
			(! $new_active_modules && $new_active_modules != $active_modules) ]] &&
			echo "JOINER_${joiner_group_index}_START:$joiner_start" > $fifo &&
			echo "JOINER_${joiner_group_index}_END:$joiner_end$joiner_separator" > $fifo
			#~/.orw/scripts/notify.sh "UPD: $module"

		#[[ $updated ]] && unset updated

		if [[ $output_content ]]; then
			#[[ (${switch_bg::2} == sf && $short == ${new_active_modules::1}) ||
			#	(${switch_bg::2} == eb && $short == ${new_active_modules: -2:1}) ]] &&

			#[[ (${switch_bg::2} == sf || ${switch_bg::2} == eb) ]] &&

			local module_distance="%{O$joiner_distance}"

			if [[ ${switch_bg::2} == sb ]]; then
				if [[ $short == ${new_active_modules::1} ]]; then
					unset module_distance
				else
					#local mod_dis="%{O$joiner_distance}"
					[[ $short == ${new_active_modules:1:1} ]] &&
						joiner_next_bg+="$module_distance"
						#local switch_distance=$mod_dis
				fi
			elif [[ ${switch_bg::2} == eb ]]; then
				if [[ $short == ${new_active_modules: -2:1} ]]; then
					unset module_distance
				else
					#local mod_dis="%{O$joiner_distance}"
					[[ $short == ${new_active_modules: -1} ]] &&
						joiner_next_bg+="$module_distance"
						#local switch_distance=$mod_dis
				fi
			fi

			[[ $short != ${new_active_modules: -1} ]] &&
				output_content+="$module_distance"

			#[[ $short != ${new_active_modules: -1} ]] &&
			#	output_content+="%{O$joiner_distance}"

			#[[ $module == time ]] &&
			#	~/.orw/scripts/notify.sh "TIME: $joiner_distance, $output_content"

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
				cjsfg="$jsfg" cjpfg="$jpfg"

			#[[ ${labeled_modules[*]} == *$module* ]] && labeled=true
			#[[ $labeled_modules == *$module* ]] && labeled=true
			[[ ${multiframe_modules[*]} == *$module* ]] &&
				local is_multiframe=true

			[[ $joiner_next_bg == *%{O[0-9]*}* ]] &&
				local has_bg_distance=true

			#local joiner_padding="%{O20}"

			#[[ $module =~ volume|email|torrents ]] &&
			#echo "$module: $joiner_next_bg" >> j.log

			#[[ $short == ${new_active_modules::1} && 
			#	! $is_multiframe && ! $has_bg_distance ]] &&
			#	output_content="$joiner_padding$output_content"

			#[[ $short == ${new_active_modules: -1} &&
			#	! $is_multiframe && ! $has_bg_distance ]] &&
			#	output_content="$output_content$joiner_padding"

			#[[ $module =~ volume|email|torrents ]] &&
			#echo "content: $output_content" >> j.log

			#[[ $module == mpd ]] &&
			#	echo "MPD: $joiner_distance, $output_content" >> j.log
			#	#~/.orw/scripts/notify.sh "MPD: $joiner_distance"
			
			#[[ $module == network ]] &&
			#	~/.orw/scripts/notify.sh "$module: ${new_active_modules::1}, $padding, $output_content"
			
			#[[ $labeled && $short == ${new_active_modules::1} ||
			#	$labeled && $short == ${new_active_modules: -1} ]] &&
			#	~/.orw/scripts/notify.sh "$module: $padding, $output_content"

			#local padding

			[[ ($cjsfg && $cjpfg) && ! $labeled ]] &&
				eval "output_content=\"$output_content\""

			#((joiner_group_index == 3)) &&
			#echo "$module $sec $2 $module: $new_active_modules, $short, ${new_active_modules: -2:1}, $output_content" >> j.log

			#[[ $module == network ]] &&
			#echo "$module: $output_content" >> j.log
			#[[ $module == volume ]] &&
			#echo "$module: $volume_padding, $output_content" >> j.log
		fi

		local module_index modules_to_reload reload_mode

		#if [[ $new_active_modules != $active_modules &&
		#		(${switch_bg::1} == s &&
		#		($short == [${active_modules::2}] ||
		#		$short == [${new_active_modules::2}])) &&
		#		${#new_active_modules} -gt 1 ]]; then
		#			for module_index in 0 1; do
		#				reload_modules $module_index
		#			done
		#else
		#	eval modules_to_print+=( \"${module^^}:"${output_content//\"/\\\"}"\" )
		#fi







		##if [[ $switch_bg && ${#new_active_modules} -gt 1 ]]; then
		#if [[ ! $2 && ${#new_active_modules} -gt 1 &&
		#	($switch_bg || $short == ${new_active_modules: -1}) ]]; then
		#		[[ ${switch_bg::1} == s ]] &&
		#			modules_to_reload='0 1' #|| modules_to_reload=-1
		#		((${#new_active_modules} > 2)) &&
		#			[[ ${switch_bg::2} == eb &&
		#			$short == ${new_active_modules: -2:1} ]] &&
		#			modules_to_reload=-2 #reload_mode=reload

		#		((joiner_group_index == 3)) &&
		#		echo "$sec CHECK: $short, ${#new_active_modules}, $new_active_modules - $modules_to_reload" >> j.log

		#		#[[ $module == emails ]] &&
		#		#	~/.orw/scripts/notify.sh "${#new_active_modules}, ${switch_bg::2}, $short, ${new_active_modules: -2}"

		#		[[ ! $2 ]] && modules_to_reload+=' -1'

		#		for module_index in $modules_to_reload; do
		#			reload_modules $module_index $reload_mode
		#		done



		#if ((${2:-0} == -2)); then
		#	reload_modules -2 reload
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

				#((joiner_group_index == 3)) &&
				#echo "$module $sec CHECK: $short, ${#new_active_modules}, $new_active_modules - $modules_to_reload" >> j.log

				for module_index in $modules_to_reload -1; do
					reload_modules $module_index #$reload_mode
				done
		#elif ((${#new_active_modules} > 2)) &&
		#	[[ ${switch_bg::2} == eb &&
		#	$short == ${new_active_modules: -2:1} ]] &&
		#			modules_to_reload=-2
		else
			#[[ $module == time ]] &&
			#~/.orw/scripts/notify.sh "TIME $output_content"

			#eval modules_to_print+=( \"${module^^}:"${output_content//\"/\\\"}"\" )
			if [[ ! ${reloaded_modules[*]} =~ (^| )$short( |$) ]]; then
				eval modules_to_print+=( \"${module^^}:"${output_content//\"/\\\"}"\" )
				reloaded_modules+=( $short )
			fi
		fi

		#[[ ! $2 && $module == time ]] &&
		#	~/.orw/scripts/notify.sh "gotten vanter.. ${modules_to_print[*]}"

		#[[ ! $2 && $module =~ time|mpd ]] &&
		#	echo "${module^^}: ${!module}" >> md.log

		if [[ ! $2 ]]; then
			#echo -e "$module $sec \nPRINT $module" >> j.log

			for module_to_print in "${modules_to_print[@]}"; do
				#echo "$module_to_print" >> rel.log
				#echo "$module $sec PRT: $module_to_print" >> j.log
				echo "$module_to_print" > $fifo
				#[[ $module == lanuchers ]] && echo "$module_to_print" >> l.log
			done

			#echo -e "$module $sec END PRINT $module\n" >> j.log
		fi
	else
		[[ ${!module} && $frame_type && ! ${multiframe_modules[*]} =~ $module ]] &&
			output_content="$module_frame_start$output_content$module_frame_end"
		[[ $short != $last_module && ${!output_content} ]] &&
			output_content+="$bar_separator"
		eval echo \"${module^^}:"$output_content"\" > $fifo
		#[[ $module == volume ]] &&
		#	eval echo -e \"V: "$output_content"\" >> v.log
		#eval modules_to_print=( \"${module^^}:"$output_content"\" )

			#~/.orw/scripts/notify.sh -t 22 "$module: ${cjsfg:-$Tsfg}, ${output_content}"
	fi
}

print_module() {
	local module=$1 content=${1}_content short=${shorts[$1]}
	local output_content new_active_modules
	[[ $2 ]] ||
		local modules_to_print reloaded_modules

	[[ "${!module}" ]] &&
		output_content="$actions_start${!content}$actions_end"

	#~/.orw/scripts/notify.sh -t 11 "LNCH: $launchers"

	#[[ $module == volume ]] &&
	#	~/.orw/scripts/notify.sh "VOL: $module"

	#[[ ${joiner_modules[$short]} ]] || 
	#	~/.orw/scripts/notify.sh "MODULE: $module, $short, ${!joiner_modules[*]}"

	if [[ ${!joiner_modules[*]} == *$short* ]]; then
		#[[ ! $2 ]] && exec 11< $joiner_lock_file

		#[[ ! $2 ]] && exec 11<$joiner_modules_file
		#[[ ! $2 ]] && flock -n 11




		{
			flock -x 11




			##OLD LOCK APPROACH
			#if [[ ! $2 ]]; then
			#	while [[ -f $joiner_lock_file ]]; do
			#		sleep 0.05
			#	done

			#	#[[ $module == mpd ]] &&
			#	#echo "MPD lock" >> mpd.log
			#	#~/.orw/scripts/notify.sh "MPD lock"

			#	[[ $module ]] && echo $module > $joiner_lock_file
			#fi

			local joiner_group_index=${joiner_modules[$short]}
			local joiner_group="${joiner_groups[joiner_group_index - 1]}"

			#if [[ ! $2 && $module == mpd ]]; then
			#	ls -l $joiner_modules_file
			#	echo HERE ^
			#	sed -n "${joiner_group_index}p" $joiner_modules_file
			#	echo ^
			#	#echo "MPD HERE: $(cat $joiner_lock_file)"
			#fi >> mpd.log

			#until [[ -r $joiner_modules_file ]]; do
			#	sleep 0.01
			#done

			#if [[ ! $2 && $module == mpd ]]; then
			#	echo "MPD reading.."
			#else
			#	echo "$module: reading modules"
			#fi >> mpd.log

			local active_modules=$(sed -n "${joiner_group_index}p" $joiner_modules_file)
			#local active_modules=$(flock $joiner_modules_file \
			#	sed -n "${joiner_group_index}p" $joiner_modules_file)
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
				#[[ -f $joiner_lock_file ]] && sed -i "/$module/d" $joiner_lock_file

				#exec 11<&-
				#flock -u 11

				#[[ $(cat $joiner_lock_file) ]] || rm $joiner_lock_file
			fi



		} 11< $joiner_modules_file




		##OLD LOCK APPROACH
		##if [[ $new_active_modules != $active_modules ]]; then
		#if [[ ! $2 ]]; then
		#	[[ $new_active_modules != $active_modules ]] &&
		#		sed -i "$joiner_group_index s/.*/$new_active_modules/" $joiner_modules_file

		#	if [[ -f $joiner_lock_file ]]; then
		#		#grep "$module" $joiner_lock_file &> /dev/null && rm $joiner_lock_file
		#		[[ -f $joiner_lock_file ]] && sed -i "/$module/d" $joiner_lock_file
		#		[[ $(cat $joiner_lock_file) ]] || rm $joiner_lock_file
		#	else
		#		~/.orw/scripts/notify.sh "WRONG: $module"
		#	fi
		#fi

		local joiner_{distance,{frame_,}{start,end},padding,next_bg} cj{p,s}fg switch_bg
		read joiner_{distance,frame_{start,end},padding} switch_bg <<< \
			"${joiners[joiner_group_index - 1]}"

		[[ ($new_active_modules &&
			$new_active_modules != $active_modules &&
			(($short == ${new_active_modules::1} && ! $start_module) ||
			($start_module && $short != ${new_active_modules::1})) ||
			($switch_bg && $short == [${new_active_modules:1:1}${new_active_modules: -1}])) ||
			($short == ${new_active_modules::1} && $updated) ]] &&
				get_joiner_frame ${new_active_modules::1} $switch_bg

		#[[ $module == counter ]] &&
		#	~/.orw/scripts/notify.sh -t 11 "CNT: ${joiners[joiner_group_index - 1]}"

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
				cjsfg="$jsfg" cjpfg="$jpfg"

			[[ ${multiframe_modules[*]} == *$module* ]] &&
				local is_multiframe=true

			[[ $joiner_next_bg == *%{O[0-9]*}* ]] &&
				local has_bg_distance=true

			[[ ($cjsfg && $cjpfg) && ! $labeled ]] &&
				eval "output_content=\"$output_content\""

			#[[ $module == volume ]] &&
			#echo "$module: $volume_padding, $output_content" >> j.log
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
		#fi

		#[[ ! $2 && $module =~ time|mpd ]] &&
		#	echo "${module^^}: ${!module}" >> md.log

		if [[ ! $2 ]]; then
			for module_to_print in "${modules_to_print[@]}"; do
				echo "$module_to_print" > $fifo
			done
		fi
	else
		[[ $short != $last_module && ${!module} ]] && local separator="$bar_separator"
		[[ ${!module} && $frame_type && ! ${multiframe_modules[*]} =~ $module ]] &&
			#output_content="$module_frame_start$output_content$module_frame_end$separator"
			output_content="$module_frame_start$output_content$module_frame_end"
		eval echo \"${module^^}:"$output_content$separator"\" > $fifo

		#[[ $module == volume ]] &&
		#	~/.orw/scripts/notify.sh -t 22 "V: ${!output_content}"
	fi
}

set_colors() {
	[[ $colorscheme ]] ||
		colorscheme=~/.config/orw/colorschemes/${1:-auto_generated}.ocs
		#colorscheme=${1:-~/.config/orw/colorschemes/auto_generated.ocs}

	color_variables="$(set | awk -F '=' '$1 ~ "[bf][gc]$" { print $1 }' | xargs)"
	unset $color_variables

	eval $(awk '\
		/#bar/ { nr = NR }

		nr && NR > nr {
			if($1 ~ "^(b?bg|.*c)$") c = $2
			else {
				l = length($1)
				p = substr($1, l - 1, 1)
				c = "%{" toupper(p) $2 "}"
			}

			if($1) print $1 "=\"" c "\""
		}

		nr && (/^$/) { exit }' $colorscheme)

	[[ $bottom ]] && bg=$bbg
	[[ $bar_frame_width ]] && bar_frame="-R$bfc -r $bar_frame_width"
}

set_frame() {
	#local args="$1"
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
	else
		unset frame_type {module_,}frame_{start,end}
	fi
}

#make_counter_content() {
#	counter_content='$padding$counter$padding'
#}

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

assign_width_args() {
	case $arg in
		a)
			bar_width=$display_width
			width=adjustable
			;;
		*) bar_width=$arg
	esac
}

while getopts :xywhspcrafFSjinemdvtDNPTCVOWARLX opt; do
	args=''
	#[[ ! ${!OPTIND} == -[[:alpha:]] ]] &&
	#	args="${!OPTIND}" && shift 1
	if [[ ${!OPTIND} != -[[:alpha:]] ]]; then
		args="${!OPTIND}"
		((joiner_start_index)) && ((joiner_start_index--))
		shift 1
	fi

	case $opt in
		a) font_size=$args;;
		r) bar_content+='%{r}';;
		c)
			[[ $colorscheme ]] &&
				bar_content+='%{c}' ||
				set_colors $args
			;;
		#f) set_frame $args;;
		[xy]) assign_args $opt;;
		w) assign_args width;;
		h) bar_height=$args;;
		s) bar_separator="%{B-}%{O$args}";;
		p) padding="%{O$args}";;
		f)
			#((frame_size)) ||
			#	frame_size=${args#*:}
			frame_size=${args#*:}
			set_frame
			;;
		F) bar_frame_width="$args";;
		n)
			bar_name="$args"

			ls /tmp/${bar_name}*joiner* 2> /dev/null | xargs -r rm

			fifo=$root_dir/${bar_name}.fifo
			[[ -p $fifo ]] && rm $fifo
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

				#for joiner_arg in ${args//,/ }; do
				#	if [[ $joiner_arg == [0-9]* ]]; then
				#		joiner_distance=$joiner_arg
				#	else
				#		#joiner_initial_distance=${joiner_arg#*:}
				#		#[[ ${joiner_arg:1:1} == s ]] &&
				#		#	joiner_next_bg="\$${joiner_group:1:1}sbg$joiner_initial_distance" ||
				#		#	joiner_start_bg="\$${joiner_group::1}sbg"

				#		#joiner_fc="%{B\$${joiner_group::1}fc}"
				#		#joiner_sbg="%{B\$${joiner_group::1}sbg}"

				#		switch_bg=${joiner_arg:1}
				#	fi
				#done

				assign_args joiner
				[[ $joiner_padding ]] ||
					joiner_padding="%{O20}"

				#if [[ $switch_bg ]]; then
				#	[[ $switch_bg == s ]] &&
				#		joiner_next_bg="$joiner_fc" ||
				#		joiner_next_bg="$joiner_sbg"
				#else
				#	joiner_start+="$joiner_sbg"
				#fi

				#if [[ $switch_bg == s ]]; then
				#	joiner_next_bg="$joiner_sbg"
				#else
				#	[[ $switch_bg ]] &&
				#		joiner_next_bg="$joiner_fc"
				#	joiner_start+="$joiner_sbg"
				#fi

				#~/.orw/scripts/notify.sh -t 11 "$joiner_start   $joiner_end   $joiner_next_bg"

				joiner_groups+=( "${joiner_group//[- ]}" )
				#joiners+=( "$joiner_distance $joiner_start $joiner_end $joiner_next_bg $switch_bg" )
				joiners+=( "$joiner_distance $frame_start $frame_end $joiner_padding $switch_bg" )
				#get_joiner_frame ${joiner_groups[-1]::1} $switch_bg
				#echo "JOINER_${#joiner_groups[*]}_START:$joiner_start" > $fifo &
				#echo "JOINER_${#joiner_groups[*]}_END:$joiner_end" > $fifo &
				unset switch_bg joiner_{distance,padding,next_bg}

				#joiners+=( "" )

				#echo "${joiner_group//[- ]}" >> $active_joiner_modules
				#echo >> $missing_joiner_modules
				#echo "${joiner_group//[- ]}" >> $missing_joiner_modules
				#echo ${joiner_group//[- ]} >> $joiner_modules

				[[ $joiner_modules_file ]] ||
					joiner_modules_file=/tmp/${bar_name}_joiner_modules
				[[ $joiner_lock_file ]] ||
					joiner_lock_file=/tmp/${bar_name}_joiner.lock
				echo >> $joiner_modules_file
				#echo -e '\n' >> $joiner_start_modules
				#echo -e '\n' >> $joiner_end_modules

				#if ((${#joiners[*]} == 3)); then
				#	echo HRE, $joiner_group
				#	exit
				#fi

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

			exec 11< $joiner_modules_file

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
				fifos_to_remove+=( /tmp/$module.fifo )

			shorts[$module]="$opt"
			modules+=( $module )
			last_module=$opt
	esac
done

bar_content+='%{B-}'

get_display_properties
set_x

((bar_y)) ||
	bar_y=$default_y_offset

[[ $bottom_y ]] &&
	bar_y=$((y + display_height - (bar_y + bar_height + 2 * bar_frame_width)))

#[[ $width == adjustable ]] && ((bar_width)) ||
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

font="Iosevka Orw:style=Semibold:size=$font_size"
bold_font="Iosevka Orw:style=Heavy:size=$font_size"
icon_font="material:size=$icon_size"
#bar_font="Iosevka Orw:size=8"
bar_font="SFMono-Medium:size=11"
bar_font="SFMono-Medium:size=$icon_size"
bar_font="SFMono-Medium:size=11"
#font_offset=$((${font##*=} - ${bar_font##*=}))
font_offset=$((font_size - (icon_size - font_size / 5) - ((frame_size + 1) / 2)))
font_offset=-3

#echo $font_offset, $frame_size, 
#exit

#echo POWER: $sbg, ${sbg:3:7}, $power_bar_bg, $power_bar_fg, $power_bar_content #, $power_bar_geometry
#echo POWER: $power_bar_main_font $power_bar_content
##launch_power_bar
#exit

#echo ${joiners[1]}
#exit

#for module in ${!joiner_modules[*]}; do
#	module_index=${joiner_modules[$module]}
#	echo $module, $module_index
#	#echo ${joiner_groups[module_index]}
#	sed -n "${module_index}p" $active_joiner_modules
#done
#exit

#echo ${fifos_to_remove[*]}
#exit

remove_fifos() {
	local fifo
	for fifo in ${fifos_to_remove[*]}; do
		[[ -p $fifo ]] && rm $fifo
	done

	exec 11<&-
}

trap self_kill INT
trap update_colors USR1
trap remove_fifos INT EXIT KILL TERM

run_modules() {
	for module in ${modules[*]}; do
		set_module_colors ${shorts[$module]}
		#[[ $module != windows ]] &&
		#	check_$module > $fifo &
		if [[ ! $module =~ windows|tiling ]]; then
			if [[ $1 == reload ]]; then
				echo RELOADING $module..
				local $module actions_{start,end}
				get_$module
				type -t set_${module}_actions &> /dev/null && set_${module}_actions
				[[ ${!module} ]] && print_module $module

				if [[ ${!module} ]]; then
					echo RELOAD $module, $Lfc
					echo ${!module}
				fi
			else
				check_$module > $fifo &
			fi
		fi
	done
}

bar_options='(A([0-9]?:?.*:$|$)|[BFU][#-]|[TO][0-9-]+$|[lcr]$|[+-][ou])'

adjust_bar_width() {
	while read content; do
		if [[ $width == adjustable ]]; then

			#awk -F '%{|}' '
			#		{
			#			fs = sprintf("%.0f", '$font_size' / 1.4)
			#			is = sprintf("%.0f", '$icon_size' * 1.8)
			#			is = sprintf("%.0f", '$icon_size' * 1.3)

			#			for(f = 1; f < NF; f++) {
			#				print "F", $f
			#				if($f ~ /O[0-9]+$/) o += substr($f, 2)
			#				else if($f ~ "C") c = !c
			#				else if($f !~ /^'$bar_options'/) {
			#					if ($f ~ "^I") i = !i
			#					#else l += length($f) * ((i) ? is : ($f ~ "━") ? 10 : fs)
			#					else {
			#						ml = length($f) * ((i) ? is : ($f ~ "━") ? 10 : fs)
			#						print "HERE", ml, f, "^" $f "^"
			#						if (c) cl += ml
			#						l += ml
			#					}
			#				}
			#			}
			#		} END { print int(o + l), cl }' <<< "$content"
			#exit



			old_width=$content_width
			#content_width=$(awk -F '%{|}' '
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
							#else if($f == "C") c = !c
							else if($f == "C") {
								#if (!c) {
								#	cl = l - cl / 2 + o
								#}
								#c = !c

								if (c) cl = int(l - cl / 2 + o)
								c = !c
							} else if($f !~ /^'$bar_options'/) {
								#if ($f ~ "^I[+-][0-9]") i = !i
								if ($f ~ "^I[0-9-]?$") i = !i
								#else l += length($f) * ((i) ? is : ($f ~ "━") ? 10 : fs)
								else {
									ml = length($f) * ((i) ? is : ($f ~ "━") ? 9 : fs)
									if (c) cl += ml
									l += ml
								}
							}
						}
					} END { print int(o + l), cl }' <<< "$content")

			#echo $content
			#awk -F '%{|}' '
			#	{
			#		fs = sprintf("%.0f", '$font_size' / 1.4)
			#		is = sprintf("%.0f", '$icon_size' * 1.3)

			#		for(f = 1; f < NF; f++) {
			#			if($f ~ /O[0-9]+$/) { print $f; o += substr($f, 2) }
			#			else if($f !~ /^'$bar_options'/) {
			#				if ($f ~ "^I") {
			#					i = !i
			#					print "HERE", $f, length($f) * ((i) ? is : fs)
			#				} else {
			#					if (i) print "THERE", o, l, $f, length($f) * ((i) ? is : fs)
			#					l += length($f) * ((i) ? is : fs)
			#				}
			#			}
			#		}
			#	} END { print o, l, int(o + l) }' <<< "$content"
			##continue
			#exit

			#echo ${!adjust_center}: $content_width
			#return

			#echo -e "$content"
			#continue

			#unset bar_x
			#set_x $content_width
			#echo $conternt_width: $bar_x
			#return

			if ((old_width != content_width)); then
				#~/.orw/scripts/notify.sh -t 3 "CW: $center_width"

				unset bar_x
				set_x $content_width
				#~/.orw/scripts/notify.sh -t 11 "CW: $content_width $bar_x"
				#~/.orw/scripts/notify.sh -t 11 "CW: $content_width $bar_x"
				#~/.orw/scripts/notify.sh -t 11 "CW: $content_width $bar_x"
				xdotool search --name "^$bar_name$" \
					windowsize $content_width $bar_height \
					windowmove $bar_x $bar_y
			fi
		fi

		echo -e "$content"
		#[[ $bar_name == *dock* ]] &&
		#	echo -e "$content_width: $content" > l.log
	done
}

#geometry='1000x30+500+20'

waiting_icon=$(get_icon 'waiting_icon')
#modules=( mpd )
run_modules

#echo $bar_content
#((frame_size)) && module_frame_size="-u $frame_size"
#IFS=':' read mod con < $fifo
#eval ${mod,,}=\""$con"\"
#echo $bar_content
#eval echo -e \""$bar_content"\"
#exit

#modules=( date )
#bar_content='%c$date'
main_pid=$$

#echo $geometry
#exit

#adjust_bar_width() {
#	while read content; do
#			#content_width=$(awk -F '%{|}' '
#		#read content_width $adjust_center <<< \
#			#$(awk -F '%{|}' '
#			awk -F '%{|}' '
#				{
#					fs = sprintf("%.0f", '$font_size' / 1.4)
#					is = sprintf("%.0f", '$icon_size' * 1.8)
#					is = sprintf("%.0f", '$icon_size' * 1.3)
#
#					for(f = 1; f < NF; f++) {
#						if($f ~ /O[0-9]+$/) { o += substr($f, 2); print "O", $f }
#						#else if($f == "C") c = !c
#						else if($f == "C") {
#							print "HERE", $f
#
#							if (c) {
#								cl = l + cl / 2 + o
#							}
#							print "hre", cl, l, o
#							c = !c
#
#							#c = !c
#							#if (c) {
#							#	cl = l + o
#							#} else {
#							#	cl = l - cl / 2 + o
#							#}
#						} else if($f !~ /^'$bar_options'/) {
#							#if ($f ~ "^I[+-][0-9]*$") i = !i
#							if ($f ~ "^I[0-9-]?$") i = !i
#							#else l += length($f) * ((i) ? is : ($f ~ "━") ? 10 : fs)
#							else {
#								ml = length($f) * ((i) ? is : ($f ~ "━") ? 10 : fs)
#								if (c) cl += ml
#								l += ml
#								if (ml) {
#									print $f " " ml " - " i " " is " " fs " " c " " cl
#									#if (cl) print "CL:", cl
#								}
#							}
#						}
#					}
#				} END { print o, l, cl }' <<< "$content"
#	done
#}
#
#while IFS=':' read module content; do
#	eval ${module,,}=\""$content"\"
#	#[[ $module == LAUNCHERS ]] && eval echo \""$content"\" >> l.log
#	eval echo -e \""$bar_content"\"
#	#eval echo -e \""$bar_content"\" >> rec.log
#	#[[ $module == DISPLAY ]] &&
#	#eval echo -e \"$module:   "$content"\" >> dis.log
#	#[[ $module == VOLUME ]] &&
#	#	eval echo \""L: $volume"\" >> v.log
#done < $fifo | adjust_bar_width
#exit

#geometry="1700x26+100+900"
#echo $geometry
#exit

while IFS=':' read module content; do
	eval ${module,,}=\""$content"\"
	#[[ $module == LAUNCHERS ]] && eval echo \""$content"\" >> l.log
	#[[ $module == WORKSPACES ]] && sleep 3
	eval echo -e \""$bar_content"\"
	#((after_ws)) && ~/.orw/scripts/notify.sh "M: $module"
	#[[ $module == WORKSPACES ]] && sleep 3 && after_ws=1
	#eval echo -e \""$bar_content"\" >> rec.log
	#[[ $module == DISPLAY ]] &&
	#eval echo -e \"$module:   "$content"\" >> dis.log
	#[[ $module == VOLUME ]] &&
	#	eval echo \""L: $volume"\" >> v.log
done < $fifo | adjust_bar_width |
	lemonbar -d -B$bg -F$fg -u 0 \
	-f "$font" -o $font_offset \
	-f "$bold_font" -o $font_offset \
	-f "$bar_font" -o $((font_offset + 1)) \
	-f "$icon_font" -o $((font_offset + 0)) \
	-a 150 -u ${frame_size:-0} $bar_frame \
	-g "$geometry" -n "$bar_name" | bash &

sleep 0.5
xdo lower -N Bar

wait
exit

while true; do
	while true; do
		IFS=':' read module content < $fifo
		eval ${module,,}=\""$content"\"
		eval echo -e \""$bar_content"\"
	done | adjust_bar_width |
		lemonbar -d -B$bg -F$fg -u 0 \
		-f "$font" -o $font_offset \
		-f "$bold_font" -o $font_offset \
		-f "$bar_font" -o $((font_offset + 1)) \
		-f "$icon_font" -o $((font_offset + 1)) \
		-a 150 -u $frame_size $bar_frame \
		-g "$geometry" -n "$bar_name" | bash &
	current_pid=$!
	wait $current_pid
	kill $current_pid
done
exit

while true; do
	while true; do
		IFS=':' read module content < $fifo
		#while IFS=':' read module content; do
		eval ${module,,}=\""$content"\"
		eval echo -e \""$bar_content"\"
		#done < $fifo
	done | adjust_bar_width |
		lemonbar -d -B$bg -F$fg -u 0 \
		-f "$font" -o $font_offset \
		-f "$bold_font" -o $font_offset \
		-f "$bar_font" -o $((font_offset + 1)) \
		-f "$icon_font" -o $((font_offset + 1)) \
		-a 150 -u $frame_size $bar_frame \
		-g "$geometry" -n "$bar_name" | bash &
	current_pid=$!
	wait $current_pid
	kill $current_pid
done
exit

sleep 0.5
xdo lower -N Bar
wait
exit

while true; do
	while IFS=':' read module content; do
		eval ${module,,}=\""$content"\"
		eval echo -e \""$bar_content"\"
	done < $fifo &

	main_pid=$!
	wait $main_pid
	kill $main_pid

	#~/.orw/scripts/notify.sh -t 11 "msfg: $Wsfg"
	~/.orw/scripts/notify.sh -t 5 "RELOAD"

	ps -C ${0##*/} --sort=start_time -o pid= | sed '1d' | xargs kill
	run_modules
	#~/.orw/scripts/notify.sh -t 11 "msfg: $Wsfg"
done | adjust_bar_width |
	lemonbar -d -B$bg -F$fg -u 0 \
	-f "$font" -o $font_offset \
	-f "$bold_font" -o $font_offset \
	-f "$bar_font" -o $((font_offset + 1)) \
	-f "$icon_font" -o $((font_offset + 1)) \
	-a 150 -u $frame_size $bar_frame \
	-g "$geometry" -n "$bar_name" | bash &

sleep 0.5
xdo lower -N Bar
exit

while true; do
	while IFS=':' read module content; do
		#eval ${module,,}_module=\""$content"\"
		eval ${module,,}=\""$content"\"
		#[[ $module == JOINER* ]] &&
		#	~/.orw/scripts/notify.sh "$module: $content"
		eval echo -e \""$bar_content"\"
		#eval echo -e \""${bar_content##O200}"\" >> bar.log
	done < $fifo | adjust_bar_width |
		lemonbar -d -B$bg -F$fg -u 0 \
		-f "$font" -o $font_offset \
		-f "$bold_font" -o $font_offset \
		-f "$bar_font" -o $((font_offset + 1)) \
		-f "$icon_font" -o $((font_offset + 1)) \
		-a 150 -u $frame_size $bar_frame \
		-g "$geometry" -n "$bar_name" | bash &
		##-g 1760x30+80+20 | bash &

	sleep 0.5
	xdo lower -N Bar

	main_pid=$!
	wait $main_pid
	kill $main_pid
	exit

	#~/.orw/scripts/notify.sh -t 11 "msfg: $Wsfg"

	ps -C ${0##*/} --sort=start_time -o pid= | sed '1d' | xargs kill
	run_modules
	#~/.orw/scripts/notify.sh -t 11 "msfg: $Wsfg"
done
