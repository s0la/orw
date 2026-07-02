#!/bin/bash

colorscheme="${1%.*}"
colorschemes_root=~/.config/orw/colorschemes
#modules="$(sed -n "s/^#\(.*\)/[\1]=1 /p" $colorchemes_root/$colorcheme | xargs)"
modules=( $(sed -n "s/^#//p" $colorschemes_root/$colorscheme.ocs) )
options=(
	done
	none
	all
	base
	)
module_count=$((${#modules[*]} + ${#options[*]}))

#read {un,}checked_icon <<< $(sed -n 's/^checkbox.*=//p' ~/.orw/scripts/icons | xargs)

theme_str="* { lines: $module_count; }"

set_all() {
	local all=$(eval echo {${#options[*]}..$((module_count - 1))})
	indices="${all// /,}"
}

set_none() {
	unset indices
}

toggle() {
	~/.orw/scripts/signal_windows_event.sh image_preview
}

trap toggle EXIT INT

toggle
set_all

while
	[[ $indices ]] &&
		hilight="-u $indices" || unset hilight

	read index module <<< \
		$(rofi -dmenu $hilight -selected-row ${index:-0} \
		-format 'i s' -theme-str "$theme_str" -theme list \
		<<< $(printf '%s\n' ${options[*]} ${modules[*]}))

	#read index module <<< \
	#	$(rofi -dmenu $hilight -selected-row ${index:-0} \
	#	-format 'i s' -theme-str "$theme_str" -theme list \
	#	<<- EOF
	#		$(tr ' ' '\n' <<< "${options[*]} ${modules[*]}")
	#	EOF
	#	)

	((index))
do
	case $index in
		[12]) set_$module;;
		3)
			~/.orw/scripts/ocsgen.sh -NAFw $colorschemes_root/$colorscheme
			exit
			;;
		*)
			if [[ $indices =~ (^|,)$index(,|$) ]]; then
				case $indices in
					$index,*) indices=${indices#*,};;
					*,$index) indices=${indices%,*};;
					*,$index,*) indices=${indices/,$index,/,};;
					$index) unset indices;;
				esac
			else
				[[ $indices ]] &&
					indices+=",$index" || indices=$index
			fi
			;;
	esac
done

if [[ $index ]]; then
	for index in ${indices//,/ }; do
		modules_to_set+="${modules[index - ${#options[*]}]},"
	done

	#~/.orw/scripts/signal_windows_event.sh image_preview

	~/.orw/scripts/rice_and_shine.sh -C ${colorscheme%.*} -m ${modules_to_set%,}
fi
