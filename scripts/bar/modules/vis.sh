#!/bin/bash

get_vis() {
	if [[ "$1" != "$previous_values" || ! $previous_values ]]; then
		local vis vis_fg
		read -a values <<< "$1"

		#for value in $(seq 0 $((bars - 1))); do
		#	vis+="${bar_icons[${values[$value]:-1}]}%{O${vis_offset:-2}}"
		for value in $(seq 1 $bars); do
			((value <= vis_color_range)) &&
				vis_fg=vis_fg$value ||
				vis_fg=vis_fg$((vis_color_range - (value - vis_color_range) + 1))
			vis+="%{F${!vis_fg}}${bar_icons[${values[value-1]:-1}]}%{O${vis_offset:-2}}"
		done

		vis="%{T4}${vis%\%*}%{T-}"
		print_module vis
	fi

	previous_values="$1"
}

check_vis() {
	declare -A bar_icons
	bar_icons_string=$(awk -F '=' '
		/^[1-8]/ { printf "[%d]=%s ", substr($1, 1, 1), $NF }
	' ~/.orw/scripts/icons)

	eval bar_icons=( "$bar_icons_string" )

	local vis_config=$HOME/.config/cava/raw.config
	((bars)) && sed -i "/bars/ s/[0-9]\+/$bars/" $vis_config
	read bars framerate raw_fifo <<< \
		$(sed -n 's/\(bars\|frame\|raw\).* //p' $vis_config | xargs)
	#read bars framerate raw_fifo <<< $(awk '
	#	/^(bars|framerate|raw)/ {
	#		if (/^bars/ && "'"$bars"'") $NF = "'"$bars"'"
	#		vv = vv " " $NF
	#	} { al = al "\n" $0 }
	#	END { print vv al }' $vis_config |
	#		{ read values; echo $values; cat > $vis_config; })

	ps -C cava -o pid=,args= | awk '$NF == "'"$vis_config"'" { print $1 }' | xargs -r kill -9
	cava -p $vis_config &
	
	#~/.orw/scripts/notify.sh -t 15 "$(ps -p $! -o pid=,ppid=)"

	local brightness{,_{step,range}}
	vis_color_range=$((bars / 2))
	gradient_value=$((gradient_range / 2))
	gradient_step=$((gradient_range / vis_color_range))
	for i in $(seq 1 $vis_color_range | sort -r); do
		#color=vis_fg$((vis_color_range - i + 1))
		if [[ $gradient ]]; then
			eval vis_fg$i=$(~/.orw/scripts/convert_colors.sh -hV ${sign:-+}${gradient_value#-} ${vis_fg:3:7})
			((gradient_value < 0)) && ((gradient_step+=2))
			((gradient_value -= gradient_step))
			sign=${gradient_value//[0-9]}
		else
			eval vis_fg$i=${vis_fg:3:7}
		fi
		#echo "$color: $brightness, $brightness_step,    $vis_fg"
	done #> ~/vis_colors.log

	#~/.orw/scripts/notify.sh -t 11 "$vis_fg1, $vis_fg2, $vis_fg3, $vis_fg4"

	while read values; do
		get_vis "$values"
	done < <(awk '{
					c %= "'"${framerate:-30}"'" / "'"${refreshrate:-2}"'"
					if (!c++) {
						split($0, av, ";")
						for (v in av) if (av[v]) printf "%.0f ", av[v] * 0.007 + 1
						print ""
						fflush()
					}}' $raw_fifo)
}

make_vis_content() {
	for arg in ${1//,/ }; do
		value=${arg:2}
		arg=${arg::1}

		case $arg in
			b) bars=$((value - (value % 2)));;
			r) refreshrate=$value;;
			o) vis_offset=$value;;
			g)
				gradient=true
				gradient_range=${value:-30}
				;;
		esac
	done

	#vis_config=$HOME/.config/cava/raw.config
	#read bars framerate raw_fifo <<< $(awk '
	#	/^(bars|framerate|raw)/ {
	#		if (/^bars/ && "'"$bars"'") $NF = "'"$bars"'"
	#		vv = vv " " $NF
	#	} { al = al "\n" $0 }
	#	END { print vv al }' $vis_config |
	#		{ read values; echo $values; cat > $vis_config; })

	[[ $Vpfg != $pfg ]] && vis_fg=$Vpfg

	[[ ${joiner_modules[V]} ]] &&
		vis_fg="${vis_fg:-${cjpfg:-$pfg}}" ||
		local vis_bg=$Vpbg vis_padding=$padding
	#~/.orw/scripts/notify.sh -t 11 "$Vpfg, $pfg, $vis_fg, $cjpfg"

	#eval read vis_fg{1..$((bars / 2)) 

	#local color_{offset{,_base},peak}
	#vis_color_range=$((bars / 2))
	#color_peak=vis_fg$vis_color_range
	#eval $color_peak=${vis_fg:3:7}
	##vis_color_offset=$vis_color_range
	#color_offset=$((vis_color_range - 1))
	##color_offset_base=$((vis_color_range / 2))
	#for i in $(seq 1 $vis_color_range); do
	#	#eval vis_fg$i=$(~/.orw/scripts/convert_colors.sh -hV +$(((vis_color_range - i) * vis_color_offset--)) ${vis_fg:3:7})
	#	#~/.orw/scripts/notify.sh -t 11 "$((i * 2 * vis_color_offset)), $i, $vis_color_offset"
	#	#eval vis_fg$vis_color_offset=${ ~/.orw/scripts/convert_colors.sh -hV +$((i * 2 * vis_color_offset--)) ${vis_fg:3:7}; }
	#	vis_color=vis_fg$color_offset
	#	#eval vis_fg$((color_offset--))=${ ~/.orw/scripts/convert_colors.sh -hV +$((color_offset_base += vis_color_range)) ${!color_peak}; }
	#	#eval vis_fg$i=${ ~/.orw/scripts/convert_colors.sh -hV +$((color_offset_base += 2 * ++z)) ${!color_peak}; }
	#	eval vis_fg$i=${ ~/.orw/scripts/convert_colors.sh -hV +$((color_offset_base += (i % 2 + 1) * ++z)) ${!color_peak}; }
	#	#vis_color=vis_fg$i
	#	#eval $vis_color=$(~/.orw/scripts/convert_colors.sh -hV +$(((vis_color_range - i) * 5)) ${vis_fg:3:7})
	#	#~/.orw/scripts/notify.sh -t 11 "$vis_color: ${!vis_color} $vis_fg $color_offset_base"
	#	echo "$vis_color: ${!vis_color} $vis_fg $color_offset_base" >> ~/vis_colors.log
	#done

	vis_content="$vis_bg$vis_padding$vis_fg\$vis$vis_padding"
}
