#!/bin/bash

if [[ $style =~ icons|dmenu ]]; then
	read list dmenu horizontal vertical resize <<< \
		$(sed -n 's/^\(list\|rofi\|resize\).*=//p' ~/.orw/scripts/icons | xargs)
	read up down font margin {,element_}padding {horizontal,vertical}_offset <<< \
		$(sed -n 's/^\(arrow_\(up\|down\).*circle.*\|font\|margin\|.*\(padding\|_offset\)\)=//p' ~/.orw/scripts/icons | xargs)
else
	font=font margin=window_margin padding=window_padding element_padding=element_padding sep=' '
fi

list_resize_options() {
	local item_count=4 theme_str
	set_theme_str

	[[ $style =~ ^(vertical_)?icons$ ]] &&
		offset=$vertical_offset ||
		offset=$horizontal_offset

	read row action <<< \
		$(cat <<- EOF | rofi -dmenu -format 'i s' -theme-str "$theme_str" -selected-row $row -theme main
			$font
			$offset
			$padding
			$element_padding
		EOF
	)
}

list_main_options() {
	read row new_style <<< \
		$(cat <<- EOF | rofi -dmenu -format 'i s' -theme-str "$theme_str" -selected-row $row -theme main
			$dmenu
			$horizontal
			$vertical
			$list
			$resize
		EOF
	)
}

choose_direction() {
	local row theme_str item_count=2
	set_theme_str

	while
		row=$(echo -e '\n' | rofi -dmenu -format i \
			-theme-str "$theme_str" -selected-row $row -theme main)

		[[ $row ]]
	do
		case $action in
			$font) property=f;;
			$offset)
				[[ $offset == $vertical_offset ]] &&
					local orientation=x || local orientation=y

				property=${orientation}o;;
			$margin) property=wm;;
			$padding) property=wp;;
			$element_padding) property=ep;;
		esac

		resize_rofi

		~/.orw/scripts/signal_windows_event.sh rofi_resize
	done
}

resize_rofi() {
	local pattern direction multiplier

	[[ $property == [xy]o ]] &&
		multiplier=10 || multiplier=1
	multiplier=1

	[[ $option == $down ]] &&
		direction=-$((${#property} * multiplier)) ||
		direction=+$((${#property} * multiplier))

	~/.orw/scripts/borderctl.sh r$property ${direction}
	set_theme_str force
	return

	while ((${#property})); do
		[[ $pattern ]] && pattern+="-"
		pattern+="${property::1}\\\w*"
		property="${property:1}"
	done

	awk -i inplace '
		function new_value(multi) {
			v = $NF
			gsub("[^0-9\\.]", "", v)
			gsub("[0-9\\.]+(\\B)" q, (v += ((multi) ? multi : 1 ) * '$direction'))
		}

		$1 ~ "'"$pattern"':" {
			if (/font/) { m = 1.5; q = "?" }
			else m = 2
			new_value()
		}

		$1 ~ "width" {
			if (m) new_value(m)
		} { print }' ~/.config/rofi/icons.rasi
}

#item_count=10
#set_theme_str
#echo "$theme_str"
#exit

toggle
trap toggle EXIT

#item_count=5
#set_theme_str

list_resize_options() {
	for resize_option in ${!resize_options[*]}; do
		option=${resize_options[resize_option]}
		if [[ ! $option ]]; then
			[[ $style =~ ^(vertical_)?icons$ ]] &&
				option=$vertical_offset || option=$horizontal_offset
		fi

		echo $option
		#~/.orw/scripts/notify.sh -t 11 "$vertical_offset"
		[[ $option == $selected_option ]] &&
			((item_count > base_count + ${#resize_options[*]})) &&
			echo -e "$up\n$down"
	done

	#[[ $resize_hilights ]] &&
	#	hilight="-u ${resize_hilights%,}" ||
	#	hilight="-u ${suboption_hilights%,}"
}

#options=( $dmenu $horizontal $vertical $list $resize )
options=(
	dmenu
	horizontal
	vertical
	list
	resize
)

resize_options=(
	$font
	"$offset"
	$margin
	$padding
	$element_padding
)

base_count=${#options[*]}
item_count=$base_count
#echo ${resize_options[*]}, $font
#sed -n 's/^\(arrow_\(up\|down\).*circle.*\|font\|margin\|.*\(padding\|_offset\)\)=//p' ~/.orw/scripts/icons | xargs
#exit

while
	set_theme_str
	#~/.orw/scripts/notify.sh -t 11 "$theme_str"

	for option_index in ${!options[*]}; do
		[[ $style == *${options[option_index]}* ]] &&
			active="-a $option_index" && break
	done

	read index option < <(
		for option_label in ${options[*]}; do
			echo ${!option_label}
			[[ ${!option_label} == $resize ]] && ((item_count > base_count)) && list_resize_options
		done | rofi -dmenu -format 'i s' -selected-row ${index:-0} \
			$active $hilight -theme-str "$theme_str" -theme $style)

	echo $index: $option
	[[ $option ]]
do
	if [[ $option == $resize ]]; then
		resize_hilight=''
		if ((item_count == base_count)); then
			((item_count += ${#resize_options[*]}))
			for resize_option in $(seq ${#resize_options[*]}); do
				resize_hilight+="$((base_count + resize_option - 1)),"
			done
			hilight="-u ${resize_hilight%,}"
		else
			((item_count -= ${#resize_options[*]}))
			unset hilight
		fi
	elif [[ $selected_option ]]; then
		echo $option, $selected_option, $item_count, $base_count, ${#resize_options[*]}
		if [[ $option == $selected_option ]]; then
			((item_count > base_count + ${#resize_options[*]}))
			hilight="-u ${resize_hilight%,}"
			unset selected_option
			((item_count-=2))
		fi

		if [[ $option =~ $up|$down ]]; then
			case $selected_option in
				$font) property=f;;
				$margin) property=wm;;
				$padding) property=wp;;
				$element_padding) property=ep;;
				$vertical_offset) property=xo;;
				$horizontal_offset) property=yo;;
			esac

			resize_rofi

			~/.orw/scripts/signal_windows_event.sh rofi_resize
		fi
	elif [[ "${resize_options[*]} $horizontal_offset $vertical_offset" == *$option* ]]; then
		selected_option=$option
		hilight="-u $((index + 1)),$((index + 2))"
		((item_count += 2))
		((index++))
	else
		new_style=$option
		[[ $style =~ ^((vertical_)?icons|dmenu)$ && $style != $new_style ]] &&
			close_rofi=true || unset close_rofi

		previous_style=$style
		case $new_style in
			$list*) style=list;;
			$dmenu*) style=dmenu;;
			$vertical*) style=vertical_icons;;
			$horizontal*) style=horizontal_icons;;
		esac

		sed -i "$ s/\w*\./$style./" ~/.orw/dotfiles/.config/rofi/main.rasi

		[[ $style =~ ^((vertical_)?icons|dmenu)$ && $style != $previous_style ]] &&
			open_rofi=true || unset open_rofi

		[[ $open_rofi && ! $previous_style =~ ^((vertical_)?icons|dmenu)$ ]] &&
			~/.orw/scripts/signal_windows_event.sh update
		[[ $close_rofi ]] && toggle force

		if [[ $open_rofi ]]; then
			echo opening
			[[ $close_rofi ]] &&
				wait_to_proceed && sleep 0.3
			toggle
		fi

		set_theme_str force
	fi
done
