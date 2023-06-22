#!/bin/bash

icons=$(awk -F '[".]' 'END { print $(NF - 2) == "icons" }' ~/.config/rofi/main.rasi)
((icons)) ||
	font=font margin=window_margin padding=window_padding element_padding=element_padding

font_icon= #   
margin_icon=
padding_icon=
element_padding_icon=

list_options() {
	read row action <<< \
		$(cat <<- EOF | rofi -dmenu -format 'i s' -selected-row $row -theme main
			$font_icon$sep$font
			$margin_icon$sep$margin
			$padding_icon$sep$padding
			$element_padding_icon$sep$element_padding
		EOF
	)
}

choose_direction() {
	local row

	while
		row=$(cat <<- EOF | rofi -dmenu -format i -selected-row $row -theme main
				
				
			EOF
		)

		[[ $row ]]
	do
		case $action in
			$font_icon) property=f;;
			$margin_icon) property=wm;;
			$padding_icon) property=wp;;
			$element_padding_icon) property=ep;;
		esac

		resize_rofi

		~/sws_test.sh rofi_resize
	done
}

resize_rofi() {
	local pattern direction
	((row)) &&
		direction=-${#property} || direction=+${#property}

	while ((${#property})); do
		[[ $pattern ]] && pattern+="-"
		pattern+="${property::1}\\\w*"
		property="${property:1}"
	done

	#echo $property, $pattern

	awk -i inplace '
		function new_value(multi) {
			v = $NF
			gsub("[^0-9\\.]", "", v)
			#gsub(v "[^0-9]*", (v += ((multi) ? multi : 1 ) * '$direction') "&")
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

#direction=+3
#action=wp
#resize_rofi
#exit

opn() {
	~/sws_test.sh rofi_toggle
}

opn
trap opn EXIT

while
	list_options
	[[ $action ]]
do
	choose_direction

	#while
	#	choose_direction
	#	[[ $direction ]]
	#do
	#	case $action in
	#		$font_icon);;
	#		$margin_icon) property=wm;;
	#		$padding_icon) property=wp;;
	#		$element_padding_icon) property=ep;;
	#	esac

	#	#~/.orw/scripts/borderctl.sh -c icons r$property $direction
	#	resize_rofi
	#done
done
