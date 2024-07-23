#!/bin/bash

toggle_windows() {
	wmctrl -l |
		awk '$2 == "'$desktop'" && $1 != "'$id'" { print $1 }' |
		xargs -I {} wmctrl -ir {} -b toggle,hidden
}

set_term_colors() {
	sed -i "/background/ s/#\w*/$bg/" $color_config
	sed -i "/foreground/ s/#\w*/$fg/" $color_config
}

accent="$1"
desktop=$(xdotool get_desktop)
id=$(printf '0x%.8x' $(xdotool getactivewindow))

color_fifo=/tmp/picked_color.fifo
color_config=~/.config/alacritty/alacritty_color_preview.toml

read h s v {b,f}g <<< $(~/.orw/scripts/convert_colors.sh -Bh $accent)
set_term_colors

until
	read -rn 1 -p "[P]ick or [A]djust? " answer

	if [[ $answer == [Pp] ]] then
		toggle_windows
		echo -e "\nPick a color.."
		bg=$(colorpicker --short --one-shot)
		read h s v {b,f}g <<< $(~/.orw/scripts/convert_colors.sh -Bh $bg)
		set_term_colors
		toggle_windows
	elif [[ $answer == [Aa] ]]; then
		while
			clear
			read -rn 1 -p $'[H]ue\n[S]aturation\n[V]alue\n[D]one\n:' hsv
			[[ $hsv && ${hsv,} != d ]]
		do
			hsv=${hsv,}
			case ${hsv,} in
				d) break;;
				h)
					property=hue
					range='0-360'
					;;
				*) 
					[[ $hsv == s ]] &&
						property=saturation || property=value
					range='0-100'
					;;
			esac

			clear
			read -p "current ${property^^} ${!hsv}($range): " adjusted

			[[ $adjusted ]] &&
				read h s v {b,f}g <<< \
				$(~/.orw/scripts/convert_colors.sh -${hsv^} $adjusted -Bh $bg) &&
				set_term_colors
		done
	fi

	clear
	read -rn 1 -p '[S]ave or [D]iscard? ' answer

	[[ ${answer,} == s || ! $answer ]]
do
	clear
done

echo $bg > $color_fifo
exit




while
	color=$(colorpicker --short --one-shot)

	#convert -size 100x100 xc:$color $preview
	#feh -g 100x100 --title 'image_preview' $preview &
	#preview_pid=$!

	read -p "[A]djust or [D]iscard the color? " answer

	if [[ $answer == [Aa] ]]; then
		#read -srn 1 -p $'Adjust color? [y/N]\n' adjust

		#if [[ $adjust == y ]]; then
		#	preview_pid=$!
		#	current_color_fifo=/tmp/current_color.fifo
		#	final_color_fifo=/tmp/final_color.fifo

		#	[[ -e $current_color_fifo ]] || mkfifo $current_color_fifo
		#	[[ -e $final_color_fifo ]] || mkfifo $final_color_fifo

			while [[ -e $current_color_fifo ]]; do
				read color < $current_color_fifo
				magick -size 100x100 xc:$color $preview

				kill $! &> /dev/null

				feh -g 100x100 --title 'image_preview' $preview &
				preview_pid=$!
			done &

			#while_pid=$!

			$colorctl -hPf $current_color_fifo,$final_color_fifo $color
			read color < $final_color_fifo

			#last_preview_pid=$(ps aux | awk '$NF == "'$preview'" { print $2 }')
			#kill $while_pid $last_preview_pid
		#fi
	fi

	read -srn 1 -p $'Keep color? [Y/n]\n' keep_color

	kill $! &> /dev/null

	[[ $keep_color == n ]]
do
	continue
done
