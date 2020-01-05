#!/bin/bash

get_bars() {
	bars=( $(ps aux | awk '! /awk/ && /lemonbar/ { print $NF }') )
	bar_count=${#bars[*]}

}

kill_bar() {
	kill $(ps aux | awk '!/barctl.sh/ { if(/-n '$bar'($| )/) print $2 }' | xargs) &> /dev/null
}

kill_bars() {
	for bar in "${bars[@]}"; do
		kill $(ps aux | awk '!/barctl.sh/ { if(/-n '$bar'$?/) print $2 }' | xargs) &> /dev/null
	done
}

lower_bars() {
	for bar in "${bars[@]}"; do
		xdo lower -N Bar
	done
}

monitor_memory_consumption() {
	current_memory_usage=$(${0%/*}/check_memory_consumption.sh Xorg)

	((current_memory_usage > initial_memory_usage)) && 
		memory_usage_delta=$((current_memory_usage - initial_memory_usage)) ||
		memory_usage_delta=$(((initial_memory_usage - current_memory_usage) * 2))

	((memory_usage_delta >= ${memory_tolerance:-10})) && $0
}

start_bar_on_boot() {
	[[ $1 ]] || bar_names="${bars[*]}"
	sed -i "/bar/ s/[^ ]*$/${1:-${bar_expr:-${bar_names// /,}}}/" ~/.config/openbox/autostart.sh
}

configs=~/.config/orw/bar/configs
initial_memory_usage=$(${0%/*}/check_memory_consumption.sh Xorg)

while getopts :ds:c:gb:m:E:e:r:kla flag; do
	case $flag in
		g)
			bar=$(sed "s/.*-n \(\w*\).*/\1/" <<< $@)

			kill_bar
			start_bar_on_boot $bar

			~/.orw/scripts/bar/generate_bar.sh ${@:2}
			exit;;
		c) check_interval=$OPTARG;;
		b)
			bar_expr=$OPTARG
			[[ ${bar_expr//[[:alnum:]_-]/} =~ ^(,+?|)$ ]] && pattern="^(${bar_expr//,/|})$" || pattern="${bar_expr//,/|}"
			read -a bars <<< $(ls $configs | awk -F '/' '$NF ~ /'${pattern//\*/\.\*}'/ { print $NF }' | xargs)
			bar_count=${#bars[*]};;
		m) memory_tolerance=$OPTARG;;
		E) inherit_config=$configs/$OPTARG;;
		[er])
			all="$@"
			replace="${all#*-[er] }"

			edit_args="${replace#* }"
			edit_flag="-${replace%% *}"

			if [[ $edit_args =~ [+-][0-9] ]]; then
				pre="${edit_args%%[+-][0-9]*}"
				post="${edit_args#$pre}"

				relative=${post%% *}
				sign=${relative:0:1}
				value=${relative:1}

				spaces="${pre//[^ ]/}"
				index="${#spaces}"
			fi

			((bar_count)) || get_bars
			((bar_count > 1)) && all_bars="${bars[*]}" || bar=$bars

			replace_config=$(eval echo $configs/${bar:-{${all_bars// /,}\}})

			awk -i inplace '\
				BEGIN {
					v = '${value:-0}'
					i = '${index:-0}'
					f = "'$edit_flag'"
					ic = ("'$inherit_config'")
				} {
					if((ic && !p) || !ic) {
						if("'$sign'") {
							cv = gensub(".*" f "( [^ ]*){" i + 1 "}.*", "\\1", 1)
							nv = cv '$sign' v

							p = "'"$pre"'" nv " '"${post/$relative/}"'"
						} else {
							if("'$inherit_config'") {
								p = gensub(".*" f " ([^-]*).*", "\\1", 1)
							} else {
								p = "'"$edit_args"' "
							}
						}
					}

					if(ic && NR == FNR) nextfile

					r = ("'$flag'" == "r") ? "" : f " " p
					gsub(f "[^-]*", r)
				} { print }' $inherit_config $replace_config
			break;;
		k)
			if [[ $bars ]]; then
				for bar in "${bars[@]}"; do
					kill_bar
				done
			else
				ps -C barctl.sh o pid= --sort=-start_time | awk 'NR > 1' | xargs kill &> /dev/null
				sleep 0.1
				killall generate_bar.sh lemonbar
			fi

			exit;;
		l)
			get_bars
			lower_bars
			exit;;
		a)
			~/.orw/scripts/add_bar_launcher.sh ${@:2}
			exit;;
	esac
done

ps -C barctl.sh o pid= --sort=-start_time | awk 'NR > 1' | xargs kill &> /dev/null

while true; do
	monitor_memory_consumption
	sleep ${check_interval:-100}
done &

[[ ! $bars ]] && get_bars

for bar in "${bars[@]}"; do
	kill_bar
	bash $configs/$bar &
done

start_bar_on_boot
