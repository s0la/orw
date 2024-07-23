#!/bin/bash

if [[ $style =~ icons|dmenu ]]; then
	read list dmenu horizontal vertical resize <<< \
		$(sed -n 's/^\(list\|rofi\|resize\).*=//p' ~/.orw/scripts/icons | xargs)
	read font margin {,element_}padding {horizontal,vertical}_offset <<< \
		$(sed -n 's/^\(font\|margin\|.*\(padding\|offset\)\).*=//p' ~/.orw/scripts/icons | xargs)
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
	local pattern direction
	((row)) &&
		direction=-${#property} || direction=+${#property}

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

toggle
trap toggle EXIT

item_count=5
set_theme_str

while
	list_main_options
	[[ $new_style ]]
do
	if [[ $new_style == $resize* ]]; then
		while
			list_resize_options
			[[ $action ]]
		do
			choose_direction
		done
	else
		[[ $style =~ ^((vertical_)?icons|dmenu)$ && $style != $new_style ]] &&
			close_rofi=true || unset close_rofi

		case $new_style in
			$list*) style=list;;
			$dmenu*) style=dmenu;;
			$vertical*)
				style=vertical_icons
				style=icons
				;;
			$horizontal*) style=horizontal_icons;;
		esac

		sed -i "$ s/\w*\./$style./" ~/.orw/dotfiles/.config/rofi/main.rasi

		[[ $style =~ ^((vertical_)?icons|dmenu)$ && $style != $new_style ]] &&
			open_rofi=true || unset open_rofi

		[[ $close_rofi ]] && toggle force

		if [[ $open_rofi ]]; then
			[[ $close_rofi ]] &&
				wait_to_proceed && sleep 0.3
			toggle
		fi

		set_theme_str force
	fi
done
