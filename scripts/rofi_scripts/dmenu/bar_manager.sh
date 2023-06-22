#!/bin/bash

get() {
	local index=$1_index

	[[ $1 == module ]] && local value_type=options || local value_type=value
	[[ $1 == value || ($1 == module && ${!1} =~ $single_value_modules) ]] &&
		local variables=$value_type || variables="check $1 $value_type"
	#[[ $1 == value ]] && local variables=value || variables="check $1 $value_type"

	#read $1_index $variables <<< $(eval list_${1}s \"${suboption:-$2}\" | \
	read $1_index $variables <<< $(eval list_${1}s \"${2:-$suboption}\" | \
		rofi -dmenu -p "$3" -format 'i s' -selected-row ${!index} -theme list)

	#[[ $1 == option && ${!1} =~ $alt_named_options ]] && option=${segment:-$module}_$option
	#[[ $1 =~ option && ${!1} =~ $alt_named_options ]] &&
	#[[ ($1 =~ option && ${!1} =~ $alt_named_options) || $1 == segment && ${!1} =~ $alt_named_segments ]] &&
	[[ $1 =~ option && ${!1} =~ $alt_named_options ]] &&
		eval $1=${segment:-${suboption:-$module}}_${!1}
	[[ $1 == segment && ${!1} =~ $alt_named_segments ]] &&
		eval $1=${option}_${!1}
	#~/.orw/scripts/notify.sh "alt ${segment:-${suboption:-$module}}_${!1}"
	#[[ $1 =~ option && ${!1} =~ $alt_named_options ]] && echo $1: ${!1}
}

print_line() {
	[[ $1 == option && $suboption ]] && local array=suboptions_array || local array=${1}s_array
	#[[ $1 == option && ${!1} =~ $alt_named_options ]] && local item=${segment:-$module}_${!1} || local item=${!1}
	#[[ $1 =~ option && ${!1} =~ $alt_named_options ]] &&
	#[[ ($1 =~ option && ${!1} =~ $alt_named_options) || $1 == segment && ${!1} =~ $alt_named_segments ]] &&
	#	local item=${segment:-${suboption:-$module}}_${!1} || local item=${!1}
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
		#x) [[ ${!options_array[*]} =~ x_offset|center|reverse ]] &&
		#		option_list="${BASH_REMATCH[*]#x_}" || option_list='offset center reverse';;
		x) option_list='offset center right';;
		y) option_list='offset bottom';;
		#center) [[ ${!suboptions_array[*]} =~ whole|(left|right)_edge ]] &&
		#		option_list="${BASH_REMATCH[0]}" || option_list='whole left_edge right_edge';;
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
		#icons) option_list='only icons none';;
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
	#awk '
	#	BEGIN { if(!"'$1'") print "remove" }
	#	/Workspace.*_p_icon/ {
	#		fn = gensub("[^_]*_(.*)_[ps].*", "\\1", 1)
	#		sn = gensub("(.)[^_]*_?", "\\1", "g", fn)
	#		if(!"'$1'") print fn
	#		else if("'$1'" ~ "^(" fn "|" sn ")$") print fn, sn
	#		#else if("'$1'" ~ "^(" fn "|i" sn ")$") print fn, "i" sn
	#		#else if("'$1'" ~ "^(" fn "|i" sn ")$") print fn, "i" sn
	#	}' ~/.orw/scripts/bar/icons


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
				#if("'"$1"'" ~ "^(" ni "|" an[ni] ")" print (("'"$1"'") ? ni " " : ""), an[ni]
			}
		}' ~/.orw/scripts/bar/icons
}

list_values() {
	case $1 in
		#labels)
		#	cat <<- EOF
		#		label
		#		numeric
		#		icons_circle_full
		#		icons_circle_empty
		#		icons_circle_check
		#		icons_circle_small
		#		icons_square_full
		#		icons_square_empty
		#		icons_square_check
		#		icons_square_small
		#		icons_rounded_square_full
		#		icons_rounded_square_empty
		#		icons_rounded_square_check
		#	EOF
		#	;;
		#workspaces_icons) list_workspace_icons;;
		representation_icons) list_workspace_icons;;
			#cat <<- EOF
			#	circle_full
			#	circle_empty
			#	circle_check
			#	circle_small
			#	square_full
			#	square_empty
			#	square_check
			#	square_small
			#	rounded_square_full
			#	rounded_square_empty
			#	rounded_square_check
			#EOF
			#;;
		workspace) echo -e 'all\ncurrent';;
		*_offset)
			echo remove
			[[ ! $module =~ (mpd|power|[xy]) ]] && echo -e 'padding\ninner\nvalue';;
			#[[ $module != mpd ]] && local inner='\ninnder'
			#echo -e "remove\npadding$inner\nvalue";;

			#echo -e 'remove\npadding\ninner\nvalue';;
		#workspaces_offset) echo -e 'remove\npadding\ninner\nvalue';;
		position) echo -e 'remove\naround\nunder\nover';;
		*_separator) echo -e 'remove\nseparator\nvalue';;
		#position) echo -e 'over\nunder\naround';;
		actions) echo -e 'lock\nlogout\nreboot\nsuspend\npoweroff';;
		#power_buttons) echo -e 'size\nicons\noffset\nactions';;
		colorschemes) echo -e 'current\nselect';;
		power_colorscheme_current)
			echo ${options_array[colorscheme_name]:-${options_array[colorscheme_select]}};;
		*select*|*clone)
			ls ~/.config/orw/colorschemes/*ocs | \
				awk 'BEGIN { print "remove" } { print gensub(".*/([^.]*).*", "\\1", 1) }';;
		*) echo remove;;
	esac
}

#get_shorthand() {
#	case $1 in
#		x) shorthand=x;;
#		y) shorthand=y;;
#		center) shorthand=c;;
#		reverse) shorthand=r;;
#		right_edge) shorthand=r;;
#		bottom) shorthand=b;;
#		circle_*|*square_*) shorthand=$(sed 's/\(\w\)[^_]*_\?/\1/g' <<< "icon_$1");;
#		step) shorthand=s;;
#		labels) shorthand=l;;
#		mpd_separator) shorthand=S;;
#		*separator) shorthand=s;;
#		padding|module_padding) shorthand=p;;
#		active) shorthand=a;;
#		length) shorthand=l;;
#		workspaces) shorthand=W;;
#		all) shorthand=a;;
#		#current) shorthand=c;;
#		slide) shorthand=s;;
#		info) shorthand=i;;
#		progressbar) shorthand=p;;
#		time) shorthand=T;;
#		secondary_color) shorthand=P;;
#		toggle) shorthand=t;;
#		mpd_buttons) shorthand=b;;
#		front_offset) shorthand=of;;
#		end_offset) shorthand=oe;;
#		[^xy]*offset) shorthand=o;;
#		separator) shorthand=s;;
#		prev) shorthand=p;;
#		play/pause) shorthand=t;;
#		next) shorthand=n;;
#		toggle_circle) shorthand=c;;
#		dashed) shorthand=d;;
#		launchers) shorthand=l;;
#		frame) shorthand=f;;
#		bar_frame) shorthand=F;;
#		top) shorthand=o;;
#		bottom) shorthand=u;;
#		all) shorthand=a;;
#		mpd) shorthand=m;;
#		memory) shorthand=M;;
#		cpu) shorthand=C;;
#		disk_space) shorthand=D;;
#		emails) shorthand=e;;
#		date) shorthand=d;;
#		half_bg) shorthand=h;;
#		next_bg) shorthand=n;;
#		joiner) shorthand=j;;
#		power_icons|icons) shorthand=i;;
#		lock) shorthand=L;;
#		logout) shorthand=l;;
#		reboot) shorthand=r;;
#		suspend) shorthand=s;;
#		poweroff) shorthand=o;;
#		power) shorthand=P;;
#		power_actions) shorthand=a;;
#		colorscheme) shorthand=c;;
#		current) [[ ${!options_array[*]} =~ colorscheme_name ]] &&
#			value=${options_array[colorscheme_name]} || value=${options_array[colorscheme_select]};;
#		*)
#			[[ $1 =~ ^[0-9]+$ || ($option =~ name|select|clone && ! $1 =~ whole|name|select|clone) ]] &&
#			shorthand=$1 || unset shorthand
#	esac
#}

get_name() {
	#if [[ $1 =~ ^[0-9]+$ || (($option =~ colorscheme && ! $1 =~ colorscheme) || $option == clone) ]]; then
	if [[ ${#1} -gt 1 && -f ~/.config/orw/colorschemes/$1.ocs  ]]; then
		short=$1
	else
		case $1 in
			x) short=x full=x;;
			y) short=y full=y;;
			w|*width)
				short=w
				[[ $module =~ frame ]] && full=${module}_width || full=width;;
				#[[ $module != power ]] && short=w
				#full=${suboption:-$module}_width;;
			h|*height)
				short=h
				[[ ! $module || $module == height ]] && full=height || full=${module}_height;;
				#[[ $module != power ]] && short=h
				#[[ $module == height ]] && full=height || full=${suboption:-$module}_height;;
			F|bar_frame) short=F full=bar_frame;;
			f|*frame) short=f full=frame;;
			frame_top) short=o full=frame_top;;
			frame_bottom|u) short=u full=frame_bottom;;
			j|joiner) short=j full=joiner;;
			*bottom|mpd_buttons|b)
				short=b
				[[ $module == y ]] && full=bottom || full=mpd_buttons;;
				#[[ $module == y ]] && short=b full=bottom || short=u full=frame_bottom;;
			of|mpd_front_offset) short=of full=front_offset;;
			oe|mpd_end_offset) short=oe full=end_offset;;
			O|o|*offset|poweroff|over)
				if [[ ! $module || $module == offset ]]; then
					short=O full=offset
				else
					short=o
					#[[ $option == power_buttons_actions ]] && full=poweroff || full=${suboption:-$module}_offset
					#echo GETTING OPT o $option, $1, $suboptions_options

					[[ $option =~ $suboptions_options ]] && local suboption=$option

					#if [[ $module == power ]]; then
						#[[ $option == power_buttons ]] && full=${option}_offset full=poweroff
						#[[ $option == power_buttons ]] || full=poweroff
					#else
						[[ $option =~ $suboptions_options ]] && local suboption=$option
						[[ $option == power_buttons_actions ]] &&
							full=poweroff || full=${suboption:-$module}_offset
					#fi
				fi;;
			u|under) short=u full=under;;
			P|power) short=P full=power;;
			p|*padding|*progressbar)
				short=p
				[[ $module && $module != padding ]] && local prefix="${suboption:-$module}_"
				[[ $module == mpd ]] && full=$option || full=${prefix}padding;;
				#[[ $module == mpd ]] && full=progressbar || full=${prefix}padding;;
			s|*separator|*size|slide|*step|suspend)
				if [[ $module == font_size ]]; then
					short=a full=font_size
				else
					short=s

					if [[ $module == power ]]; then
						#[[ $option == power_buttons_actions ]] &&
						#	full=suspend || full=${suboption:-$module}_size

						#echo NAMING OPT o $option, $1, $suboptions_options

						case $option in
							*actions) full=suspend;;
							*) [[ $option =~ buttons ]] && full=power_buttons_size || full=power_size;;
						esac

						#[[ $option =~ $suboptions_option ]] && local suboption=$option

						#[[ $option == power_buttons_actions ]] &&
						#	full=suspend || full=${suboption:-$module}_size

						#if [[ $option == power_buttons_actions ]]; then
						#	full=suspend
						#else
						#	[[ $option == power_buttons ]] && full=power_buttons_size || full=size
						#fi
					elif [[ $1 == *step ]]; then
						full=${module}_step
					elif [[ $module == mpd ]]; then
						full=slide
						#[[ $option == progressbar ]] && full=step || full=slide
					#elif [[ $module == mpd ]]; then
					#	[[ $option == progressbar ]] && full=step || full=slide
					else
						#echo NAMING v $value, 
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
					#[[ ${options_array[colorscheme_name]} ]] && full=center || full=colorscheme
					[[ ${module_options:-$options} ]] && full=colorscheme || full=center
				fi;;
				#[[ $module == apps ]] && full=current || full=center;;
				#[[ $module == x ]] && full=center || full=controls;;
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
				#[[ $module == mpd ]] && full=${option}_dashed || full=date;;
			C|cpu) short=C full=cpu;;
			M|memory) short=M full=memory;;
			D|disks) short=D full=disks;;
			R|rss) short=R full=rss;;
			H|hidden) short=H full=hidden;;
			m|mpd) short=m full=mpd;;
			e|email) short=e full=email;;
			#v|volume) short=v full=volume;;
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
			#i|info|icons)
				#if [[ $module == workspaces ]]; then
			*circle_*|*square_*) read full short <<< $(list_workspace_icons $1);;
					#echo f: $full, s: $short
					#read full short <<< $(awk '/Workspace.*_[sp]/ {
					#		fn = gensub("[^_]*_(.*)_[ps].*", "\\1", 1)
					#		sn = gensub("(.)[^_]*_?", "\\1", "g", fn)
					#		if("'$1'" =~ fn|"i"sn) print fn, "i" sn
					#	}' ~/.orw/scripts/bar/icons)
				#else
			i*|icon|*icons|info|inner)
				#if [[ $module == workspaces ]]; then
				#	read full short <<< $(list_workspace_icons $1)
				#	echo f: $full, s: $short
				#else
				#if [[ $module != workspaces ]]; then

					#short=i
					#[[ $module == mpd ]] && full=info || full=${module}_icons;;

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
					fi;;
				#fi;;
			S|slide) short=S full=slide;;
			d|*dashed) short=d full=${option}_dashed;;
			#t|play/pause) short=t full=play/pause;;
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
				fi;;
				#[[ $module == mpd ]] && full=next || full=numeric;;

				#case $module in
				#	mpd) full=next;;
				#	workspaces) full=numeric;;
				#	*) full=name
				#esac;;

			#power_colorscheme_current)
			#	[[ $module == power ]] &&
			#		value=${options_array[colorscheme_name]:-${options_array[colorscheme_select]}} ||
			#		short=c full=$1;;
				#if [[ $module == power ]]; then
				#	value=${options_array[colorscheme_name]:-${options_array[colorscheme_select]}}
					#[[ ${!options_array[*]} =~ colorscheme_name ]] &&
					#	value=${options_array[colorscheme_name]} || value=${options_array[colorscheme_select]};;
			#*) short=$1 full=$1;;
			#*) [[ $1 =~ ^[0-9]+$ ]] && short=$1 || unset short full;;
			#*colorscheme) short=c full=colorscheme;;
			colorscheme) short=c full=colorscheme;;
			#*) [[ $1 =~ ^[0-9]+$ || ($option =~ name|select|clone && ! $1 =~ name|select|clone) ]] &&
			[^[:alnum:]]*) read short full <<< $(list_workspace_icons $1);;
			*) [[ $1 =~ ^[0-9]+$ || ($option =~ colorscheme && ! $1 =~ colorscheme) ]] &&
				short=$1 || unset short full;;
		esac
		#echo name: $1, $short, $full
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
	#option=$full
}

remove_value() {
	local value=${!1} variable=${1}s
	#local value=${!1}
	#[[ $1 == suboption ]] && variable=options || variable=${1}s

	[[ $1 == module ]] &&
		#local shorthand=" -$shorthand "
		local short=" -$short "
	[[ $1 =~ option && $value =~ ${multi_segment_options/|size} ]] && local new_separator=':'

	#local pattern="$shorthand$new_separator\${${1}s_array[$value]}"
	eval local pattern="$short$new_separator\${${1}s_array[$value]}"
	local remove_pattern="$pattern"

	#echo REM_PAT $pattern
	#eval echo REMOVE $1, $value, ${!variable}, $pattern

	if [[ $1 =~ option ]]; then
		shopt -s extglob
		#[[ $options =~ ^$shorthand ]] &&
		#[[ $value =~ ^$short ]] &&
		[[ ${!variable} =~ ^$pattern ]] &&
			pattern+="?(,)" || pattern="?(,)$pattern"
		#echo REM OPT: $short ^$pattern^
	fi

	eval $variable="\"\${$variable/$pattern/}\""
	#eval removed_value=\${${1}s_array[$value]}
	eval unset ${1}s_array[$value]

	#echo AFTER REM ${!variable}

	if [[ $1 == suboption ]]; then
		for suboptions_option in ${suboptions_options//|/ }; do
			[[ "$(list_suboptions)" =~ $suboption ]] && break
		done

		#eval echo REMOVING OPT PAT $pattern
		#echo REMOVING OPTION os $options, o $option, $pattern
		#eval local options="\${options/$pattern/}"

		#option=$suboptions_option

		#local original_options=${options_array[$suboptions_option]}
		#options_array[$suboptions_option]="${original_options/$pattern}"

		local new_option_value=${options_array[$suboptions_option]/$pattern}
		[[ $new_option_value ]] &&
			options_array[$suboptions_option]="$new_option_value" ||
			unset options_array[$suboptions_option]

		[[ $options =~ ^$remove_pattern ]] &&
			options="${options/$remove_pattern?(,)}" || options="${options/?(,)$remove_pattern}"
			#pattern="$remove_pattern?(,)" || pattern="?(,)$remove_pattern"
		#options="${options/$pattern}"

		unset suboption

		#echo HERE REM $suboptions_option $options

		#local option=${options_array[$suboptions_option]}
		#options_array[$suboptions_option]="${option/$pattern}"
	fi

	#eval echo REMOVE VAR $variable, \${$variable//$pattern/}

	if [[ ! $1 =~ value|segment ]]; then
		#echo removing $1 $value $variable ${!variable}
		#echo REMOVING o ${!options_array[*]}, so ${!suboptions_array[*]}, s ${!segments_array[*]}

		#shopt -s extglob

		#suboptions_pattern="+($all_suboptions)"
		#segments_pattern="+($multi_segment_options)"

		[[ $remove_pattern ]] && options_to_remove=${remove_pattern//[0-9:,]/}

		#echo HERE RP $remove_pattern $index, $options_to_remove
		#((index < ${#options_to_remove})) && echo Y || echo N
		#echo $index, ${#options_to_remove}, $options_to_remove
		#((index < ${#options_to_remove})) && echo Y || echo N
		#exit

		while ((index < ${#options_to_remove})); do
			get_option $options_to_remove

			#echo REMOVING OPTION $full

			if [[ $full ]]; then
				if [[ $full =~ $segment_options ]]; then
					unset segments_array[$full]
				elif [[ $full =~ $all_suboptions ]]; then
					unset suboptions_array[$full]
				else
					unset options_array[$full]
				fi
			fi

			#case $option in
			#	$segments_pattern) echo unset segments_array[$option];;
			#	$suboptions_pattern) echo unset suboptions_array[$option];;
			#	*) echo unset options_array[$option];;
			#esac

			#[[ $option =~ $all_suboptions ]] &&
			#	unset suboptions_array[$option] || unset options_array[$option]

			#echo removing o: $option_short $option
		done

		unset index

		#echo checking module
		#echo $module ^${modules_array[$module]}^
		#[[ ${modules_array[$module]} == $removed_value ]] &&
		#	modules=${modules/ -$module $removed_value/} && unset modules_array[$module]
	fi
}

add_value() {
	local value=${!1} array=${1}s_array variable=${1}s
	#echo ADDING $value

	#get_shorthand $value
	get_name $value

	#[[ $1 == segment ]] && local variable=values || variable=${1}s
	[[ $1 == module ]] &&
		local short=" -$short" separator=' ' new_separator=' '
		#local shorthand=" -$shorthand" separator=' ' new_separator=' '
	[[ $1 =~ option && $value =~ ${multi_segment_options/|size} ]] && local new_separator=':'

	if [[ "$(eval echo \${!$array[*]})" =~ $value ]]; then
		if [[ $value =~ ^($no_values)$ ]]; then
			remove_value $1
		else
			#eval $variable="\"\${$variable/$shorthand$new_separator\${$array[$value]}/$shorthand$new_separator$2}\""
			eval $variable="\"\${$variable/$short$new_separator\${$array[$value]}/$short$new_separator$2}\""
			eval $array[$value]="\"$2\""
		fi
	else
		if [[ $1 =~ option ]]; then
			#[[ $option =~ $separated_options ]] &&
			[[ $module =~ power && $1 == option ]] &&
				local separator=' ' || local separator=,
			#[[ $option =~ center|reverse ]] && local new_separator=' '
		fi

		#echo $variable, ${!variable}, $2

		[[ ${!variable} ]] &&
			eval $variable=\"${!variable}$separator$short$new_separator$2\" ||
			eval $variable=\"$short$new_separator$2\"
			#eval $variable=\"${!variable}$separator$shorthand$new_separator$2\" ||
			#eval $variable=\"$shorthand$new_separator$2\"

		#echo $1, ${!1}, $2, $separator, $variable, ${!variable}

		#~/.orw/scripts/notify.sh "ADD $array, $value, $2"
		[[ $value =~ ^($repeatable_segments)$ ]] || eval $array[$value]=\"$2\"
		#[[ $value =~ ^($repeatable_segments)$ ]] && echo v: $value
	fi

	#echo post var: ${!variable}

	#eval echo v: $value, $array: \${$array[$value]}
}

list_suboptions() {
	case $suboptions_option in
		#center) echo whole {left,right}_edge;;
		power_buttons) echo power_buttons_{size,icons,offset,actions};;
		representation) echo labels numeric representation_icons;;
		power_colorscheme) echo power_colorscheme_{current,select};;
	esac
}

add_suboptions() {
	local value values separator

	for suboptions_option in $(list_suboptions); do
		if [[ ${!suboptions_array[*]} =~ $suboptions_option ]]; then
			#get_shorthand $suboptions_option
			get_name $suboptions_option

			#[[ $suboptions_option =~ right_edge ]] && separator=' '
			[[ $suboptions_option =~ ${multi_segment_options/|size} ]] && separator=':'
			value=${suboptions_array[$suboptions_option]}
			#values+="$shorthand$separator$value,"
			values+="$short$separator$value,"
			#echo s: $shorthand, v: $value
			#echo s: $short, v: $value
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
						#echo HEREA so: ${suboptions_options//,/ }, o: $option
						for suboptions_option in ${suboptions_options//|/ }; do
							#echo s: $suboptions_option, so: ${suboptions_options//|/ }
							[[ "$(list_suboptions)" =~ $option ]] && break
						done

						suboption=$suboptions_option
					fi
					#echo HERE o: $option, so: $suboption
				fi
			fi

			previous_option=$option
			#[[ $module =~ ^($single_value_modules)$ ]] &&
			#	get value module "ENTER VALUE" || get option

			if [[ $module =~ ^($single_value_modules)$ ]]; then
				options=$(rofi -dmenu -p "ENTER VALUE" -theme list)
				#echo HERE $module $value
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
				#elif [[ $check == remove ]]; then
				#	echo HERE REMOVE
				#	option=$suboption
				#	get_name $option
				#	remove_value option
				else
					suboption=$option
				fi
			fi

			#echo OPT: $option, $suboptions_options
			#[[ $option =~ $suboptions_options ]] && echo Y || echo N
			#[[ $option =~ $suboptions_options && $check != remove ]] && continue
			[[ $option =~ ^($suboptions_options)$ ]] && continue

			#if [[ $option =~ $suboptions_options ]]; then
			#	continue
			#else
			#	[[ $suboption ]] &&
			#		option_type=suboption suboption=$option ||
			#		option_type=option
			#fi

			if [[ $check == remove ]]; then
				#get_shorthand $module
				#if [[ ! $option =~ $suboptions_options ]]; then
				#echo REMOVE HERE o $option, s $suboption, p $previous_option

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
				#[[ $suboption ]] && option_type=suboption || option_type=option
				#[[ $suboption ]] && suboption=$option

				#[[ $value && $value == ${options[$option]} ]] && values="${value//,/ }" && unset value
				#[[ $value && $value == ${options_array[$option]} ]] && segments="${value//,/ }" && unset value
				#echo v: $value, ov: ${options_array[$option]}, suv: ${suboptions_array[$option]}, s: $segments
				#[[ $value && $value == ${options[$option]} ]] && value="${value//,/ }"

				if [[ $option =~ ^($multi_segment_options)$ ]]; then
					segments="${value//,/ }"

					until [[ $check =~ back|done|remove ]]; do
						get segment
						#~/.orw/scripts/notify.sh "seg: $segment"
						#~/.orw/scripts/notify.sh "HERE $option $segment"

						if [[ $check == remove ]]; then
							#get_shorthand $option
							get_name $option
							remove_value $option_type
						fi

						if [[ ! $check =~ back|done|remove ]]; then
							[[ ! $segment =~ $multi_values && ! $segment =~ ^($no_values)$ ]] &&
								get value $segment "ENTER VALUE"

							#get_shorthand $segment
							get_name $segment
							[[ $value == remove ]] &&
								remove_value segment || add_value segment "$value"
						fi
					done

					#value=$values
					value=$segments
					unset segment segments
				else
					#echo pre o: $option, so: $suboption, ot: $option_type
					#echo VAL $option
					if [[ $option =~ ^($no_values)$ ]]; then
						#[[ $option == power_colorscheme_current ]] &&
						#	value=${options_array[colorscheme_name]:-${options_array[colorscheme_select]}}

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
							#echo ASKING FOR VALUE
							#get value $option "ENTER VALUE"
							get value $value "ENTER VALUE"
							#value=$(rofi -dmenu -p "ENTER VALUE" -theme list)
						elif [[ $value == remove ]]; then
							get_name $option
							remove_value $option_type
						else
							#echo VALUE $value
							get_name $value
							value=$short
						fi
					fi

					#if [[ $value == remove ]]; then
					#	#get_shorthand $option
					#	get_name $option
					#	remove_value $option_type
					#else
					#	#get_shorthand $value
					#	echo VALUE $value
					#	get_name $value
					#	value=$short
					#	#value=$shorthand
					#fi

					#echo o: $option, val: $value
				fi

				#[[ $option == size ]] && value="${segments_array[width]}x${segments_array[height]}"
				[[ $option == power_size && ! $suboption ]] &&
					value="${segments_array[width]}x${segments_array[height]}"

				#get_shorthand $option
				get_name $option

				#echo GETTING OPT $option: $short, $full: $value

				[[ $check != remove && $value != remove ]] && add_value $option_type "$value"
				[[ $option ]] && check=$option
			#elif [[ $check == remove ]]; then
			#	eval $option_type=$previous_option
			#	get_name ${!option_type}
			#	remove_value $option_type #${!option_type} $previous_option
			#	unset check
			#	#exit
			fi

			#previous_option=${!option_type}
		done
	fi

	if [[ $module =~ $repeatable_segments ]]; then
		get_name $module
		#echo MOD $short OPT $options VAL $value
		modules+=" -$short $options"

		for option in $(list_options | xargs); do
			unset options_array[$option]
		done

		#modules+=" -$short ${options:-$value}"

		#[[ $options ]] || unset repeatable_options
		#modules+=" -$short$repeatable_options"

		#[[ $options ]] &&
		#	repeatable_options=" ${options//,/ }" ||
		#	unset repeatable_options

		##get_shorthand $module
		#get_name $module
		#modules+=" -$short$repeatable_options"
		##modules+=" -$shorthand$repeatable_options"
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
			#echo final round: $module $options $modules
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
#segment_options='(mpd|torrent)_(dashed|step)|prev|play/pause|next|circle|mpd_separator|power_(width|height)|lock|logout|reboot|suspend|poweroff'
multi_values='(launchers|workspaces|apps)_separator|representation_icons|workspace|(workspaces|power_buttons)_offset|offset|position|power_colorscheme_select|colorscheme_clone|icons'
repeatable_segments='mpd.*offset|circle|frame|joiner|offset|separator|padding|icons'
suboptions_modules='x|workspaces|power'
suboptions_options='representation|power_buttons|power_colorscheme'
#all_suboptions='representation|labels|icons|numeric|power_colorscheme|power_(buttons|icons|offset|separator|actions)|current|select|center|whole|(left|right)_edge'
all_suboptions='representation|labels|representation_icons|numeric|power_(colorscheme(_(select|current))?|buttons(_(size|icons|offset|actions))?)'
alt_named_options='width|height|top|bottom|offset|separator|padding|buttons|icons|size|actions|colorscheme|name|clone|select|current|volume|progressbar|step'
alt_named_segments='.*(step|dashed|progressbar)'
#separated_options='(x|y)_offset|center|reverse|(left|right)_edge|buttons|colorscheme|size|colorscheme_*|width|edge|distance|(half|next)_bg|symbol'
separated_options='power_(buttons|colorscheme|size)'

no_values='cpu|memory|disk_space|hidden|network|updates|email|rss|.*volume|'
no_values+='secondary_color|info|time|toggle|volume|(workspaces|launchers)_padding|active|over|under|around|labels|numeric|.*current|.*bottom|center|right|only|icon|none|'
no_values+='prev|play/pause|next|circle|.*dashed|remain|half_bg|lock|logout|reboot|suspend|poweroff|power_buttons_icons|(circle|square)_*|adjustable'

#until
#	read section_index section <<< $(echo -e 'done\nsettings\nmodules' | \
#		rofi -dmenu -format 'i s' -selected_row $section_index -theme list)
#	[[ $section == done ]]
#do
#	section=all_$section
#	get_section "${!section}"
#done

#echo so ${!suboptions_array[*]} ${suboptions_array[*]}
#echo o ${!options_array[*]} ${options_array[*]}
#exit

#echo "generate_bar.sh$modules"
#exit

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
		#echo o $option, ${options:index:1} $options
		#echo $index $short $full

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

		#echo o $option, ${options:index:1} $options
		#echo $short $full, $segment_value
		#echo $index $option_value_full = $segment_value

		segments_array[$option_value_full]="$segment_value"
		option_values+="$option_value_short$segment_value"
		unset segment_value
	done
}

#declare -A short_modules_array

#eval $(awk '{
#	print "short_modules_array=( " gensub("([^-]*-(.)\\s*([^-]*))", "[\\2]=\"\\3\" ", "g") " )" }' \
#		~/.config/orw/bar/configs/moun)

#awk '{ print gensub("([^-]*-(.)\\s*([^-]*))", "\\2 \\3", "g") }' ~/.config/orw/bar/configs/moun

#config=~/.config/orw/bar/configs/moun
#
#read index module options <<< $(while read module options; do
#		get_name $module
#		echo $full
#	done <<< $(awk '{ print gensub("([^-]*-(.)\\s*([^-]*))", "\\2 \\3\n", "g") }' $config) |
#		rofi -dmenu -format 'i s' -theme list)
#
#((index++))
#read module options <<< $(awk '{ print gensub("([^-]*-(.)\\s*([^-]*)){'$index'}.*", "\\2 \\3", 1) }' $config)
##echo m $module, o $options
##exit

#read module options <<< \
#	$(for module in ${!short_modules_array[*]}; do
#		get_name $module
#		module_options=${short_modules_array[$module]}
#		printf '%s%-*s%s\n' $full $((offset - (${#full} + ${#module_options} + 1))) ' ' "$module_options"
#	done | rofi -dmenu -theme list)

config_path=~/.config/orw/bar/configs

select_config() {
	config_selection=$(echo -e 'select\nrunning' | rofi -dmenu -theme list)

	#[[ $config_selection == running ]] &&
	#	config=$(ps -C lemonbar -o args= | awk '{ print $NF }' | rofi -dmenu -theme list) ||
	#	config=$(ls $config_path | awk '{ print gensub(".*/(.*)\\..*", "\\1", 1) }' | rofi -dmenu -theme list)

	if [[ $config_selection == running ]]; then
		##config=$(ps -C lemonbar -o args= | awk '{ print $NF }' | rofi -dmenu -theme list)
	#read -a running <<< $(ps -C lemonbar -o args= | awk '{ print $NF }' | xargs)
	#((${#running[*]} == 1))
		read count running <<< $(ps -C lemonbar -o args= |
			awk '{ s = (r) ? "\\\\n" : ""; r = r s $NF; rc++ } END { print rc, r }')
		((count == 1)) && bar_config=$running || bar_config=$(echo -e $running | rofi -dmenu -theme list)
	else
		bar_config=$(ls $config_path | awk '{ print gensub(".*/(.*)\\..*", "\\1", 1) }' | rofi -dmenu -theme list)
	fi

	config="$config_path/$bar_config"
}

get_module() {
	#config_modules=$(awk '{ print gensub("([^-]*-(.)\\s*([^-]*))", "\"\\2 \\3\" ", "g") }' $config) 
	#eval config_modules_array=( $config_modules )

	#read index for config_module in "${config_modules_array[@]}"; do
	#	get_name ${config_module%% *}
	#	echo $full
	#done

#	read index config_module <<< $(
#		while read config_module module_options; do
#			if [[ $config_module == done ]]; then
#				echo done
#			else
#				get_name $config_module
#				#[[ $full =~ colorscheme ]] &&
#				#	options_array[colorscheme_name]=${module_options%,*}
#				echo $full
#			fi
#		done <<< $(awk '
#		BEGIN { if("'$action'" != "add") print "done" }
#			{ print gensub("([^-]*-(.)\\s*([^-]*))", "\\2 \\3\n", "g") }' $config) |
#			rofi -dmenu -format 'i s' -theme list)

	read index config_module <<< $(
		while read config_module module_options; do
			[[ $config_module == done ]] && full=done || get_name $config_module
			echo $full
		done <<< $(awk '
			BEGIN { if("'$action'" != "add") print "done" }
				{ print gensub("([^-]*-(.)\\s*([^-]*))", "\\2 \\3\n", "g") }' $config) |
				rofi -dmenu -format 'i s' -theme list)

		#BEGIN { if("'$action'" ~ "remove|edit") printf "done\n" }

		#done <<< $(awk '{ print gensub("([^-]*-(.)\\s*([^-]*))", "\\2\n", "g") }' $config) |
		#	rofi -dmenu -format 'i s' -theme list)

	#exit
	#read module options <<< $(awk '{ print gensub("([^-]*-(.)\\s*([^-]*)){'$index'}.*", "\\2 \\3", 1) }' $config)

	#((index++))
	#[[ $action =~ remove|edit ]] || ((index++))
	[[ $action == add ]] && ((index++))
	original_index=$index

	read last_index module_flag options <<< \
		$(awk '{ am = gensub("([^-]*-(.)\\s*([^-]*))", "\\2 \\3\n", "g") }
			END {
				mc = split(am, ma, "\n")
				print mc - 1, ma['$index']
			}' $config) 
}

#select_config
#get_module
#config_modules=$(awk '{ print gensub("([^-]*-(.)\\s*([^-]*))", "\"\\2 \\3\" ", "g") }' $config) 
#echo "$config_modules"
#eval config_modules_array=( $config_modules )
#echo ${#config_modules_array[*]}
#exit

#get_module() {
#	read index module options <<< $(
#		while read last_index module options; do
#			get_name $module
#			echo $full
#		#done <<< $(awk '{ print gensub("([^-]*-(.)\\s*([^-]*))", "\\2 \\3\n", "g") }' $config) |
#		done <<< $(awk '{
#						am = gensub("([^-]*-(.)\\s*([^-]*))", "\\2 \\3\n", "g")
#					} END {
#						mc = split(am, ma, "\n")
#						for(mi in ma) { print mc - 1, ma[mi] }
#					}' $config) |
#				rofi -dmenu -format 'i s' -theme list)
#
#		echo l: $last_index
#		exit
#
#	[[ $add ]] || ((index++))
#	read module options <<< $(awk '{ print gensub("([^-]*-(.)\\s*([^-]*)){'$index'}.*", "\\2 \\3", 1) }' $config)
#
#	get_name $module
#	module=$full
#}

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
	#until
	#	read section_index section <<< $(echo -e 'done\nsettings\nmodules' | \
	#		rofi -dmenu -format 'i s' -selected_row $section_index -theme list)
	#	[[ $section == done ]]
	#do
	#	section=all_$section
	#	get_section "${!section}"
	#done
	list_sections

	[[ $modules ]] && ~/.orw/scripts/barctl.sh -g "$modules" || echo nothing to generate
	exit 0
else
	select_config

	while
		#[[ $action == add ]] && add=$(echo -e 'done\nbefore\nafter' | rofi -dmenu -theme list)
		[[ $action == add ]] && add=$(echo -e 'done\nbefore\nafter' | rofi -dmenu -theme list)

		#get_module

		[[ $add == done ]] && break || get_module
		[[ $module_flag ]]; do
		#[[ $module_flag || ($action == add && $add != done) ]]; do
		#original_index=$index

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

			#echo $module_flag
			#exit

			#[[ $add == insert ]] && ((original_index--))
			#if ((original_index < last_index)); then
			#	[[ $add == insert ]] && before_separator=' ' || after_separator=' '
			#fi

			#[[ $add == append && $index -lt $last_index ]] && after_separator=' '

			#if [[ $add == insert ]]; then
			#	((original_index--))
			#else
			#	((original_index < last_index)) && after_separator=' ' || before_separator=' '
			#	#if ! grep "$short[^-]*$" $config; then after_separator=' '; fi
			#	#echo $original_index, $last_index, ^$after_separator^
			#fi

			[[ $add == before ]] && ((original_index--))
			if ((original_index < ${original_last_index:-$last_index})); then
				after_separator=' '
			else
				[[ $add == after ]] && before_separator=' '
			fi

			#module_flag="$(sed 's/^\s*//; s/\s*$//' <<< "$modules")"

			awk -i inplace '
				BEGIN { m = "'"$before_separator$module_flag$after_separator"'" }
				{ print gensub("(([^-]*-.\\s*[^-]*){'$original_index'})(.*)", "\\1" m "\\3", 1) }' $config

			#awk -i inplace '
			#	BEGIN {
			#		i = '$original_index'
			#		m = "'"$before_separator$module_flag$after_separator"'"
			#	} { print gensub("(([^-]*-.\\s*[^-]*){" i - 1 "})(-[^-]*)(.*)", "\\1" m "\\3", 1) }' ${original_config:-$config}
				#{ print gensub("(([^-]*-.\\s*[^-]*){'$original_index'})(.*)", "\\1" m "\\3", 1) }' $config
		elif [[ $action == swap ]]; then
			org_module_flag=$module_flag
			unset module_flag
			first_index=$original_index

			get_module
			#echo $org_module_flag, $module_flag, $first_index, $index
			#[[ "j" == [$org_module_flag$module_flag] ]] &&
			#	match_ending='' || match_ending='[^-]*'
			#awk '
			#	function get(i) {
			#		#return gensub("(([^-]*-){" i - 1 "}[^-]*)(-(j(([^-]*-)[^j]).([^-]*-.){2}[^-]*|[^-]*)).*", "\\3", 1)
			#		return gensub("(([^-]*-){" i - 1 "}[^-]*)(-(j[^j]*.\\s*-[^-]*|[^-]*)).*", "\\3", 1)
			#	}
			#	{ print get('$first_index') }
			#	{ print get('$index') }' $config
			#exit
			awk -i inplace '
				BEGIN { f = '$first_index'; s = '$index'; l = '$last_index' }

				function get(i) {
					#return gensub("(([^-]*-){" i - 1 "}[^-]*)(-[^-]*).*", "\\3", 1)
					return gensub("(([^-]*-){" i - 1 "}[^-]*)(-(j[^j]*.\\s*-[^-]*|[^-]*)).*", "\\3", 1)
				}

				function set(i, current_module, new_module) {
					if(i == l) {
						sub("\\s+$", "", new_module)
					} else if(new_module !~ " $") new_module = new_module " "

					if(current_module ~ "-j") sub(current_module, new_module)
					else $0 = gensub(current_module, new_module, 2)
					#else gsub(current_module, new_module, 2)

					#$0 = gensub("(-[^-]*)", new_module, i)
					#$0 = gensub("(([^-]*-){" i - 1 "}[^-]*)(-[^-]*)", "\\1" new_module, 1)
				}

				{
					fm = get(f)
					sm = get(s)
					set(f, fm, sm)
					set(s, sm, fm)
					print 
					#print "^" $0 "^"
				}' $config
		elif [[ $action == remove ]]; then
			#while [[ $module_flag ]]; do
				#echo $module $full $short $index $last_index
				awk -i inplace '
					BEGIN { i = '$index'; li = '$last_index'; s = (i == li) ? "" : " " }
					{ print gensub("((-[^-]*){" i - 1 "})( -[^-]*)", "\\1" s, 1) }' $config
				#unset module_flag
				#get_module
			#done
		else
			#module_name=$module
			#unset module
			#while [[ $module_flag ]]; do

			get_name $module_flag
			module=$full

			if [[ $module == power ]]; then
				#if [[ ! ${options_array[colorscheme_name]} ]]; then
				#	read colorscheme_name colorscheme_clone <<< $(awk '{
				#		print gensub("([^-]*-[^c])*[^-]*-c\\s*(([^, ]*),?([^ ]*)).*", "\\3 \\4", 1)
				#	}' $config)

				#	options_array[colorscheme_name]=$colorscheme_name
				#	[[ $colorscheme_clone ]] && options_array[colorscheme_clone]=$colorscheme_clone
				#fi

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
										#echo BUTTON ACTION ${power_actions:0:1}, $short, $full
										power_actions=${power_actions:1}
									done

									full=power_buttons_actions
								fi

								#echo BUTT OPT $short, $full: $segment_value

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
				#echo ${modules_array[$short]}

				while ((index < ${#options})); do
					#option_short=${options:$index:1}
					#((index++))

					#[[ $option_short == [\ ,] ]] &&
					#	option_short=${options:$index:1} && ((index++))

					#[[ $module == mpd && $option_short == o ]] &&
					#	option_short+=${options:index:1} && ((index++))

					#[[ $module == workspaces && $option_short == i ]] &&
					#	option_short=${options:index - 1} index=${#options}

					#get_name $option_short
					#option=$full

					get_option $options
					option=$full

					#echo FULL: $full

					if [[ ! $option =~ $no_values ]]; then
						if [[ $option =~ $multi_segment_options ]]; then
							get_segment_values
						else
							get_numeric_value
							option_values=$numeric_value
							unset numeric_value
						fi
					fi

					#echo s $option_short, o $option, v $option_values
					[[ $option == representation_icons ]] &&
						option_values=$option_short suboptions_array[$option]=${option_values#i} option=representation

					#echo f: $option, v: $option_values
					[[ $option ]] && options_array[$option]="$option_values"
					#options+="$option_short$option_values"
					unset option_values

					unset option_value_{short,option}
				done
			fi

			#echo o ${!options_array[*]}, so ${!suboptions_array[*]}
			#echo o ${options_array[*]}, so ${suboptions_array[*]}

			unset {sub,}option index check
			configure_module

			awk -i inplace '
				BEGIN { oi = '$original_index'; li = '$last_index'; s = (oi == li) ? "" : " " }
				{ print gensub("-[^-]*", "'"${modules# }"'" s, '$original_index') }' $config
			#echo $modules
			#echo $options

			#unset module{_flag,s,}
			#unset module{s,}
			#get_module
			#done
		fi

		unset module{,s,_flag}
		#unset module_flag
	done

	#if [[ $action =~ replace ]]; then
	#	from_bar=$config
	#fi

	#awk '{ print gensub("([^-]*-(.)\\s*([^-]*)){'$index'}.*", "\\2 \\3", 1) }' $config
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
							#echo BUTTON ACTION ${power_actions:0:1}, $short, $full
							power_actions=${power_actions:1}
						done

						full=power_buttons_actions
					fi

					#echo BUTT OPT $short, $full: $segment_value

					suboptions_array[$full]="$segment_value"
				done
			fi
		fi
	done
else
	index=0
	#echo ${modules_array[$short]}

	while ((index < ${#options})); do
		#option_short=${options:$index:1}
		#((index++))

		#[[ $option_short == [\ ,] ]] &&
		#	option_short=${options:$index:1} && ((index++))

		#[[ $module == mpd && $option_short == o ]] &&
		#	option_short+=${options:index:1} && ((index++))

		#[[ $module == workspaces && $option_short == i ]] &&
		#	option_short=${options:index - 1} index=${#options}

		#get_name $option_short
		#option=$full

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
		#options+="$option_short$option_values"
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

#map() {
#	case $1 in
#		x) short=x full=x;;
#		y) short=y full=y;;
#		w|width) short=w full=width;;
#		h|height) short=h full=height;;
#		f|frame) short=f full=frame;;
#		F|bar_frame) short=F full=bar_frame;;
#		j|joiner) short=x full=x;;
#		x) short=x full=x;;
#		x) short=x full=x;;
#		x) short=x full=x;;
#		x) short=x full=x;;
#		x) short=x full=x;;
#	esac
#}

#get_module_name() {
#	case $1 in
#		w) module_name=width;;
#		h) module_name=height;;
#		f) module_name=frame;;
#		F) module_name=bar_frame;;
#		j) module_name=joiner;;
#		O) module_name=offset;;
#		p) module_name=padding;;
#		s) module_name=separator;;
#		d) module_name=date;;
#		C) module_name=cpu;;
#		M) module_name=memory;;
#		D) module_name=disks;;
#		m) module_name=mpd;;
#		e) module_name=email;;
#		v) module_name=volume;;
#		N) module_name=network;;
#		A) module_name=apps;;
#		L) module_name=launchers;;
#		W) module_name=workspaces;;
#		a) module_name=font_size;;
#		*) module_name=$1;;
#	esac
#
#	echo $module_name
#}

#while read -r module value; do
#awk '{ print gensub("([^-]*-(.))", "\\2 ", "g") }' ~/.config/orw/bar/configs/moun

#get_name() {
#	case $1 in
#		w|width) short=w full=width;;
#		h|height) short=h full=height;;
#		f|frame) short=f full=frame;;
#		F|bar_frame) short=F full=bar_frame;;
#		j|joiner) short=j full=joiner;;
#		O|offset) short=O full=offset;;
#		#p|padding) short=p full=padding;;
#		s|step) short=s full=step;;
#		s|separator) short=s full=separator;;
#		d|date) short=d full=date;;
#		C|cpu) short=C full=cpu;;
#		M|memory) short=M full=memory;;
#		D|disks) short=D full=disks;;
#		R|rss) short=R full=rss;;
#		H|hidden) short=H full=hidden;;
#		m|mpd) short=m full=mpd;;
#		e|email) short=e full=email;;
#		v|volume) short=v full=volume;;
#		N|network) short=N full=network;;
#		A|apps) short=A full=apps;;
#		L|launchers) short=L full=launchers;;
#		W|workspace) short=W full=workspaces;;
#		a|font_size) short=a full=font_size;;
#		p|progressbar) short=p full=progressbar;;
#		T|time) short=T full=time;;
#		s|step) short=s full=step;;
#		i|info) short=i full=info;;
#		S|slide) short=S full=slide;;
#		d|dashed) short=d full=dashed;;
#		c|controls) short=c full=controls;;
#		t|play/pause) short=t full=play/pause;;
#		p|prev) short=p full=prev;;
#		n|next) short=n full=next;;
#		*) short=$1 full=$1;;
#	esac
#}

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

				#[[ $option == power_actions ]] && full=poweroff || full=${module}_offset
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
		#i|info|icons)
		i*)
			if [[ $module == workspaces ]]; then
				read full short <<< $(awk '/Workspace.*_[sp]/ {
						fn = gensub("[^_]*_(.*)_[ps].*", "\\1", 1)
						sn = gensub("(.)[^_]*_?", "\\1", "g", fn)
						if("'$1'" =~ fn|"i"sn) print fn, "i" sn
					}' ~/.orw/scripts/bar/icons)
				echo HERE
			else
				echo THERE
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

#all_modules=$(awk '{
#	print "all_modules=( " gensub("([^-]*-(.)\\s*([^-]*))", "[\\2]=\"\\3\" ", "g") " )" }' \
#		~/.config/orw/bar/configs/moun)

#declare -A modules_array
#eval "$all_modules"

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
#value_length=${#value}

#[[ $module =~ $separated_options ]] && separator=' ' || separator=,
#for option in ${all_modules[$module]//$separator/ }

get_numeric_value() {
	#local numeric_value
	local current_digit=${options:$index:1}

	while [[ $current_digit == [0-9] && $index -le ${#options} ]]; do
		#option_value=${value:$index:1}

		#get_name $option_value
		#option_value_full=$full
		#option_value_short=$short

		#[[ $value == [0-9] && $index -le $((value_length - 1)) ]]
		#[[ $value == [0-9] && $index -lt $value_length ]]
	#do
		numeric_value+=$current_digit
		((index++))
		current_digit=${options:$index:1}
	done

	#echo $numeric_value
}

get_segment_values() {
	until
		#option_value=${value:$index:1}
		#get_name $option_value

		get_name ${options:$index:1}
		option_value_short=$short
		option_value_full=$full
		((index++))

		#echo SEG: $option_value_short, $option_value_full

		[[ $option_value_short == [\ ,] || $index -gt ${#options} ]]
	do
		#[[ $option_value_full =~ $no_values ]] && segment_value=$(get_numeric_value)
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

#if [[ $module =~ $separated_options ]]; then
#	echo here
#else
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

	#while ((index < value_length)); do
	while ((index < ${#options})); do
		#((index)) || option_shorthand=${value:0:1}
		#option=$(get_name $option_shorthand)

		#option=$(get_name ${value:$index:1})
		#get_name ${value:$index:1}






		#option=${value:$index:1}
		#((index++))

		#[[ $option == [\ ,] ]] &&
		#	options+="$option" option=${value:$index:1} && ((index++))

		#[[ $module == mpd && $option == o ]] &&
		#	option+=${value:$index:1} && ((index++))

		#get_name $option
		#option_short=$short
		#option_full=$full

		option_short=${options:$index:1}
		((index++))

		[[ $option_short == [\ ,] ]] &&
			option_short=${options:$index:1} && ((index++))
			#options+="$option_short" option_short=${value:$index:1} && ((index++))

		[[ $module == mpd && $option_short == o ]] &&
			option_short+=${options:$index:1} && ((index++))

		#[[ $module == mpd && $option_short == o ]] &&
		#	((index+=2)) && option_short+=${value:$index:1} 

		get_name $option_short
		#option_short=$short
		option=$full

		if [[ ! $option =~ $no_values ]]; then
			if [[ $option =~ $multi_segment_options ]]; then
				#echo segment: $option_short, ${value:$index:1}
				#echo segments $index, ${value:$index:1}

				get_segment_values

				#echo SEG $options, $option_value_short, $option_values
				#echo options_array[$option]="$segment_values"
				#option_values+="$option_value_short$segment_values"
			else
				get_numeric_value
				option_values=$numeric_value
				unset numeric_value
				#option_values=$(get_numeric_value)
			fi
		fi

		[[ $option ]] && options_array[$option]="$option_values"
		#options+="$option_short$option_values"
		unset option_values

		#[[ $option_value_short == [\ ,] ]] && options+="$option_value_short"
		unset option_value_{short,full}
	done
fi

unset option

#echo ${!options_array[*]}
#echo ${!segments_array[*]}
#exit
configure_module
echo $modules
echo $options

#read index module <<< $(echo ${!all_modules[*]} | tr ' ' '\n' | rofi -dmenu -format 'i s' -theme list)
#read index module <<< $(for module in ${!all_modules[*]}; do echo $module

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
