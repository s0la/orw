#!/bin/bash

config=~/.config/orw/config
active=$(wmctrl -l | awk '\
	{
		switch ($NF) {
			case /vifm[0-9]?/: a = a ",2"; break;
			case /alacritty[0-9]?/: a = a ",0"; break;
			case /DROPDOWN/: a = a ",1"; break;
			case /qutebrowser/: a = a ",3"; break
		}
	} END { if (a) print "-a " substr(a, 2) }')

if [[ $style =~ icons|dmenu ]]; then
	read dropdown term vifm qb left right top bottom <<< \
		$(sed -n 's/^\(arrow_down_square_full\|.*_side\|term\|dir_empty\|web\).*=//p' $icons | xargs)
else
	term=alacritty dropdown=dropdown vifm=vifm qb=qutebrowser \
		left=left right=right top=top bottom=bottom
fi

toggle
trap toggle EXIT

item_count=4
set_theme_str

options=(
	$term
	$dropdown
	$vifm
	$qb
)

dropdown_options=(
	$top
	$right
	$left
	$bottom
)

get_title() {
	title=$(wmctrl -l | awk '$NF ~ "^'$1'[0-9]+?" { print $NF }' | sort -n | \
		awk '{
				ic = gensub("'$1'", "", 1)
				if(mc + 1 < ic) exit; else mc = (ic) ? ic : 0
			} END { if(length(mc)) mc++; print "'"$1"'" mc }')
}

focused_window=$(xdotool getwindowfocus getwindowname)
base_count=${#options[*]}
item_count=$base_count

while
	set_theme_str

	read index option < <(
		for option in ${options[*]}; do
			echo $option
			[[ $selected_option == $option ]] &&
				tr ' ' '\n' <<< "${dropdown_options[*]}"
		done | rofi -dmenu -format 'i s' -selected-row $index \
			$hilight $active -theme-str "$theme_str" -theme main)

	[[ $option ]]
do
	case "$option" in
		$dropdown|$top|$right|$left|$bottom)
			if [[ $option == $dropdown ]]; then
				if [[ $focused_window == DROPDOWN ]]; then
					xdotool getactivewindow windowminimize
				else
					if ! wmctrl -a DROPDOWN; then
						if [[ $selected_option ]]; then
							item_count=$base_count
							unset selected_option hilight
						else
							selected_option=$option
							((item_count += ${#dropdown_options[*]}))
							for h in $(seq 1 ${#dropdown_options[*]}); do
								hilight+=",$((index + h))"
							done

							[[ $hilight ]] && hilight="-u ${hilight#,}"
						fi

						continue
					fi
				fi
			else
				case $option in
					$top|$bottom)
						x=c w=60 h=40
						[[ $option == $top ]] && y=t || y=b
						;;
					$left|$right)
						y=c w=25 h=65
						[[ $option == $left ]] && x=l || x=r
						;;
				esac

				~/.orw/scripts/dropdown.sh -x $x -y $y -w $w -h $h
			fi
				#~/.orw/scripts/dropdown.sh ${app#*$dropdown}
			;;
		$term*)
			get_title alacritty
			alacritty -t $title &
			;;
		$vifm*)
			get_title vifm
			spy_windows=~/.orw/scripts/spy_windows.sh
			workspace=$(xdotool get_desktop)
			class="--class=custom_size"

			[[ $(awk '/^mode/ { print $NF }' $config) == tiling ]] &&
				grep "^tiling_workspace.*\b$workspace\b" $spy_windows &> /dev/null &&
				width=250 height=150

			~/.orw/scripts/set_geometry.sh -c custom_size -w ${width:-400} -h ${height:-500}

			alacritty -t $title --class=custom_size -e ~/.orw/scripts/vifm.sh &
			;;
		$qb*)
			get_title qutebrowser
			if [[ ! $app =~ private ]]; then
				qutebrowser ${app#*$qb} &
			else
				qutebrowser -s content.private_browsing true &
			fi
			;;
	esac
	exit
done
