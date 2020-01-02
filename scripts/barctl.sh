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
	current_ram_usage=$(${0%/*}/check_memory_consumption.sh Xorg)

	((current_ram_usage > initial_ram_usage)) && 
		ram_usage_delta=$((current_ram_usage - initial_ram_usage)) ||
		ram_usage_delta=$(((initial_ram_usage - current_ram_usage) * 2))

	((ram_usage_delta >= ${ram_tolerance:-10})) && $0
}

start_bar_on_boot() {
	[[ $1 ]] || bar_names="${bars[*]}"
	sed -i "/bar/ s/\w* &/${1:-${bar_names// /,}} \&/" ~/.config/openbox/autostart.sh
}


initial_ram_usage=$(${0%/*}/check_memory_consumption.sh Xorg)

while getopts :ds:c:gb:r:E:e:kla flag; do
	case $flag in
		g)
			bar=$(sed "s/.*-n \(\w*\).*/\1/" <<< $@)

			kill_bar
			start_bar_on_boot $bar

			~/.orw/scripts/bar/generate_bar.sh ${@:2}
			exit;;
		c) check_interval=$OPTARG;;
		b)
			bars=( ${OPTARG//,/ } )
			bar_count=${#bars[*]};;
		r) ram_tolerance=$OPTARG;;
		E) inherit_config=~/.config/orw/bar/configs/$OPTARG;;
		e)
			all="$@"
			replace="${all#*-e }"

			[[ $inherit_config ]] &&
				args=$(sed -n "s/.*\($replace[^-]*\).*/\1/p" $inherit_config) || args="${replace#* }"

			flag="${replace%% *}"

			if [[ $args =~ [+-][0-9] ]]; then
				pre="${args%%[+-][0-9]*}"
				post="${args#$pre}"

				relative=${post%% *}
				sign=${relative:0:1}
				value=${relative:1}

				spaces="${pre//[^ ]/}"
				index="${#spaces}"
			fi

			[[ $first_arg =~ [+-][0-9] ]] && sign=${first_arg}

			((bar_count)) || get_bars
			((bar_count > 1)) && all_bars="${bars[*]}" || bar=$bars

			replace_config=$(eval echo ~/.config/orw/bar/configs/${bar:-{${all_bars// /,}\}})

			awk -i inplace '\
				BEGIN {
					f = "'$flag'"
					v = '${value:-0}'
					i = '${index:-0}'
				} {
					if("'$sign'") {
						cv = gensub(".*" f "( [^ ]*){" i + 1 "}.*", "\\1", 1)
						nv = cv '$sign' v

						p = "'"$pre"'" nv " '"${post/$relative/}"'"
					} else {
						p = "'"$args"' "
					}

					gsub(f "[^-]*", f " " p)
				} {
					print
				}' $replace_config
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
	bash ~/.config/orw/bar/configs/$bar &
done

start_bar_on_boot
