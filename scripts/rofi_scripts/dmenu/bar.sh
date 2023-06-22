#!/bin/bash

declare -A modules options segments values

#print_line() {
#	#local item=$1
#	[[ $3 ]] && local item=${3}_$1 || local item=$1
#	eval local item_value=\${$2[$item]}
#	eval [[ \${!$2[*]} =~ $item ]] && local checked= || checked=
#	printf '%s %s%-*s%s\n' $checked $1 $((offset - (${#1} + ${#item_value} + 3))) ' ' "$item_value"
#	#printf '%s %s%-*s%s\n' $checked $item $((offset - (${#item} + ${#item_value} + 3))) ' ' "$item_value"
#}

print_line() {
	[[ $1 =~ offset|separator ]] && local item=${segment:-$module}_$1 || local item=$1
	#[[ $1 =~ offset|separator ]] && eval ~/.orw/scripts/notify.sh "pre $1, $item, \${$2[$item]}"
	eval local item_value=\${$2[$item]}
	eval [[ \${!$2[*]} =~ $item ]] && local checked= || checked=
	#eval [[ \${!$2[*]} =~ \(^\| \)$item\( \|\$\) ]] && local checked= || checked=
	printf '%s %s%-*s%s\n' $checked $1 $((offset - (${#1} + ${#item_value} + 3))) ' ' "$item_value"
	#[[ $1 =~ offset|separator ]] && eval ~/.orw/scripts/notify.sh "post $1, $item, \${$2[$item]}"
}

list_modules() {
	echo done

	for module in apps mpd workspaces launchers bar_frame frame memory cpu disk_space emails updates networks rss volume joiner power; do
		print_line $module modules
	done
}

list_options() {
	local option_list

	case ${1:-$module} in
		apps) option_list='separator offset length workspace';;
		mpd) option_list='slide info progressbar time secondary_color toggle controls front_offset end_offset ';;
		workspaces) option_list='offset labels separator';;
		launchers) option_list='active offset separator module_padding';;
		frame) option_list='width edge';;
		joiner) option_list='distance half_bg next_bg symbol';;
		power) option_list='size buttons colorscheme';;
		buttons) option_list='icons offset separator actions';;
		colorscheme) option_list='current choose';;
	esac

	~/.orw/scripts/notify.sh "listing ${1:-$module}"

	echo -e 'back\ndone\nremove'

	for option in $option_list; do
		print_line $option options
	done
}

list_segments() {
	local segment_list

	case $option in
		controls) segment_list='prev next play/pause toggle_circle controls_separator';;
		progressbar) segment_list='step dashed';;
		#buttons) segment_list='icons offset separator actions';;
		size) segment_list='width height';;
		actions) segment_list='lock logout reboot suspend poweroff';;
	esac

	echo -e 'back\ndone\nremove'

	for segment in $segment_list; do
		print_line $segment segments
	done
}

list_values() {
	case $1 in
		labels)
			cat <<- EOF
				label
				numeric
				icons_circle_full
				icons_circle_empty
				icons_circle_check
				icons_circle_small
				icons_square_full
				icons_square_empty
				icons_square_check
				icons_square_small
				icons_rounded_square_full
				icons_rounded_square_empty
				icons_rounded_square_check
			EOF
			;;
		workspace) echo -e 'all\ncurrent';;
		offset) echo -e 'inner\npadding';;
		edge) echo -e 'all\ntop\nbottom';;
		actions) echo -e 'lock\nlogout\nreboot\nsuspend\npoweroff';;
		buttons) echo -e 'icons\noffset\nseparator\nactions';;
		colorschemes) echo -e 'current\nchoose';;
		#next_module_bg) echo -e 'half_bg\nnext_bg';;
		choose) ls ~/.config/orw/colorschemes/ | awk '{ print gensub(".*/(.*).ocs", "\\1", 1) }';;
		*) echo remove;;
	esac
}

get_shorthand() {
	case $1 in
		icon*) shorthand=$(sed 's/\(\w\)[^_]*_\?/\1/g' <<< $1);;
		step) shorthand=s;;
		labels) shorthand=l;;
		controls_separator) shorthand=S;;
		*separator) shorthand=s;;
		padding|module_padding) shorthand=p;;
		active) shorthand=a;;
		length) shorthand=l;;
		workspaces) shorthand=w;;
		all) shorthand=a;;
		current) shorthand=c;;
		slide) shorthand=s;;
		info) shorthand=i;;
		progressbar) shorthand=p;;
		time) shorthand=T;;
		secondary_color) shorthand=P;;
		toggle) shorthand=t;;
		controls) shorthand=c;;
		front_offset) shorthand=of;;
		end_offset) shorthand=oe;;
		*offset) shorthand=o;;
		separator) shorthand=s;;
		prev) shorthand=p;;
		play/pause) shorthand=t;;
		next) shorthand=n;;
		toggle_circle) shorthand=c;;
		dashed) shorthand=d;;
		launchers) shorthand=l;;
		frame) shorthand=f;;
		bar_frame) shorthand=F;;
		top) shorthand=o;;
		bottom) shorthand=u;;
		all) shorthand=a;;
		mpd) shorthand=m;;
		memory) shorthand=M;;
		cpu) shorthand=C;;
		disk_space) shorthand=D;;
		emails) shorthand=e;;
		date) shorthand=d;;
		half_bg) shorthand=h;;
		next_bg) shorthand=n;;
		joiner) shorthand=j;;
		icons) shorthand=i;;
		lock) shorthand=L;;
		logout) shorthand=l;;
		reboot) shorthand=r;;
		suspend) shorthand=s;;
		poweroff) shorthand=o;;
		power) shorthand=P;;
		*) [[ $1 =~ ^[0-9]+$ ]] && shorthand=$1 || unset shorthand
	esac
}

remove_value() {
	local value=${!1} variable

	[[ -z $variable ]] &&
		case $1 in
			segment) variable=values;;
			option) variable=module_options;;
			module) variable=all_modules;;
		esac

	[[ $1 == module ]] &&
		local shorthand=" -$shorthand "

	local pattern="$shorthand\${${1}s[$value]}"

	if [[ $1 == option ]]; then
		shopt -s extglob
		[[ $module_options =~ ^$shorthand ]] &&
			pattern+="?(,)" || pattern="?(,)$pattern"
			#pattern="$shorthand+(,)" || pattern="+(,)$shorthand"
	fi

	#eval echo pattern: "$pattern"
	#eval echo var: "\"\${$variable/$pattern/}\""

	#eval echo remove: "${pattern:-$shorthand}\${${1}s[$value]}"
	#eval $variable="\"\${$variable/${pattern:-$shorthand}\${${1}s[$value]}/}\""
	eval $variable="\"\${$variable/$pattern/}\""
	eval unset ${1}s[$value]
}

add_value() {
	local value=${!1} array=${1}s variable

	case $1 in
		segment) variable=values;;
		option) variable=module_options;;
		module) variable=all_modules;;
	esac

	[[ $1 == module ]] &&
		local shorthand=" -$shorthand" separator=' ' new_separator=' '

	if [[ "$(eval echo \${!$array[*]})" =~ $value ]]; then
		#if [[ $no_values =~ $value ]]; then
		#	if [[ $1 == option ]]; then
		#		shopt -s extglob
		#		local pattern
		#		[[ $module_options =~ ^$shorthand ]] &&
		#			pattern="$shorthand+(,)" || pattern="+(,)$shorthand"
		#	fi

		#	eval $variable="\"\${$variable/${pattern:-$shorthand}/}\""
		#	eval unset $array[$value]
		#else
		#	eval $variable="\"\${$variable/$shorthand$separator\${$array[$value]}/$shorthand$separator$2}\""
		#	eval $array[$value]="\"$2\""
		#fi
		if [[ $no_values =~ " $value " ]]; then
			remove_value $1
		else
			eval $variable="\"\${$variable/$shorthand$separator\${$array[$value]}/$shorthand$separator$2}\""
			eval $array[$value]="\"$2\""
		fi
	else
		[[ $1 == option ]] && local separator=,
		#[[ $1 == module ]] && local shorthand=" -$shorthand "
		[[ ${!variable} ]] &&
			eval $variable=\"${!variable}$separator$shorthand$new_separator$2\" ||
			eval $variable=\"$shorthand$new_separator$2\"

		[[ $repeatable_segments =~ $value ]] || eval $array[$value]="$2"
	fi
}

display_width=$(awk '\
	BEGIN {
		id = "'$id'"
		wx = '${window_x:-0}'
		wy = '${window_y:-0}'
	}

	{
		if(!id) {
			if($1 == "primary") p = $NF
			if(p && $1 == p "_size") {
				print $2
				exit
			}
		} else {
			if(/^display/) {
				if($1 ~ /xy$/) {
					x = $2
					y = $3
				} else if($1 ~ /size$/) {
					if(wx < x + $2 && wy < y + $3) {
						print $2
						exit
					}
				}
			}
		}
	}' ~/.config/orw/config)

offset=$(awk '
	function get_value() {
		return gensub(".* ([0-9]+).*", "\\1", 1)
		#return gensub("[^0-9]*([0-9]+).*", "\\1", 1)
	}

	$1 == "font:" { f = get_value() }
	$1 == "window-width:" { ww = get_value() }
	$1 == "window-padding:" { wp = get_value() }
	$1 == "element-padding:" { ep = get_value() }
	END {
		rw = int('$display_width' * ww / 100)
		iw = rw - 2 * (wp + ep)
		print int(iw / (f - 2))
	}' ~/.config/rofi/list.rasi)

multi_segment_options='progressbar,controls,size,actions'
multi_values='labels,workspace,offset,edge'
repeatable_segments='front_offset end_offset toggle_circle frame joiner bar_offset bar_separator padding'

no_values=' cpu memory disk_space networks updates emails rss volume'
no_values+=' secondary_color info volume module_padding active top bottom all'
no_values+=' prev play/pause next toggle_circle dashed remain half_bg lock logout reboot suspend poweroff icons '

until [[ $check == done ]]; do
	if [[ $module && $repeatable_segments =~ $module ]]; then
		for option in $(list_options | xargs); do
			unset options[$option]
		done
	fi

	read check module module_options <<< $(list_modules | rofi -dmenu -theme list)

	#[[ $check == done ]] && module=done

	#if [[ ! $module =~ back|done ]]; then
	if [[ $check != done ]]; then
		if [[ ! $no_values =~ " $module " ]]; then
			until [[ $check =~ back|done|remove ]]; do
				#if [[ $option =~ buttons|actions ]]; then
				#if [[ $module == power && $option =~ buttons|icons|offset|separator|actions ]]; then
					#[[ $option =~ buttons|icons|offset|separator|actions && $check != done ]] &&

				#if [[ $module == power ]]; then
				#	[[ $option =~ buttons|icons|offset|separator|actions ]] && sub_options=buttons
				#	[[ $option == colorscheme ]] && sub_options=colorscheme

				echo m: $module, o :$option

				if [[ $module == power && $option =~ colorscheme|buttons|icons|offset|separator|actions ]]; then
					echo HERE

					#[[ $sub_options ]] &&
					[[ $option == colorscheme ]] && sub_options=colorscheme || sub_options=buttons
					read index check option value <<< $(list_options $sub_options | rofi -dmenu -p '' -format 'i s' -selected-row $index -theme list)
				else
					read index check option value <<< $(list_options | rofi -dmenu -p '' -format 'i s' -selected-row $index -theme list)
				fi

				#read index check option value <<< $(list_options | rofi -dmenu -p '' -format 'i s' -selected-row $index -theme list)

				if [[ $check == remove ]]; then
					get_shorthand $module
					remove_value module 
				fi

				if [[ ! $check =~ back|done|remove ]]; then
					[[ $option =~ offset|separator ]] && option=${module}_$option
					[[ $value && $value == ${options[$option]} ]] && values="${value//,/ }" && unset value

					#echo o: $option, v: ${options[$option]}, ao: ${!options[*]}

					if [[ -z $value ]]; then
						if [[ $multi_segment_options =~ $option ]]; then
							until [[ $check =~ back|done|remove ]]; do
								read index check segment value <<< $(list_segments | rofi -dmenu -p '' -format 'i s' -selected-row $index -theme list)

								if [[ $check == remove ]]; then
									get_shorthand $option
									remove_value option 
								fi
								#[[ $check == remove ]] && remove_value option 
								#[[ $check == done ]] && segment=done

								if [[ ! $check =~ back|done|remove ]]; then
									#[[ ! $value && ! $multi_values =~ $segment && ! $no_values =~ " $segment " ]] &&
									[[ ! $multi_values =~ $segment && ! $no_values =~ " $segment " ]] &&
										value=$(list_values $segment | rofi -dmenu -p "$option -> $segment value" -theme list)

									get_shorthand $segment
									[[ $value == remove ]] &&
										remove_value segment || add_value segment "$value"

									#if [[ ${!segments[*]} =~ $segment ]]; then
									#	if [[ $no_values =~ $segment ]]; then
									#		#values="${values/$shorthand${segments[$segment]}/}"
									#		values="${values/$shorthand/}"
									#		unset segments[$segment]
									#	else
									#		values="${values/$shorthand${segments[$segment]}/$shorthand$value}"
									#		segments[$segment]="$shorthand$value"
									#	fi
									#else
									#	values+=$shorthand$value
									#	segments[$segment]="$value"
									#fi
								fi
							done

							value=$values
							unset segment values
						else
							#echo HERE o: $option, v: $value
							#if [[ $multi_values =~ $option ]]; then
							#	value=$(list_values $option | rofi -dmenu -theme list)
							#fi

							#[[ $multi_values =~ $option ]] &&
							#	value=$(list_values $option | rofi -dmenu -theme list) ||

							[[ $no_values =~ $option ]] ||
								value=$(list_values $option | rofi -dmenu -theme list)

							#get_shorthand ${value:-$option}
							#[[ $value == remove ]] && remove_value option || value=$shorthand

							if [[ $value == remove ]]; then
								get_shorthand $option
								remove_value option
							else
								get_shorthand $value
								value=$shorthand
							fi

							#value=$shorthand
						fi
					fi

					#if [[ $option == size ]]; then
					#	echo o: $option, s: $segment, v: $value
					#	echo as: ${!segments[*]}
					#	echo ${segments[width]}, ${segments[height]}
					#	exit
					#	options[size]="${segments[width]}x${segments[height]}"
					#fi

					[[ $option == size ]] && value="${segments[width]}x${segments[height]}"

					get_shorthand $option

					#if [[ $check != remove ]]; then
					#	[[ $shorthand == o[fe] ]] &&
					#		module_options+="$shorthand,$value" ||
					#		add_value option "$value"
					#fi

					#[[ $check != remove ]] && add_value option "$value"
					[[ $check != remove && $value != remove ]] && add_value option "$value"

					#if [[ ${!options[*]} =~ $option ]]; then
					#	if [[ $no_values =~ $option ]]; then
					#		shopt -s extglob

					#		[[ $module_options =~ ^$shorthand ]] &&
					#			pattern="$shorthand+(,)" || pattern="+(,)$shorthand"
					#		module_options="${module_options/$pattern/}"
					#		#~/.orw/scripts/notify.sh "o: $option ${options[$option]}"
					#		#~/.orw/scripts/notify.sh "ao: ${!options[*]}"
					#		unset options[$option]
					#	else
					#		module_options="${module_options/$shorthand${options[$option]}/$shorthand$value}"
					#		options[$option]="$value"
					#	fi
					#else
					#	[[ $module_options ]] &&
					#		module_options="$module_options,$shorthand$value" ||
					#		module_options="$shorthand$value"

					#	options[$option]="$value"
					#fi

					[[ $option ]] && check=$option
				fi
			done

			#echo o: $option, m: $module
			[[ $module == power && -z $option ]] &&
				read index check option value <<< $(list_options buttons | rofi -dmenu -p '' -format 'i s' -selected-row $index -theme list)
			#[[ $repeatable_segments =~ $module ]] && unset options[$option]
		fi

		get_shorthand $module

		#[[ ${!modules[*]} =~ $module && $module != [psjfO] ]] &&
		#	all_modules="${all_modules//-$shorthand ${modules[$module]}/-$shorthand $module_options}" ||
		#	all_modules+=" -$shorthand $module_options"

		#[[ $module == [psjfO] ]] &&
		#	all_modules+=" -$shorthand ${module_options//,/ }" ||
		#	add_value module "$value"

		if [[ $shorthand == [psjfO] ]]; then
			[[ $module_options ]] &&
				repeatable_module_options=" ${module_options//,/ }" ||
				unset repeatable_module_options
			all_modules+=" -$shorthand$repeatable_module_options"
		else
			[[ $check != remove ]] && add_value module "$module_options"
		fi

		[[ $module ]] && check=$module
		#modules[$module]="${module_options// /,}"
		unset value module_options
	fi

	#unset option
done

echo "generate_bar.sh$all_modules"
