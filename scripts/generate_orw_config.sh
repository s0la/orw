#!/bin/bash

#get_displays() {
#	xrandr | awk -F '[ x+]' '
#				NR == 1 {
#					h = $9
#					v = $12
#					sub("[^0-9]", "", v)
#					si = (h > 2 * v) ? 2 : 3
#				}
#				$2 == "connected" {
#					p = $3 == "primary"
#					i = 3 + p
#					ad[$(i + si)] = $1 " " p " " $i " " $(i + 1) " " $(i + 2) " " $(i + 3)
#				} END { for (d in ad) print ad[d] }'
#}

#get_displays() {
#	xrandr | awk -F '[ x+]' '
#		NR == 1 {
#			h = $9
#			v = $12
#			sub("[^0-9]", "", v)
#			si = (h > 2 * v) ? 2 : 3
#		}
#		$2 == "connected" {
#			ad[$(3 + ($3 == "primary") + si)] = ++d
#		} END {
#			for (d in ad) printf "[%d]=%d ", ++di, ad[d]
#		}'
#}

conf=~/.config/orw/config

wm() {
	part=1
	ratio=2
	x_offset=20
	y_offset=10
	offset=false
	reverse=false

	read x_border y_border <<< $(~/.orw/scripts/print_borders.sh)

	properties=(
		"#wm"
		"margin 10"
		"x_border $x_border"
		"y_border $y_border"
		"x_offset 50"
		"y_offset 50"
		"mode tiling"
		"full false"
		"reverse false"
		"direction auto"
		"interactive true"
	)

	printf '%s\\n' "${properties[@]}"
}

display() {
	get_bar_offset() {
		local current_bars="${current_running//,/ }"

		read default_y_offset primary_display <<< \
			$(awk -F '[_ ]' '/^(y_offset|primary)/ { print $NF }' ~/.config/orw/config | xargs)

		while read bar_config; do
				read display bottom offset <<< $(awk '
					function get_flag(flag) {
						if(match($0, "-" flag "[^-]*")) return substr($0, RSTART + 3, RLENGTH - 3)
					}

					function get_value(flag) {
						gsub("[^0-9]", "", flag)
					}

					/^[^#]/ {
						y = get_flag("y")
						b = (y ~ "b")
						if (y) {
							gsub("[^0-9]", "", y)
						} else y = '$default_y_offset'

						h = get_flag("h")
						if (h) get_value(h)

						f = get_flag("f")
						if (f) {
							m = (f ~ "[ou]") ? 1 : 2
							get_value(f)
							f *= m
						}

						F = get_flag("F")
						if (F) {
							get_value(F)
							F *= 2
						}

						s = get_flag("S")
						if (!s) s = 1

						print s, b, y + h + f + F
					}' $bar_config)

			((!${#offsets[$display]})) &&
				display_offsets=( 0 0 ) ||
				read -a display_offsets <<< ${offsets[$display]}

			if [[ ! $killed || ($killed && ! ${bars[*]} =~ $bar) ]]; then
				((offset > ${display_offsets[bottom]:-0})) && display_offsets[bottom]=$offset
			fi

			offsets[$display]="${display_offsets[*]}"
		done < <(
				awk '
					NR == FNR && /^last_running/ {
						sub(".*=", "")
						ab = $NF
					}
					NR > FNR && $0 ~ "/(" ab ")$" { print }' \
						~/.orw/scripts/barctl.sh <(ls ~/.config/orw/bar/configs/*)
				)
	}

	declare -A offsets
	get_bar_offset

	while read -r display_index name primary width height x y; do
		((index++))
		((last_x += x))
		((last_y += y))
		last_width=$width
		last_height=$height

		displays+="display_${index}_name $name\n"
		displays+="display_${index}_size $width $height\n"
		displays+="display_${index}_xy $x $y\n"
		displays+="display_${index}_offset ${offsets[$index]:-0 0}\n"

		((index == 1)) && first_display_name=$name first_display_index=$index
		((primary)) && primary_display_name=$name primary_display_index=$index
	done <<< $(~/.orw/scripts/display_mapper.sh)
	#done <<< $(get_displays)
	#done <<< $(xrandr | awk -F '[ x+]' '$2 == "connected" {
	#								p = $3 == "primary"
	#								i = 3 + p
	#								print $1, p, $i, $(i + 1), $(i + 2), $(i + 3) }' | sort -n)

	((primary_display_index)) || xrandr --output $first_display_name --primary

	#primary_display="primary display_${primary_display_index:-$first_display_index}"
	primary_display="primary display_$first_display_index"

	x_size=$((last_x + last_width))
	y_size=$((last_y + last_height))
	((x_size > y_size)) && orientation=horizontal || orientation=vertical

	echo "#display\norientation $orientation\n$primary_display\n${displays%\\*}\n"
}

wallpapers() {
	display_count=$(xrandr -q | grep -w connected | wc -l)
	displays=$(eval "echo \\\"{1..$display_count}\\\"")

	for desktop in $(wmctrl -d | awk '{print $1}'); do
		desktops+="desktop_$desktop $displays\n"
	done

	echo "#wallpapers\ndepth 0\ndirectory \n${desktops%\\n}"
}

if [[ -f $conf ]]; then
	for arg in $@; do
		line_number=$(sed -n "/^#$arg/=" $conf)
		sed -i "/^#$arg/,/^$/d" $conf

		((line_number > $(wc -l < $conf))) &&
			echo -e $($arg) >> $conf ||
			sed -i "${line_number}i$($arg)" $conf

		if [[ $arg == display ]]; then
			awk -i inplace -F '"' '
				/^display.*name/ { d++ }
				/^desktop/ {
					if (d > NF / 2) {
						for (f=NF/2; f<d; f++) sub("$", " \"" $(NF - 1) "\"")
					}
				} { print }
			' ~/.config/orw/config
		fi
	done
else
	echo -e "$(wm)\n$(display)\n$(wallpapers)" > $conf
fi

~/.orw/scripts/signal_windows_event.sh update
