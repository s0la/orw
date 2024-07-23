#!/bin/bash

declare -A modules options segments values

print_line() {
	[[ $1 =~ offset|separator ]] && local item=${segment:-$module}_$1 || local item=$1
	eval local item_value=\${$2[$item]}
	eval [[ \${!$2[*]} =~ $item ]] && local checked= || checked=
	printf '%s %s%-*s%s\n' $checked $1 $((offset - (${#1} + ${#item_value} + 3))) ' ' "$item_value"
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
	fi

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
		if [[ $no_values =~ " $value " ]]; then
			remove_value $1
		else
			eval $variable="\"\${$variable/$shorthand$separator\${$array[$value]}/$shorthand$separator$2}\""
			eval $array[$value]="\"$2\""
		fi
	else
		[[ $1 == option ]] && local separator=,
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

	if [[ $check != done ]]; then
		if [[ ! $no_values =~ " $module " ]]; then
			until [[ $check =~ back|done|remove ]]; do
				if [[ $module == power && $option =~ colorscheme|buttons|icons|offset|separator|actions ]]; then
					[[ $option == colorscheme ]] && sub_options=colorscheme || sub_options=buttons
					read index check option value <<< $(list_options $sub_options | rofi -dmenu -p '' -format 'i s' -selected-row $index -theme list)
				else
					read index check option value <<< $(list_options | rofi -dmenu -p '' -format 'i s' -selected-row $index -theme list)
				fi

				if [[ $check == remove ]]; then
					get_shorthand $module
					remove_value module 
				fi

				if [[ ! $check =~ back|done|remove ]]; then
					[[ $option =~ offset|separator ]] && option=${module}_$option
					[[ $value && $value == ${options[$option]} ]] && values="${value//,/ }" && unset value

					if [[ -z $value ]]; then
						if [[ $multi_segment_options =~ $option ]]; then
							until [[ $check =~ back|done|remove ]]; do
								read index check segment value <<< $(list_segments | rofi -dmenu -p '' -format 'i s' -selected-row $index -theme list)

								if [[ $check == remove ]]; then
									get_shorthand $option
									remove_value option 
								fi

								if [[ ! $check =~ back|done|remove ]]; then
									[[ ! $multi_values =~ $segment && ! $no_values =~ " $segment " ]] &&
										value=$(list_values $segment | rofi -dmenu -p "$option -> $segment value" -theme list)

									get_shorthand $segment
									[[ $value == remove ]] &&
										remove_value segment || add_value segment "$value"
								fi
							done

							value=$values
							unset segment values
						else
							[[ $no_values =~ $option ]] ||
								value=$(list_values $option | rofi -dmenu -theme list)

							if [[ $value == remove ]]; then
								get_shorthand $option
								remove_value option
							else
								get_shorthand $value
								value=$shorthand
							fi
						fi
					fi

					[[ $option == size ]] && value="${segments[width]}x${segments[height]}"

					get_shorthand $option

					[[ $check != remove && $value != remove ]] && add_value option "$value"
					[[ $option ]] && check=$option
				fi
			done

			[[ $module == power && -z $option ]] &&
				read index check option value <<< $(list_options buttons | rofi -dmenu -p '' -format 'i s' -selected-row $index -theme list)
		fi

		get_shorthand $module

		if [[ $shorthand == [psjfO] ]]; then
			[[ $module_options ]] &&
				repeatable_module_options=" ${module_options//,/ }" ||
				unset repeatable_module_options
			all_modules+=" -$shorthand$repeatable_module_options"
		else
			[[ $check != remove ]] && add_value module "$module_options"
		fi

		[[ $module ]] && check=$module
		unset value module_options
	fi
done

echo "generate_bar.sh$all_modules"
