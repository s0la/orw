#!/bin/bash

get_mpd_stats() {
	mpc status -f '%artist%\n%title%' | awk '
		BEGIN {
			sa = int("'"$scroll_area"'")
			d = int("'"${scroll_delay:-0}"'")
			pbs = int("'"${mpd_progressbar_step:-10}"'")
			li = "'$limiter_icon'"
			st = "'"$mpd_time"'"
			pbi = "'"$mpd_progressbar_icon"'"
		}

		function make_progressbar(sp, ep) {
			cpbs = ""
			for (i=sp; i<sp+ep; i++)
				cpbs = cpbs "%{A:mpc -q seek " (i + ((i < pbs / 2) ? 0 : 1)) * spbs "%:}" pbi "%{A}"
			return cpbs
		}

		function get_seconds(time) {
			tl = split(time, ta, ":")
			ctm = ta[tl - 1]
			cts = ta[tl]

			return ctm * 60 + cts
		}

		{
			switch (NR) {
				case 1:
					a = $0
					break
				case 2:
					t = $0
					break
				case 3:
					s = substr($1, 2, length($1) - 2)
					p = substr($NF, 2, length($NF) - 3)

					spbs = int(100 / pbs)
					es = int(sprintf("%.0f", int(p) / spbs))
					rs = pbs - es

					pb = "%{T3}\\${cjpfg:-\\${pbefg:-\\$mpfg}}" make_progressbar(0, es)
					pb = pb "\\${cjsfg:-\\${pbfg:-\\$msfg}}" make_progressbar(es, rs) "%{T-}"

					split($3, ert, "/")
					et = ert[1]
					tt = ert[2]
					ft = "%{T2}" et "┃%{T-}" tt
					ft = "%{T2}" et "❙%{T-}" tt
					ft = "%{T2}" et "❚%{T-}" tt
					to = "'"$mpd_time_offset"'"
					teo = "'"${mpd_time_ending_offset:-$mpd_time_offset}"'"
					ft = to "%{T2}" et "|%{T-}" tt teo
					#ft = to "%{T2}" et "❙%{T-}" tt teo
					#ft = "%{T2}" et "┃%{T-}" tt

					es = get_seconds(et)
					ts = get_seconds(tt)
					ss = es % int(ts / pbs)

					ns = "❙"
					ns = "❚"
					ns = "┃"
					ns = "|"
					fn = a ns t
					nsl = length(ns)
					fnl = length(fn)
					sal = fnl - sa + 2 * d + 1
					ct = (sal) ? es % sal : fnl
					rs = (fnl > sa) ? 1 : int(ts / pbs) - ss

					si = (ct < d || fnl <= sa) ? 0 : (ct >= fnl - sa + d) ? fnl - sa : ct - d

					al = length(a)
					bl = al + (al <= si + sa)

					if (fnl > sa || st) {
						rs = 1

						if (st && fnl <= sa) fn = fn "  " ft
						else {
							fn = li " " substr(fn, si + 1, sa) " " li
							lil = length(li) + 1
						}
					} else rs = int(ts / pbs) - ss

					if (si < al) {
						if (si + sa > al) {
							fn = "%{T2}" substr(fn, 1, bl + lil - si) \
								"%{T-}" substr(fn, bl + lil - si + nsl)
						} else fn = "%{T2}" fn "%{T-}"
					}
				case 4:
					v = $2
					break
			}
		} END {
			if (s) printf "%s\n%d\n%s\n%s\n%s", s, rs, v, pb, fn
		}'
}

get_mpd() {
	local show_buttons mpd_{info,{progress,}bar}
	IFS=$'\n' read -d '' status remain_sleep volume_level mpd_bar song_info \
		<<< $(get_mpd_stats)

	if [[ $status ]]; then
		if [[ $mpd_volume_visible ]]; then
			set_volume="mpc -q volume ${volume_level%*\%}"
			action1="$toggle_mpd_volume_buttons && $set_volume"
			action4='mpc -q volume +5'
			action5='mpc -q volume -5'
			actions_start="%{A:$action1:}%{A4:$action4:}%{A5:$action5:}"
			actions_end="%{A}%{A}%{A}"
			volume="$actions_start%{T2}$volume_level%{T1}$actions_end"

			if [[ $change == mixer || ! $change ]]; then
				show_buttons=$(awk '$1 == "mpd_volume_buttons" { print $NF }' $bar_config)
				((show_buttons)) &&
					volume="$mpd_volume_down_button$volume$mpd_volume_up_button"

				[[ $change ]] &&
					~/.orw/scripts/system_notification.sh mpd osd &> /dev/null
			fi
		fi

		[[ $mpd_bar ]] &&
			eval "mpd_progressbar=\"$mpd_progressbar_components\""

		eval "mpd_info=\"$mpd_info_components\""
	fi

	local mpd_full_form=$(sed -n "s/mpd_full.* //p" $bar_config)
	((mpd_full_form)) &&
		local mpd_components="$full_mpd_components" ||
		local mpd_components="$short_mpd_components"

	if [[ $mpd_buttons_components == *toggle* ]]; then
		[[ $status == playing ]] &&
			toggle_icon=pause || toggle_icon=play
		toggle="%{A:mpc -q toggle:}$(get_icon "^${toggle_icon}${toggle_style}=")%{A}"
	fi

	eval mpd_buttons=\""$mpd_buttons_components"\"
	#~/.orw/scripts/notify.sh "$mpd_buttons_components"

	eval mpd=\""$mpd_components"\"
	[[ $mpd_fs && $mpd != *$mpd_fs* ]] && mpd="$mpd_fs$mpd"
	#[[ $mpd_fe && $mpd != *%{B${!frame_color}}${mpd_fe#*\}}* ]] && mpd+="$mpd_fe"
	[[ $mpd_fe && $mpd != *${mpd_fe/\$$frame_color/${!frame_color}}* ]] && mpd+="$mpd_fe"
	#~/.orw/scripts/notify.sh -t 22 "$msbg, $mpbg, $mpd"
	unset change
}

print_mpd() {
	while
		get_mpd
		print_module mpd
		[[ $status == playing ]]
	do
		sleep $remain_sleep
	done &

	playing=$(mpc status | awk 'NR == 2 { print $1 ~ "playing" }')
	[[ $change == player ]] && ((playing)) && mpid=$!
}

assign_components() {
	[[ $2 ]] && local value="$2"

	while read -d ' ' component; do
		[[ ${#component} -gt 1 ]] &&
			component_value="${component:1}" \
			component="${component::1}" ||
			component_value=""
		assign_${1}_components
	done <<< $(sed 's/[^a-zA-Z]*/& /g' <<< "$value")
}

assign_mpd_toggle_components() {
	case $component in
		i) mpd_toggle_components='$mpd_info';;
		t) mpd_toggle_components='$mpd_time';;
		v) mpd_toggle_components='$volume';;
		b) mpd_toggle_components='$mpd_buttons';;
		p) mpd_toggle_components='$mpd_progressbar';;
	esac
}

assign_mpd_info_components() {
	case $component in
		s) scroll_area=$component_value;;
		d) scroll_delay=$component_value;;
		o) mpd_info_components+="%{O$component_value}";;
		#i) mpd_info_components+='$mpfg$song_info';;
		i) mpd_info_components+='$song_info';;
	esac

	#mpd_info_components="$mpd_bg$mpd_fg$mpd_info_components"
	#mpd_info_components="$mpd_bg$mpfg$mpd_info_components"
}

assign_mpd_progressbar_components() {
	case $component in
		d) mpd_progressbar_icon="■";;
		s) mpd_progressbar_step="$component_value";;
		o) mpd_progressbar_components+="%{O$component_value}";;
		b) mpd_progressbar_components+='$mpd_bar';;
		#b) mpd_progressbar_components+="$mpd_bg$mpd_fg$mpd_bar";;
	esac

	#mpd_progressbar_components="$mpd_bg$mpd_fg$mpd_progressbar_components"
}

assign_mpd_buttons_components() {
	local mpd_button

	case $component in
		p) mpd_button=prev;;
		n) mpd_button=next;;
		s) mpd_button=stop;;
		t)
			mpd_button=toggle
			toggle_style=$icon_style
			;;
		c)
			[[ $icon_style ]] &&
				icon_style='' || icon_style='_circle_empty'
			;;
		#o) mpd_buttons_components+="%{O$component_value}";;
		o) local mpd_buttons_offset="%{O$component_value}";;
		#o)
		#	[[ $mpd_buttons_offset ]] &&
		#		mpd_buttons_ending_offset="%{O$component_value}" ||
		#		mpd_buttons_offset+="%{O$component_value}"
		#	;;
		f)
			mpd_button_start_frame="%{U$msfc}%{B$msfc}%{O1}%{+u}%{+o}$mpd_bg"
			mpd_button_end_frame="%{B$msfc}%{O1}%{-u}%{-o}$mpd_bg"
			mpd_button_bg="${mbbg:-$msbg}"
			;;
		P) mpd_button_padding="%{O$component_value}";;
		S) mpd_button_separator="%{O$component_value}";;
	esac

	if [[ $mpd_button ]]; then
		[[ $mpd_button == toggle ]] &&
			mpd_button_icon='$toggle' ||
			mpd_button_icon="$(get_icon "${mpd_button}${icon_style}=")" \
			mpd_button_icon="%{A:mpc -q $mpd_button:}$mpd_button_icon%{A}"
		#mpd_buttons+="$mpd_button_icon$mpd_button_separator"
		mpd_buttons_components+="$mpd_button_start_frame$mpd_button_bg"
		mpd_buttons_components+="$mpd_button_padding%{T4}$mpd_fg$mpd_button_icon%{T-}$mpd_button_padding"
		mpd_buttons_components+="$mpd_button_end_frame$mpd_button_separator"
		#~/.orw/scripts/notify.sh -t 22 "MBS: $mpd_buttons"
		#mpd_buttons="$mpd_bg$mpd_fg%{T4}$mpd_buttons%{T-}"
	elif [[ $mpd_buttons_offset ]]; then
		[[ $mpd_buttons_components == *T* ]] &&
			mpd_buttons_components="${mpd_buttons_components%\%*}"
		mpd_buttons_components+="$mpd_buttons_offset"
	fi
	#else
	#	#[[ $mpd_buttons && $mpd_button_separator ]] && ~/.orw/scripts/notify.sh -t 22 "pre MBS: $mpd_buttons" && mpd_buttons="${mpd_buttons%\%*}" &&
	#		#~/.orw/scripts/notify.sh -t 22 "post MBS: $mpd_buttons"
	#	[[ $mpd_buttons && $mpd_button_separator ]] &&
	#		mpd_buttons="${mpd_buttons%\%*}" &&
	#		unset mpd_button_separator
	#		~/.orw/scripts/notify.sh -t 22 "post MBS: $mpd_buttons"
	#	#[[ $mpd_buttons && $mpd_button_separator ]] &&
	#	#	mpd_buttons="${mpd_buttons%\%*}" && unset mpd_button_separator ||
	#	#	return
	#fi

	#mpd_buttons="$mpd_bg$mpd_fg%{T4}$mpd_buttons%{T-}"
	#mpd_buttons_components="$mpd_bg$mpd_fg%{T4}$mpd_buttons_offset"
	#mpd_buttons_components+="$mpd_buttons$mpd_buttons_ending_offset%{T-}"
	#mpd_buttons_components="$mpd_bg$mpd_fg$mpd_button_padding$mpd_buttons_components$mpd_button_padding"
	#mpd_buttons_components="$mpd_bg$mpd_fg$mpd_buttons_components"
	#~/.orw/scripts/notify.sh -t 22 "BUTT: $((cnt++)) $mpd_buttons_components"
}

assign_mpd_time_components() {
	case $component in
		t) mpd_time=true;;
		o)
			[[ ! $mpd_time_offset ]] &&
				mpd_time_offset="%{O$component_value}" ||
				mpd_time_ending_offset="%{O$component_value}"
			;;
	esac
}

restore_color() {
	[[ $restore_start_color ]] &&
		eval "mpd_${mpd_module}_components='$restore_end_color$mpd_{mpd_module}_components'"
	[[ $restore_end_color ]] &&
		eval "mpd_${mpd_module}_components+='$restore_end_color'"
	#~/.orw/scripts/notify.sh -t 11 "$1 - $mpd_buttons_components"
	unset restore_{start,end}_color mpd_bg #mpd_fe
	#mpd_bg='%{B-}'
}

make_mpd_content() {
	#limiter_icon='%{I}%{I}'
	limiter_icon='%{I}%{I}'
	#local mpd_bg=$msbg mpd_fg=$msfg
	local mpd_{padding,bg}
	[[ ${joiner_modules[m]} ]] ||
		mpd_padding=$padding mpd_bg=${msbg:-$sbg} mpd_fs="$mfs$mpd_bg" mpd_fe="$mfe"
	[[ $mpd_fe =~ ^%\{B\$([^\}]*)\} ]] && frame_color=${BASH_REMATCH[1]}

	for arg in ${1//,/ }; do
		value=${arg:2}
		arg=${arg%%:*}

		#mpd_components+="$mpd_bg$mpd_fg"

		case $arg in
			o) mpd_components+="%{O$value}";;
			[PS])
				eval mpd_${value}g="\$m${arg,}${value:-g\$m${arg,}f}g"
				eval switch_${value}g_color="\$m${arg,}${value:-g\$m${arg,}f}g"
				;;
			R)
				[[ $value == s* ]] &&
					side=start || side=end side_frame_end=$mfe

				((${#value} > 1)) &&
					color="\${m${value:1:1}bg}" || color='%{B-}'
				eval restore_${side}_color="$color$side_frame_end"
				[[ $side_frame_end ]] && unset side_frame_end #mpd_fe
				#mpd_bg='%{B-}'
				;;
			[PS]) switch_color="\$m${arg,}${value:-g\$m${arg,}f}g";;
			P*) mpd_components+="\$mp${value:-g\$mpf}g";;
			t) assign_components mpd_time;;
			i)
				mpd_module=info mpd_module_fg=$mpfg
				#assign_components mpd_info
				#[[ $restore_end ]] && restore_end mpd_info
				#mpd_components+='$mpd_info'

				#if [[ ${switch_bg_color:-${switch_fg_color:-${restore_start_color:-$restore_end_color}}} ]]; then
				#	mpd_info_components="$restore_start_color$switch_bg_color$switch_fg_color$mpd_info_components$restore_end_color"
				#	unset {switch_{b,f}g,restore_{start,end}}_color
				#fi
				;;
			v)
				#mpd_module=volume
				read volume_{up,down}_icon <<< $(get_icon 'arrow_(right|left).*full' | xargs)
				toggle_mpd_volume_buttons="sed -i '/mpd_volume_buttons/ y/01/10/' \$bar_config"
				mpd_volume_down_button="%{A:mpc -q volume -5:}$volume_down_icon%{A}%{O10}"
				mpd_volume_up_button="%{O10}%{A:mpc -q volume +5:}$volume_up_icon%{A}"
				mpd_volume_visible=true
				mpd_volume="$mpd_bg$mpd_fg\$volume"

				mpd_components+='$mpd_volume'

				#if [[ ${switch_bg_color:-${switch_fg_color:-${restore_start_color:-$restore_end_color}}} ]]; then
				#	mpd_volume="$restore_start_color$switch_bg_color$switch_fg_color$mpd_volume$restore_end_color"
				#	unset {switch_{b,f}g,restore_{start,end}}_color
				#fi
				;;
			p)
				mpd_module=progressbar
				mpd_progressbar_icon="━"
				mpd_progressbar_step=10

				#assign_components mpd_progressbar
				#[[ $restore_end ]] && restore_end mpd_progressbar
				#mpd_components+='$mpd_progressbar'

				#if [[ ${switch_bg_color:-${switch_fg_color:-${restore_start_color:-$restore_end_color}}} ]]; then
				#	mpd_progressbar_components="$restore_start_color$switch_bg_color$switch_fg_color$mpd_progressbar_components$restore_end_color"
				#	unset {switch_{b,f}g,restore_{start,end}}_color
				#fi
				;;
			b)
				mpd_module=buttons mpd_module_fg=$msfg mpd_module_args="${value:-ptn}"

				#[[ $mpd_button_separator ]] && mpd_buttons="${mpd_buttons%\%*}"
				#~/.orw/scripts/notify.sh -t 22 "MB: $mpd_buttons, $mpd_button_separator"

				#if [[ ${switch_bg_color:-${switch_fg_color:-${restore_start_color:-$restore_end_color}}} ]]; then
				#	mpd_buttons="$restore_start_color$switch_bg_color$switch_fg_color$mpd_buttons$restore_end_color"
				#	unset {switch_{b,f}g,restore_{start,end}}_color
				#fi

				#assign_components mpd_buttons "$buttons"
				#[[ $restore_end ]] && restore_end mpd_buttons
				#mpd_components+='$mpd_buttons'
				;;
			T)
				mpd_module=toggle
				#[[ $value ]] &&
				#	short_mpd_components="$mpd_bg$mpd_fg\$mpd_toggle" &&
				#	while ((i < ${#value})); do
				#		case ${value:$((i++)):1} in
				#			b) mpd_short_module='%{T4}$mpd_buttons%{T-}';;
				#			p) mpd_short_module='$mpd_progressbar';;
				#			i) mpd_short_module='$mpd_info';;
				#			t) mpd_short_module='$mpd_time';;
				#			v) mpd_short_module='$volume';;
				#		esac
				#		short_mpd_components+="$mpd_short_module"
				#	done

				toggle_volume='mpc -q volume +1 && mpc -q volume -1'
				toggle_command="sed -i '/mpd_full/ y/01/10/' \$bar_config && $toggle_volume"
				toggle_icon=$(get_icon music)
				mpd_toggle_components="%{A:$toggle_command:}$toggle_icon%{A}"

				#[[ $restore_end ]] && restore_end short_mpd
				#mpd_components+="$mpd_bg$mpd_fg$mpd_toggle"
				;;
		esac

		if [[ $mpd_module ]]; then
			assign_components mpd_$mpd_module $mpd_module_args
			#eval mpd_${mpd_module}_components="$mpd_bg$mpd_fg\$mpd_${mpd_module}"
			mpd_components+="$mpd_bg${mpd_module_fg:-$mpd_fg}\$mpd_${mpd_module}"
			[[ $restore_start_color || $restore_end_color ]] && restore_color
			#~/.orw/scripts/notify.sh -t 22 "MB: $mpd_buttons, $mpd_progressbar_components"

			unset mpd_module{,_{args,{b,f}g}}
		fi

		#if [[ $module_arg ]]; then
		#	[[ $restore_end_color ]] && unset restore_end_color mpd_fe
		#	[[ $restore_start_color ]] && unset restore_start_color
		#	unset module_arg
		#fi
	done

	#~/.orw/scripts/notify.sh -t 22 "$mpd_components"

	full_mpd_components="$mpd_components"
	#short_mpd_components='$mpd_toggle$mpd_info$mpd_time'

	#mpd_content="$mpd_fs$mpd_bg\$mpd_padding\$mpd\$mpd_padding$mpd_fe"
	#mpd_content="$mpd_fs$mpd_bg\$mpd_padding\$mpd\$mpd_padding$mpd_fe"
	#mpd_content="$mpd_fs$mpd_bg\$mpd_padding\$mpd\$mpd_padding\$mpd_fe"
	mpd_content="$mpd_bg\$mpd_padding\$mpd\$mpd_padding"
}

switch_mpd_volume_buttons() {
	if [[ $mpd_volume_buttons ]]; then
		unset mpd_volume_{buttons,{up,down}_button}
	else
		read volume_{up,down}_icon <<< $(get_icon 'volume_(up|down).*full' | xargs)
		mpd_volume_down_button="%{A:mpc -q volume -5:}$volume_down_icon%{A}%{O10}"
		mpd_volume_up_button="%{O10}%{A:mpc -q volume +5:}$volume_up_icon%{A}"
		mpd_volume_buttons=true
	fi
}

check_mpd() {
	#local limiter_icon='%{I}%{I}'
	#local limiter_icon='%{I}%{I}'

	print_mpd

	while true; do
		change=$(mpc idle)
		[[ $change =~ player|mixer ]] && print_mpd
	done
}

trap switch_mpd_volume_buttons SIGRTMIN
