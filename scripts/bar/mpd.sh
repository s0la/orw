#!/bin/bash

fifo=$1
padding=$2
separator=$3
bg='${msbg:-${mpbg:-$sbg}}'

current_mode=controls
[[ $current_mode == song_info ]] && mode=controls || mode=song_info

function set_icon() {
	local icon="$(sed -n "s/mpd_${1}_icon=//p" ${0%/*}/icons)"
	eval mpd_${1}_icon=\"$icon\"
}

set_icon toggle

#toggle="\$inner\${msfg:-\$sfg}%{A:sed -i '/^current_mode/ s/=.*/=$mode/' $0:}%{A}\$inner"
toggle="$bg\${msfg:-\$sfg}%{A:sed -i '/^current_mode/ s/=.*/=$mode/' $0:}%{A}\$inner"

commands='%{A:mpc -q toggle:}'
commands+='%{A3:~/.orw/scripts/song_notification.sh:}'
commands+='%{A4:mpc -q prev:}'
commands+='%{A5:mpc -q next:}'
commands_end='%{A}%{A}%{A}%{A}'

info="\${mpfg:-\$pfg}\${inner}$commands\${song_info-not playing}$commands_end\${inner}"
#info='${mpfg:-$pfg}${inner}${song_info-not playing}${inner}'

status=$(mpc | sed -n 's/^\[\(.*\)\].*/\1/p')

get_song_info() {
	time=$(mpc | awk 'NR == 2 { print $3 }') elapsed_time=${time%/*}
	[[ $show_time ]] && time_length=${#time}

	minutes=${elapsed_time%:*} seconds=${elapsed_time#*:}
	#song_info="$(mpc current -f "%artist% - %title%")"
	scrollable_area=${scrollable_area:-25}
	delay=${delay-3}

	#if [[ $scroll ]] && ((${#song_info} - time_length - 3 > $scrollable_area)); then
	#	final_index=$((${#song_info} - scrollable_area))
	#	(( $minutes == 0 && ${seconds#0} < 5 )) && song_info_index=0 ||
	#		song_info_index=$(((minutes * 60 + ${seconds#0}) % (final_index + 2 * delay)))

	#artist="$(mpc current -f "%artist%")"
	#title="$(mpc current -f "%title%")"
	##song_info="$(mpc current -f "%artist% - %title%")"
	#info_length=$((${#artist} + ${#title} + 2))

	artist="$(mpc current -f "%artist%")"
	song_info="$(mpc current -f "$artist: %title%")"

	artist_length=${#artist}
	info_length=${#song_info}

	#song_info="$artist: $title"

	#~/.orw/scripts/notify.sh "il: $info_length, $scrollable_area"

	if [[ $scroll ]] && ((info_length - time_length - 3 > $scrollable_area)); then
		final_index=$((info_length - scrollable_area))
		(( $minutes == 0 && ${seconds#0} < 5 )) && song_info_index=0 ||
			song_info_index=$(((minutes * 60 + ${seconds#0}) % (final_index + 2 * delay)))

		((song_info_index = song_info_index > delay ? song_info_index - delay : 0))
		[[ $song_info_index -gt $final_index ]] && song_info_index=$final_index

		#set_icon left_arrow_limiter
		#set_icon right_arrow_limiter
		set_icon left_dot_limiter
		set_icon right_dot_limiter

		left_limiter="%{T4}\${mlfg:-\${msfg:-\$sfg}}$mpd_left_dot_limiter_icon \${mpfg:-\$pfg}%{T-}"
		right_limiter="%{T4}\${mlfg:-\${msfg:-\$sfg}} $mpd_right_dot_limiter_icon\${mpfg:-\$pfg}%{T-}"

		#currently_visible_portion="${song_info:$song_info_index:$scrollable_area}"
		song_info="${song_info:$song_info_index:$scrollable_area}"

		#~/.orw/scripts/notify.sh "cwp: $currently_visible_portion"

		#if ((song_info_index < artist_length + 1)); then
		#	artist_portion=$(((artist_length + 1) - song_info_index))
		#	currently_visible_portion="%{T5}${currently_visible_portion:0:$artist_portion}%{T1}${currently_visible_portion:$artist_portion}"
		#fi

		#~/.orw/scripts/notify.sh "cwp: $currently_visible_portion"

		#song_info="$currently_visible_portion"
	elif [[ $show_time ]]; then
		if [[ $remained ]]; then
			get_seconds() {
				read minutes seconds <<< ${1//:/ }
				echo $((10#$minutes * 60 + 10#$seconds))
			}

			total_seconds=$(get_seconds ${time#*/})
			elapsed_seconds=$(get_seconds $elapsed_time)
			remained_seconds=$((total_seconds - elapsed_seconds))
			minutes=$(printf '%01d' $((remained_seconds / 60)))
			seconds=$(printf '%02d' $((remained_seconds % 60)))

			time_info="$minutes:$seconds"
		else
			#song_info+="  $tof$time$toe"
			#song_info+="  $tof%{T5}$elapsed_time%{T1}${time#$elapsed_time}$toe"
			#time_info="$elapsed_time┃%{T1}${time#*/}"
			time_info="$elapsed_time%{T1}|${time#*/}"
		fi

		song_info+="  $tof%{T5}$time_info%{T1}$toe"
	fi

	#~/.orw/scripts/notify.sh "$song_info"

	if ((song_info_index < artist_length + 1)); then
	#~/.orw/scripts/notify.sh "$song_info"
		artist_portion=$(((artist_length + 1) - song_info_index))
		song_info="%{T5}${song_info:0:$artist_portion}%{T1}${song_info:$artist_portion}"
	fi

	#~/.orw/scripts/notify.sh "$song_info"
	echo -e "$commands\${mpfg:-\$pfg}$left_limiter$song_info$right_limiter$commands_end"
	#echo -e "$commands\${mpfg:-\$pfg}%{T1}$song_info$commands_end"
}

if [[ $status == playing ]]; then
	get_progressbar() {
		draw() {
			local var=$1_percentage

			for p in $(seq ${!var}); do
				((percentage += progression_step))
				#eval $1+=\"%{A:mpc -q seek $percentage%:}\%{I-0}━%{I-}%{A}\"
				#eval $1+=\"%{A:mpc -q seek $percentage%:}\%{I-0}█%{I-}%{A}\"
				#eval $1+=\"%{A:mpc -q seek $percentage%:}\%{I-0}▇%{I-}%{A}\"
				#eval $1+=\"%{A:mpc -q seek $percentage%:}\%{I-0}■%{I-}%{A}\"
				#eval $1+=\"%{A:mpc -q seek $percentage%:}\%{I-0}━%{I-}%{A}\"
				#eval $1+=\"%{A:mpc -q seek $percentage%:}\%{I-0}▇%{I-}%{A}\"
				#eval $1+=\"%{A:mpc -q seek $percentage%:}\%{I-0}▇%{I-}%{A}\"
				#eval $1+=\"%{A:mpc -q seek $percentage%:}\%{I-0}▇%{I-}%{A}\"
				#eval $1+=\"%{A:mpc -q seek $percentage%:}\%{I-0}█%{I-}%{A}\"
				eval $1+=\"%{A:mpc -q seek $percentage%:}\%{I-0}$bar_icon%{I-}%{A}\"
			done
		}

		read elapsed_percentage remaining_percentage <<< $(mpc | awk -F '[(%]' 'NR == 2 {
			ps = '$progression_step'
			t = sprintf("%.0f", 100 / ps)
			e = sprintf("%.0f", $(NF - 1) / ps)
			print e, t - e }')

		draw elapsed
		draw remaining

		echo -e "$bg$of\$inner\${pbefg:-\$pfg}${elapsed}\${pbfg:-\${msfg:-\$sfg}}${remaining}\$inner$oe"
	}

	get_volume() {
		current_mpd_volume_mode=duo
		eval args=( $(${0%/*}/volume.sh mpd $1) )

		if [[ $current_mpd_volume_mode == duo ]]; then
			echo -e "$bg$of\$inner\${msfg:-\$sfg}${args[0]}\$inner\${mpfg:-\$pfg}${args[1]}\$inner$oe"
		else
			echo -e "$bg$of\$inner${args[*]}\$inner$oe"
		fi
	}
fi

#get_controls() {
#	set_icon prev
#	set_icon next
#	set_icon play
#	set_icon pause
#
#	[[ $status == playing ]] && toggle_icon=$mpd_pause_icon || toggle_icon=$mpd_play_icon
#
#	#stop="%{A:mpc -q stop; echo 'PROGRESSBAR' > $fifo;"
#	#stop+="echo 'SONG_INFO not playing' > $fifo;"
#	#stop+="echo 'MPD_VOLUME' > $fifo:}%{I-n}%{I-}%{A}"
#
#	#controls="%{T3}%{A:mpc -q prev:}%{I-n}%{I-}%{A}"
#	#controls+="\$inner%{A:mpc -q toggle:}%{I-n}$toggle_icon%{I-}%{A}"
#	#controls+="\$inner$stop\$inner%{A:mpc -q next:}%{I-n}%{I-}%{A}%{T-}"
#
#	#controls="%{T3}%{A:mpc -q prev:}$mpd_prev_icon%{A}\$inner"
#	#controls+="\$inner%{A:mpc -q toggle:}$toggle_icon%{A}\$inner"
#	#controls+="\$inner%{A:mpc -q next:}$mpd_next_icon%{A}%{T-}\$inner"
#
#	controls="%{T3}%{A:mpc -q prev:}$mpd_prev_icon%{A}"
#	controls+="\$inner%{A:mpc -q toggle:}$toggle_icon%{A}"
#	controls+="\$inner%{A:mpc -q next:}$mpd_next_icon%{A}%{T-}"
#
#	echo -e "$bg$of\$inner\${msfg:-\$sfg}$controls\${inner}$oe"
#}

get_controls() {
	local icon=mpd_${control}${circle}_icon
	set_icon $control$circle
	#controls+="%{A:mpc -q $control:} ${!icon}%{A}${control_separator}"
	controls+="%{A:mpc -q $control:}${!icon}%{A}%{O${control_separator:-0}}"
	#controls+="%{A:~/.orw/scripts/notify.sh '$control':} ${!icon}%{A}"
	#controls+="%{A:~/.orw/scripts/notify.sh 'mpc -q $control':}${!icon}%{A}"
	#~/.orw/scripts/notify.sh "c: $controls"
}

for module in ${4//,/ }; do
	case $module in
		t) modules+="$toggle";;
		p*)
			modules+='$progressbar'
			#((${#module} == 1)) && progression_step=5 || progression_step=${module#p}
			((${#module} == 1)) && progression_step=5 || progression_step=${module//[^0-9]/}
			#bar_style=${module//[0-9p]/}
			[[ $module =~ s ]] && bar_icon=■ || bar_icon=━

			[[ $status == playing && $current_mode == controls ]] &&
				echo -e "PROGRESSBAR $(get_progressbar)" > $fifo;;
		c*)
			modules+='$controls'

			if [[ $current_mode == controls ]]; then
				((${#module} > 1)) && selected_controls="${module#*:}" || selected_controls="pstn"

				for control_index in $(seq 1 ${#selected_controls}); do
					current_control=${selected_controls:control_index - 1:1}

					case $current_control in
						p) control=prev;;
						n) control=next;;
						s) control=stop;;
						#S*) control_separator="%{O${current_control:1}}";;
						S*) control_separator=${selected_controls//[^0-9]/};;
						#S*) control_separator=${current_control:1};;
							#separator_value=${current_control:1}
							#control_separator="%{O$separator_value}";;
						t) [[ $status == playing ]] && control=pause || control=play;;
						c) [[ $circle ]] && unset circle || circle=_circle;;
					esac

					if [[ $current_control != [co0-9] ]]; then
						#((control_index > 1)) && controls+='${inner}'

						# add offset between control buttons, commented because space was added before each button, so the click action would respond on the right location
						#[[ $control_index -eq 1 || $control_index -eq 2 &&
						#	${selected_controls:control_index - 2:1} == c ]] || controls+='${inner}'
						get_controls $control
					fi
				done

				controls="${controls%\%*}"
				echo -e "CONTROLS $bg\${msfg:-\$sfg}$of%{T3}${controls}%{T-}$oe" > $fifo
			fi;;

			#echo $controls
			#exit

			#[[ $current_mode == controls ]] &&
			#	echo -e "CONTROLS $(get_controls)" > $fifo;;
		i)
			modules+="$bg$of$info$oe"

			[[ $status == playing ]] &&
				echo -e "SONG_INFO $(get_song_info)" > $fifo;;
		v)
			modules+='$mpd_volume'

			[[ $status == playing && $current_mode == controls ]] &&
				echo -e "MPD_VOLUME $(get_volume $4)" > $fifo;;
		P) bg='${mpbg:-$pbg}';;
		T*)
			show_time=true
			[[ $of ]] && tof=$of
			[[ $oe ]] && toe=$oe
			((${#module} > 1)) && remained=true;;
		d*) delay=${module#d};;
		s*)
			scroll=true
			[[ ${#module} -gt 1 ]] && scrollable_area=${module#s};;
		o*) eval ${module:0:2}=%{O${module:2}};;
			#~/.orw/scripts/notify.sh "$module $of $oe";;
			#offset=${module:2}
			#position=${module:1:1}

			#if [[ $position == f ]]; then
			#	offset="%{O$offset}"
			#else
			#	modules+="%{O$offset}"
			#	unset offset
			#fi;;
	esac

	#[[ $offset && ! $module =~ ^o ]] && unset offset
	[[ ($of || $oe) && ! $module =~ ^o ]] && unset o{e,f}
done

#~/.orw/scripts/notify.sh "$separator"

[[ $current_mode == song_info ]] && toggled_modules="$toggle\$inner$bg$info"
echo -e "${padding}${toggled_modules:-$modules}$padding $separator"
