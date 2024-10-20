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

add_bar() {
	[[ $last_running ]] && separator=,
	sed -i "/^last_running/ { /\<$bar\>/! s/$/$separator$bar/ }" $0
}

configs=~/.config/orw/bar/configs
last_running=under_join

while getopts :dI:gb:M:E:eriamsR:klLnc:u flag; do
	case $flag in
		g)
			bar=$(sed "s/.*-n \(\w*\).*/\1/" <<< $@)
			kill_bar

			[[ -f $configs/$bar ]] && overwrite=-o
			~/bar_new/run.sh ${@:2} $overwrite

			add_bar
			exit
			;;
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

			[[ $current_running == none ]] && unset current_running
			[[ $current_running != $last_running ]] && recalculate_offsets=true

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
					sf = "'"$suffix"'"
					n_f = "'$new_flag'"
					e_a = "'"${new_args:-$edit_args}"'"
					e_f = "'${reference_flag:-$edit_flag}'"

					i_c = "'"$inherit_config"'"
					if(i_c) i_f = "'${inherit_flag:-$edit_flag}'"

					split(e_a, aa)
					split(e_f, fa, ",")
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

							for(iai in ia) {
								naa[iai] = gensub("(([^-]*-[^" ia[iai] "])*[^-]*-" ia[iai] ") ([^-]*).*", "\\3", 1)
								if("'$move'") sub(" -" ia[iai] "[^-]*", "")
							}

							print
							nextfile
						}

						for(fi in fa) {
							f = fa[fi]

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
								} else {
									if(p) p = " " p
									if(!sf && $0 ~ "-" f "[^-]*$") pf = " "; else sf = " "

									if("'$flag'" == "r") {
										r_f = (p) ? "-" n_f p sf : p = gensub(".*(-" n_f "[^-]*).*", "\\1", 1)
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

			break;;
		R)
			modules="${OPTARG//\*/\.\*}"
			colorscheme_name="${!OPTIND}"

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
				killall run.sh lemonbar
				bars=( ${last_running//,/ } )
			fi

			killed=true;;
		l)
			get_bars
			lower_bars
			exit;;
		L)
			~/.orw/scripts/add_bar_launcher.sh ${@:2}
			exit;;
		n) no_reload=true;;
		c)
			config=$OPTARG
			clone_config=${!OPTIND}
			config_path=~/.config/orw/bar/configs

			shift

			awk '{
				$0 = gensub(/(-c).(\w*)[^-]*/, "\\1,bar_'$clone_config' \\2 ", 1)
				print gensub(/-n [^ ]*/, "-n '$clone_config'", 1)
			}' $config_path/$config > $config_path/$clone_config

			bar=$clone_config
			bars=( $bar )
			add_bar
			;;
		u)
			while read pid; do
				kill -10 $pid
			done <<< $(ps -C run.sh -o pid=,ppid= |
				awk '{
						p[$1] = $2
						if ($2 in p) pc[$2]++
					} END {
						for (pi in pc) if (pc[pi] > 1) print pi
					}')
			exit
	esac
done

[[ -z $@ ]] && bars=( ${last_running//,/ } )
[[ $move ]] && bars+=( ${inherit_config##*/} )

check_new_bars() {
	declare -A displays
	local current_bars="${current_running//,/ }"

	read default_y_offset primary_display <<< \
		$(awk -F '[_ ]' '/^(y_offset|primary)/ { print $NF }' ~/.config/orw/config | xargs)

	for bar in ${current_bars:-${bars[@]}}; do
			read display bottom offset <<< $(awk '
				function get_flag(flag) {
					if(match($0, "-" flag "[^-]*")) return substr($0, RSTART + 3, RLENGTH - 3)
				}

				function get_value(flag) {
					gsub("[^0-9]", "", flag)
				}

				/^[^#]/ {
					y = get_flag("y")
					b = (y ~ "b")
					if (y) {
						gsub("[^0-9]", "", y)
					} else y = '$default_y_offset'

					h = get_flag("h")
					if (h) get_value(h)

					f = get_flag("f")
					if (f) {
						m = (f ~ "[ou]") ? 1 : 2
						get_value(f)
						f *= m
					}

					F = get_flag("F")
					if (F) {
						get_value(F)
						F *= 2
					}

					s = get_flag("S")
					if (!s) s = '$primary_display'

					print s, b, y + h + f + F
				}' ~/.config/orw/bar/configs/$bar)

		((!${#displays[$display]})) &&
			display_offsets=( 0 0 ) ||
			read -a display_offsets <<< ${displays[$display]}

		if [[ ! $killed || ($killed && ! ${bars[*]} =~ $bar) ]]; then
			((offset > ${display_offsets[bottom]:-0})) && display_offsets[bottom]=$offset
		fi

		displays[$display]="${display_offsets[*]}"
	done

	update_values=$(awk -i inplace -F '[_ ]' '
		{
			if (NR == FNR) d[$1] = $2 " " $3
			else {
				if ($1 == "display" && $3 == "offset" && $2 in d &&
					$(NF - 1) " " $NF != d[$2]) {
						printf "display_%d_offset %s\n", $2, d[$2]
						uv = 1
						next
					}

				print
			}
		} END { print uv }' <(
			for d in ${!displays[*]}; do
				echo $d ${displays[$d]}
			done
		) ~/.config/orw/config 2> /dev/null)

	((update_values)) && ~/.orw/scripts/signal_windows_event.sh update

	[[ $killed ]] && exit
}

check_new_bars

if [[ ! $no_reload ]]; then
	current_pid=$$
	kill_running_script

	[[ ! $bars ]] && get_bars

	for bar in "${bars[@]}"; do
		kill_bar
		bash $configs/$bar &
	done

	exit

	if [[ $recalculate_offsets ]]; then
		bars+=( ${last_running//,/ } )
		until (($(ps -C lemonbar -o pid= | wc -l) == ${#bars[*]})); do
			sleep 0.1
		done

		~/.orw/scripts/signal_windows_event.sh update
	fi
fi
