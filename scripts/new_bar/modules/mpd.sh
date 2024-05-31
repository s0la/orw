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

					pb = "%{T3}$pbefg" make_progressbar(0, es)
					pb = pb "$pbfg" make_progressbar(es, rs) "%{T-}"

					split($3, ert, "/")
					et = ert[1]
					tt = ert[2]
					ft = "%{T2}" et "┃%{T-}" tt
					ft = "%{T2}" et "|%{T-}" tt

					es = get_seconds(et)
					ts = get_seconds(tt)
					ss = es % int(ts / pbs)

					ns = ": "
					ns = " ┃ "
					ns = ":"
					ns = "┃"
					ns = "│"
					ns = "|"
					ns = "┃"
					fn = a ns t
					nsl = length(ns)
					fnl = length(fn)
					sal = fnl - sa + 2 * d + 1
					ct = (sal) ? es % sal : fnl
					rs = (fnl > sa) ? 1 : int(ts / pbs) - ss

					si = (ct < d || fnl <= sa) ? 0 : (ct >= fnl - sa + d) ? fnl - sa : ct - d

					#bl = length(a) + 1
					#if (si + sa <= bl) bl--
					#if (si + sa <= bl) sv = 1
					#print si + sa, bl, sv

					al = length(a)
					bl = al + (al <= si + sa)

					if (fnl > sa || st) {
						rs = 1

						if (st && fnl < sa) fn = fn "  " ft
						else {
							fn = li " " substr(fn, si + 1, sa) " " li
							lil = length(li) + 1
						}
					} else rs = int(ts / pbs) - ss

					#print fn

					#al = length(a) + 0
					#if (si + sa <= al) sv = 1

					##print si, bl, sa, bl + lil - si - sv, fn
					##print 1, fn "      " substr(fn, 1, bl + lil - si - sv)
					#print 1, fn "      " substr(fn, 1, bl + lil - (si + 0) - sv)
					#print 2, "%{T2}" substr(fn, 1, bl + lil - (si + 0) - sv)
					##print 3, "%{T-}" substr(fn, bl + lil - (si + 1) + nsl - sv)

					#print 1, fn "      " substr(fn, 1, al + lil - (si + 0) - sv)
					#print bl + lil - (si + 0) + nsl - sv

					if (si < al) {
						if (si + sa > al) {
							fn = "%{T2}" substr(fn, 1, bl + lil - si) \
								"%{T-}" substr(fn, bl + lil - si + nsl)
						} else fn = "%{T2}" fn "%{T-}"
					}

					#print length(a), a
					#print lil, li
					#print al + lil - si, fn
					#print al, lil, si, nsl, al + lil - si + nsl
					break

					al = length(a) + 1 + lil
					print fn, si, al - si

					if (si < al) 
						fn = "%{T2}" substr(fn, 1, al - si) \
							"%{T-}" substr(fn, al - si + 1)

					break
				case 4:
					v = $2
					break
			}
		} END {
			#print fn
			if (s) printf "%s\n%d\n%s\n%s\n%s", s, rs, v, pb, fn
		}'
}

#mpd_progressbar_icon="━"
#limiter_icon='%{I}%{I}'
#scroll_area=20
#while true; do
#	get_mpd_stats
#	exit
#	echo
#	sleep 1
#done
#exit

get_mpd() {
	local show_buttons mpd_{info,{progress,}bar}
	#IFS=$'\n' read -d '' status remain_sleep volume_level mpd_progressbar info \
	IFS=$'\n' read -d '' status remain_sleep volume_level mpd_bar song_info \
		<<< $(get_mpd_stats)

	#~/.orw/scripts/notify.sh -t 22 "INFO: $mpd_info"

	if [[ $status ]]; then
		if [[ $mpd_volume ]]; then
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

				#[[ $change ]] && ~/.orw/scripts/notify.sh "CH: $change"
				#sleep 2

				[[ $change ]] &&
					~/.orw/scripts/system_notification.sh mpd osd &> /dev/null
			fi
		fi

		[[ $mpd_bar ]] &&
			eval "mpd_progressbar=\"$mpd_progressbar_components\""

		#[[ $change ]] && ~/.orw/scripts/notify.sh "CH: $song_info"
		eval "mpd_info=\"$mpd_info_components\""
	#else
	#	info="not_playing.."
	fi

	if [[ $mpd_components =~ toggle ]]; then
		[[ $status == playing ]] &&
			toggle_icon=pause || toggle_icon=play
		toggle="%{A:mpc -q toggle:}$(get_icon "mpd_${toggle_icon}_${toggle_style}icon")%{A}"
	fi

	eval mpd=\""$mpd_components"\"
	unset change
}

print_mpd() {
	#~/.orw/scripts/notify.sh "EX: $mpid"
	#echo "EX: $mpid" >> pids.log

	#((mpid)) && kill $mpid && unset mpid
	if ((mpid)); then
		while [[ -f $joiner_lock_file ]]; do
			sleep 0.01
		done
		kill $mpid
		#echo "KILLED" >> mpd.log
		unset mpid
	fi

	while
		get_mpd
		print_module mpd
		[[ $status == playing ]]
	do
		sleep $remain_sleep
	done &
	#mpid=$!
	#~/.orw/scripts/notify.sh "NEW: $mpid"

	playing=$(mpc status | awk 'NR == 2 { print $1 ~ "playing" }')
	[[ $change == player ]] && ((playing)) && mpid=$!
	#echo "NEW: $status $mpid" >> pids.log
}

#print_mpd() {
#	get_mpd
#	print_module mpd
#}

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

assign_mpd_info_components() {
	case $component in
		s) scroll_area=$component_value;;
		t) mpd_time=true;;
		d) scroll_delay=$component_value;;
		o) mpd_info_components+="%{O$component_value}";;
		i) mpd_info_components+='$mpfg$song_info';;
	esac
}

assign_mpd_progressbar_components() {
	case $component in
		d) mpd_progressbar_icon="■";;
		s) mpd_progressbar_step="$component_value";;
		o) mpd_progressbar_components+="%{O$component_value}";;
		b) mpd_progressbar_components+='$mpd_bar';;
	esac
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
				icon_style='' || icon_style='circle_'
			;;
		o) mpd_buttons+="%{O$component_value}";;
		S) mpd_button_separator="%{O$component_value}";;
	esac

	if [[ $mpd_button ]]; then
		[[ $mpd_button == toggle ]] &&
			mpd_button_icon='$toggle' ||
			mpd_button_icon="$(get_icon "mpd_${mpd_button}_${icon_style}icon")" \
			mpd_button_icon="%{A:mpc -q $mpd_button:}$mpd_button_icon%{A}"
		mpd_buttons+="$mpd_button_icon$mpd_button_separator"
	fi
}

make_mpd_content() {
	for arg in ${1//,/ }; do
		#value=${arg#*:}
		value=${arg:2}
		arg=${arg%%:*}

		case $arg in
			o) mpd_components+="%{O$value}";;
			[PS]) switch_color="\$m${arg,}${value:-g\$m${arg,}f}g";;
			P*) mpd_components+="\$mp${value:-g\$mpf}g";;
			i)
				assign_components mpd_info
				#mpd_components+='$mpfg$mpd_info'
				mpd_components+='$mpd_info'

				if [[ $switch_color ]]; then
					mpd_info="$switch_color$mpd_info"
					unset switch_color
				fi
				;;
			v)
				read volume_{up,down}_icon <<< $(get_icon 'volume_\(up\|down\)_icon' 2 | xargs)
				toggle_mpd_volume_buttons="sed -i '/mpd_volume_buttons/ y/01/10/' \$bar_config"
				mpd_volume_down_button="%{A:mpc -q volume -5:}$volume_down_icon%{A}%{O10}"
				mpd_volume_up_button="%{O10}%{A:mpc -q volume +5:}$volume_up_icon%{A}"
				mpd_volume=true
				mpd_components+='$volume'

				if [[ $switch_color ]]; then
					mpd_volume="$switch_color$mpd_volume"
					unset switch_color
				fi
				;;
				#[[ $arg == P ]] &&
				#	mpd_components+='$mpbg$mpfg' ||
				#	mpd_components+="\$mp${arg: -1}g"
				#;;
			p)
				mpd_progressbar_icon="━"
				mpd_progressbar_step=10

				assign_components mpd_progressbar
				mpd_components+='$mpd_progressbar'

				if [[ $switch_color ]]; then
					mpd_progressbar="$switch_color$mpd_progressbar"
					unset switch_color
				fi
				;;
			b)
				buttons="${value:-ptn}"

				assign_components mpd_buttons "$buttons"

				if [[ $switch_color ]]; then
					mpd_buttons="$switch_color$mpd_buttons"
					unset switch_color
				fi

				mpd_components+="%{T4}$mpd_buttons%{T-}"
				;;
		esac
	done

	#echo $mpd_components

	#mpd_content='$padding$mpd$padding'
	[[ ${joiner_modules[m]} ]] ||
		local mpd_padding=$padding mpd_bg=${msbg:-$sbg} mpd_fs=$mfs mpd_fe=$mfe
	#mpd_content="\$mpd_padding\$mpd\$mpd_padding"
	mpd_content="$mpd_fs$mpd_bg\$mpd_padding\$mpd\$mpd_padding$mpd_fe"
	#~/.orw/scripts/notify.sh "MPD: $mpd_content"
}

switch_mpd_volume_buttons() {
	if [[ $mpd_volume_buttons ]]; then
		unset mpd_volume_{buttons,{up,down}_button}
	else
		read volume_{up,down}_icon <<< $(get_icon 'volume_\(up\|down\)_icon' 2 | xargs)
		mpd_volume_down_button="%{A:mpc -q volume -5:}$volume_down_icon%{A}%{O10}"
		mpd_volume_up_button="%{O10}%{A:mpc -q volume +5:}$volume_up_icon%{A}"
		mpd_volume_buttons=true
	fi
}

check_mpd() {
	local limiter_icon='%{I}%{I}'
	local limiter_icon='%{I}%{I}'

	print_mpd

	while true; do
		change=$(mpc idle)
		#[[ $change ]] && ~/.orw/scripts/notify.sh "$change"
		[[ $change =~ player|mixer ]] && print_mpd
	done
}

trap switch_mpd_volume_buttons SIGRTMIN
