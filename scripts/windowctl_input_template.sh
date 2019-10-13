#!/bin/bash

set_grid_offests() {
	while getopts x:y:m: flag; do
		case $flag in
			x) x_offset=$OPTARG;;
			y) y_offset=$OPTARG;;
			m) margin_offset=$OPTARG;;
		esac
	done

	if [[ $edge ]]; then
		x_offset=60
		y_offset=30
	fi

	[[ ! $x ]] && x="-x ${x_offset-200}"
	[[ ! $y ]] && y="-y ${y_offset-100}"
	[[ ! $margin ]] && margin="-m ${margin_offset-15}"
}

evaluate() {
	input=$1

	case $input in
		e) edge=-e;;
		a) all=true;;
		o) offsets=-o;;
		A) adjucent=-a;;
		[Cc])
			center=-c
			[[ $input == C ]] && stop=true;;
		E) equal=true;;
		M) mirror=-M;;
		[Rs])
			[[ $all ]] && state=-${input^} || state=-${input,}
			[[ $input == R ]] && stop=true;;
		d) display=-d;;
		m) option=move;;
		[trbl])
			if [[ $option ]]; then
				if [[ $edge ]]; then
					edge+=" $input"
				else
					orientation=-${input^}
					stop=true
				fi
			else
				if [[ $mirror ]]; then
					mirror+=" $input"
					stop=true
				else
					[[ $input == r ]] &&
						option=resize ||
						bar=-b
				fi
			fi;;
		[HD])
			option=resize
			multi=-$input;;
		[hv])
			if [[ $option == fill || $center ]]; then
				orientation=$input
				stop=true
			else
				[[ $multi ]] && orientation=$input || orientation=-$input
			fi;;
		[fF])
			option=fill
			if [[ $input == F || $orientation ]]; then
				orientation=${orientation#-}
				stop=true
			fi;;
		[1-9]*)
			digit_count=${#input}

			if ((digit_count == 1)); then
				if [[ $zoom ]]; then
					current_desktop=$(xdotool get_desktop)
					id=$(wmctrl -lG | awk '$2 == '$current_desktop'' | sort -nk 4,3 | awk 'NR == '$input' { print $1 }')

					~/.orw/scripts/windowctl.sh $x $y $margin -i $id -s move -h 1/1 -v 1/1 resize -h 1/1 -v 1/1
					wmctrl -ia $id
					exit
				elif [[ $multi ]]; then
					ratio=$input
				else
					option=move
					display+=" $input"
				fi
			else
				half=$((digit_count / 2))
				ratio=${input:0:half}/${input:half}

				if [[ $equal ]]; then
					~/.orw/scripts/windowctl.sh resize -h $ratio -v $ratio
					exit
				fi
			fi

			stop=true;;
		p)
			x='-x 200'
			y='-y 100'
			margin='-m 15';;
		g)
			grid=-g
			state=-S

			stop=true;;
		z)
			~/.orw/scripts/windowctl.sh $x $y $margin -s move -h 1/1 -v 1/1 resize -h 1/1 -v 1/1
			exit;;
		*) stop=true
	esac
}

get_argument_count() {
	[[ $option && $orientation && ! $multi || $equal ]] && argument_count=2
}

execute() {
	~/.orw/scripts/windowctl.sh $x $y $margin $offsets $center $bar $state $grid $display $mirror $option $edge $multi $orientation $ratio $adjucent
}

while getopts :o:O: flag; do
	case $flag in
		x) x="-x $OPTARG";;
		y) y="-y $OPTARG";;
		o) option=$OPTARG;;
		m) margin="-m $OPTARG";;
		O) orientation=-$OPTARG;;
	esac
done
