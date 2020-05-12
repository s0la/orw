#!/bin/bash

get_bars() {
	bars=( $(ps aux | awk '! /awk/ && /lemonbar/ { print $NF }') )
	bar_count=${#bars[*]}
}

kill_bar() {
	local pid=$(ps aux | awk '!/barctl.sh/ { if(/-n \<'$bar'\>/) print $2 }' | xargs)
	[[ $pid ]] && kill $pid
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

add_bar() {
	[[ $last_running ]] && separator=,
	sed -i "/^last_running/ { /\<$bar\>/! s/$/$separator$bar/ }" $0
}

configs=~/.config/orw/bar/configs
initial_memory_usage=$(${0%/*}/check_memory_consumption.sh Xorg)

last_running=4pt,full,join_und,left

while getopts :ds:i:gb:m:E:e:r:R:klanc: flag; do
	case $flag in
		g)
			bar=$(sed "s/.*-n \(\w*\).*/\1/" <<< $@)

			kill_bar
			~/.orw/scripts/bar/generate_bar.sh ${@:2}

			add_bar
			exit;;
		i) check_interval=$OPTARG;;
		b)
			bar_expr=$OPTARG

			[[ ${bar_expr//[[:alnum:]_-]/} =~ ^(,+?|)$ ]] &&
				pattern="^(${bar_expr//,/|})$" || pattern="${bar_expr//,/|}"

			[[ $@ =~ -k ]] && remove=true

			read last_running bar_array <<< $(ls $configs | awk -F '/' '\
				BEGIN {
					r = "'$remove'"
					lr = "'$last_running'"
				}

				$NF ~ /'${pattern//\*/\.\*}'/ {
					b = $NF
					if(! r && b !~ "^('${last_running//,/|}')$") nb = nb "," b
					ub = ub "," b
				} END {
					if(r) {
						ab = gensub(",?\\<(" gensub(",", "|", "g", ub) ")\\>", "", "g", lr)
						if(ab ~ /^,/) sub("^,", "", ab)
					} else {
						if(nb && ! lr) sub("^,", "", nb)
						ab = lr nb
					}

					print (ab) ? ab : "none", gensub(",", " ", "g", (nb) ? nb : ub)
				}')

			[[ $last_running == none ]] && unset last_running

			bars=( $bar_array )
			bar_count=${#bars[*]}

			sed -i "/^last_running/ s/[^=]*$/$last_running/" $0;;
		m) memory_tolerance=$OPTARG;;
		E)
			inherit_config=$configs/$OPTARG
			[[ ! ${!OPTIND} =~ ^- ]] && inherit_flag=${!OPTIND} && shift;;
		[er])
			all="$@"
			args="${all#*-[er] }"

			edit_flag="${args%% *}"
			edit_args="${args#$edit_flag}"

			((bar_count)) || get_bars
			((bar_count > 1)) && all_bars="${bars[*]}" || bar=$bars

			edit_config=$(eval echo $configs/${bar:-{${all_bars// /,}\}})

			awk -i inplace '\
				function get_new_value(flag) {
					return gensub("((([^-]*-[^" flag "])*[^-]*-" flag ")([^0-9]*([0-9]+)){" ai "}[^-]*).*", "\\5", 1)
				}

				function replace_value() {
					$0 = gensub("(([^-]*-[^" f "])*[^" f "]*" f ")((([0-9]+)?([^0-9]*)){" ai "})[0-9]+(.*)", "\\1\\3" nv "\\7", 1)
				}

				BEGIN {
					e_f = "'$edit_flag'"
					e_a = "'"$edit_args"'"
					i_c = "'"$inherit_config"'"
					if(i_c) i_f = "'${inherit_flag:-$edit_flag}'"

					split(e_a, aa)
					split(e_f, fa, ",")
					#split(i_f, fa, ",")
				} {
					if(e_a ~ /[+-][0-9]?/) {
						if(i_c && NR == FNR) {
							for(ai in aa) naa[ai] = get_new_value(i_f)
							print
							nextfile
						}

						for(fi in fa) {
							f = fa[fi]

							for(ai in aa) {
								a = aa[ai]
								as = substr(a, 1, 1)
								av = int(substr(a, 2))
								cv = get_new_value(f)

								fo = (length(naa[1])) ? naa[ai] : cv
								so = (length(a) > 1) ? av : cv
								nv = (as == "+") ? so + fo : fo - so

								replace_value()
							}
						}
					} else {
						if(i_c && NR == FNR) {
							if(i_f) split(i_f, ia, ","); else ia = fa

							for(iai in ia) naa[iai] = gensub(".*-" ia[iai] " ([^-]*).*", "\\1", 1)

							print
							nextfile
						}

						for(fi in fa) {
							f = fa[fi]

							#p = (length(naa[1])) ? naa[fi] : fa[fi]
							#if(i_c) sub("-" f "[^-]*", "-" f " " p)
							#else sub("-" f "[^-]*", ("'$flag'" == "r") ? "" : "-" f " " e_a " ")

							if(length(naa)) {
								if(length(naa[fi])) p = naa[fi]
							} else p = e_a

							if(i_c) {
								sub("-" f "[^-]*", "-" f " " p)
							} else {
								sub("-" f "[^-]*", ("'$flag'" == "r") ? "" : "-" f " " e_a " ")
							}
						}
					}

					print
				}' $inherit_config $edit_config

			break;;
		R)
			#modules="$OPTARG"
			modules="${OPTARG//\*/\.\*}"
			colorscheme_name="${!OPTIND}"
			#[[ ! $modules =~ '^' ]] && modules="${modules//\*/\.\*}"

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
		n) no_reload=true;;
		c)
			config=$OPTARG
			clone_config=${!OPTIND}
			config_path=~/.config/orw/bar/configs

			shift

			#cp $config_path/$config $config_path/$clone_config
			#sed -n "s/\(.*c\).*/\\1/1p" $config_path/$config
			#sed -n "s/\(\([^-]*-[^c]\)*[^-]*-c\)/\\1 bar_$clone_config/p" $config_path/$config
			awk '{
				$0 = gensub("(([^-]*-[^c])*[^-]*-c)", "\\1 bar_'$clone_config'", 1)
				$0 = gensub("(.*-n)( [^ ]*)", "\\1 '$clone_config'", 1, $0)
				print
			}' $config_path/$config > $config_path/$clone_config

			bar=$clone_config
			bars=( $bar )
			add_bar
	esac
done

[[ -z $@ ]] && bars=( ${last_running//,/ } )

if [[ ! $no_reload ]]; then
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
fi
