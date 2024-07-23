#!/bin/bash

get() {
	local index=$1_index

	[[ $1 == module ]] && local value_type=options || local value_type=value
	[[ $1 == value || ($1 == module && ${!1} =~ $single_value_modules) ]] &&
		local variables=$value_type || variables="check $1 $value_type"

	read $1_index $variables <<< $(eval list_${1}s \"${2:-$suboption}\" | \
		rofi -dmenu -p "$3" -format 'i s' -selected-row ${!index} -theme list)

	[[ $1 =~ option && ${!1} =~ $alt_named_options ]] &&
		eval $1=${segment:-${suboption:-$module}}_${!1}
	[[ $1 == segment && ${!1} =~ $alt_named_segments ]] &&
		eval $1=${option}_${!1}
}

print_line() {
	[[ $1 == option && $suboption ]] && local array=suboptions_array || local array=${1}s_array
	if [[ $1 =~ option && ${!1} =~ $alt_named_options ]]; then local item=${segment:-${suboption:-$module}}_${!1}
	elif [[ $1 == segment && ${!1} =~ $alt_named_segments ]]; then local item=${option}_${!1}
	else local item=${!1}; fi

	eval local item_name=${!1} item_value=\${$array[$item]}
	eval [[ \${!$array[*]} =~ $item ]] && local checked= || checked=

	printf '%s %s%-*s%s\n' \
		$checked $item_name $((offset - (${#item_name} + ${#item_value} + 3))) ' ' "$item_value"
}

list_modules() {
	echo done

	for module in $1; do
		print_line module modules
	done
}

list_options() {
	local option_list

	case ${1:-$module} in
		x) option_list='offset center right';;
		y) option_list='offset bottom';;
		width) option_list='value adjustable';;
		height|padding|separator) option_list=value;;
		apps) option_list='separator offset length workspace';;
		mpd) option_list='slide info progressbar time secondary_color toggle buttons front_offset end_offset volume';;
		workspaces) option_list='offset padding separator representation';;
		launchers) option_list='offset padding active separator';;
		frame) option_list='width position';;
		joiner)
			option_list='distance '
			[[ ${!options_array[*]} =~ next_bg ]] || option_list+='half_bg '
			[[ ${!options_array[*]} =~ half_bg ]] || option_list+='next_bg '
			option_list+='symbol';;
		icons) option_list='none icon only';;
		power) option_list='size buttons colorscheme';;
		power_buttons) option_list='size icons offset actions';;
		representation) option_list='icons labels numeric';;
		power_colorscheme) option_list='current select';;
		colorscheme)
			[[ ${!options_array[*]} =~ power_colorscheme_select ]] || option_list='name '
			[[ ${!options_array[*]} =~ colorscheme_name ]] && option_list+=clone || option_list+=select;;
		torrent) option_list='count progressbar';;
		date) option_list=format;;
	esac

	echo -e 'back\ndone\nremove'

	for option in $option_list; do
		print_line option options
	done
}

list_segments() {
	local segment_list

	case $option in
		mpd_buttons) segment_list='prev next play/pause circle separator';;
		*progressbar) segment_list='step dashed';;
		power_size) segment_list='width height';;
		power_buttons_actions) segment_list='lock logout reboot suspend poweroff';;
	esac

	echo -e 'back\ndone\nremove'

	for segment in $segment_list; do
		print_line segment segments
	done
}

list_workspace_icons() {
	awk '
		function get_icon() {
			return gensub("^[^_]*_(.*)(_[^_]*){2}=[^}]*}([^%]*).*", "\\1 \\3", 1)
		}

		/Workspace.*_[psar]\w*_icon/ {
			nai = get_icon()
			split(nai, naia)
			n = gensub("(.)[^_]*_?", "\\1", "g", naia[1])
			an[n] = an[n] naia[2]
		}

		END {
			for(ni in an) {
				r = ni " " an[ni]
				if(r ~ "(^| )'"$1"'") print ("'"$1"'") ? r : an[ni]
			}
		}' ~/.orw/scripts/bar/icons
}

list_values() {
	case $1 in
		representation_icons) list_workspace_icons;;
		workspace) echo -e 'all\ncurrent';;
		*_offset)
			echo remove
			[[ ! $module =~ (mpd|power|[xy]) ]] && echo -e 'padding\ninner\nvalue';;
		position) echo -e 'remove\naround\nunder\nover';;
		*_separator) echo -e 'remove\nseparator\nvalue';;
		actions) echo -e 'lock\nlogout\nreboot\nsuspend\npoweroff';;
		colorschemes) echo -e 'current\nselect';;
		power_colorscheme_current)
			echo ${options_array[colorscheme_name]:-${options_array[colorscheme_select]}};;
		*select*|*clone)
			ls ~/.config/orw/colorschemes/*ocs | \
				awk 'BEGIN { print "remove" } { print gensub(".*/([^.]*).*", "\\1", 1) }';;
		*) echo remove;;
	esac
}

get_name() {
	if [[ ${#1} -gt 1 && -f ~/.config/orw/colorschemes/$1.ocs  ]]; then
		short=$1
	else
		case $1 in
			x) short=x full=x;;
			y) short=y full=y;;
			w|*width)
				short=w
				[[ $module =~ frame ]] && full=${module}_width || full=width;;
			h|*height)
				short=h
				[[ ! $module || $module == height ]] && full=height || full=${module}_height;;
			F|bar_frame) short=F full=bar_frame;;
			f|*frame) short=f full=frame;;
			frame_top) short=o full=frame_top;;
			frame_bottom|u) short=u full=frame_bottom;;
			j|joiner) short=j full=joiner;;
			*bottom|mpd_buttons|b)
				short=b
				[[ $module == y ]] && full=bottom || full=mpd_buttons;;
			of|mpd_front_offset) short=of full=front_offset;;
			oe|mpd_end_offset) short=oe full=end_offset;;
			O|o|*offset|poweroff|over)
				if [[ ! $module || $module == offset ]]; then
					short=O full=offset
				else
					short=o

					[[ $option =~ $suboptions_options ]] && local suboption=$option

					[[ $option =~ $suboptions_options ]] && local suboption=$option
					[[ $option == power_buttons_actions ]] &&
						full=poweroff || full=${suboption:-$module}_offset
				fi;;
			u|under) short=u full=under;;
			P|power) short=P full=power;;
			p|*padding|*progressbar)
				short=p
				[[ $module && $module != padding ]] && local prefix="${suboption:-$module}_"
				[[ $module == mpd ]] && full=$option || full=${prefix}padding;;
			s|*separator|*size|slide|*step|suspend)
				if [[ $module == font_size ]]; then
					short=a full=font_size
				else
					short=s

					if [[ $module == power ]]; then
						case $option in
							*actions) full=suspend;;
							*) [[ $option =~ buttons ]] && full=power_buttons_size || full=power_size;;
						esac
					elif [[ $1 == *step ]]; then
						full=${module}_step
					elif [[ $module == mpd ]]; then
						full=slide
					else
						[[ $value == separator ]] && unset short
						[[ ! $module || $module == separator ]] && full=separator || full=${module}_separator
					fi
				fi;;
			b|mpd_buttons) short=b full=mpd_buttons;;
			c|center|circle|current)
				short=c
				if [[ $module ]]; then
					[[ $module == apps ]] && full=current || full=center
				else
					[[ ${module_options:-$options} ]] && full=colorscheme || full=center
				fi;;
			l|labels|logout)
				short=l
				[[ $module == workspaces ]] && full=labels || full=logout;;
			L|lock) short=L full=lock;;
			r|right|reboot)
				short=r
				[[ $module == power ]] && full=reboot || full=right;;
			d|date|*dashed)
				short=d
				case $module in
					mpd) full=${option}_dashed;;
					joiner) full=distance;;
					*) full=date
				esac;;
			C|cpu) short=C full=cpu;;
			M|memory) short=M full=memory;;
			D|disks) short=D full=disks;;
			R|rss) short=R full=rss;;
			H|hidden) short=H full=hidden;;
			m|mpd) short=m full=mpd;;
			e|email) short=e full=email;;
			v|*volume)
				short=v
				[[ $module == mpd ]] && full=mpd_volume || full=volume;;
			N|network) short=N full=network;;
			A|apps) short=A full=apps;;
			L|launchers) short=L full=launchers;;
			W|workspaces) short=W full=workspaces;;
			a|adjustable|around|active|power_buttons_actions)
				short=a

				case $module in
					launchers) full=active;;
					width) full=adjustable;;
					power) full=power_buttons_actions;;
					frame) full=around;;
					*) full=font_size;;
				esac;;
			T|time) short=T full=time;;
			s|step) short=s full=step;;
			*circle_*|*square_*) read full short <<< $(list_workspace_icons $1);;
			i*|icon|*icons|info|inner)
					if [[ ! $module || $module == icons ]]; then
						[[ $option ]] && short=icon full=icon || short=i full=icons
					else
						short=i

						if [[ $module == workspaces ]]; then
							if [[ $option == workspaces_offset ]]; then
								full=inner
							else
								full=representation_icons
								[[ $1 =~ ^i ]] && short=$1
							fi
						else
							[[ $option =~ $suboptions_options ]] && local suboption=$option
							[[ $module == mpd ]] && full=info || full=${suboption:-$module}_icons
						fi
					fi
					;;
			S|slide) short=S full=slide;;
			d|*dashed) short=d full=${option}_dashed;;
			t|torrent|play/pause)
				short=t
				[[ $module == mpd ]] && full=play/pause || full=torrent;;
			p|prev) short=p full=prev;;
			n|name|numeric|next*)
				short=n
				if [[ $module ]]; then
					[[ $module == mpd ]] && full=next || full=numeric
				else
					full=name
				fi
				;;
			colorscheme) short=c full=colorscheme;;
			[^[:alnum:]]*) read short full <<< $(list_workspace_icons $1);;
			*) [[ $1 =~ ^[0-9]+$ || ($option =~ colorscheme && ! $1 =~ colorscheme) ]] &&
				short=$1 || unset short full;;
		esac
	fi
}

get_option() {
	local options=$1
	option_short=${options:$index:1}
	((index++))

	[[ $option_short == [\ ,] ]] &&
		option_short=${options:$index:1} && ((index++))

	[[ $module == mpd && $option_short == o ]] &&
		option_short+=${options:index:1} && ((index++))

	[[ $module == workspaces && $option_short == i ]] &&
		option_short=${options:index - 1} index=${#options}

	get_name $option_short
}

remove_value() {
	local value=${!1} variable=${1}s

	[[ $1 == module ]] &&
		local short=" -$short "
	[[ $1 =~ option && $value =~ ${multi_segment_options/|size} ]] && local new_separator=':'

	eval local pattern="$short$new_separator\${${1}s_array[$value]}"
	local remove_pattern="$pattern"

	if [[ $1 =~ option ]]; then
		shopt -s extglob
		[[ ${!variable} =~ ^$pattern ]] &&
			pattern+="?(,)" || pattern="?(,)$pattern"
	fi

	eval $variable="\"\${$variable/$pattern/}\""
	eval unset ${1}s_array[$value]

	if [[ $1 == suboption ]]; then
		for suboptions_option in ${suboptions_options//|/ }; do
			[[ "$(list_suboptions)" =~ $suboption ]] && break
		done

		local new_option_value=${options_array[$suboptions_option]/$pattern}
		[[ $new_option_value ]] &&
			options_array[$suboptions_option]="$new_option_value" ||
			unset options_array[$suboptions_option]

		[[ $options =~ ^$remove_pattern ]] &&
			options="${options/$remove_pattern?(,)}" || options="${options/?(,)$remove_pattern}"

		unset suboption
	fi

	if [[ ! $1 =~ value|segment ]]; then
		[[ $remove_pattern ]] && options_to_remove=${remove_pattern//[0-9:,]/}

		while ((index < ${#options_to_remove})); do
			get_option $options_to_remove

			if [[ $full ]]; then
				if [[ $full =~ $segment_options ]]; then
					unset segments_array[$full]
				elif [[ $full =~ $all_suboptions ]]; then
					unset suboptions_array[$full]
				else
					unset options_array[$full]
				fi
			fi
		done

		unset index
	fi
}

add_value() {
	local value=${!1} array=${1}s_array variable=${1}s

	get_name $value

	[[ $1 == module ]] &&
		local short=" -$short" separator=' ' new_separator=' '
	[[ $1 =~ option && $value =~ ${multi_segment_options/|size} ]] && local new_separator=':'

	if [[ "$(eval echo \${!$array[*]})" =~ $value ]]; then
		if [[ $value =~ ^($no_values)$ ]]; then
			remove_value $1
		else
			eval $variable="\"\${$variable/$short$new_separator\${$array[$value]}/$short$new_separator$2}\""
			eval $array[$value]="\"$2\""
		fi
	else
		if [[ $1 =~ option ]]; then
			[[ $module =~ power && $1 == option ]] &&
				local separator=' ' || local separator=,
		fi

		[[ ${!variable} ]] &&
			eval $variable=\"${!variable}$separator$short$new_separator$2\" ||
			eval $variable=\"$short$new_separator$2\"

		[[ $value =~ ^($repeatable_segments)$ ]] || eval $array[$value]=\"$2\"
	fi
}

list_suboptions() {
	case $suboptions_option in
		power_buttons) echo power_buttons_{size,icons,offset,actions};;
		representation) echo labels numeric representation_icons;;
		power_colorscheme) echo power_colorscheme_{current,select};;
	esac
}

add_suboptions() {
	local value values separator

	for suboptions_option in $(list_suboptions); do
		if [[ ${!suboptions_array[*]} =~ $suboptions_option ]]; then
			get_name $suboptions_option

			[[ $suboptions_option =~ ${multi_segment_options/|size} ]] && separator=':'
			value=${suboptions_array[$suboptions_option]}
			values+="$short$separator$value,"
		fi
	done

	[[ $values ]] && add_value option "${values%,}"
}

configure_module() {
	if [[ ! $module =~ ^($no_values)$ ]]; then
		until [[ $check =~ back|done|remove ]]; do
			if [[ $module =~ $suboptions_modules ]]; then
				if [[ $option =~ $all_suboptions ]]; then
					if [[ $option =~ ^($suboptions_options)$ ]]; then
						suboption=$option
					else
						for suboptions_option in ${suboptions_options//|/ }; do
							[[ "$(list_suboptions)" =~ $option ]] && break
						done

						suboption=$suboptions_option
					fi
				fi
			fi

			previous_option=$option

			if [[ $module =~ ^($single_value_modules)$ ]]; then
				options=$(rofi -dmenu -p "ENTER VALUE" -theme list)
				check=done
			else
				get option
			fi

			if [[ $suboption ]]; then
				if [[ $check == done ]]; then
					option=$suboption
					add_suboptions
					unset suboption
					get option
				else
					suboption=$option
				fi
			fi

			[[ $option =~ ^($suboptions_options)$ ]] && continue

			if [[ $check == remove ]]; then
				if [[ $previous_option =~ $suboptions_options ]]; then
					#echo remove o $option, s $suboption
					option=$previous_option
					get_name $option
					remove_value option
					unset check
					continue
				else
					get_name $module
					remove_value module 
				fi
			fi

			if [[ ! $check =~ back|done|remove ]]; then
				[[ $suboption ]] && option_type=suboption suboption=$option || option_type=option

				if [[ $option =~ ^($multi_segment_options)$ ]]; then
					segments="${value//,/ }"

					until [[ $check =~ back|done|remove ]]; do
						get segment

						if [[ $check == remove ]]; then
							get_name $option
							remove_value $option_type
						fi

						if [[ ! $check =~ back|done|remove ]]; then
							[[ ! $segment =~ $multi_values && ! $segment =~ ^($no_values)$ ]] &&
								get value $segment "ENTER VALUE"

							get_name $segment
							[[ $value == remove ]] &&
								remove_value segment || add_value segment "$value"
						fi
					done

					value=$segments
					unset segment segments
				else
					if [[ $option =~ ^($no_values)$ ]]; then
						if [[ $option == power_colorscheme_current ]]; then
							if [[ ! ${options_array[colorscheme_name]} ]]; then
								read colorscheme_name colorscheme_clone <<< $(awk '{
									print gensub("([^-]*-[^c])*[^-]*-c\\s*(([^, ]*),?([^ ]*)).*", "\\3 \\4", 1)
								}' $config)

								options_array[colorscheme_name]=$colorscheme_name
								[[ $colorscheme_clone ]] && options_array[colorscheme_clone]=$colorscheme_clone
								value=${options_array[colorscheme_name]:-${options_array[colorscheme_select]}}
							fi
						fi
					else
						[[ ! $option =~ ^($multi_values)$ ]] && prompt="ENTER VALUE" || unset prompt
						get value $option "$prompt"

						if [[ $value == value ]]; then
							get value $value "ENTER VALUE"
						elif [[ $value == remove ]]; then
							get_name $option
							remove_value $option_type
						else
							get_name $value
							value=$short
						fi
					fi
				fi

				[[ $option == power_size && ! $suboption ]] &&
					value="${segments_array[width]}x${segments_array[height]}"

				get_name $option

				[[ $check != remove && $value != remove ]] && add_value $option_type "$value"
				[[ $option ]] && check=$option
			fi
		done
	fi

	if [[ $module =~ $repeatable_segments ]]; then
		get_name $module
		modules+=" -$short $options"

		for option in $(list_options | xargs); do
			unset options_array[$option]
		done
	else
		[[ $check != remove ]] && add_value module "$options"
	fi
}

get_section() {
	until [[ $check == done ]]; do
		if [[ $module && $module =~ $repeatable_segments ]]; then
			for option in $(list_options | xargs); do
				unset options_array[$option]
			done
		fi

		get module "$1"

		if [[ $check != done ]]; then
			configure_module

			[[ $module ]] && check=$module
			unset module options value
		fi
	done

	unset check
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

declare -A {modules,options,suboptions,segments,values}_array

all_settings='x y width height bar_frame frame joiner padding separator offset font_size colorscheme name center right icons'
all_modules='apps launchers workspaces cpu disks memory hidden email updates network rss volume power mpd torrent date'

single_value_modules='name|height|offset|separator|padding|font_size'
multi_segment_options='.*progressbar|mpd_buttons|power_size|power_buttons_actions'
segment_options='.*(dashed|step)|prev|play/pause|next|circle|mpd_separator|power_(width|height)|lock|logout|reboot|suspend|poweroff'
multi_values='(launchers|workspaces|apps)_separator|representation_icons|workspace|(workspaces|power_buttons)_offset|offset|position|power_colorscheme_select|colorscheme_clone|icons'
repeatable_segments='mpd.*offset|circle|frame|joiner|offset|separator|padding|icons'
suboptions_modules='x|workspaces|power'
suboptions_options='representation|power_buttons|power_colorscheme'
all_suboptions='representation|labels|representation_icons|numeric|power_(colorscheme(_(select|current))?|buttons(_(size|icons|offset|actions))?)'
alt_named_options='width|height|top|bottom|offset|separator|padding|buttons|icons|size|actions|colorscheme|name|clone|select|current|volume|progressbar|step'
alt_named_segments='.*(step|dashed|progressbar)'
separated_options='power_(buttons|colorscheme|size)'

no_values='cpu|memory|disk_space|hidden|network|updates|email|rss|.*volume|'
no_values+='secondary_color|info|time|toggle|volume|(workspaces|launchers)_padding|active|over|under|around|labels|numeric|.*current|.*bottom|center|right|only|icon|none|'
no_values+='prev|play/pause|next|circle|.*dashed|remain|half_bg|lock|logout|reboot|suspend|poweroff|power_buttons_icons|(circle|square)_*|adjustable'

get_numeric_value() {
	local current_digit=${options:$index:1}

	while [[ $current_digit == [0-9] && $index -le ${#options} ]]; do
		numeric_value+=$current_digit
		((index++))
		current_digit=${options:$index:1}
	done
}

get_segment_values() {
	((index++))

	until
		get_name ${options:$index:1}

		option_value_short=$short
		option_value_full=$full
		((index++))

		[[ ${options:index - 1:1} == [\ ,] || $index -gt ${#options} ]]
	do
		if [[ ! $option_value_full =~ $no_values ]]; then
			get_numeric_value
			segment_value=$numeric_value
			unset numeric_value
		fi

		segments_array[$option_value_full]="$segment_value"
		option_values+="$option_value_short$segment_value"
		unset segment_value
	done
}

config_path=~/.config/orw/bar/configs

select_config() {
	config_selection=$(echo -e 'select\nrunning' | rofi -dmenu -theme list)

	if [[ $config_selection == running ]]; then
		read count running <<< $(ps -C lemonbar -o args= |
			awk '{ s = (r) ? "\\\\n" : ""; r = r s $NF; rc++ } END { print rc, r }')
		((count == 1)) && bar_config=$running || bar_config=$(echo -e $running | rofi -dmenu -theme list)
	else
		bar_config=$(ls $config_path | awk '{ print gensub(".*/(.*)\\..*", "\\1", 1) }' | rofi -dmenu -theme list)
	fi

	config="$config_path/$bar_config"
}

get_module() {
	read index config_module <<< $(
		while read config_module module_options; do
			[[ $config_module == done ]] && full=done || get_name $config_module
			echo $full
		done <<< $(awk '
			BEGIN { if("'$action'" != "add") print "done" }
				{ print gensub("([^-]*-(.)\\s*([^-]*))", "\\2 \\3\n", "g") }' $config) |
				rofi -dmenu -format 'i s' -theme list)

	[[ $action == add ]] && ((index++))
	original_index=$index

	read last_index module_flag options <<< \
		$(awk '{ am = gensub("([^-]*-(.)\\s*([^-]*))", "\\2 \\3\n", "g") }
			END {
				mc = split(am, ma, "\n")
				print mc - 1, ma['$index']
			}' $config) 
}

list_sections() {
	until
		read section_index section <<< $(echo -e 'done\nsettings\nmodules' | \
			rofi -dmenu -format 'i s' -selected_row $section_index -theme list)
		[[ $section == done ]]
	do
		section=all_$section
		get_section "${!section}"
	done
}

action=$(echo -e 'add\nedit\nswap\nremove\ngenerate' | rofi -dmenu -theme list)
[[ $action ]] || exit 0

if [[ $action == generate ]]; then
	list_sections

	[[ $modules ]] && ~/.orw/scripts/barctl.sh -g "$modules" || echo nothing to generate
	exit 0
else
	select_config

	while
		[[ $action == add ]] && add=$(echo -e 'done\nbefore\nafter' | rofi -dmenu -theme list)

		[[ $add == done ]] && break || get_module
		[[ $module_flag ]]; do

		if [[ $add ]]; then
			add_type=$(echo -e 'add_new\ninherit' | rofi -dmenu -theme list)

			if [[ $add_type == add_new ]]; then
				list_sections
				module_flag="$(sed 's/^\s*//; s/\s*$//' <<< "$modules")"
			else
				original_config=$config
				original_bar_config=$bar_config
				original_config_index=$original_index
				original_last_index=$last_index

				select_config
				get_module
				module_flag="-$module_flag $options"

				config=$original_config
				bar_config=$original_bar_config
				original_index=$original_config_index
			fi

			[[ $add == before ]] && ((original_index--))
			if ((original_index < ${original_last_index:-$last_index})); then
				after_separator=' '
			else
				[[ $add == after ]] && before_separator=' '
			fi

			awk -i inplace '
				BEGIN { m = "'"$before_separator$module_flag$after_separator"'" }
				{ print gensub("(([^-]*-.\\s*[^-]*){'$original_index'})(.*)", "\\1" m "\\3", 1) }' $config
		elif [[ $action == swap ]]; then
			org_module_flag=$module_flag
			unset module_flag
			first_index=$original_index

			get_module

			awk -i inplace '
				BEGIN { f = '$first_index'; s = '$index'; l = '$last_index' }

				function get(i) {
					return gensub("(([^-]*-){" i - 1 "}[^-]*)(-(j[^j]*.\\s*-[^-]*|[^-]*)).*", "\\3", 1)
				}

				function set(i, current_module, new_module) {
					if(i == l) {
						sub("\\s+$", "", new_module)
					} else if(new_module !~ " $") new_module = new_module " "

					if(current_module ~ "-j") sub(current_module, new_module)
					else $0 = gensub(current_module, new_module, 2)
				}

				{
					fm = get(f)
					sm = get(s)
					set(f, fm, sm)
					set(s, sm, fm)
					print 
				}' $config
		elif [[ $action == remove ]]; then
				awk -i inplace '
					BEGIN { i = '$index'; li = '$last_index'; s = (i == li) ? "" : " " }
					{ print gensub("((-[^-]*){" i - 1 "})( -[^-]*)", "\\1" s, 1) }' $config
		else
			get_name $module_flag
			module=$full

			if [[ $module == power ]]; then
				for power_option in $options; do
					if [[ -f ~/.config/orw/colorschemes/$power_option.ocs ]]; then
						suboptions_array[power_colorscheme_select]=$power_option
						options_array[power_colorscheme]=$power_option
					else
						if [[ $power_option =~ x ]]; then
							options_array[size]=$power_option
							segments_array[width]=${power_option%x*}
							segments_array[height]=${power_option#*x}
						else
							option=power_buttons
							suboption=$option
							options_array[power_buttons]=$power_option

							for buttons_option in ${power_option//,/ }; do
								if [[ $buttons_option =~ i|[os][0-9]+ ]]; then
									get_name ${buttons_option:0:1}
									[[ $short == [os] ]] && segment_value=${buttons_option:1}
								else
									option=power_buttons_actions
									power_actions=${buttons_option#*:}

									segment_value=$power_actions
									options_array[power_buttons_actions]=$power_actions

									while [[ $power_actions ]]; do
										get_name ${power_actions:0:1}
										segments_array[$full]=""
										power_actions=${power_actions:1}
									done

									full=power_buttons_actions
								fi

								suboptions_array[$full]="$segment_value"
							done
						fi
					fi
				done
			elif [[ $module == colorscheme ]]; then
				read colorscheme_name colorscheme_clone <<< ${options//,/ }
				options_array[colorscheme_name]=$colorscheme_name
				[[ $colorscheme_clone ]] && options_array[colorscheme_clone]=$colorscheme_clone
			else
				index=0

				while ((index < ${#options})); do
					get_option $options
					option=$full

					if [[ ! $option =~ $no_values ]]; then
						if [[ $option =~ $multi_segment_options ]]; then
							get_segment_values
						else
							get_numeric_value
							option_values=$numeric_value
							unset numeric_value
						fi
					fi

					[[ $option == representation_icons ]] &&
						option_values=$option_short suboptions_array[$option]=${option_values#i} option=representation

					[[ $option ]] && options_array[$option]="$option_values"

					unset option_values
					unset option_value_{short,option}
				done
			fi

			unset {sub,}option index check
			configure_module

			awk -i inplace '
				BEGIN { oi = '$original_index'; li = '$last_index'; s = (oi == li) ? "" : " " }
				{ print gensub("-[^-]*", "'"${modules# }"'" s, '$original_index') }' $config
		fi

		unset module{,s,_flag}
	done
fi

~/.orw/scripts/barctl.sh -b $bar_config
exit 0
get_name $module
module=$full

if [[ $module == power ]]; then
	for power_option in $options; do
		if [[ -f ~/.config/orw/colorschemes/$power_option.ocs ]]; then
			suboptions_array[power_colorscheme_select]=$power_option
			options_array[power_colorscheme]=$power_option
		else
			if [[ $power_option =~ x ]]; then
				options_array[size]=$power_option
				segments_array[width]=${power_option%x*}
				segments_array[height]=${power_option#*x}
			else
				option=power_buttons
				suboption=$option
				options_array[power_buttons]=$power_option

				for buttons_option in ${power_option//,/ }; do
					if [[ $buttons_option =~ i|[os][0-9]+ ]]; then
						get_name ${buttons_option:0:1}
						[[ $short == [os] ]] && segment_value=${buttons_option:1}
					else
						option=power_buttons_actions
						power_actions=${buttons_option#*:}

						segment_value=$power_actions
						options_array[power_buttons_actions]=$power_actions

						while [[ $power_actions ]]; do
							get_name ${power_actions:0:1}
							segments_array[$full]=""
							power_actions=${power_actions:1}
						done

						full=power_buttons_actions
					fi

					suboptions_array[$full]="$segment_value"
				done
			fi
		fi
	done
else
	index=0

	while ((index < ${#options})); do
		get_option $options

		if [[ ! $full =~ $no_values ]]; then
			if [[ $full =~ $multi_segment_options ]]; then
				get_segment_values
			else
				get_numeric_value
				option_values=$numeric_value
				unset numeric_value
			fi
		fi

		echo s $option_short, o $full, v $option_values
		[[ $full == representation_icons ]] &&
			option_values=$option_short suboptions_array[$full]=${option_values#i} full=representation

		echo f: $full, v: $option_values
		[[ $full ]] && options_array[$full]="$option_values"
		unset option_values

		unset option_value_{short,full}
	done
fi

echo o ${!options_array[*]}, so ${!suboptions_array[*]}
echo o ${options_array[*]}, so ${suboptions_array[*]}

unset {sub,}option index
configure_module
echo $modules
echo $options
exit

get_name() {
	case $1 in
		w|width)
			short=w
			[[ $module =~ frame ]] && full=${module}_width || full=width;;
		h|height) short=h full=height;;
		f|*frame) short=f full=frame;;
		F|bar_frame) short=F full=bar_frame;;
		j|joiner) short=j full=joiner;;
		of) short=of full=front_offset;;
		oe) short=oe full=end_offset;;
		O|o|*offset|poweroff|over)
			if [[ $module == offset ]]; then short=O full=offset
			else
				short=o

				case $option in
					position) full=over;;
					power_options) full=poweroff;;
					*) full=${module}_offset
				esac;;
			fi;;
		u|under) short=u full=under;;
		P|power) short=P full=power;;
		p|padding|progressbar)
			short=p
			[[ $module == mpd ]] && full=progressbar || full=padding;;
		s|separator|slide|step|size|suspend)
			short=s

			if [[ $module == power ]]; then
				if [[ $option == power_buttons_actions ]]; then
					full=suspend
				else
					[[ $option == power_buttons ]] && full=power_separator || full=size
				fi
			elif [[ $module == mpd ]]; then
				[[ $option == progressbar ]] && full=step || full=slide
			else
				[[ $module == separator ]] && full=separator || full=${module}_separator
			fi;;
		b|mpd_buttons) short=b full=mpd_buttons;;
		c|circle)
			short=c
			full=controls;;
		l|labels|logout)
			short=l
			[[ $module == workspaces ]] && full=labels || full=logout;;
		L|lock) short=L full=lock;;
		r|right|reboot)
			short=r
			[[ $module == power ]] && full=reboot || full=right;;
		d|date) short=d full=date;;
		C|cpu) short=C full=cpu;;
		M|memory) short=M full=memory;;
		D|disks) short=D full=disks;;
		R|rss) short=R full=rss;;
		H|hidden) short=H full=hidden;;
		m|mpd) short=m full=mpd;;
		e|email) short=e full=email;;
		v|volume) short=v full=volume;;
		N|network) short=N full=network;;
		A|apps) short=A full=apps;;
		L|launchers) short=L full=launchers;;
		W|workspace) short=W full=workspaces;;
		a|font_size) short=a full=font_size;;
		T|time) short=T full=time;;
		s|step) short=s full=step;;
		i*)
			if [[ $module == workspaces ]]; then
				read full short <<< $(awk '/Workspace.*_[sp]/ {
						fn = gensub("[^_]*_(.*)_[ps].*", "\\1", 1)
						sn = gensub("(.)[^_]*_?", "\\1", "g", fn)
						if("'$1'" =~ fn|"i"sn) print fn, "i" sn
					}' ~/.orw/scripts/bar/icons)
			else
				short=i
				[[ $module == mpd ]] && full=info || full=${module}_icons
			fi;;
		S|slide) short=S full=slide;;
		d|dashed) short=d full=dashed;;
		t|play/pause) short=t full=play/pause;;
		p|prev) short=p full=prev;;
		n|next) short=n full=next;;
		*) short=$1 full=$1;;
	esac
}

declare -A short_modules_array

eval $(awk '{
	print "short_modules_array=( " gensub("([^-]*-(.)\\s*([^-]*))", "[\\2]=\"\\3\" ", "g") " )" }' \
		~/.config/orw/bar/configs/moun)

read module options <<< \
	$(for module in ${!short_modules_array[*]}; do
		get_name $module
		module_options=${short_modules_array[$module]}
		printf '%s%-*s%s\n' $full $((offset - (${#full} + ${#module_options} + 1))) ' ' "$module_options"
	done | rofi -dmenu -theme list)

get_name $module

get_numeric_value() {
	local current_digit=${options:$index:1}

	while [[ $current_digit == [0-9] && $index -le ${#options} ]]; do
		numeric_value+=$current_digit
		((index++))
		current_digit=${options:$index:1}
	done
}

get_segment_values() {
	until
		get_name ${options:$index:1}
		option_value_short=$short
		option_value_full=$full
		((index++))

		[[ $option_value_short == [\ ,] || $index -gt ${#options} ]]
	do
		if [[ ! $option_value_full =~ $no_values ]]; then
			get_numeric_value
			segment_value=$numeric_value
			unset numeric_value
		fi

		segments_array[$option_value_full]="$segment_value"
		option_values+="$option_value_short$segment_value"
		unset segment_value
	done
}

if [[ $module == power ]]; then
	for power_option in $options; do
		if [[ -f ~/.config/orw/colorschemes/$power_option.ocs ]]; then
			suboptions_array[power_colorscheme_select]=$power_option
			options_array[power_colorscheme]=$power_option
		else
			if [[ $power_option =~ x ]]; then
				options_array[size]=$power_option
				segments_array[width]=${power_option%x*}
				segments_array[height]=${power_option#*x}
			else
				option=power_buttons
				options_array[power_buttons]=$power_option

				for power_segment in ${power_option//,/ }; do
					if [[ $power_segment =~ i|[os][0-9]+ ]]; then
						get_name ${power_segment:0:1}
						[[ $short == [os] ]] && segment_value=${power_segment:1}
					else
						option=power_buttons_actions
						segment_value=$power_segment
						options_array[power_buttons_actions]=$power_segment

						while [[ $power_segment ]]; do
							get_name ${power_segment:0:1}
							segments_array[$full]=""
							power_segment=${power_segment:1}
						done

						full=power_buttons_actions
					fi

					suboptions_array[$full]="$segment_value"
				done
			fi
		fi
	done
else
	index=0
	echo ${modules_array[$short]}

	while ((index < ${#options})); do
		option_short=${options:$index:1}
		((index++))

		[[ $option_short == [\ ,] ]] &&
			option_short=${options:$index:1} && ((index++))

		[[ $module == mpd && $option_short == o ]] &&
			option_short+=${options:$index:1} && ((index++))

		get_name $option_short
		option=$full

		if [[ ! $option =~ $no_values ]]; then
			if [[ $option =~ $multi_segment_options ]]; then
				get_segment_values
			else
				get_numeric_value
				option_values=$numeric_value
				unset numeric_value
			fi
		fi

		[[ $option ]] && options_array[$option]="$option_values"
		unset option_values

		unset option_value_{short,full}
	done
fi

unset option

configure_module
echo $modules
echo $options

exit

until
	read section_index section <<< $(echo -e 'done\nsettings\nmodules' | \
		rofi -dmenu -format 'i s' -selected_row $section_index -theme list)
	[[ $section == done ]]
do
	section=all_$section
	get_section "${!section}"
done

echo "generate_bar.sh$modules"
