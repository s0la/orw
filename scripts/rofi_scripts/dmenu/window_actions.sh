#!/bin/bash

theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)
[[ $theme =~ dmenu|icons ]] && ~/.orw/scripts/set_rofi_geometry.sh volume
[[ $theme != icons ]] && close=close min=min max=max sep=' '

icon_max=
icon_min=
icon_close=

#id=$(printf "0x%.8x" $(xdotool getactivewindow))
config=~/.config/orw/config
offsets=~/.config/orw/offsets
properties=~/.config/orw/windows_properties

id=$(printf "0x%.8x" $(xdotool getactivewindow))
title=$(wmctrl -l | awk '$1 == "'$id'" { print $NF }')
maxed=$(awk '$1 == "'$id'" { m = ($NF == "maxed") } END { if(m) print "-a 1" }' $properties)

##read title x y w h <<< $(wmctrl -l | awk '$1 == "'$id'" { print $NF, $3, $4, $5, $6 }')
##mode=$(awk '/^mode/ { print $NF }' ~/.config/orw/config)
#read mode {x,{double_,}y}_border {x,y}_offset offset <<< \
#	$(awk '/^mode/ { m = $NF }
#		$1 ~ "border" {
#			if(/^x/) xb = $NF
#			else {
#				yb = $NF
#				dyb = (yb - (xb / 2)) * 2
#			}
#		}
#		$1 ~ "offset" {
#			if(/^x/) xo = $NF
#			else if(/^y/) yo = $NF
#			else print m, xb, dyb, yb, xo, yo, $NF
#		}' $config)
#
#read title x y w h <<< $(wmctrl -lG | \
#			awk '$1 == "'$id'" { print $NF, $3 - '$x_border', $4 - '$double_y_border', $5, $6 }')
#
##read x_border y_border x y w h <<< $(~/.orw/scripts/windowctl.sh -p)
#read display display_x display_y display_w display_h rest <<< $(~/.orw/scripts/get_display.sh $x $y)
##read x_offset y_offset offset <<< $(awk '$1 ~ "offset" { print $NF }' $config | xargs)
#[[ $offset == true ]] && read {x,y}_offset <<< $(sed -n 's/.*offset=//p' $offsets | xargs)
#
#while read -r bar_name position bar_x bar_y bar_width bar_height adjustable_width frame; do
#	if ((adjustable_width)); then
#		read bar_width bar_height bar_x bar_y < ~/.config/orw/bar/geometries/$bar_name
#	fi
#
#	current_bar_height=$((bar_y + bar_height + frame))
#
#	if ((position)); then
#		((current_bar_height > bar_top_offset)) && bar_top_offset=$current_bar_height
#	else
#		((current_bar_height > bar_bottom_offset)) && bar_bottom_offset=$current_bar_height
#	fi
#done <<< $(~/.orw/scripts/get_bar_info.sh $display)
#
#x_start=$((display_x + x_offset))
#x_end=$((display_x + display_w - x_offset))
#y_start=$((display_y + bar_top_offset + y_offset))
#y_end=$((display_y + display_h - bar_bottom_offset - y_offset))
#
#((x == x_start && y == y_start && x + w + x_border == x_end && y + h + y_border == y_end)) && maxed='-a 1'
##maxed=$(awk '$1 == "'$id'" { print "-a 1" }' ~/.config/orw/windows_properties)

action=$(cat <<- EOF | rofi -dmenu $maxed -theme main
	$icon_close$sep$close
	$icon_max$sep$max
	$icon_min$sep$min
EOF
)

if [[ $action ]]; then
	case "$action" in
		#$icon_min*) xdotool getactivewindow windowminimize;;
		$icon_min*) ~/.orw/scripts/minimize_window.sh $id;;
		$icon_max*)
			[[ $theme == icons ]] || args="${action#*$sep$max}"

			if [[ $maxed ]]; then
				~/.orw/scripts/minimize_window.sh $id restore
				sed -i '${ /^'$id'/d }' $properties

				#read line_number properties <<< $(awk '/^'$id'/ {
				#		nr = NR; p = gensub($1 " (.*) ?" $6, "\\1", 1)
				#	} END { print nr, p }' $properties)
				#sed -i "${line_number}d" $properties
			else
				[[ $mode != floating ]] && align='-A m'
				~/.orw/scripts/windowctl.sh -s $align move -h 1/1 -v 1/1 resize -h 1/1 -v 1/1
				awk -i inplace '$1 == "'$id'" { $6 = "maxed" } { print }' $properties
			fi;;

		#$icon_max*)
		#	[[ $theme == icons ]] || args="${action#*$sep$max}"

		#	[[ $maxed ]] && state='-r' || state='-s' geometry='move -h 1/1 -v 1/1 resize -h 1/1 -v 1/1'
		#	[[ $mode != floating && ! $maxed ]] && align='-A m'
		#	[[ $mode != floating ]] && state=${state^^}

		#	#echo ~/.orw/scripts/windowctl.sh $args $state $geometry $align
		#	#exit

		#	~/.orw/scripts/windowctl.sh $args $state $align $geometry
		#	((maxed)) || awk -i inplace '$1 == "'$id'" { $6 = "maxed" } { print }' $properties

		#	#[[ $maxed ]] && command="-r" ||
		#	#	command="-s move -h 1/1 -v 1/1 resize -h 1/1 -v 1/1"
		#	#~/.orw/scripts/windowctl.sh $args $command;;
		$icon_close*)
			#[[ $mode == floating ]] &&
			#	wmctrl -c :ACTIVE: ||
			#	~/.orw/scripts/windowctl.sh -A c
			wmctrl -c :ACTIVE:

			[[ $title =~ ^vifm ]] && vifm --remote -c quit

			tmux_command='tmux -S /tmp/tmux_hidden'
			tmux_session=$($tmux_command ls | awk -F ':' '$1 == "'$title'" { print $1 }')
			[[ $tmux_session ]] && $tmux_command kill-session -t $tmux_session
	esac
fi
