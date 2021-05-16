#!/bin/bash

getopts :m: flag
[[ $flag == m ]] && mode=$OPTARG && shift 2

id=$(xdotool getactivewindow 2> /dev/null)
[[ $mode ]] || mode=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)

if [[ $id ]]; then
	read x y <<< $(wmctrl -lG | awk '$1 == sprintf("0x%.8x", "'$id'") { print $3, $4 }')
	read display width height <<< $(~/.orw/scripts/get_display.sh $x $y | cut -d ' ' -f 1,4,5)
else
	read width height <<< $(awk '/^primary/ { p = $NF } p && $1 == p "_size" { print $2, $3 }' ~/.config/orw/config)
fi

if [[ $mode == icons ]]; then
	script=~/.orw/scripts/rofi_scripts/dmenu/$1.sh

	count_items() {
		awk '/s*'"$1"'/ { wc = gensub(/[\0-\177]/, "", "g"); print length(wc) }' $script
	}

	location=$(awk -F '[; ]' '/window-location:/ { print $(NF - 1) }' ~/.config/rofi/icons.rasi)

	if [[ $location =~ south|north ]]; then
		printf -v id '0x%.8x' $(xdotool getactivewindow)

		if [[ $id ]];then
			read x y <<< $(wmctrl -lG | awk '$1 == "'$id'" { print $3, $4 }')
			display=$(~/.orw/scripts/get_display.sh $x $y 2> /dev/null | cut -d ' ' -f 1)

			bar_offset=$(awk '
				/^primary/ {
					d = ('${display:-0}') ? "display_'${display:-0}'" : $NF
				}
				$1 == d "_offset" {
					print ("'$location'" == "south") ? $3 : $2
				}' ~/.config/orw/config)

			#((display)) || display=$(awk -F '_' '/^primary/ { print $NF }' ~/.config/orw/config)

			#while read name position bar_x bar_y bar_widht bar_height adjustable_width frame; do
			#	#if ((adjustable_width)); then
			#	#	read bar_width bar_height bar_x bar_y < ~/.config/orw/bar/geometries/$name
			#	#fi

			#	current_bar_height=$((bar_y + bar_height + frame))

			#	if ((position)); then
			#		((current_bar_height > top_offset)) && top_offset=$current_bar_height
			#	else
			#		((current_bar_height > bottom_offset)) && bottom_offset=$current_bar_height
			#	fi
			#done <<< $(~/.orw/scripts/get_bar_info.sh $display)
		fi

		#[[ $location == south ]] && bar_offset=$bottom_offset || bar_offset=$top_offset
	fi

	[[ $2 ]] &&
		item_count=$2 ||
		item_count=$(awk '\
			/<<-/ { start = 1; nr = NR + 1 }
			/^\s*EOF/ && start { print NR - nr; exit }' $script)

		read {x,y}_offset offset <<< $(awk '/^([xy]_)?offset/ { print $NF }' ~/.config/orw/config | xargs)

	[[ $offset == true ]] && eval $(cat ~/.config/orw/offsets)

	#if [[ $2 ]]; then
	#	item_count=$2
	#else
	#	case $1 in
	#		#wallpapers) item_count=6;;
	#		workspaces) item_count=$(wmctrl -d | awk 'END { print NR + 2 }');;
	#		*) item_count=$(awk '/<<-/ { start = 1; nr = NR + 1 } /^\s*EOF/ && start { print NR - nr; exit }' $script)
	#	esac
	#fi

	#awk -i inplace -F '[ %;]' '{
	read property property_value margin <<< $(awk -i inplace -F '[ ;]' '\
		BEGIN {
			xo = '$x_offset'
			yo = '$y_offset'
			ic = '$item_count'
			bo = '${bar_offset:-0}'
		}

		{
			if(/font/) fs = gensub(/.* ([0-9.]+).*/, "\\1", 1)

			if(/window-orientation:/) o = $(NF - 1)

			if(/(window|element)-padding:/) {
				hp[++vi] = gensub(/[^0-9]*( ([0-9]+)px){2}.*/, "\\2", 1) * 2
				vp[++hi] = gensub(/[^0-9]*( ([0-9]+)px){1}.*/, "\\2", 1) * 2
			}

			if(/element-border:/) eb = gensub(/.* ([0-9]+)px.*/, "\\1", 1)

			if(/spacing:/) ls = gensub(".* ([0-9.]+)px.*", "\\1", 1)

			if(/window-orientation:/) o = $(NF - 1)

			if(/window-margin:/) wm = gensub(/.* ([0-9]+)px.*/, "\\1", 1)

			if(/window-width:/) {
				if(o == "vertical") {
					fw = fs *1.39
					tw = hp[2] + hp[1] + fw
					#tw = hp[2] + hp[1] + fw + wm
					#tw = (xo > tw) ? tw + (xo - tw) / 2 : tw + wm
				} else {
					#for three consecutive different font sizes
					fm = fs % 3
					fw = (fm == 2) ? 1.291 + (1 / fs) : (fm == 1) ? 1.31 : 1.33
					#for reducing font width as count grows
					fw *= (fs + (fs / ic) / 10)
					tw = hp[2] + (hp[1] + fw) * ic + ls * (ic - 1)
				}

				sub(/[0-9.]+px/, tw "px")
			}

			if(/window-height:/) {
				if(o == "vertical") {
					#fh = (fs % 2 == 0) ? fs * 1.51 : fs * 1.48
					fh = (fs % 2 == 0) ? fs * 1.55 : fs * 1.55
					th = vp[2] + (vp[1] + fh) * ic + ls * (ic - 1) + eb
				} else {
					#fh = fs * 2.37
					#fh = fs * (3 - (0.11 - (fs / 1000)) * int((fs + 1) / 2))
					#th = vp[2] + vp[1] + fh + eb
					fh = fs * 1.55
					th = vp[2] + vp[1] + fh + eb
					#th = vp[2] + vp[1] + fh + eb + wm
				}

				sub(/[0-9.]+px/, th "px")
			}

			wo = wo "\n" $0
		} END {
			if(o ~ "v") {
				pv = tw
				p = "width"
				if(xo > tw) wm = int((xo - tw) / 2)
			} else {
				pv = th
				p = "height"
				if(yo > th) { wm = int((yo - th) / 2) }
				wm += bo
			}

			print p, pv + wm, wm
			print substr(wo, 2)
		}' ~/.config/rofi/$mode.rasi | { read -r wo; { echo "$wo" >&1; cat > ~/.config/rofi/$mode.rasi; } })
		#}' ~/.config/rofi/$mode.rasi

		#echo $property $property_value $margin
		awk -i inplace '
			function set_value(value) {
				sub("[0-9.]+px", value "px")
			}

			/window-margin:/ { set_value('$margin') }
			/window-'$property':/ { set_value('$property_value') }
			{ print }' ~/.config/rofi/icons.rasi
		exit

	exit
else
	#read x_offset y_offset <<< $(awk '/^[xy]_offset/ { print $NF }' ~/.config/orw/config | xargs)

	while read -r bar_name position bar_x bar_y bar_width bar_height adjustable_width frame; do
		if ((position)); then
			if ((adjustable_width)); then
				read bar_width bar_height bar_x bar_y < ~/.config/orw/bar/geometries/$bar_name
			fi

			#bar_end=$((bar_x + bar_width + frame))
			#current_bar_height=$((bar_y + bar_height + frame + 2))
			bar_y_end=$((bar_y + bar_height + frame))

			echo $bar_name $position

			#((x_offset && bar_x > x_offset)) || x_offset=$bar_x
			#((bar_end > right_x_offset)) && right_x_offset=$bar_end
			((bar_y_end > bar_max_y_end)) && bar_max_y_end=$bar_y_end y_offset=$bar_y
			#(((x_offset && x_offset > bar_x) || !x_offset)) && x_offset=$bar_x

			#if ((x_offset)); then
			#	((bar_x < x_offset)) && x_offset=$bar_x
			#else
			#	x_offset=$bar_x
			#fi

			#if ((current_bar_height > y_offset)); then
			#	y_offset=$current_bar_height
			#	x_offset=$bar_x
			#fi
		fi
	done <<< $(~/.orw/scripts/get_bar_info.sh $display)
	exit

	#rofi_width=$((right_x_offset - x_offset))
	awk -i inplace '\
		/window-width:/ {
			#rw = ('$((right_x_offset - x_offset))') / ('$width' / 100)
			rw = '$((right_x_offset - x_offset))'
			sub(/[0-9]+[^;]*/, rw "px")
		}

		/window-margin:/ {
			#wm = '$y_offset' / ('$height' / 100)
			#sub(/[0-9.]+%/, wm "%")
			by = '${bar_y:-0}'
			bye = '${bar_max_y_end:-0}'
			y = (by) ? bye + by : bye
			sub(/[0-9]+px/, y "px")
		}

		{ print }' ~/.config/rofi/$mode.rasi
fi
