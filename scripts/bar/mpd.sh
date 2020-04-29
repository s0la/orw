#!/bin/bash

fifo=$1
padding=$2
separator=$3
bg='${msbg:-${mpbg:-$sbg}}'

current_mode=controls
[[ $current_mode == song_info ]] && mode=controls || mode=song_info

function set_icon() {
	local icon="$(sed -n "s/mpd_${1}_icon=//p" ${0%/*}/icons)"
	eval mpd_${1}_icon=$icon
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
	song_info="$(mpc current -f "%artist% - %title%")"
	scrollable_area=${scrollable_area-25}
	delay=${delay-3}

	if [[ $scroll ]] && ((${#song_info} - time_length - 3 > $scrollable_area)); then
		final_index=$((${#song_info} - scrollable_area))
		(( $minutes == 0 && ${seconds#0} < 5 )) && song_info_index=0 ||
			song_info_index=$(((minutes * 60 + ${seconds#0}) % (final_index + 2 * delay)))

		((song_info_index = song_info_index > delay ? song_info_index - delay : 0))
		[[ $song_info_index -gt $final_index ]] && song_info_index=$final_index

		set_icon left_limiter
		set_icon right_limiter

		left_limiter="\${mlfg:-\${msfg:-\$sfg}}$mpd_left_limiter_icon\${mpfg:-\$pfg}"
		right_limiter="\${mlfg:-\${msfg:-\$sfg}}$mpd_right_limiter_icon\${mpfg:-\$pfg}"

		song_info="$left_limiter ${song_info:$song_info_index:$scrollable_area} $right_limiter"
	elif [[ $show_time ]]; then
		song_info+="  $time"
	fi

	echo -e "$commands\${mpfg:-\$pfg}%{T1}$song_info$commands_end"
}

if [[ $status == playing ]]; then
	get_progressbar() {
		draw() {
			local var=$1_percentage

			for p in $(seq ${!var}); do
				((percentage += progression_step))
				eval $1+=\"%{A:mpc -q seek $percentage%:}\%{I-0}━%{I-}%{A}\"
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
	controls+="%{A:mpc -q $control:}${!icon}%{A}"
}

for module in ${4//,/ }; do
	case $module in
		t) modules+="$toggle";;
		p*)
			modules+='$progressbar'
			((${#module} == 1)) && progression_step=5 || progression_step=${module#p}

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
						t) [[ $status == playing ]] && control=pause || control=play;;
						c) [[ $circle ]] && unset circle || circle=_circle;;
					esac

					if [[ $current_control != c ]]; then
						#((control_index > 1)) && controls+='${inner}'
						[[ $control_index -eq 1 || $control_index -eq 2 &&
							${selected_controls:control_index - 2:1} == c ]] || controls+='${inner}'
						get_controls $control
					fi
				done

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
		T) show_time=true;;
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
