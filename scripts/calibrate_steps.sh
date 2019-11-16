#!/bin/bash

function get_properties() {
	properties=( $(wmctrl -lG | awk '$1 == "'$id'" { print $3, $4, $5, $6 }') )
}

function calculate_font_dimension() {
	local size=0 step=0
	dimension=${properties[index]}

	while true; do
		(( size+=base ))
		(( properties[index]+=size ))

		wmctrl -r :ACTIVE: -e 0,${properties[0]},${properties[1]},${properties[2]},${properties[3]}
		get_properties

		step=$((${properties[index]} - dimension))
		((step > 0)) && echo $step && break
	done
}

id=$(printf "0x%.8x" $(xdotool getactivewindow))
get_properties

h_base=${properties[2]}

base=5 index=2
h=$(calculate_font_dimension h)

base=10 index=3
v=$(calculate_font_dimension v)

fifo=/tmp/calculate_step.fifo
[[ ! -f $fifo ]] && mkfifo $fifo
echo "$h $v" > $fifo
