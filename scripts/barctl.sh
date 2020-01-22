#!/bin/bash

get_bars() {
	bars=( $(ps aux | awk '! /awk/ && /lemonbar/ { print $NF }') )
	bar_count=${#bars[*]}
}

kill_bar() {
	local pid=$(ps aux | awk '!/barctl.sh/ { if(/-n '$bar'($| )/) print $2 }' | xargs)
	[[ $pid ]] && kill $pid
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

while getopts :ds:c:gb:m:E:e:r:R:kla flag; do
	case $flag in
		g)
			bar=$(sed "s/.*-n \(\w*\).*/\1/" <<< $@)

			kill_bar
			~/.orw/scripts/bar/generate_bar.sh ${@:2}

			awk -i inplace '\
				/bar/ && $(NF - 1) !~ /\<'$bar'\>/ {
						sub("$", ",'$bar'", $(NF - 1))
				} { print }' ~/.config/openbox/autostart.sh

			exit;;
		c) check_interval=$OPTARG;;
		b)
			bar_expr=$OPTARG

			[[ ${bar_expr//[[:alnum:]_-]/} =~ ^(,+?|)$ ]] && pattern="^(${bar_expr//,/|})$" || pattern="${bar_expr//,/|}"
			read -a bars <<< $(ls $configs | awk -F '/' '$NF ~ /^'${pattern//\*/\.\*}'/ { print $NF }' | xargs)

			bar_count=${#bars[*]};;
		m) memory_tolerance=$OPTARG;;
		E)
			inherit_config=$configs/$OPTARG
			[[ ! ${!OPTIND} =~ ^- ]] && inherit_flag=${!OPTIND} && shift;;
		[er])
			all="$@"
			args="${all#*-[er] }"

			edit_args="${args#* }"
			edit_flag="${args%% *}"

			((bar_count)) || get_bars
			((bar_count > 1)) && all_bars="${bars[*]}" || bar=$bars

			edit_config=$(eval echo $configs/${bar:-{${all_bars// /,}\}})

			awk -i inplace '\
				function get_new_values(flag) {
					a = aa[ai]
					as = substr(a, 1, 1)
					av = int(substr(a, 2))
					cv =  gensub(".*(-" flag "([^0-9]*([0-9]+)){" ai "}[^-]*).*", "\\3", 1)
					naa[ai] = (as == "+") ? cv + av : cv - av
				}

				function replace_value() {
					$0 = gensub("(.*-" f ")((([0-9]+)?([^0-9]*)){" ai "})[0-9]+(.*)", "\\1\\2" naa[ai] "\\6", 1)
				}

				BEGIN {
					e_f = "'$edit_flag'"
					e_a = "'"$edit_args"'"
					i_f = "'$inherit_flag'"

					split(e_a, aa)
					split(e_f, fa, ",")
				} {
					if(e_a ~ /[+-][0-9]/) {
						if(i_f && NR == FNR) {
							for(ai in aa) get_new_values(i_f)
							nextfile
						}

						for(fi in fa) {
							f = fa[fi]

							for(ai in aa) {
								if(! i_f) get_new_values(f)
								replace_value()
							}
						}
					} else {
						if(i_f && ! p) {
							p = gensub(".*-" i_f " ([^-]*).*", "\\1", 1)
							nextfile
						}

						for(fi in fa) {
							f = fa[fi]
							if(i_f) sub("-" f "[^-]*", "-" f " " p)
							else sub("-" f "[^-]*", ("'$flag'" == "r") ? "" : "-" f " " e_a " ")
						}
					}

					print
				}' $inherit_config $edit_config

			break;;
		R)
			modules="$1"
			colorscheme_name="${!OPTIND}"
			[[ ! $1 =~ '^' ]] && modules="${1//\*/\.\*}"

			if [[ $colorscheme_name ]]; then
				colorscheme=~/.config/orw/colorschemes/$colorscheme_name.ocs
				shift

				bars=( $(ps aux | awk '\
							BEGIN { b = "" }
					/-c '"$colorscheme_name"'/ { 
						n = gensub(".*-n (\\w*).*", "\\1", 1)
						if(b !~ n) b = b " " n
						} END { print b }') )
				bar_count=${#bars[*]}
			fi

			sed -i "/^\(${modules//,/\\\|}\)[= ]/d" ${colorscheme:-~/.orw/scripts/bar/module_colors};;
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

current_pid=$$
ps -C barctl.sh o pid= --sort=-start_time | grep -v $current_pid | xargs kill 2> /dev/null

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
