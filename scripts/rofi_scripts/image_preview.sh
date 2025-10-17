#!/bin/bash

item_count=8

read icon_size window_width <<< \
	$(awk '
		function get_value() {
			gsub("[^0-9]", "", $NF)
			return $NF
		}

		NR == FNR && $1 ~ "^[xy]_offset" { if (/^x/) xo = get_value(); else yo = get_value() }
		NR == FNR && $1 == "display_" d "_offset" { to = $(NF - 1); bo = $NF }
		NR == FNR && $1 == "display_" d "_size" { h = $NF }
		NR == FNR && $1 == "primary" { d = get_value() }

		NR > FNR {
			if ($1 == "orientation") {
				print xo, yo
				print to, bo
			}
			if (/font/) { f = get_value() }
			if (/element-padding/) { ep = get_value() }
			if (/window-padding/) { wp = get_value() }
			if (/input-padding/) { ip = get_value() }
			if (/window-width/) { exit }
		} END {
			ww = int((h - (2 * (wp + ip) + f)) / '$item_count')
			is = ww - 3 * ep - 5
			print is
		 }' ~/.config/{orw/config,rofi/image_preview.rasi})

read location width y lines columns icon_size keybinds <<< $(awk '
		function get_value() {
			gsub("[^0-9]", "", $NF)
			return $NF
		}

		NR == FNR && $1 ~ "^[xy]_offset" { if (/^x/) xo = get_value(); else yo = get_value() }
		NR == FNR && $1 == "display_" d "_offset" { bto = $(NF - 1); bbo = $NF }
		NR == FNR && $1 == "display_" d "_size" { w = $(NF - 1); h = $NF }
		NR == FNR && $1 == "primary" { d = get_value() }

		NR > FNR {
			if ($1 == "window-orientation:") { o = $NF }
			if (/font/) { f = get_value() }
			if (/element-padding/) { ep = get_value() }
			if (/window-padding/) { wp = get_value() }
			if (/input-padding/) { ip = get_value() }
			if (/window-width/) { exit }
		} END {
			ryo = int((bto - bbo) / 2)

			if (o ~ "horizontal") {
				ln = 1
				l = "center"
				es = sprintf("%.0f", (w / 11))
				is = int(es - 2 * ep)
				c = int((w / 3 * 2) / es)
				ww = 2 * wp + es * c
				#kb = "kb-row-up: \"\"; kb-row-down: \"\"; kb-row-left: \"ctrl+j\"; kb-row-right: \"ctrl+k\";"
				kb = "-kb-row-up \"\" -kb-row-down \"\" -kb-row-left \"ctrl+k\" -kb-row-right \"ctrl+j\""
			} else {
				c = 1
				ww = 130
				l = "west"
				es = sprintf("%.0f", h / 7)
				is = int(es - 3 * ep - 5)
				rh = h - (2 * yo + bo)
				kb = "-kb-row-left \"\" -kb-row-right \"\" -kb-row-up \"ctrl+k\" -kb-row-down \"ctrl+j\""
				#kb = "kb-row-up: \"ctrl+j\"; kb-row-down: \"ctrl+k\"; kb-row-left: \"\"; kb-row-right: \"\";"
				#ln = sprintf("%.0f", (h - (2 * (yo + wp) + bto + bbo)) / 100)
				s = h / 7
				ln = int((h - (2 * (yo + wp) + bto + bbo)) / s)
				ww += ep + wp
			}

			print l, ww, ryo, ln, c, is, kb
			exit

			ww = int((h - (2 * (wp + ip) + f)) / '$item_count')
			is = ww - 3 * ep - 5
			print is
		}' ~/.config/{orw/config,rofi/image_preview.rasi})

theme_str="* { y-offset: ${y}px; window-location: $location; } "
theme_str+="listview { lines: $lines; columns: $columns; } "
theme_str+="window { width: ${width:-530}px; }"
theme_str+="element-icon { size: ${icon_size}px; } "
#theme_str+=' configuration { kb-row-up:        ""; kb-row-down:      ""; kb-row-left:      "Ctrl+k"; kb-row-right:     "Ctrl+j"; } '

#ar=( "-kb-row-left" "ctrl+j" "-kb-row-right" "ctrl+k" )
#ar=( "-kb-row-up" "\"\"" "-kb-row-down" "\"\"" "-kb-row-left" "ctrl+j" "-kb-row-right" "ctrl+k" )
#ar=( "-kb-row-up" "" "-kb-row-down" "" "-kb-row-left" "ctrl+j" "-kb-row-right" "ctrl+k" )
eval keybinds=( "$keybinds" )

#theme_str+="configuration {kb-row-up: \"\"; kb-row-down: \"\"; kb-row-left: \"ctrl+j\"; kb-row-right: \"ctrl+k\";}"

#theme_str="listview { lines: 5; } "
#theme_str+="element-icon { size: ${icon_size}px; } "
#theme_str+="window { width: ${window_width:-130}px; }"
IFS=$'\n' read -d '' command active content
[[ $active == *[0-9]* ]] && active="-a $active"

#keybinds="-kb-row-left '' -kb-row-right '' -kb-row-up 'ctrl+j' -kb-row-down 'ctrl+k'"
#keybinds="-kb-row-up '' -kb-row-down '' -kb-row-left 'ctrl+j' -kb-row-right 'ctrl+k'"
#keybinds="-kb-row-up \"\" -kb-row-down \"\" -kb-row-left \"ctrl+j\" -kb-row-right \"ctrl+k\""
#keybinds="-kb-row-up '' -kb-row-down '' -kb-row-left ctrl+j -kb-row-right ctrl+k"

#KB_BINDINGS=(-kb-row-up "" -kb-row-down "" -kb-row-left "ctrl+j" -kb-row-right "ctrl+k")

toggle force
trap "toggle force" EXIT

while
	#while read -r element; do
	#			echo -en "${element##*/}\0icon\x1f$element\n"
	#	done <<< $(echo -e "$content") | rofi -dmenu -show-icons -format 'i s' "${keybinds[@]}" \
	#			$active -selected-row ${index:-0} -theme-str "$theme_str" -theme image_preview 2> /dev/null

	#exit

	read index element <<< $(while read -r element; do
				echo -en "${element##*/}\0icon\x1f$element\n"
		done <<< $(echo -e "$content") |
			rofi -dmenu -show-icons -format 'i s' "${keybinds[@]}" \
				$active -selected-row ${index:-0} -theme-str "$theme_str" -theme image_preview 2> /dev/null
		)

	[[ $element ]]
do
	[[ $command ]] &&
		eval "$command" &&
		active="-a $index" ||
		exit
done
exit

ISF=$'\n' read -d '' active wallpapers <<< $(~/.orw/scripts/rofi_scripts/select_wallpaper.sh)
[[ $active ]] && active="-a $active"

while
	read index wallpaper <<< $(while read -r wall; do
			echo -en "$wall\0icon\x1f$wall\n"
		done <<< $(echo -e "$wallpapers") |
			rofi -dmenu -show-icons -format 'i s' \
			$active -selected-row ${index:-0} -theme-str "$theme_str" -theme img)
	[[ $wallpaper ]]
do
	eval ~/.orw/scripts/wallctl.sh -s "'$wallpaper'"
	active="-a $index"
done
