#!/bin/bash

function get_properties() {
	properties=( $(wmctrl -lG | awk '$1 == "'$id'" {print $3, $4, $5, $6}') )
}

function calculate_font_dimension() {
	orientation=$1

	if [[ $orientation == h ]]; then
		base=5
		index=2
		dimension=${properties[2]}
	else
		base=10
		index=3
		dimension=${properties[3]}
	fi

	size=0 step=0

	while true; do
		(( size+=$base ))
		(( properties[$index]+=$size ))

		wmctrl -ir $id -e 0,${properties[0]},${properties[1]},${properties[2]},${properties[3]}
		get_properties

		step=$((${properties[$index]} - dimension))
		((step > 0)) && echo $step && break
	done
}

id=$(printf "0x%.8x" $(xdotool getactivewindow))
get_properties

h_base=${properties[2]}

sleep 0.2

config=~/.config/orw/config
echo "h_base $h_base" >> $config
echo "v_base ${properties[3]}" >> $config
echo "font_width $(calculate_font_dimension h)" >> $config
echo "font_height $(calculate_font_dimension v)" >> $config
