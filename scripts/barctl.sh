#!/bin/bash

get_bars() {
	bars=( $(ps aux | awk '! /awk/ && /lemonbar/ { print $NF }') )
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

while getopts :ds:c:gb:r:kla flag; do
	case $flag in
		g)
			bar=$(sed "s/.*-n \(\w*\).*/\1/" <<< $@)

			kill_bar
			start_bar_on_boot $bar

			~/.orw/scripts/bar/generate_bar.sh ${@:2}
			exit;;
		c) check_interval=$OPTARG;;
		b) bars=( ${OPTARG//,/ } );;
		r) ram_tolerance=$OPTARG;;
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
