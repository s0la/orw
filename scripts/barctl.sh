#!/bin/bash

get_bars() {
	bars=( $(ps aux | awk '! /awk/ && /lemonbar/ { print $NF }') )
	bar_count=${#bars[*]}
}

kill_bar() {
	local pid=$(ps aux | awk '!/barctl.sh/ { if(/-n \<'$bar'\>/) print $2 }' | xargs)
	[[ $pid ]] && kill $pid
}

kill_running_script() {
	local running_pids=( $(pidof -o %PPID -x ${0##*/}) )
	((${#running_pids[*]})) && kill ${running_pids[*]}
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

last_running=moun_sep

#[[ $@ =~ -b ]] || get_bars

#while getopts :ds:I:gb:m:E:e:r:R:klLnc: flag; do
while getopts :dI:gb:M:E:eriamsR:klLnc: flag; do
	case $flag in
		g)
			bar=$(sed "s/.*-n \(\w*\).*/\1/" <<< $@)
			kill_bar

			[[ -f $configs/$bar ]] && overwrite=-o
			~/.orw/scripts/bar/generate_bar.sh ${@:2} $overwrite

			add_bar
			exit;;
		I) check_interval=$OPTARG;;
		b)
			bar_expr=$OPTARG

			[[ ${bar_expr//[[:alnum:]_-]/} =~ ^(,+?|)$ ]] &&
				pattern="^(${bar_expr//,/|})$" || pattern="${bar_expr//,/|}"

			[[ $@ =~ -k ]] && remove=true

			read current_running bar_array <<< $(ls $configs | awk -F '/' '\
				BEGIN {
					r = "'$remove'"
					lr = "'$last_running'"
				}

				$NF ~ /^'${pattern//\*/\.\*}'/ {
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

			#[[ $current_running != ${last_running:-none} ]] && recalculate_offsets=true
			[[ $current_running == none ]] && unset current_running
			[[ $current_running != $last_running ]] && recalculate_offsets=true
			#[[ $last_running == none ]] && unset last_running

			bars=( $bar_array )
			bar_count=${#bars[*]}

			sed -i "/^last_running/ s/[^=]*$/$current_running/" $0;;
		M) memory_tolerance=$OPTARG;;
		m) move=true;;
		E)
			inherit_config=$configs/$OPTARG
			[[ ! ${!OPTIND} =~ ^- ]] && inherit_flag=${!OPTIND} && shift;;
		[erias])
			if [[ $flag == [rias] ]]; then
				[[ $inherit_flag ]] &&
					new_flag=$inherit_flag || new_flag=new_flag
				read reference_flag $new_flag new_args <<< ${@:OPTIND}

				[[ $flag == a ]] &&
					pattern="(.*-${reference_flag: -1}[^-]*)(.*)" ||
					pattern="(.*)(-${reference_flag: -1}.*)" suffix=" "
			else
				all="$@"
				args="${all#*-[erias] }"

				edit_flag="${args%% *}"
				edit_args="${args#$edit_flag}"
			fi

			[[ $edit_flag =~ y ]] && recalculate_offsets=true

				#awk -i inplace '
				#	{
				#		f = "-'$flag'"
				#		a = "'"$args"'"
				#		if(a) a = " " a
				#		sf = "'"$suffix"'"

				#		if(!sf && "-" f "[^-]*$") pf = " "
				#		$0 = gensub("'"$pattern"'", "\\1" pf f a sf "\\2", 1)
				#		print
				#	}' $edit_config

			((bar_count)) || get_bars
			((bar_count > 1)) && all_bars="${bars[*]}" || bar=$bars

			edit_config=$(eval echo $configs/${bar:-{${all_bars// /,}\}})

			awk -i inplace '\
				function get_new_value(flag) {
					return gensub("((([^-]*-[^" flag "])*[^-]*-" flag ")([^0-9]*([0-9]+)){" ai "}[^-]*).*", "\\5", 1)
				}

				function replace_value() {
					#system("~/.orw/scripts/notify.sh \"^" nv "\"")
					$0 = gensub("(([^-]*-[^" f "])*[^" f "]*" f ")((([0-9]+)?([^0-9]*)){" ai "})[0-9]+(.*)", "\\1\\3" nv "\\7", 1)
				}

				BEGIN {
					sf = "'"$suffix"'"
					n_f = "'$new_flag'"
					e_a = "'"${new_args:-$edit_args}"'"
					e_f = "'${reference_flag:-$edit_flag}'"

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

							#for(iai in ia) naa[iai] = gensub(".*-" ia[iai] " ([^-]*).*", "\\1", 1)
							#for(iai in ia) naa[iai] = gensub("(([^-]*-[^" ia[iai] "])*[^-]*-" ia[iai] ") ([^-]*).*", "\\3", 1)

							#for(iai in ia) {
							#	iv = gensub("(([^-]*-[^" ia[iai] "])*[^-]*-" ia[iai] ") ([^-]*).*", "\\3", 1)
							#	sub("\\s*$", "", iv)
							#	naa[iai] = iv
							#}

							#for(iai in ia) naa[iai] = gensub("(([^-]*-[^" ia[iai] "])*[^-]*-" ia[iai] ") ([^-]*).*", "\\3", 1)
							for(iai in ia) {
								naa[iai] = gensub("(([^-]*-[^" ia[iai] "])*[^-]*-" ia[iai] ") ([^-]*).*", "\\3", 1)
								if("'$move'") sub(" -" ia[iai] "[^-]*", "")
							}

							print
							nextfile
						}

						for(fi in fa) {
							f = fa[fi]

							#if(length(naa)) {
							#	if(length(naa[fi])) p = naa[fi]
							#} else p = e_a

							p = (length(naa) && length(naa[fi])) ? naa[fi] : e_a
							sub("\\s*$", "", p)

							if("'$flag'" ~ "^[rias]$") {
								if("'$flag'" == "s") {
									o_i = index($0, "-" f)
									n_i = index($0, "-" n_f)
									if(o_i > n_i) { f_f = n_f; s_f = f } else { f_f = f; s_f = n_f }

									f_m = gensub(".*(-" f_f "[^-]*).*", "\\1", 1)
									s_m = gensub(".*(-" s_f "[^-]*).*", "\\1", 1)

									sub(s_m, f_m)
									sub(f_m, s_m)
									#print
									#exit

									#o_m = $(gensub(".*(-" f "[^-]*).*", "\\1", 1)
									#n_m = $(gensub(".*(-" n_f "[^-]*).*", "\\1", 1)
								} else {
									if(p) p = " " p
									if(!sf && $0 ~ "-" f "[^-]*$") pf = " "; else sf = " "

									#print "here " f, "^" pf "^ ^" sh "^ ^" p "^"

									if("'$flag'" == "r") {
										r_f = (p) ? "-" n_f p sf : p = gensub(".*(-" n_f "[^-]*).*", "\\1", 1)
										#print "r_f: ^" r_f "^"
										sub("-" e_f "[^-]*", r_f)
									} else {
										$0 = gensub("'"$pattern"'", "\\1" pf "-" n_f p sf "\\2", 1)
									}
								}
							} else if(i_c) {
								sub("-" f "[^-]*", "-" f " " p)
							} else {
								sub("-" f "[^-]*", ("'$flag'" == "r") ? "" : "-" f " " e_a " ")
							}
						}
					}

					print
				}' $inherit_config $edit_config
			#exit

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
					#read y_end bottom display <<< $(awk '
					#	function get_value(module) {
					#		if($0 ~ "-" module) {
					#			return gensub("(([^-]*-[^" module "]*)*)[^-]*-" module "[^0-9]*([0-9]+) .*", "\\3", 1)
					#		}
					#	}

					#	END {
					#		ye = get_value("y") + get_value("h") + get_value("f") + get_value("F") * 2
					#		s = get_value("S")
					#		print ye, (/-y b/), s
					#	}' $configs/$bar)

					#read is_last_bar display <<< $(awk -F '[_ ]' '
					#	$1 == "primary" { d = ('${display:-0}') ? '${display:-0}' : $NF }
					#	$2 == d && $3 == "offset" { print $('$bottom' + 4) == '$y_end', d }' ~/.config/orw/config)

					kill_bar

					#if ((is_last_bar)); then
					#	delta=$(~/.orw/scripts/assign_bars_to_displays.sh -o | \
					#		awk '$1 == "display_'$display'" { print '$y_end' - $('$bottom' + 2) }')

					#	if ((bottom)); then
					#		((delta > max_bottom_delta)) && max_bottom_delta=$delta
					#	else
					#		((delta > max_top_delta)) && max_top_delta=$delta
					#	fi

					#	#if ((bottom)); then
					#	#	((y_end > max_y_bottom_end)) && max_y_bottom_end=$y_end
					#	#else
					#	#	((y_end > max_y_top_end)) && max_y_top_end=$y_end
					#	#fi
					#fi
				done

				#[[ $recalculate_offsets ]] && ~/.orw/scripts/assign_bars_to_displays.sh &

				#offsets=$(~/.orw/scripts/assign_bars_to_displays.sh -d | awk '{ wo = wo " " $0 }
				#										END { print gensub("\\<0\\>", "", "g", wo) }')

				#offsets=$(~/.orw/scripts/assign_bars_to_displays.sh -d | awk '{ wo = wo " " $0 }
				offsets=$(~/.orw/scripts/get_bar_offset.sh -d | awk '{ wo = wo " " $0 }
					END { gsub("\\<0\\>| ", ",", wo); print gensub(",{2,}", ",", "g", wo) }')
					#END { gsub(" ?\\<0\\> ?", ",", wo); print gensub(",{2,}", ",", "g", wo) }')

				#[[ ${offsets//,/} ]] && ~/.orw/scripts/offset_tiled_windows.sh -y "+${offsets#,}"
				[[ ${offsets//,/} ]] && ~/.orw/scripts/offset_tiled_windows.sh -y "${offsets#,}"
				exit
				echo top delta: $max_top_delta
				echo bottom delta: $max_bottom_delta
				exit
			else
				#ps -C barctl.sh o pid= --sort=-start_time | awk 'NR > 1' | xargs kill &> /dev/null
				kill_running_script
				sleep 0.1
				killall generate_bar.sh lemonbar
			fi

			#~/.orw/scripts/assign_bars_to_displays.sh
			exit;;
		l)
			get_bars
			lower_bars
			exit;;
		L)
			~/.orw/scripts/add_bar_launcher.sh ${@:2}
			exit;;
		#a)
		#	read position flag args <<< ${@:OPTIND}
		#	[[ ${#position} == 2 && ${position:0:1} == b ]] &&
		#		pattern="(.*)(-${position: -1}.*)" suffix=" " ||
		#		pattern="(.*-${position: -1}[^-]*)(.*)"

		#		((bar_count)) || get_bars
		#		((bar_count > 1)) && all_bars="${bars[*]}" || bar=$bars

		#		edit_config=$(eval echo $configs/${bar:-{${all_bars// /,}\}})

		#		#awk '{ print (/-d[^-]*$/) }' ~/.config/orw/bar/configs/moun
		#		#exit

		#		#awk '{ print gensub("'"$pattern"'", "\\1   SOLA   \\2", 1) }' $edit_config
		#		#awk '{ print gensub("'"$pattern"'", "\\1-'$flag' '"$args"' \\2", 1) }' $edit_config

		#		awk -i inplace '
		#			{
		#				f = "-'$flag'"
		#				a = "'"$args"'"
		#				if(a) a = " " a
		#				sf = "'"$suffix"'"

		#				if(!sf && "-" f "[^-]*$") pf = " "
		#				$0 = gensub("'"$pattern"'", "\\1" pf f a sf "\\2", 1)
		#				print
		#			}' $edit_config;;
		n) no_reload=true;;
		c)
			config=$OPTARG
			clone_config=${!OPTIND}
			config_path=~/.config/orw/bar/configs

			shift

			#cp $config_path/$config $config_path/$clone_config
			#sed -n "s/\(.*c\).*/\\1/1p" $config_path/$config
			#sed -n "s/\(\([^-]*-[^c]\)*[^-]*-c\)/\\1 bar_$clone_config/p" $config_path/$config

			#awk '{
			#	$0 = gensub("(([^-]*-[^c])*[^-]*-c)", "\\1 bar_'$clone_config'", 1)
			#	$0 = gensub("(.*-n)( [^ ]*)", "\\1 '$clone_config'", 1, $0)
			#	print
			#}' $config_path/$config > $config_path/$clone_config

			awk '{
				$0 = gensub(/(-c).(\w*)[^-]*/, "\\1,bar_'$clone_config' \\2 ", 1)
				print gensub(/-n [^ ]*/, "-n '$clone_config'", 1)
			}' $config_path/$config > $config_path/$clone_config

			bar=$clone_config
			bars=( $bar )
			add_bar
	esac
done

[[ -z $@ ]] && bars=( ${last_running//,/ } )
[[ $move ]] && bars+=( ${inherit_config##*/} )

if [[ ! $no_reload ]]; then
	current_pid=$$
	#ps -C barctl.sh o pid= --sort=-start_time | grep -v $current_pid | xargs kill 2> /dev/null
	kill_running_script

	while true; do
		monitor_memory_consumption
		sleep ${check_interval:-100}
	done &

	[[ ! $bars ]] && get_bars

	for bar in "${bars[@]}"; do
		kill_bar
		bash $configs/$bar &
	done

	#sleep 1
	#last_bar_pid=$!
	[[ $recalculate_offsets ]] &&
		#offsets=$(~/.orw/scripts/assign_bars_to_displays.sh -dc ${#bars[*]} | \
		offsets=$(~/.orw/scripts/get_bar_offset.sh -dc ${#bars[*]} | \
			awk '{ wo = wo " " $0 } END { gsub("\\<0\\>| ", ",", wo); print gensub(",{2,}", ",", "g", wo) }')
			#END { gsub(" ?\\<0\\> ?", ",", wo); print gensub(",{2,}", ",", "g", wo) }')

	[[ ${offsets//,/} ]] && ~/.orw/scripts/offset_tiled_windows.sh -y "${offsets#,}"
fi
