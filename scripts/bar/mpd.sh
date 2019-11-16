#!/bin/bash

fifo=$1
bg='${msbg:-${mpbg:-$sbg}}'

current_mode=controls
[[ $current_mode == song_info ]] && mode=controls || mode=song_info

toggle="\$inner\${msfg:-\$sfg}%{A:sed -i '/^current_mode/ s/=.*/=$mode/' $0:}%{A}\$inner"
info='${mpfg:-$pfg}${inner}${song_info-not playing}${inner}'

for m in ${2//,/ }; do
	case $m in
		t) modules+="$toggle";;
		p*)
			modules+='$progressbar'
			((${#m} == 1)) &&
				progression_step=5 ||
				progression_step=${m#p};;
		c) modules+='$controls';;
		i) modules+="$info";;
		v) modules+='$mpd_volume';;
		P) modules+='${mpbg:-$pbg}';;
		T) show_time=true;;
		d*) delay=${m#d};;
		s*)
			scroll=true
			[[ ${#m} -gt 1 ]] && scrollable_area=${m#s};;
	esac
done

status=$(mpc | sed -n 's/.*\[\(.*\)\].*/\1/p')

get_song_info() {
	time=$(mpc | awk 'NR == 2 {print $3}') elapsed_time=${time%/*}
	minutes=${elapsed_time%:*} seconds=${elapsed_time#*:}
	song_info="$(mpc current -f "%artist% - %title%")"
	scrollable_area=${scrollable_area-25}
	delay=${delay-3}

	if [[ $scroll ]] && (( ${#song_info} - ${#time} - 3 > $scrollable_area )); then
		final_index=$((${#song_info} - scrollable_area))
		(( $minutes == 0 && ${seconds#0} < 5 )) && song_info_index=0 ||
			song_info_index=$(((minutes * 60 + ${seconds#0}) % (final_index + 2 * delay)))

		((song_info_index = song_info_index > delay ? song_info_index - delay : 0))
		[[ $song_info_index -gt $final_index ]] && song_info_index=$final_index

		left_limiter='${mlfg:-${msfg:-$sfg}}%{I-S}%{I-}${mpfg:-$pfg}'
		right_limiter='${mlfg:-${msfg:-$sfg}}%{I-S}%{I-}${mpfg:-$pfg}'

		song_info="$left_limiter ${song_info:$song_info_index:$scrollable_area} $right_limiter"
	elif [[ $show_time ]]; then
		song_info+=" $time"
	fi

	echo -e "%{A:~/.orw/scripts/song_notification.sh:}\${mpfg:-\$pfg}%{T1}$song_info%{A}"
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

		read elapsed_percentage remaining_percentage <<< $(mpc | awk -F '[(%]' \
			'NR == 2 { ps = '$progression_step'; t = 100 / ps; e = sprintf("%.0f", $(NF - 1) / ps); print e, t - e }')

		draw elapsed
		draw remaining

		echo -e "$bg\$inner\${pbefg:-\$pfg}${elapsed}\${pbfg:-\${msfg:-\$sfg}}${remaining}\$inner"
	}

	get_volume() {
		current_mpd_volume_mode=duo
		eval args=( $(${0%/*}/volume.sh mpd $1) )

		if [[ $current_mpd_volume_mode == duo ]]; then
			echo -e "$bg\$inner\${msfg:-\$sfg}${args[0]}\$inner\${mpfg:-\$pfg}${args[1]}\$inner"
		else
			echo -e "$bg\$inner${args[*]}\$inner"
		fi
	}
fi

get_controls() {
	[[ $status == playing ]] && toggle_icon= || toggle_icon=

	stop="%{A:mpc -q stop; echo 'PROGRESSBAR' > $fifo;"
	stop+="echo 'SONG_INFO not playing' > $fifo;"
	stop+="echo 'MPD_VOLUME' > $fifo:}%{I-n}%{I-}%{A}"

	controls="%{T3}%{A:mpc -q prev:}%{I-n}%{I-}%{A}"
	controls+="\$inner%{A:mpc -q toggle:}%{I-n}$toggle_icon%{I-}%{A}"
	controls+="\$inner$stop\$inner%{A:mpc -q next:}%{I-n}%{I-}%{A}%{T-}"

	#controls="%{T3}%{A:mpc -q prev:}%{I-n}%{I-}%{A}\$inner"
	#controls+="\$inner%{A:mpc -q toggle:}%{I-n}$toggle_icon%{I-}%{A}\$inner"
	#controls+="\$inner%{A:mpc -q next:}%{I-n}%{I-}%{A}%{T-}\$inner"

	echo -e "$bg\$inner\${msfg:-\$sfg}$controls\${inner}"
}

for m in ${2//,/ }; do
	case $m in
		t) modules+="$bg$toggle";;
		p*)
			modules+='$progressbar'
			((${#m} == 1)) && progression_step=5 || progression_step=${m#p}

			[[ $status == playing && $current_mode == controls ]] &&
				echo -e "PROGRESSBAR $(get_progressbar)" > $fifo;;
		c)
			modules+='$controls'

			[[ $current_mode == controls ]] &&
				echo -e "CONTROLS $(get_controls)" > $fifo;;
		i)
			modules+="$bg$info"

			[[ $status == playing ]] &&
				echo -e "SONG_INFO $(get_song_info)" > $fifo;;
		v)
			modules+='$volume'

			[[ $status == playing && $current_mode == controls ]] &&
				echo -e "MPD_VOLUME $(get_volume $3)" > $fifo;;
		P) bg='${mpbg:-$pbg}';;
		T) show_time=true;;
		d*) delay=${m#d};;
		s*)
			scroll=true
			[[ ${#m} -gt 1 ]] && scrollable_area=${m#s};;
	esac
done

[[ $current_mode == song_info ]] && toggled_modules="$toggle\$inner$info"
echo -e "\${padding}${toggled_modules:-$modules}\$padding \$separator"
