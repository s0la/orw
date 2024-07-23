#!/bin/bash

adjust_colors() {
	local preview=/tmp/color_preview.png
	local current_color_fifo=/tmp/current_color.fifo
	local final_color_fifo=/tmp/final_color.fifo

	while true; do
		show_colors=''

		for color in ${!all_colors[*]}; do
			show_colors+="$color) $(print_color ${all_colors[color]} label)\n"
		done

		show_colors+="d) done"
		echo -e "$show_colors"

		read -rsn 1 -p $'\nSelect color to adjust:\n' choice

		if [[ $choice == d ]]; then
			break
		else
			[[ -e $current_color_fifo ]] || mkfifo $current_color_fifo
			[[ -e $final_color_fifo ]] || mkfifo $final_color_fifo

			while [[ -e $current_color_fifo ]]; do
				read color < $current_color_fifo
				convert -size 100x100 xc:$color $preview

				kill $! &> /dev/null

				feh -g 100x100 --title 'image_preview' $preview &
				preview_pid=$!
			done &

			while_pid=$!

			~/.orw/scripts/convert_colors.sh -hbPf $current_color_fifo,$final_color_fifo "${all_colors[choice]##*_}"
			read new_rgb new_hex < $final_color_fifo

			all_colors[choice]="0_0_${new_rgb}_${new_hex}"
			((choice == 1)) && all_colors[2]="0_0_$(get_sbg "$new_hex" +4 | tr ' ' '_')"

			last_preview_pid=$(ps aux | awk '$NF == "'$preview'" { print $2 }')
			kill $while_pid $last_preview_pid
		fi
	done
}

print_color() {
	local br hsv rgb hex
	read hsv rgb hex <<< "${1//_/ }"

	[[ $2 ]] && local label="$hsv  $rgb  $hex"

	printf "\033[48;2;${rgb}38;2;2m    \033[0m\033[38;2;${rgb}2m  $label  \033[0m\n"
}

get_sbg() {
	local type sign=${2//[0-9]} saturation=$3 value=${2#[+-]}

	if [[ $sign ]]; then
		[[ $sign == - ]] && opposite_sign=+ || opposite_sign=-
	fi

	[[ $1 =~ ^# ]] && type=h || type=r
	[[ $sign && ! $saturation ]] && saturation=$((value / 2))

	~/.orw/scripts/convert_colors.sh -${type}bV $sign$value -S $opposite_sign${saturation:-+0} "$1"
}

yet_another_sort() {
	local wallpaper="$1"
	convert "$wallpaper" -scale 50x50! \
		-depth 8 +dither -colors 25 -format "%c" histogram:info: |
		sort -nrk 1,1 | awk --non-decimal-data -F '#' '
			function get_rgb_value(position) {
				decimal = sprintf("%f", "0x" substr($NF, position, 2))
				return sprintf("%f", int(decimal) / 255)
			}

			BEGIN { minh = 360 }

			{
				sub("\\s.*", "", $NF)

				r = get_rgb_value(0)
				g = get_rgb_value(3)
				b = get_rgb_value(5)

				split(r " " g " " b, rgb, " ")
				asort(rgb)
				min = rgb[1]
				max = rgb[3]

				v = max

				if(min == max) h = s = 0
				else {
					d = max - min
					s = d / max

					if(max == r) h = ((max - b) / d) - ((max - g) / d)
					else if(max == g) h = 2 + ((max - r) / d) - ((max - b) / d)
					else if(max == b) h = 4 + ((max - g) / d) - ((max - r) / d)

					h = ((h / 6 + 1) * 360) % 360
					if(!h) h = 360
				}

				r *= 255; g *= 255; b *= 255
				hex = sprintf("%.2x%.2x%.2x", r , g, b)

				cc = sprintf("%.0f;%.0f;%.0f;_%.0f;%.0f;%.0f;_#%s", \
					h, s * 100, v * 100, r, g, b, hex)

				if(NR == 1) dbg = cc
				#else ac = ac " " cc
				else {
					ac = ac " [" cc "]=" NR

					if(h > maxh) maxh = h
					if(h < minh) minh = h

					if(!h) {
						cc = sprintf("%.0f;%.0f;%.0f;_%.0f;%.0f;%.0f;_#%s", \
							360, s * 100, v * 100, r, g, b, hex)
						#ac = ac " [" cc "]=" NR
					}
				}

				as += s * 100
				av += v * 100
				asv += (s + v) * 100
			} END {
				as /= NR
				av /= NR
				asv /= NR
				ahs = sprintf("%.0f", (maxh - minh) / NR)

				print dbg, ahs, int(as), int(av), ac
			}'
}

wallpaper="$1"

[[ ! -f $wallpaper ]] &&
	echo "$wallpaper not found, exiting.." && exit

wallpaper_name="${wallpaper##*/}"
read dbg average_hue_step saturation value colors <<< $(yet_another_sort "$wallpaper")
declare -A colors
eval colors=( $colors )

#((average_hue_step < 5)) && mono=true

mono_treshold=0
echo $average_hue_step

get_mono_accent() {
	tr ' ' '\n' <<< ${!colors[*]} | sort -n |
		awk -F '[;_]' '
			function add_hue() {
				{
					if ($1 - ph < 25) {
						ahd += $1 - ph
						hc++
					}

					#print $1, ph, $0
					ph = $1

					if ($3 > $2 * 1.3) {
						asv[$2 + $3] = $0
						svs[++i] = $2 + $3
						#print
					}
				}
			}

			{ add_hue() }

			END {
				i = asort(svs)
				ah = ahd / hc
				print ah, ah < '$mono_treshold', asv[svs[i - 2]]
				exit

				for (si in svs) print si, svs[si]
				print "HERE"
				for (c in asv) {
					print c, asv[c]
				}
				exit
				tt = length(asv) - 5
				for (c in asv) {
					#print c, asv[c]
					if (++i > tt) print asv[c]
				}

				#for (i=5; i; i--) print length(asv) - i, asv[length(asv) - i]
			}'
}

#get_mono_accent
#exit

read average_hue mono{,_accent} <<< $(get_mono_accent)
#echo $mono, $average_hue
#exit

#for c in ${!colors[*]}; do
#	#echo $c: ${colors[$c]}
#	print_color $c label
#done
#exit
#
#for c in ${!sorted_colors[*]}; do
#	echo $c: ${sorted_colors[$c]}
#done
#exit

#while read c; do
#	echo $c
#	print_color $c label
#done <<< $(get_top_colors)
#exit

#bg_s=$(cut -d ';' -f 2 <<< $dbg)
#read {rgb,hex}_bg <<< $(get_sbg ${dbg##*_} 8 $((bg_s / 2)))
#read {rgb,hex}_sbg <<< $(get_sbg $hex_bg +5)
#read {rgb,hex}_sfg <<< $(get_sbg $hex_sbg +10)
#read {rgb,hex}_pbg <<< $(get_sbg $hex_sbg +5)
#read {rgb,hex}_pfg <<< $(get_sbg $hex_pbg +10)

if ((mono)); then
	#read {rgb,hex}_dbg <<< $(get_sbg "#2d2d2d")
	#read {rgb,hex}_bfg <<< $(get_sbg "#cecece")
	bg_v=8
	fg_v=75
	sign=+
	#main_bg='#2d2d2d'
	#org_fg='#cecece'
	main_bg="$(get_sbg "#2d2d2d")"
	main_bg="$(get_sbg "#111111")"
	echo $dbg
	mono_dbg=$(awk -F ';' '{ v = 8 + $3; printf "#%.2x%.2x%.2x", v, v, v  }' <<< $dbg)
	main_bg=$(get_sbg $mono_dbg)
	org_fg="0;0;81;_206;206;206;_#cecece"
	read {rgb,hex}_fg <<< $(get_sbg "#aaaaaa")
	hex_vim_fg=$hex_fg
else
	sorted_colors=( $(tr ' ' '\n' <<< ${!colors[*]} | sort -n) )
	#for c in ${sorted_colors[*]}; do
	#	#echo ${colors[$c]}, $c
	#	print_color $c label
	#done
	#exit

	read org_fg fgi <<< $(\
		tr ' ' '\n' <<< ${sorted_colors[*]} | awk -F '[;_]' '
			BEGIN { minv = mins = 100 }
			{
				if($3 > 45 && $2 < mins) {
					mins = $2
					fgi = NR - 1
					fg = $0
				}
			} END { print fg, fgi }')

	read fg_{saturation,value} <<< $(cut -d ';' -f 2,3 <<< $org_fg | tr ';' ' ')

	if ((value > 50 && fg_value > 80)); then
		fg_value=${colors[$org_fg]}
		unset sorted_colors[fgi]
		unset colors[$org_fg]
	else
		new_accent=$(get_sbg ${org_fg##*_} -10)
		fg_hsv="${org_fg%%;*};$((fg_saturation + 5));$((fg_value - 10))"
		new_fg="${fg_hsv};_${new_accent/ /_}"

		((80 - fg_value < 10)) &&
			colors[$new_fg]=${colors[$org_fg]} sorted_colors[$fgi]=$new_fg
	fi

	((value > 90)) &&
		main_bg=$org_fg main_fg=$dbg bg_v=70 fg_v=40 sign=- ||
		main_bg=$dbg main_fg=$org_fg bg_v=8 fg_v=75 sign=+

	echo $value, $main_bg, $main_fg, $sign

	read {rgb,hex}_fg <<< $(get_sbg "${org_fg##*_}" $fg_v 10)
	#read {rgb,hex}_vim_fg <<< $(get_sbg "$hex_fg" 85 12)
	read {rgb,hex}_vim_fg <<< $(get_sbg "$hex_fg" +5)
fi

bg_s=$(cut -d ';' -f 2 <<< $main_bg)
read {rgb,hex}_bg <<< $(get_sbg ${main_bg##*_} $bg_v $((bg_s / 1)))
read {rgb,hex}_sbg <<< $(get_sbg $hex_bg ${sign}5)
read {rgb,hex}_sfg <<< $(get_sbg $hex_sbg ${sign}10)
read {rgb,hex}_pbg <<< $(get_sbg $hex_sbg ${sign}5)
read {rgb,hex}_pfg <<< $(get_sbg $hex_pbg ${sign}10)

#for color in rgb_{fg,{,s,p}bg}; do
#	printf '%-8s' $color
#	print_color "0_${!color}_0" label
#done
#exit

if ((mono)); then
	#read {rgb,hex}_a{1..6} <<< \
	#	$(tr ' ' '\n' <<< "${accent_colors[*]}" |
	#		awk -F '_' '{ rgb = rgb " " $(NF - 1); hex = hex " " $NF }
	#					END { print rgb, hex }')

	set_mono_accents() {
		local type=$1 ai=2 sign s=25

		#for color in ${type}_{fg,{,s,p}bg}; do
		#for color in ${type}_{pfg,pbg,sfg,sbg}; do
		#for color in ${type}_{pfg,fg,pbg,bg}; do
		#for color in ${type}_{pfg,fg,sfg,sfg}; do
		#for color in ${type}_{sfg,fg,pfg,bg}; do
		for color in ${type}_{bg,fg,pfg,sbg}; do
			#eval "${type}_a$ai='${!color}'"
			#echo "${type}_a$ai='${!color}'"
			[[ $color == *_fg ]] && sign=- || sign=+
			#[[ $color == *fg ]] && s=0 || s=15
			echo $color, $sign, ${!color}
			read {rgb,hex}_a$ai <<< $(get_sbg "${!color}" "+$s")
			((ai++))
			((s -= ai - 3))
		done
	}

	set_mono_accents hex
	#echo $hex_a1, $rgb_a1, $hex_a2, $rgb_a2, $hex_a3, $rgb_a3
	#exit

	#for type in hex rgb; do
	#	set_mono_accents $type
	#done

	#a1=$(get_top_colors)
	#IFS='_' read {hue,rgb,hex}_a1 <<< $(get_top_colors)
	read {rgb,hex}_a1 <<< $(get_sbg ${mono_accent##*_} +10)
	#read {rgb,hex}_a5 <<< $(get_sbg ${mono_accent##*_} -10)
	echo $hex_a1, $rgb_a1, $hex_a2, $rgb_a2, $hex_a3, $rgb_a3
else
	get_step() {
		tr ' ' '\n' <<< ${sorted_colors[*]}
	}

	yet_another_get_step() {
		#tr ' ' '\n' <<< "${sorted_colors[*]}" |
		tr ' ' '\n' <<< "$1" |
			#sort -nk 1,1 | awk -F ';' '
			awk -F ';' '
			function abs(n1, n2) {
				return sqrt((n1 - n2) ^ 2)
			}

			function add_distance() {
				if(dc) {
					ed = (dc > 5) ? (!min_d) ? 0 : 1 : 1

					if(dc == 2 && td > 5) aad[++di] = 0
					else {
						ad = td / (dc + 1)
						ed = (dc <= 5) ? 0 : (ad < 1) ? 0 : 1
						if(max_d && !min_d && ad > 1) min_d++

						aad[++di] = sprintf("%.0f", (sqrt((ad - min_d) ^ 2) < max_d - ad) ? min_d + ad + 1 : max_d + 1) + 1
						if(aad[di] > 2) sc++
					}
				} else aad[++di] = 0
				min_d = 360; dc = 1; max_d = td = dai = cd = 0
			}

			function rgb_to_xyz(r, g, b) {
				R = r / 255
				G = g / 255
				B = b / 255

				R = (R > 0.04045) ? ((R + 0.055) / 1.055) ^ 2.4 : R / 12.92
				G = (G > 0.04045) ? ((G + 0.055) / 1.055) ^ 2.4 : G / 12.92
				B = (B > 0.04045) ? ((B + 0.055) / 1.055) ^ 2.4 : B / 12.92

				R *= 100
				G *= 100
				B *= 100

				X = R * 0.4124 + G * 0.3576 + B * 0.1805
				Y = R * 0.2126 + G * 0.7152 + B * 0.0722
				Z = R * 0.0193 + G * 0.1192 + B * 0.9505
			}

			function xyz_to_lab(x, y, z) {
				refx =  95.047
				refy = 100.000
				refz = 108.883

				X = x / refx
				Y = y / refy
				Z = z / refz

				X = (X > 0.008856) ? X ^ (1 / 3) : (7.787 * X) + (16 / 116)
				Y = (Y > 0.008856) ? Y ^ (1 / 3) : (7.787 * Y) + (16 / 116)
				Z = (Z > 0.008856) ? Z ^ (1 / 3) : (7.787 * Z) + (16 / 116)

				L = 116 * Y - 16
				a = 500 * (X - Y)
				b = 200 * (Y - Z)
			}

			function set_previous(color) {
				pc = color
				split(pc, prc, "[;_]")
				prsv = prc[1]; prh = prc[2]; prs = prc[3]; prv = prc[4]
				pr = prc[6]; pg = prc[7]; pb = prc[8]

				prsv = prc[1]; prh = prc[1]; prs = prc[2]; prv = prc[3]
				pr = prc[5]; pg = prc[6]; pb = prc[7]
			}

			function is_different(sai) {
				#print h, prh, fa
				#print h "     " fa
				if(aac) {
					clmsv = msv ? msv : pmsv
					split(msvc, ccp)
					r = substr(ccp[4], 2); g = ccp[5]; b = ccp[6]

					rgb_to_xyz(r, g, b)
					xyz_to_lab(X, Y, Z)
					l1 = L; a1 = a; b1 = b

					as = 65
					pai = sai

					do {
						#if(h > 190) print h, prh
						#if(h > 200) {
						#	print h, pai
						#	for(r in rm) print rm[r]
						#}

						#if(h == 106) print h, prh, fa, pai

						if(!(pai in rm)) {
							set_previous(aaa[pai])
							nde = (c0 || abs(h, prh) <= as || (h > 320 && abs(0, prh) <= as))
							#print h, prh, nde

							#if(h > 200) {
							#	print h, prh, pai, (pai in rm), rm[2]
							#	for(a in aaa) print aaa[a]
							#	print ""
							#}

							if(nde) {
								rgb_to_xyz(pr, pg, pb)
								xyz_to_lab(X, Y, Z)
								l2 = L; a2 = a; b2 = b

								l = (l2 - l1) ^ 2
								a = (a2 - a1) ^ 2
								b = (b2 - b1) ^ 2

								#pt = (v < 30 && prv < 30) ? 5 : \
								#	(v > 65 && prv > 65) ? 13 : 13

								##pt = (v <= 30 && prv <= 30) ? 6 : '${2:-13}'
								#if(pt > 6) {
								#	if(ci > 15 && aac <= 6) pt -= 2
								#	else if(v > 65 && prv > 65) pt *= 0.7
								#}

								pt = '${2:-13}'
								if(v <= 30 && prv <= 30) pt = int(pt / 2)
								else {
									if(ci > 15 && aac <= 6) pt -= 2
									else if(v > 65 && prv > 65) pt *= 0.7
								}

								lab_d = int(sprintf("%.0f", sqrt(l + a + b)))
								nde = sqrt(l + a + b) < pt
								nde = lab_d < pt
								#print h, prh, lab_d, pt, nde

								#if(h == 150) print h, prh, nde, int(lab_d) < int(pt)

								#if(h == 106) print h, prh, nde, pai

								#print h, prh, nde, lab_d
								#if(nde) print h, prh, v, prv, s, prs
								#if(nde) print ((h > prh && v > prv && 2 * s > prs) ||
								#	(prh > h && prv > v && 2 * prs > s))

								#if(nde) print (v < prv && s < 2 * prs)

								#if(nde &&
								#	((h > prh && v > prv && 2 * s > prs) ||
								#	(prh > h && prv > v && 2 * prs > s))) {
								##if(nde && prv < v) print "HERE", h, prh
								##if(nde && prv < v && 2 * s > prs) {
								if(nde) {
									kp = (v < prv && s < 2 * prs)
									if(!kp) {
										#print "HERE"
										sub(pc, "", fa)
										delete aaa[pai]

										#print h, prh, pai

										#rm[++rmi] = pai
										rm[pai] = 1
										tv -= prv
										ts -= prs
										tsv -= clmsv
										nde = 0

										if(h < 320) break
									}
								}
							}
						}

						pai--
					} while(pai && (h > 320 || (h < 320 && abs(h, prh) <= as)) && !nde)
				}

				#if(h == 106) print "end", h, prh, fa
				return !nde
			}

			function add_color() {
				de = is_different(aac)

				if(de || c0) {
					fa = fa " " msvc
					aaa[++aac] = msvc
					aai[aac] = cai
					lmsv = msv
					tsv += msv
					tv += v
					ts += s
					lh = h; ls = s; lv = v
				}

				h = cp[1]; s = cp[2]; v = cp[3]
				msv = s + v
				pmsv = msv
				#msvc = msv "_" ac[ci]
				msvc = ac[ci]
			}

			{
				c = sqrt(($2 - $3) ^ 2)

				b = $2 > 5 && !(c > 30 && $3 > $2 && $2 > 65) &&
					!($2 < 20 && $3 < 20) &&
					$3 > 10 && $3 <= 95 && c <= 70 &&
					1
					#abs(substr($4, 2), $6) > 5

				v = $3 <= '$value' + 15 && $3 >= '$value' - 25
				v = 1

				if(b && $2 + $3 > max_v) {
					max_v = $2 + $3
					mva = max_v "_" $0
				}

				if(!(b && v)) next

				if(length(lh)) {
					d = $1 - lh

					if($1 - lh < 15) {
						if(d < min_d) min_d = d
						if(d > max_d) max_d = d
						if(d <= 3) cd++
						td += d
						dc++

						if(cd && dc / cd > 1) {
							if(!dai) {
								dai = ci + 1
								cda[di + 1] = dai
							}
						}
					} else if(length(lh)) {
						add_distance()
					}

					as += d
					asc++
				}

				lh = $1
				ac[++ci] = $0
			} END {
				add_distance()
				di = 1

				as = 50
				#aac = split("'"$2"'", aaa, " ")

				for(ci in ac) {
					split(ac[ci], cp, ";")
					ch = cp[1]
					if(ch == 360) c0 = 1

					if(ci == 1 || ch - ph < 15) {
						ce = (NR < 20) ? 0 : ch - ph < aad[di]
						if(ci == 1 || ((sc < 3 && ce) || (sc >= 3 && ce))) {
							if(ci == 1 || (cp[2] + cp[3] > msv) ||
								(cp[2] + cp[3] == msv && cp[3] > v)) {
								#msvc = cp[2] + cp[3] "_" ac[ci]
								msvc = ac[ci]
								h = ch; s = cp[2]; v = cp[3]
								msv = s + v
								cai = ci
							}
						} else {
							add_color()
						}
					} else {
						add_color()
						di++
					}

					ph = ch
				}

				gsub(" +", " ", fa)

				add_color()
				#for(ai in aaa) print "^" ai, aaa[ai] "^"
				aac = length(aaa)
				print aac, int(tsv / aac), int(tv / aac), int(ts / aac), fa
			}'
	}

	yet_another_get_step2() {
		#tr ' ' '\n' <<< "${sorted_colors[*]}" |
		tr ' ' '\n' <<< "$1" |
			#sort -nk 1,1 | awk -F ';' '
			awk -F ';' '
			function abs(n1, n2) {
				return sqrt((n1 - n2) ^ 2)
			}

			function add_distance() {
				if(dc) {
					ed = (dc > 5) ? (!min_d) ? 0 : 1 : 1

					if(dc == 2 && td > 5) aad[++di] = 0
					else {
						ad = td / (dc + 1)
						ed = (dc <= 5) ? 0 : (ad < 1) ? 0 : 1
						if(max_d && !min_d && ad > 1) min_d++

						aad[++di] = sprintf("%.0f", (sqrt((ad - min_d) ^ 2) < max_d - ad) ? min_d + ad + 1 : max_d + 1) + 1
						if(aad[di] > 2) sc++
					}
				} else aad[++di] = 0
				min_d = 360; dc = 1; max_d = td = dai = cd = 0
			}

			function rgb_to_xyz(r, g, b) {
				R = r / 255
				G = g / 255
				B = b / 255

				R = (R > 0.04045) ? ((R + 0.055) / 1.055) ^ 2.4 : R / 12.92
				G = (G > 0.04045) ? ((G + 0.055) / 1.055) ^ 2.4 : G / 12.92
				B = (B > 0.04045) ? ((B + 0.055) / 1.055) ^ 2.4 : B / 12.92

				R *= 100
				G *= 100
				B *= 100

				X = R * 0.4124 + G * 0.3576 + B * 0.1805
				Y = R * 0.2126 + G * 0.7152 + B * 0.0722
				Z = R * 0.0193 + G * 0.1192 + B * 0.9505
			}

			function xyz_to_lab(x, y, z) {
				refx =  95.047
				refy = 100.000
				refz = 108.883

				X = x / refx
				Y = y / refy
				Z = z / refz

				X = (X > 0.008856) ? X ^ (1 / 3) : (7.787 * X) + (16 / 116)
				Y = (Y > 0.008856) ? Y ^ (1 / 3) : (7.787 * Y) + (16 / 116)
				Z = (Z > 0.008856) ? Z ^ (1 / 3) : (7.787 * Z) + (16 / 116)

				L = 116 * Y - 16
				a = 500 * (X - Y)
				b = 200 * (Y - Z)
			}

			function set_previous(color) {
				pc = color
				split(pc, prc, "[;_]")
				prsv = prc[1]; prh = prc[2]; prs = prc[3]; prv = prc[4]
				pr = prc[6]; pg = prc[7]; pb = prc[8]

				prsv = prc[1]; prh = prc[1]; prs = prc[2]; prv = prc[3]
				pr = prc[5]; pg = prc[6]; pb = prc[7]
			}

			function is_different(sai) {
				#print h, prh, fa
				#print h "     " fa
				if(aac) {
					clmsv = msv ? msv : pmsv
					split(msvc, ccp)
					r = substr(ccp[4], 2); g = ccp[5]; b = ccp[6]

					rgb_to_xyz(r, g, b)
					xyz_to_lab(X, Y, Z)
					l1 = L; a1 = a; b1 = b

					as = 65
					pai = sai

					do {
						#if(h > 190) print h, prh
						#if(h > 200) {
						#	print h, pai
						#	for(r in rm) print rm[r]
						#}

						#if(h == 106) print h, prh, fa, pai

						if(!(pai in rm)) {
							set_previous(aaa[pai])
							nde = (c0 || abs(h, prh) <= as || (h > 320 && abs(0, prh) <= as))
							#print h, prh, nde

							#if(h > 200) {
							#	print h, prh, pai, (pai in rm), rm[2]
							#	for(a in aaa) print aaa[a]
							#	print ""
							#}

							if(nde) {
								rgb_to_xyz(pr, pg, pb)
								xyz_to_lab(X, Y, Z)
								l2 = L; a2 = a; b2 = b

								l = (l2 - l1) ^ 2
								a = (a2 - a1) ^ 2
								b = (b2 - b1) ^ 2

								#pt = (v < 30 && prv < 30) ? 5 : \
								#	(v > 65 && prv > 65) ? 13 : 13

								##pt = (v <= 30 && prv <= 30) ? 6 : '${2:-13}'
								#if(pt > 6) {
								#	if(ci > 15 && aac <= 6) pt -= 2
								#	else if(v > 65 && prv > 65) pt *= 0.7
								#}

								pt = '${2:-13}'
								if(v <= 30 && prv <= 30) pt = int(pt / 2)
								else {
									if(ci > 15 && aac <= 6) pt -= 2
									else if(v > 65 && prv > 65) pt *= 0.7
								}

								lab_d = int(sprintf("%.0f", sqrt(l + a + b)))
								nde = sqrt(l + a + b) < pt
								nde = lab_d < pt
								#print h, prh, lab_d, pt, nde

								#if(h == 150) print h, prh, nde, int(lab_d) < int(pt)

								#if(h == 106) print h, prh, nde, pai

								#print h, prh, nde, lab_d
								#if(nde) print h, prh, v, prv, s, prs
								#if(nde) print ((h > prh && v > prv && 2 * s > prs) ||
								#	(prh > h && prv > v && 2 * prs > s))

								#if(nde) print (v < prv && s < 2 * prs)

								#if(nde &&
								#	((h > prh && v > prv && 2 * s > prs) ||
								#	(prh > h && prv > v && 2 * prs > s))) {
								##if(nde && prv < v) print "HERE", h, prh
								##if(nde && prv < v && 2 * s > prs) {
								if(nde) {
									kp = (v < prv && s < 2 * prs)
									if(!kp) {
										#print "HERE"
										sub(pc, "", fa)
										delete aaa[pai]

										#print h, prh, pai

										#rm[++rmi] = pai
										rm[pai] = 1
										tv -= prv
										ts -= prs
										tsv -= clmsv
										nde = 0

										if(h < 320) break
									}
								}
							}
						}

						pai--
					} while(pai && (h > 320 || (h < 320 && abs(h, prh) <= as)) && !nde)
				}

				#if(h == 106) print "end", h, prh, fa
				return !nde
			}

			function add_color() {
				de = is_different(aac)

				if(de || c0) {
					fa = fa " " msvc
					aaa[++aac] = msvc
					aai[aac] = cai
					lmsv = msv
					tsv += msv
					tv += v
					ts += s

					#print aac, lh, h, msvc
					if (aac > 1 && h - lh < 50) thd += h - lh
					lh = h; ls = s; lv = v
				}

				h = cp[1]; s = cp[2]; v = cp[3]
				msv = s + v
				pmsv = msv
				#msvc = msv "_" ac[ci]
				msvc = ac[ci]
			}

			{
				c = sqrt(($2 - $3) ^ 2)

				b = $2 >= 5 && !(c > 30 && $3 > $2 && $2 > 65) &&
					!($2 < 20 && $3 < 20) &&
					$3 > 10 && $3 <= 95 && c <= 70 &&
					1
					#abs(substr($4, 2), $6) > 5

				v = $3 <= '$value' + 15 && $3 >= '$value' - 25
				v = 1

				if(b && $2 + $3 > max_v) {
					max_v = $2 + $3
					mva = max_v "_" $0
				}

				if(!(b && v)) next

				if(length(lh)) {
					d = $1 - lh

					if($1 - lh < 15) {
						if(d < min_d) min_d = d
						if(d > max_d) max_d = d
						if(d <= 3) cd++
						td += d
						dc++

						if(cd && dc / cd > 1) {
							if(!dai) {
								dai = ci + 1
								cda[di + 1] = dai
							}
						}
					} else if(length(lh)) {
						add_distance()
					}

					as += d
					asc++
				}

				lh = $1
				ac[++ci] = $0
			} END {
				add_distance()
				di = 1

				as = 50
				#aac = split("'"$2"'", aaa, " ")

				for(ci in ac) {
					split(ac[ci], cp, ";")
					ch = cp[1]
					if(ch == 360) c0 = 1

					if(ci == 1 || ch - ph < 15) {
						ce = (NR < 20) ? 0 : ch - ph < aad[di]
						if(ci == 1 || ((sc < 3 && ce) || (sc >= 3 && ce))) {
							if(ci == 1 || (cp[2] + cp[3] > msv) ||
								(cp[2] + cp[3] == msv && cp[3] > v)) {
								#msvc = cp[2] + cp[3] "_" ac[ci]
								msvc = ac[ci]
								h = ch; s = cp[2]; v = cp[3]
								msv = s + v
								cai = ci
							}
						} else {
							add_color()
						}
					} else {
						add_color()
						di++
					}

					ph = ch
				}

				gsub(" +", " ", fa)

				add_color()
				#for(ai in aaa) print "^" ai, aaa[ai] "^"
				aac = length(aaa)
				print aac, int(tsv / aac), int(tv / aac), int(ts / aac), fa
			}'
	}

	treshold=13
	#yet_another_get_step2 "${accents[*]:-${sorted_colors[*]}}" $treshold
	#exit

	#for c in ${sorted_colors[*]}; do
	#	#echo ${colors[$c]}, $c
	#	print_color $c label
	#done
	#
	#echo ACCENTS
	#read _{,,,} acs <<< $(yet_another_get_step2 "${accents[*]:-${sorted_colors[*]}}" $treshold)
	#while read c; do
	#	print_color $c label
	#done <<< $(tr ' ' '\n' <<< "$acs")
	#exit

	#yet_another_get_step "${accents[*]:-${sorted_colors[*]}}" $treshold
	#exit

	#accents=( '360;5;56;_144;137;137;_#908989' '341;58;29;_73;31;44;_#491f2b' '319;28;31;_78;56;71;_#4d3846' '264;14;41;_95;89;104;_#5e5967' '253;25;28;_58;54;72;_#3a3648' '203;27;62;_115;141;157;_#728c9c' '184;18;88;_184;221;224;_#b8dddf' '20;49;83;_211;141;107;_#d38c6b' '2;24;83;_211;162;160;_#d3a1a0' )
	##accents=( '2;24;83;_211;162;160;_#d3a1a0' '20;49;83;_211;141;107;_#d38c6b' '184;18;88;_184;221;224;_#b8dddf' '203;27;62;_115;141;157;_#728c9c' '253;25;28;_58;54;72;_#3a3648' '264;14;41;_95;89;104;_#5e5967' '319;28;31;_78;56;71;_#4d3846' '341;58;29;_73;31;44;_#491f2b' '360;5;56;_144;137;137;_#908989' )
	#
	#yet_another_get_step "${accents[*]:-${sorted_colors[*]}}" 19
	#exit

	while
		#treshold=25
		#accents=('319;39;16;_41;25;36;_#281823' '212;43;14;_20;27;35;_#131a23' '190;49;38;_50;90;98;_#315962' '150;16;84;_180;214;197;_#b3d6c4' '142;34;76;_127;193;151;_#7ec197' '71;19;57;_141;146;118;_#8c9175' '60;9;32;_81;81;74;_#505049')
		#yet_another_get_step "${accents[*]:-${sorted_colors[*]}}" $treshold
		#exit

		#yet_another_get_step "${accents[*]:-${sorted_colors[*]}}" $treshold
		#(( treshold += 3 ))
		#(( si++ ))
		#((si == 2)) && exit
		##accents=( '141;36;35;_58;90;69;_#3a5944' '107;45;29;_48;74;41;_#2f4928' '99;71;20;_28;52;15;_#1c340f' '62;24;56;_142;143;109;_#8e8e6d' '56;16;67;_171;169;144;_#aaa890' '46;28;40;_102;95;73;_#665e49' '34;86;77;_196;122;28;_#c3791c' )
		##accents=( '34;86;77;_196;122;28;_#c3791c' '46;28;40;_102;95;73;_#665e49' '56;16;67;_171;169;144;_#aaa890' '62;24;56;_142;143;109;_#8e8e6d' '99;71;20;_28;52;15;_#1c340f' '107;45;29;_48;74;41;_#2f4928' '141;36;35;_58;90;69;_#3a5944' )
		#accents=( '11;75;52;_133;51;33;_#853321' '197;19;28;_58;68;72;_#3a4448' '231;14;40;_88;90;102;_#575966' '240;7;71;_166;166;179;_#a6a6b3' '265;13;51;_121;114;131;_#797282' '339;25;64;_163;123;137;_#a37b89' '357;27;29;_74;54;55;_#493636' )
		#continue

		read accent_count avg_sv avg_value avg_saturation sorted_accents <<< \
			$(yet_another_get_step2 "${accents[*]:-${sorted_colors[*]}}" $treshold)

		#echo $sorted_accents

		if [[ ! $sign ]]; then
			((accent_count > 6)) && sign=+ || sign=-
		fi

		if ((!accent_limit)); then
			#((accent_count < 9)) &&
			#	accent_limit=7 || accent_limit=8
			((accent_count > 10)) &&
				accent_limit=8 || accent_limit=7
		fi

		#accent_limit=9

		#read accent_count avg_sv avg_value avg_saturation sorted_accents <<< \
		#	$(yet_another_get_step "${accents[*]:-${sorted_colors[*]}}" $treshold |
		#	tr ' ' '\n' | awk -F '[;_]' '{ b = sqrt(($5 - $7) ^ 2); if(b <= 5) next; print }')

			#$(yet_another_get_step "${sorted_colors[*]}" "${accents[*]}" $treshold)
		#accents=( $(tr ' ' '\n' <<< $sorted_accents | sort -nr) )

		#[[ $sign == - ]] &&
		#	accents=( ${sorted_colors[*]} ) ||
		#	accents=( $(tr ' ' '\n' <<< $sorted_accents | sort -nr) )

		[[ $reverse ]] && unset reverse || reverse=r

		accents=( $(tr ' ' '\n' <<< $sorted_accents | sort -n$reverse) )
		#accents=( $(tr ' ' '\n' <<< $sorted_accents | grep -v ^264 | sort -nr) )
		echo accents ${accents[*]}

		#while read a; do
		#	print_color $a label
		#done <<< $(tr ' ' '\n' <<< $sorted_accents)
		for c in ${accents[*]}; do
			print_color $c label
		done

		echo $accent_count, $avg_sv, $avg_value, $avg_saturation, $treshold
		#((treshold > 20)) && exit

		((accent_count > accent_limit))
		#[[ ($sign == + && $accent_count -gt 6) ||
		#	($sign == - && $accent_count -lt 6) ]]
	do
		(( treshold += 2 ))
		#(( treshold $sign= 3 ))
	done

	#echo $avg_value
	for a in ${accents[*]}; do
		#echo $a
		print_color $a label
	done
	#exit

	#yet_another_get_step
	#exit

	#read avg_sv avg_value avg_saturation sorted_accents <<< $(yet_another_get_step)

	#while read color; do
	#	accents+=( ${color#*_} )
	#	print_color ${color#*_} label
	#done <<< $(tr ' ' '\n' <<< $sorted_accents | #sort -t ';' -k 1,1nr -k 3,3nr)
	#	awk -F ';' '{ if($3 > 10 && !($2 > 3 * $3)) print }' |
	#	sort -t ';' -k 1,1nr -k 3,3nr)

	#while read color; do
	#	accents+=( ${color#*_} )
	#	print_color ${color#*_} label
	#done <<< $(tr ' ' '\n' <<< $sorted_accents | #sort -t ';' -k 1,1nr -k 3,3nr)
	#	awk -F ';' '{
	#			als = ('$avg_value' < 50) ? 1 : $2 >= 5 && $3 > 50
	#			als = 1
	#			if(als && $3 > 10 && !($2 > 3 * $3)) print
	#		}' |
	#	sort -t ';' -k 1,1nr -k 3,3nr)

	by_value() {
		echo value: $value
		while read color; do
			print_color ${color#*_} label
		done <<< $(tr ' ' '\n' <<< $sorted_accents | #sort -t ';' -k 1,1nr -k 3,3nr)
			awk -F ';' '{ if($3 > 10 && !($2 > 3 * $3)) print }' |
			sort -t ';' -k 3,3nr)
	}

	#while read accent; do
	#	v=${accent%%_*}
	#	v=$(sed 's/\([^;]*;\)\{2\}\([0-9]\+\).*/\2/' <<< $accent)
	#	echo $v ${colors[$accent]:-$fg_value} $accent
	#done <<< $(tr ' ' '\n' <<< ${accents[*]}) |
	#	sort -nrk 2,2
	#exit

	by_freq() {
		local value min_value=100

		echo freq, $value, $avg_value
		while read value frequency frequent_accent; do
			(( total_freq+=frequency ))
			#echo freqacc: $value, $frequency, $frequent_accent
			frequent_accents+=( $frequent_accent )
			final_accents1+=( $frequent_accent )
			#echo $frequency, $frequent_accent
			print_color ${frequency}-$frequent_accent label

			((value < min_value)) &&
				min_value=$value lowest_accent=$frequent_accent
			#echo $frequent_accent, $value, $min_value
		done <<< $(while read accent; do
					v=${accent%%_*}
					v=$(sed 's/\([^;]*;\)\{2\}\([0-9]\+\).*/\2/' <<< $accent)
					echo $v ${colors[$accent]:-$fg_value}  $accent
				done <<< $(tr ' ' '\n' <<< ${accents[*]:0}) |
					sort -nrk 2,2)
		echo $((total_freq / ${#accents[*]}))
	}

	new() {
		while read color; do
			print_color $color label
			final_accents+=( $color )
		done <<< $(tr ' ' '\n' <<< ${accents[*]} | awk '{
				aa[++i] = $0
			} END {
				print aa[1] "\n" aa[2] "\n" aa[3]
				print aa[4 + mid] "\n" aa[4 + mid + 1]
				print aa[full]
			}')
	}

	new_freq() {
		while read accent; do
			v=$(sed 's/\([^;]*;\)\{2\}\([0-9]\+\).*/\2/' <<< $accent)
			echo $v ${colors[$accent]} $accent
		done <<< $(tr ' ' '\n' <<< ${accents[*]:0}) |
			#sort -nrk 1,1 | awk '
			sort -nrk 2,2 | awk '
				$1 > 10 {
					td += $2
					ad[++di] = $2
					da[++ai] = $0
					print
				} END {
					#ad = td / ai
					avd = (ad[1] + ad[di]) / 2
					print avd, '$avg_value'

					for(i=1; i <= ai; i++) {
						split(da[i], d_a)

						if(d_a[1] >= '$avg_value' || (mda && i > ai - mda)) print da[i]
						else if(!mda) {
							mda = 6 - (i - 1)
							if(i > ai -mda) print da[i]
						}
					}
				}' #| sort -nrk 1,1
	}

	by_new_freq() {
		echo freq, $value, $avg_value
		unset final_accents
		local value

		while read value frequency frequent_accent; do
			#frequent_accents+=( $frequent_accent )
			final_accents+=( $frequent_accent )
			#echo $frequency, $frequent_accent
			print_color ${frequency}-$frequent_accent label
		done <<< $(while read accent; do
					v=${accent%%_*}
					v=$(sed 's/\([^;]*;\)\{2\}\([0-9]\+\).*/\2/' <<< $accent)
					echo $v ${colors[$accent]} $accent
				done <<< $(tr ' ' '\n' <<< ${accents[*]:0}) | #sort -nk 1,1)
					#sort -nrk 1,1 | awk -F '[; ]' '
					sort -nrk 2,2 | awk '
						$1 > 15 {
							td += $2
							ad[++di] = $2
							aa[++ai] = $0
						} END {
							avd = td / ai
							avd = (ad[1] + ad[di]) / 2 - 0
							avd = td / ai + 0
							#system("~/.orw/scripts/notify.sh " avd)

							for(i = 1; i <= ai; i++) {
								split(aa[i], vda)
								if(vda[2] <= avd) print aa[i]
							}
						}' | sort -nrk 2,2)
	}

	vibrant() {
		echo vibrant
		while read color; do
			print_color $color label
		done <<< $(tr ' ' '\n' <<< ${accents[*]} | sort -t ';' -k 3,3nr)
	}

	frequent() {
		echo frequent, $value, $avg_value
		while read frequency frequent_accent; do
			frequent_accents+=( $frequent_accent )
			#echo $frequency, $frequent_accent
			print_color ${frequency}-$frequent_accent label
		done <<< $(while read accent; do
					echo ${colors[$accent]} $accent
				done <<< $(tr ' ' '\n' <<< ${accents[*]:0} | #sort -nk 1,1)
					awk -F ';' '$3 > 10' | head -20) | sort -nrk 1,1)
	}

	#most_vibrant_accents=( ${accents[*]::4} )
	#exclude_vibrant="${most_vibrant_accents[*]}"
	#most_frequent_accents=( $(tr ' ' '\n' <<< ${frequent_accents[*]} |
	#	grep -v "\(${exclude_vibrant// /\\|}\)" | head -2) )
	#
	##all_accents=( ${most_vibrant_accents[*]::4} ${most_frequent_accents[*]::2} )
	#all_accents=( ${frequent_accents[*]::6} )
	##all_accents=( ${frequent_accents[*]} )
	#
	##all_accents=( ${most_vibrant_accents[0]} ${most_frequent_accents[*]::5} )
	##all_accents=( ${most_vibrant_accents[*]::5} )

	distribute_accents() {
		((accent_count < 6)) &&
			compensate_accents ||
			all_accents=( $( \
				tr ' ' '\n' <<< ${all_accents[*]} |
				awk '{ ac[NR] = $0 }

					END {
						full = length(ac)
						mid1 = int(full / 2) + 0
						mid2 = (full % 2) ? mid1 + 2 : mid1 + 1

						step = int((full - 2) / 4)
						step = sprintf("%.0f", (full - 2) / 4)
						step = (full - 2) / 5
						#system("~/.orw/scripts/notify.sh " step)
						for(a = 1; a <= 4; a++) print ac[2 + int(a * step)]
						#if(2 + 4 * step > full) print ac[full]
						step = (full - 2) / 4
						#for(a = 1; a <= 4; a++) print ac[2 + sprintf("%.0f", a * step)]
					}'
				) )
	}

	old_approach() {
		all_accents=( ${most_vibrant_accents[*]::4} ${most_frequent_accents[*]::2} )
		#all_accents=( ${frequent_accents[*]::6} )
		accent_count=${#all_accents[*]}

		compensate_accents
		#ffg=$(tr ' ' '\n' <<< ${all_accents[*]} | sort -t ';' -nk 3,3 | head -1)

		for accent in $(tr ' ' '\n' <<< "${all_accents[*]}" | awk -F ';' '
				{ print $2 + $3, $0 }' | sort -t ';' -nrk 1,1 | grep -o '[^ ]*$'); do
				#!/'"$ffg"'/ { print $2 + $3, $0 }' | sort -t ';' -nrk 1,1 | grep -o '[^ ]*$'); do
			print_color $accent label
			final_accents+=( $accent )
		done

		final_accents+=( $ffg )
	}

	new_approach() {
		all_accents=( ${frequent_accents[*]} )
		accent_count=${#all_accents[*]}
		distribute_accents

		ffg=$(tr ' ' '\n' <<< ${all_accents[*]} | sort -t ';' -nk 3,3 | head -1)

		for accent in $(tr ' ' '\n' <<< "${all_accents[*]}" | awk -F ';' '
				!/'"$ffg"'/ { print $2 + $3, $0 }' | sort -t ';' -nrk 1,1 | grep -o '[^ ]*$'); do
				#{ print $2 + $3, $0 }' | sort -t ';' -nrk 1,1 | grep -o '[^ ]*$'); do
			print_color $accent label
			final_accents+=( $accent )
		done

		final_accents+=( $ffg )
	}

	get_dark_accents() {
		local exclude="${accents[*]}"

		if ((accent_count < 6)); then
			count_diff=$((5 - (accent_count - 0)))
			local dark_accent_count=$((6 - accent_count))
			tr ' ' '\n' <<< "${sorted_colors[*]::20}" | awk -F ';' '
				$0 !~ "('"${exclude// /|}"')$" {
					b = $3 > 15 && $3 < 85
					if(b) print $1, $2 + $3, $0
				}' | sort -k 1,1n -k 2,2 | tail -$dark_accent_count | grep -o '[^ ]*$'
		fi
	}

	#accent_count=${#accents[*]}

	set_all_accents() {
		((accent_count > 6)) &&
			final_accents=(
				$(tr ' ' '\n' <<< ${accents[*]} | awk '
						{ ac[NR] = $0 }
						END {
							full = length(ac)
							mid1 = int(full / 2) + 0
							mid2 = (full % 2) ? mid1 + 2 : mid1 + 1

							print ac[1] "\n" ac[2]
							print ac[mid1] "\n" ac[mid1 + 1]
							print ac[full - 1] "\n" ac[full]
						}' #| sed 's/[^_]*_//'
				) ) ||

		final_accents=( $( (tr ' ' '\n' <<< ${accents[*]::6} && get_dark_accents) |
			awk -F ';' '{ print $2 + $3 "_" $0 }' | sort -k 1,1nr -k 3,3nr | grep -o '\([^_]*_\?\)\{3\}$') )
	}

	compensate_accents1() {
		local exclude="${final_accents[*]:-${accents[*]}}"
		local count_diff=$((6 - accent_count))
		#((count_diff < 2)) && (( count_diff++ ))

		if ((count_diff)); then
			while read extra_accent; do
				echo extra
				print_color $extra_accent label
				final_accents+=( $extra_accent )
				extra_accents+=( $extra_accent )
				accents+=( $extra_accent )
			#done <<< $(tr ' ' '\n' <<< "${sorted_colors[*]:5:13}" | awk -F ';' '
			#done <<< $(tr ' ' '\n' <<< "${sorted_colors[*]:10}" | awk -F ';' '
			done <<< $(tr ' ' '\n' <<< "${sorted_colors[*]}" | awk -F ';' '
				BEGIN {
					av = "'$value'"
					aav = "'$avg_value'"

					as = "'$saturation'"
					aas = "'$avg_saturation'"

					asv = ("'$saturation'" + "'$value'") / 1
					aasv = "'$avg_sv'"

					ci = split("'"${accents[*]}"'", fa, " ")

					#system("~/.orw/scripts/notify.sh \"" av " " aav "\"")
					#system("~/.orw/scripts/notify.sh \"" asv " " aasv "\"")
				}

				function abs(n1, n2) {
					return sqrt((n1 - n2) ^ 2)
				}

				function rgb_to_xyz(r, g, b) {
					R = r / 255
					G = g / 255
					B = b / 255

					R = (R > 0.04045) ? ((R + 0.055) / 1.055) ^ 2.4 : R / 12.92
					G = (G > 0.04045) ? ((G + 0.055) / 1.055) ^ 2.4 : G / 12.92
					B = (B > 0.04045) ? ((B + 0.055) / 1.055) ^ 2.4 : B / 12.92

					R *= 100
					G *= 100
					B *= 100

					X = R * 0.4124 + G * 0.3576 + B * 0.1805
					Y = R * 0.2126 + G * 0.7152 + B * 0.0722
					Z = R * 0.0193 + G * 0.1192 + B * 0.9505
				}

				function xyz_to_lab(x, y, z) {
					refx =  95.047
					refy = 100.000
					refz = 108.883

					X = x / refx
					Y = y / refy
					Z = z / refz

					X = (X > 0.008856) ? X ^ (1 / 3) : (7.787 * X) + (16 / 116)
					Y = (Y > 0.008856) ? Y ^ (1 / 3) : (7.787 * Y) + (16 / 116)
					Z = (Z > 0.008856) ? Z ^ (1 / 3) : (7.787 * Z) + (16 / 116)

					L = 116 * Y - 16
					a = 500 * (X - Y)
					b = 200 * (Y - Z)
				}

				function set_previous(color) {
					pc = color
					split(pc, prc, "[;_]")
					prsv = prc[1]; prh = prc[2]; prs = prc[3]; prv = prc[4]
					pr = prc[5]; pg = prc[6]; pb = prc[7]
				}

				function is_different() {
					#print r, g, b
					#print pr, pg, pb

					rgb_to_xyz(r, g, b)
					xyz_to_lab(X, Y, Z)
					l1 = L; a1 = a; b1 = b

					as = 65
					pai = ci

					do {
						set_previous(fa[pai])

						nde = (abs(h, prh) <= as || (h == 360 && abs(0, prh) <= as))

						if(nde) {
							rgb_to_xyz(pr, pg, pb)
							xyz_to_lab(X, Y, Z)
							l2 = L; a2 = a; b2 = b

							l = (l2 - l1) ^ 2
							a = (a2 - a1) ^ 2
							b = (b2 - b1) ^ 2

							#print h, prh, sqrt(l + a + b)
							nde = sqrt(l + a + b) < 11
						}

						pai--
					} while(pai && (h == 360 || (h != 360 && abs(h, prh) <= as)) && !nde)

					return !nde
				}

				$0 !~ "('"${exclude// /|}"')$" {
					b = $3 > 15 && $3 < 85 &&
						!($3 > 10 * $2)

					b = $3 > (aav - av / 2) && $3 < (aav + av / 2)

					vd = abs(av, aav)
					b = $3 > (av - vd) && $3 < (av + vd)

					b = $2 > 10 && $3 > 10 && $3 < 80 &&
						((aav > av) ? $2 + $3 < aasv - 0 : $2 + $3 >= aasv - 0)
						#((aav > av) ? $3 < aav + 5 : $3 > aav - 5)
						#((aasv > asv) ? $2 + $3 < aasv + 0 : $2 + $3 > aasv - 0)
						#((aas > as) ? $2 + $3 < aas + 10 : $2 + $3 > aas - 10)

					if(!b) next

					split($0, cp, "[;_]")
					r = cp[5]; g = cp[6]; b = cp[7]

					if(is_different()) {
						print $2 + $3, $0
						fa[++ci] = $2 + $3 "_" $0
					}
				}' | sort -k 1,1nr -k 2,2 | head -$((count_diff - 0)) | grep -o '[^ ]*$')
				#}' | sort -k 2,2nr -k 1,1 | head -$((count_diff - 0)) | grep -o '[^ ]*$')
		fi
	}





	print_compensated() {
		exclude="${final_accents[*]:-${accents[*]}}"
		count_diff=$((6 - accent_count))
		#((count_diff < 2)) && (( count_diff++ ))

		if ((count_diff)); then
			#while read extra_accent; do
			#	echo extra
			#	print_color $extra_accent label
			#	final_accents+=( $extra_accent )
			#	extra_accents+=( $extra_accent )
			#	accents+=( $extra_accent )
			##done <<< $(tr ' ' '\n' <<< "${sorted_colors[*]:5:13}" | awk -F ';' '
			##done <<< $(tr ' ' '\n' <<< "${sorted_colors[*]:10}" | awk -F ';' '
			#done <<< $(tr ' ' '\n' <<< "${sorted_colors[*]}" | awk -F ';' '
			tr ' ' '\n' <<< "${sorted_colors[*]}" | awk -F ';' '
				BEGIN {
					av = "'$value'"
					aav = "'$avg_value'"

					as = "'$saturation'"
					aas = "'$avg_saturation'"

					asv = ("'$saturation'" + "'$value'") / 1
					aasv = "'$avg_sv'"

					ci = split("'"${accents[*]}"'", fa, " ")

					#system("~/.orw/scripts/notify.sh \"" av " " aav "\"")
					#system("~/.orw/scripts/notify.sh \"" asv " " aasv "\"")
				}

				function abs(n1, n2) {
					return sqrt((n1 - n2) ^ 2)
				}

				function rgb_to_xyz(r, g, b) {
					R = r / 255
					G = g / 255
					B = b / 255

					R = (R > 0.04045) ? ((R + 0.055) / 1.055) ^ 2.4 : R / 12.92
					G = (G > 0.04045) ? ((G + 0.055) / 1.055) ^ 2.4 : G / 12.92
					B = (B > 0.04045) ? ((B + 0.055) / 1.055) ^ 2.4 : B / 12.92

					R *= 100
					G *= 100
					B *= 100

					X = R * 0.4124 + G * 0.3576 + B * 0.1805
					Y = R * 0.2126 + G * 0.7152 + B * 0.0722
					Z = R * 0.0193 + G * 0.1192 + B * 0.9505
				}

				function xyz_to_lab(x, y, z) {
					refx =  95.047
					refy = 100.000
					refz = 108.883

					X = x / refx
					Y = y / refy
					Z = z / refz

					X = (X > 0.008856) ? X ^ (1 / 3) : (7.787 * X) + (16 / 116)
					Y = (Y > 0.008856) ? Y ^ (1 / 3) : (7.787 * Y) + (16 / 116)
					Z = (Z > 0.008856) ? Z ^ (1 / 3) : (7.787 * Z) + (16 / 116)

					L = 116 * Y - 16
					a = 500 * (X - Y)
					b = 200 * (Y - Z)
				}

				function set_previous(color) {
					pc = color
					split(pc, prc, "[;_]")
					#prsv = prc[1]; prh = prc[2]; prs = prc[3]; prv = prc[4]
					prsv = prc[1]; prh = prc[1]; prs = prc[2]; prv = prc[3]
					pr = prc[5]; pg = prc[6]; pb = prc[7]
				}

				function is_different() {
					#print r, g, b
					#print pr, pg, pb

					rgb_to_xyz(r, g, b)
					xyz_to_lab(X, Y, Z)
					l1 = L; a1 = a; b1 = b

					as = 65
					pai = ci

					do {
						set_previous(fa[pai])

						nde = (abs(h, prh) <= as || (h == 360 && abs(0, prh) <= as))
						#print h, prh, nde
						#print $0, pc, pai, nde, abs(h, prh), h, prh

						if(nde) {
							rgb_to_xyz(pr, pg, pb)
							xyz_to_lab(X, Y, Z)
							l2 = L; a2 = a; b2 = b

							l = (l2 - l1) ^ 2
							a = (a2 - a1) ^ 2
							b = (b2 - b1) ^ 2

							#print h, prh, sqrt(l + a + b)
							nde = sqrt(l + a + b) < 15
							print "HERE", h, prh, sqrt(l + a + b), nde
							#if(h == 204) print $0, pc, nde, h, prh
						}

						pai--
					} while(pai && !nde)
					#} while(pai && (h == 360 || (h != 360 && abs(h, prh) <= as)) && !nde)

					return !nde
				}

				$0 !~ "('"${exclude// /|}"')$" {
					b = $3 > 15 && $3 < 85 &&
						!($3 > 10 * $2)

					b = $3 > (aav - av / 2) && $3 < (aav + av / 2)

					vd = abs(av, aav)
					b = $3 > (av - vd) && $3 < (av + vd)

					b = $2 > 10 && $3 > 10 && $3 < 80 &&
						((aav > av) ? $2 + $3 < aasv - 0 : $2 + $3 >= aasv - 0)
						#((aav > av) ? $3 < aav + 5 : $3 > aav - 5)
						#((aasv > asv) ? $2 + $3 < aasv + 0 : $2 + $3 > aasv - 0)
						#((aas > as) ? $2 + $3 < aas + 10 : $2 + $3 > aas - 10)

					if(!b) next
					#print "here"

					split($0, cp, "[;_]")
					h = cp[1]; r = cp[5]; g = cp[6]; b = cp[7]

					if(is_different()) {
						print $2 + $3, $0
						fa[++ci] = $2 + $3 "_" $0
					}
			}' #| sort -k 1,1nr -k 2,2 | head -$((count_diff - 0)) | grep -o '[^ ]*$'
		fi
		exit
	}



	compensate_accents() {
		local exclude="${final_accents[*]:-${accents[*]}}"
		local count_diff=$((6 - accent_count))
		#((count_diff < 2)) && (( count_diff++ ))

		if ((count_diff)); then
			while read extra_accent; do
				echo extra
				print_color $extra_accent label
				final_accents+=( $extra_accent )
				extra_accents+=( $extra_accent )
				accents+=( $extra_accent )
			#done <<< $(tr ' ' '\n' <<< "${sorted_colors[*]:5:13}" | awk -F ';' '
			#done <<< $(tr ' ' '\n' <<< "${sorted_colors[*]:10}" | awk -F ';' '
			done <<< $(tr ' ' '\n' <<< "${sorted_colors[*]}" | awk -F ';' '
				BEGIN {
					av = "'$value'"
					aav = "'$avg_value'"

					as = "'$saturation'"
					aas = "'$avg_saturation'"

					asv = ("'$saturation'" + "'$value'") / 1
					aasv = "'$avg_sv'"

					ci = split("'"${accents[*]}"'", fa, " ")

					#system("~/.orw/scripts/notify.sh \"" av " " aav "\"")
					#system("~/.orw/scripts/notify.sh \"" asv " " aasv "\"")
				}

				function abs(n1, n2) {
					return sqrt((n1 - n2) ^ 2)
				}

				function rgb_to_xyz(r, g, b) {
					R = r / 255
					G = g / 255
					B = b / 255

					R = (R > 0.04045) ? ((R + 0.055) / 1.055) ^ 2.4 : R / 12.92
					G = (G > 0.04045) ? ((G + 0.055) / 1.055) ^ 2.4 : G / 12.92
					B = (B > 0.04045) ? ((B + 0.055) / 1.055) ^ 2.4 : B / 12.92

					R *= 100
					G *= 100
					B *= 100

					X = R * 0.4124 + G * 0.3576 + B * 0.1805
					Y = R * 0.2126 + G * 0.7152 + B * 0.0722
					Z = R * 0.0193 + G * 0.1192 + B * 0.9505
				}

				function xyz_to_lab(x, y, z) {
					refx =  95.047
					refy = 100.000
					refz = 108.883

					X = x / refx
					Y = y / refy
					Z = z / refz

					X = (X > 0.008856) ? X ^ (1 / 3) : (7.787 * X) + (16 / 116)
					Y = (Y > 0.008856) ? Y ^ (1 / 3) : (7.787 * Y) + (16 / 116)
					Z = (Z > 0.008856) ? Z ^ (1 / 3) : (7.787 * Z) + (16 / 116)

					L = 116 * Y - 16
					a = 500 * (X - Y)
					b = 200 * (Y - Z)
				}

				function set_previous(color) {
					pc = color
					split(pc, prc, "[;_]")
					#prsv = prc[1]; prh = prc[2]; prs = prc[3]; prv = prc[4]
					prsv = prc[1]; prh = prc[1]; prs = prc[2]; prv = prc[3]
					pr = prc[5]; pg = prc[6]; pb = prc[7]
				}

				function is_different() {
					#print r, g, b
					#print pr, pg, pb

					rgb_to_xyz(r, g, b)
					xyz_to_lab(X, Y, Z)
					l1 = L; a1 = a; b1 = b

					as = 65
					pai = ci

					do {
						set_previous(fa[pai])

						nde = (abs(h, prh) <= as || (h == 360 && abs(0, prh) <= as))
						#print $0, pc, pai, nde, abs(h, prh), h, prh

						if(nde) {
							rgb_to_xyz(pr, pg, pb)
							xyz_to_lab(X, Y, Z)
							l2 = L; a2 = a; b2 = b

							l = (l2 - l1) ^ 2
							a = (a2 - a1) ^ 2
							b = (b2 - b1) ^ 2

							#print h, prh, sqrt(l + a + b)
							nde = sqrt(l + a + b) < 10
							#if(h == 204) print $0, pc, nde, h, prh
						}

						pai--
					} while(pai && !nde)
					#} while(pai && (h == 360 || (h != 360 && abs(h, prh) <= as)) && !nde)

					return !nde
				}

				$0 !~ "('"${exclude// /|}"')$" {
					b = $3 > 15 && $3 < 85 &&
						!($3 > 10 * $2)

					b = $3 > (aav - av / 2) && $3 < (aav + av / 2)

					vd = abs(av, aav)
					b = $3 > (av - vd) && $3 < (av + vd)

					b = $2 > 10 && $3 > 10 && $3 < 80 &&
						((aav > av) ? $2 + $3 < aasv - 0 : $2 + $3 >= aasv - 0)
						#((aav > av) ? $3 < aav + 5 : $3 > aav - 5)
						#((aasv > asv) ? $2 + $3 < aasv + 0 : $2 + $3 > aasv - 0)
						#((aas > as) ? $2 + $3 < aas + 10 : $2 + $3 > aas - 10)

					if(!b) next

					split($0, cp, "[;_]")
					h = cp[1]; r = cp[5]; g = cp[6]; b = cp[7]

					if(is_different()) {
						print $2 + $3, $0
						fa[++ci] = $2 + $3 "_" $0
					}
			}' | sort -k 1,1nr -k 2,2 | head -$((count_diff - 0)) | grep -o '[^ ]*$')
		fi
	}
	#compensate_accents
	#exit




	#by_value
	accent_count=${#accents[*]}

	echo $saturation, $value, ${#accents[*]}
	#((${#accents[*]} < 6)) && print_compensated
	#((${#accents[*]} < 6)) && compensate_accents
	#((${#accents[*]} < 6)) && final_accents+=( $(get_dark_accents) )
	#((${#accents[*]} < 6)) && accents+=( $(get_dark_accents) )
	((${#accents[*]} < 6)) && compensate_accents

	by_freq
	by_new_freq

	#accent_count=${#accents[*]}
	#((accent_count < 6)) && 
	#	final_accents=( $( (tr ' ' '\n' <<< ${accents[*]} && get_dark_accents) |
	#		awk -F ';' '{ print $2 + $3, $0 }' | sort -t ';' -k 1,1nr -k 3,3nr | grep -o '[^ ]*$') )

	echo sv: $avg_sv
	most_frequent_accents=( ${final_accents[*]} )
	accent_count=${#accents[*]}

	#echo ${frequent_accents[*]}
	#exit

	#echo $lowest_color
	#echo ${frequent_accents[*]/$lowest_color}
	#exit

	#final_accents=( ${frequent_accents[*]::6} )
	((accent_count > 6)) && accent_to_remove=$lowest_accent
	final_accents=( ${frequent_accents[*]/$accent_to_remove} )
	accent_count=${#final_accents[*]}
	#accent_count=${#accents[*]}

	if ((accent_count < 6)); then
		final_accents=( ${accents[*]} )
		compensate_accents

		final_accents=(
			$(tr ' ' '\n' <<< ${final_accents[*]} |
			awk -F ';' '{ print $2 + $3, $0 }' |
			sort -t ';' -k 1,1nr -k 3,3nr | grep -o '[^ ]*$')
		)
	else
		exclude="${final_accents[*]}"
		final_count=${#final_accents[*]}
		final_accents=( $((
			tr ' ' '\n' <<< ${frequent_accents[*]} |
			grep -v "\(${exclude// /\\|}\)" |
			sort -t ';' -k 3,3nr -k 2,2nr |
			head -$((10 - final_count)) &&
			tr ' ' '\n' <<< ${final_accents[*]} ) |
			sort -t ';' -nrk 3,3) )
	fi

	##echo $avg_value
	#for a in ${final_accents[*]}; do
	#	#echo $a
	#	print_color $a label
	#done
	#exit

	echo $avg_value, $avg_saturation
	most_vibrant=${accents[0]}

	final=(
		$most_vibrant
		$(tr ' ' '\n' <<< ${final_accents[*]} | awk -F ';' '
			!/'$most_vibrant'/ {
				sd = sqrt(($2 - '$avg_saturation') ^ 2)
				vd = sqrt(($3 - '$avg_value') ^ 2)
				print vd, sd, $0
			}' | sort -k 1,1n -k 2,2n | grep -o '[^ ]*$')
		)

	#for a in ${final[*]}; do
	#	print_color $a label
	#done
	#exit

	#((${#final_accents[*]} < 6)) && final_accents+=( 0_0_0 )

	#final_accents=(
	#	$(tr ' ' '\n' <<< ${final_accents[*]} |
	#	awk -F ';' '{ print $2 + $3, $0 }' |
	#	sort -t ';' -k 1,1nr -k 3,3nr | grep -o '[^ ]*$')
	#)


	echo $avg_value, $((100 - avg_value)), $value
	((avg_value < 50)) && avg_value=$((100 - avg_value))
	#avg_value=$((100 - avg_value))
	#avg_value=54
	echo $avg_value, $value

	set_accent() {
		echo AV $avg_value

		for accent in $1; do
			read h s v r g b <<< $(cut -d ';' -f 1,2,3,4,5,6 <<< $accent | tr '[;_]' ' ')

			sv=$((s + v))
			a=$((sv / 2 - 13))

			value_diff=$((s - a - accent_deviation))
			if ((s > v)); then
				if ((s > 3 * v)); then
					value=$(((s - 3 * v) * 5))
					((value > 30)) && value=30
					light_accent=$(get_sbg ${accent##*_} +$value)
					echo HREHREHRHERHE $value
				else
					#((a + 1 >= v)) && multiplier=1.3 || multiplier=1.7
					#((a + 1 >= v)) && multiplier=1.3 || multiplier=1.9

					#((a + 1 >= v)) && multiplier=1.3 || multiplier=1.6
					((a + 1 >= v)) && multiplier=1.3 || multiplier=1.7
					#((a + 1 >= v)) && multiplier=1.3 || multiplier=2.3

					#value_diff=$(bc <<< "($value_diff * $multiplier) / 1 + $v")
					value=$(bc <<< "($value_diff * $multiplier) / 1 + 0")
					((value > 100)) && value=90
					#light_accent=$(get_sbg ${accent##*_} ${value_diff#-} $((s - 5)))
					light_accent=$(get_sbg ${accent##*_} +${value#-} 5)
					#light_accent=$(get_sbg ${accent##*_} +${value#-})

					echo THERE $a, $s, $v, $multiplier, $value, $light_accent
				fi
			else
				if ((v < avg_value)); then
					if ((s > a && v > a)); then
						sv_diff=$((s - v))

						if ((${sv_diff#-} > a)); then
							value=${sv_diff#-}
							((${sv_diff#-} > 2 * a)) && multiplier=0.4 || multiplier=1
							((${sv_diff#-} > 2 * a && 2 * v > avg_value)) &&
								multiplier=0.4 || multiplier=0.7
								#multiplier=0.4 || multiplier=1
							multiplier=0.8
							#multiplier=1.2
							#multiplier=2.2
						else
							value=$((value_diff + accent_deviation)) multiplier=1.6
							((value > 10)) && value=10
							((value < 5)) && value=5
						fi
					else
						if ((avg_value - v > ${value_diff#-})); then
							value=$((avg_value - v))
							((avg_value - v > 2 * ${value_diff#-})) &&
								multiplier=0.7 || multiplier=0.9
							((avg_value - v > 2 * ${value_diff#-})) &&
								multiplier=0.5 || multiplier=0.8
							#((value < 5)) && value=10
						else
							value=$((v - a)) multiplier=0.4
							value=$((v - a)) multiplier=0.3
							multiplier=1
							((v > 3 * s)) && value=$s
						fi

						echo HERE $value, $value_diff, $avg_value, $v, $s, $a
					fi

					#value_diff=$(bc <<< "($value * $multiplier) / 1")
					value_diff=$(bc <<< "(5 * $multiplier) / 1")

					echo OVER $value - $value_diff: $avg_value, $v, $accent $multiplier
					#((value_diff > 10)) && value_diff=10
					#((value_diff < 5)) && value_diff=5

					#value=10
					#value_diff=1
					light_accent=$(get_sbg ${accent##*_} +${value_diff#-})
					#echo ACCENT: $light_accent, ${accent##*_} - $(get_sbg ${accent##*_} +0)

					((avg_value -= 5))
				else
					if ((v > 75)); then
						((s > 60)) &&
							light_accent=$(get_sbg ${accent##*_} +$((v - s))) ||
							light_accent="${accent#*_}"
							#light_accent=$(get_sbg ${accent##*_} +10)

					#elif ((v >= 6 * (s - 1))); then
					#	light_accent=$(get_sbg ${accent##*_} $((v + 5)) $((s + 10)))
					#	light_accent="${accent#*_}"
					#	#light_accent=$(get_sbg ${accent##*_} $((v + 0)) $((s + 0)))
					elif ((v >= 3 * (s - 1))); then
						echo OVER HERE $accent,
						((v < 70)) && value=10 || value=+5
						((s < 20)) &&
							#light_accent=$(get_sbg ${accent##*_} $((v + value)) $((s + 5))) ||
							light_accent=$(get_sbg ${accent##*_} $((v + value)) $((s + value))) ||
							light_accent=$(get_sbg ${accent##*_} $((v + 18)) $((s + 5)))

						#light_accent=$(get_sbg ${accent##*_} $((v + 15)) $((s + 5)))
						#light_accent=$(get_sbg ${accent##*_} +0)
					else
						#value=$((10 - (v - avg_value)))
						#((value < 0)) && value=5
						#echo $value, $avg_value, $v
						#light_accent=$(get_sbg ${accent##*_} +$value)

						#light_accent=$(get_sbg ${accent##*_} +20 10)
						#light_accent=$(get_sbg ${accent##*_} +10)
						((v > 2 * s)) &&
							value=10 || value=5
						light_accent=$(get_sbg ${accent##*_} +$value)
						echo 20: $accent
					fi
				fi
			fi

			#echo ACCENT $value: $light_accent

			#((value < 9)) && light_accent=$(get_sbg ${accent##*_} +10)
			((value < 10)) && light_accent=$(get_sbg ${accent##*_} +10)
			#((value <= 10 && avg_value < 50)) && light_accent=$(get_sbg ${accent##*_} +10)
			echo $h, $a, $value_diff, $s, $new_s, $v, $new_v, $avg_value, $v, $light_accent

			#light_accent_colors+=( "${sv};${h};${s};${v}_${light_accent// /_}" )

			#if ((value < 50)); then
			#	echo HERERE $accent
			#	light_accent=$(get_sbg ${accent##*_} +5)
			#	#light_accent_colors+=( "${sv};${h};${s};${v}_${light_accent// /_}" )
			#	light_accent_colors+=( "$sv;${accent%_*}_${light_accent#* }" )
			#	echo "$sv;${accent%_*}_${light_accent#* }" 
			#else
			#	((value > 90)) &&
			#		light_accent_colors+=( "$accent" ) ||
			#		light_accent_colors+=( "${sv};${h};${s};${v}_${light_accent// /_}" )
			#fi

			light_accent_colors+=( "${sv};${h};${s};${v}_${light_accent// /_}" )

			#light_accent_colors+=( "$accent" )
			((accent_deviation+=1))
		done
	}

	all_accents=(
		${final_accents[0]}
		$(tr ' ' '\n' <<< ${most_frequent_accents[*]} | sort -t ';' -nrk 3,3)
		$(tr ' ' '\n' <<< ${extra_accents[*]} | sort -t ';' -nrk 3,3)
	)

	#for a in ${all_accents[*]}; do
	#	print_color $a lavel
	#done
	#exit






	#fa=(
	#	$(tr ' ' '\n' <<< ${final_accents[*]} |
	#		awk -F ';' '{ print $2 + $3, $0 }' |
	#		sort -t ';' -k 1,1nr -k 3,3nr | grep -o '[^ ]*$')
	#	)
	#set_accent "${fa[*]}"

	#set_accent "${all_accents[*]}"
	#light_accent_colors=( $(tr ' ' '\n' <<< ${light_accent_colors[*]} | sort -t ';' -nrk 1,1) )

	set_accent "${final_accents[*]}"

	#set_accent "${frequent_accents[*]}"
	#set_accent "${all_accents[*]}"
	#light_accent_colors=( $(tr ' ' '\n' <<< ${light_accent_colors[*]} | sort -t ';' -nrk 1,1) )





	for la in ${light_accent_colors[*]}; do
		print_color $la label
	done
	#exit

	set_accents() {
		for accent in $@; do
			light_accent=$(get_sbg ${accent##*_} +10)
			light_accent_colors+=( "${accent%%_*}_${light_accent// /_}" )
			#light_accent_colors+=( "${sv};${h};${s};${v}_${light_accent// /_}" )
		done
	}

	#set_accents "${final_accents[*]}"

	#light_accent_colors=( $(tr ' ' '\n' <<< ${light_accent_colors[*]} | sort -nrk 1,1) )
	most_vibrant=$(tr ' ' '\n' <<< ${light_accent_colors[*]} | sort -t ';' -nrk 1,1 | head -1)

	accent_colors=(
		#${light_accent_colors[*]::4}
		#$(tr ' ' '\n' <<< ${light_accent_colors[*]: -2} | sort -t ';' -nrk 1,1)
		#$(tr ' ' '\n' <<< ${light_accent_colors[*]} | sort -t ';' -nrk 1,1)

		#${light_accent_colors[*]}
		#${light_accent_colors[*]::6}
		#$(tr ' ' '\n' <<< ${light_accent_colors[*]::6} | sort -t ';' -nrk 1,1)

		#$(tr ' ' '\n' <<< ${light_accent_colors[*]::4} | sort -t ';' -nrk 1,1)
		#${light_accent_colors[*]: -2}



		#$(tr ' ' '\n' <<< ${light_accent_colors[*]} | sort -t ';' -nrk 1,1)
		#${light_accent_colors[*]}
		
		#${light_accent_colors[*]::4}
		#$(tr ' ' '\n' <<< ${light_accent_colors[*]: -2} | sort -t ';' -nrk 1,1)
		#$(tr ' ' '\n' <<< ${light_accent_colors[*]::4} | sort -t ';' -nrk 1,1)
		#${light_accent_colors[*]: -2}
		#${light_accent_colors[*]}

		#${light_accent_colors[*]}
		$(tr ' ' '\n' <<< ${light_accent_colors[*]} | sort -t ';' -nrk 1,1)

		#$(tr ' ' '\n' <<< ${light_accent_colors[*]::5} | sort -t ';' -nrk 4,4)
		#${light_accent_colors[-1]}

		#$(tr ' ' '\n' <<< ${light_accent_colors[*]} | sort -t ';' -nrk 3,3 | head -4 | sort -nr)
		#$(tr ' ' '\n' <<< ${light_accent_colors[*]} | sort -t ';' -nrk 3,3 | tail -2)
		#${light_accent_colors[*]: -2}

		#$(tr ' ' '\n' <<< ${light_accent_colors[*]::4} | sort -t ';' -nrk 1,1)
		#${light_accent_colors[*]: -2}

		#$(tr ' ' '\n' <<< ${light_accent_colors[*]} | sort -t ';' -nrk 1,1)
		#$(tr ' ' '\n' <<< ${light_accent_colors[*]::4} | sort -t ';' -nrk 1,1)
		#${light_accent_colors[*]: -2}

		#$(tr ' ' '\n' <<< ${light_accent_colors[*]} |
		#	sort -t ';' -k 1,1nr -k 4,4 | head -4 | sort -t ';' -nrk 4,4)
		#$(tr ' ' '\n' <<< ${light_accent_colors[*]} |
		#	sort -nrk 1,1 | tail -2 | sort -t ';' -nrk 4,4)
	)

	#echo
	#for a in ${light_accent_colors[*]}; do
	#	print_color $a label
	#done
	#exit

	[[ $2 == -s ]] && reverse_last='r'

	[[ $# -gt 1 && ${@: -1} != -s ]] && skip="\|${@: -1}"

	sort_accents() {
		#local light_accent_colors=( ${accents[*]} )
		#sort -t ';' -nrk 4,4 <<< \
		#	$(tr ' ' '\n' <<< ${light_accent_colors[*]}) |

		#most_vibrant=$(tr ' ' '\n' <<< ${light_accent_colors[*]} | sort -nr | head -1)
		#read most_vibrant darkest <<< $(tr ' ' '\n' <<< ${light_accent_colors[*]} |
		#	sort -nr | awk 'NR == 1 { print } END { print }' | xargs)
		#	#sort -t ';' -nrk 4,4 | awk 'NR == 1 { print } END { print }' | xargs)

		#darkest=$(tr ' ' '\n' <<< ${light_accent_colors[*]} | sort -t ';' -nk 1,1 |
		#	head -2 | sort -t ';' -nk 3,3 | tail -1)

		#darkest=$(tr ' ' '\n' <<< ${light_accent_colors[*]} | 
		#	grep -v $most_vibrant | sort -t ';' -nk 4,4 -nk 4,4 | head -2)

		#unset light_accent_colors[-1]

		local dark_count=$((${#light_accent_colors[*]} / 3))
		dark_count=2
		dark_count=$(((${#light_accent_colors[*]} + 3 / 2) / 3))
		most_vibrant=$(tr ' ' '\n' <<< ${light_accent_colors[*]} |
			grep -v "^${darkest/ /\|}$" | sort -nr | head -1)
		darkest=$(tr ' ' '\n' <<< ${light_accent_colors[*]} | 
			grep -v $most_vibrant | sort -t ';' -nk 4,4 -k 3,3nr |
			head -$dark_count) #| sort -n$reverse_last)



		#tr ' ' '\n' <<< ${light_accent_colors[*]} |
		#	awk -F '[;_]' '
		#			!/'"$most_vibrant"'/ { ac[$5 + $6 + $7] = $0 }
		#					END { for (a in ac) print ac[a] }' #|
		#						#sort -nrk 1,1 | cut -d ' ' -f 2

		#return




			#grep -v $most_vibrant | sort -t ';' -nk 4,4 -nk 3,3r | head -2 | sort -n$reverse_last)

			#grep -v $most_vibrant | sort -t ';' -nk 1,1 -nk 4,4 | head -2)

		#most_vibrant=$(tr ' ' '\n' <<< ${light_accent_colors[*]} |
		#	grep -v "${darkest/ /\|}" | sort -nr | head -1)

		#darkest=$(tr ' ' '\n' <<< ${light_accent_colors[*]} | sort -t ';' -nk 1,1 |
		#	head -2 | sort -t ';' -nk 4,4 | xargs)

		accent_count=${#light_accent_colors[*]}

		(
			echo $most_vibrant

			#tr ' ' '\n' <<< ${light_accent_colors[*]} |
			#	awk -F '[;_]' '
			#			!/'"$most_vibrant"'/ { ac[$5 + $6 + $7] = $0 }
			#					END { for (a in ac) print ac[a] }'

			echo -e "${darkest/ /\\n}"
			#tr ' ' '\n' <<< ${light_accent_colors[*]} | grep -v "$most_vibrant" |
			tr ' ' '\n' <<< ${light_accent_colors[*]} | grep -v "$most_vibrant\|${darkest/ /\\|}$skip" |
				sort -t ';' -nrk 4,4
			#echo $darkest
		) | awk '
				function rgb_to_xyz(r, g, b) {
					R = r / 255
					G = g / 255
					B = b / 255

					R = (R > 0.04045) ? ((R + 0.055) / 1.055) ^ 2.4 : R / 12.92
					G = (G > 0.04045) ? ((G + 0.055) / 1.055) ^ 2.4 : G / 12.92
					B = (B > 0.04045) ? ((B + 0.055) / 1.055) ^ 2.4 : B / 12.92

					R *= 100
					G *= 100
					B *= 100

					X = R * 0.4124 + G * 0.3576 + B * 0.1805
					Y = R * 0.2126 + G * 0.7152 + B * 0.0722
					Z = R * 0.0193 + G * 0.1192 + B * 0.9505
				}

				function xyz_to_lab(x, y, z) {
					refx =  95.047
					refy = 100.000
					refz = 108.883

					X = x / refx
					Y = y / refy
					Z = z / refz

					X = (X > 0.008856) ? X ^ (1 / 3) : (7.787 * X) + (16 / 116)
					Y = (Y > 0.008856) ? Y ^ (1 / 3) : (7.787 * Y) + (16 / 116)
					Z = (Z > 0.008856) ? Z ^ (1 / 3) : (7.787 * Z) + (16 / 116)

					L = 116 * Y - 16
					a = 500 * (X - Y)
					b = 200 * (Y - Z)
				}

				function get_rgb(color) {
					split(color, cp, "[;_]")
					r = cp[5]; g = cp[6]; b = cp[7]
				}

				function get_lab() {
					rgb_to_xyz(r, g, b)
					xyz_to_lab(X, Y, Z)
					l2 = L; a2 = a; b2 = b

					l = (l2 - l1) ^ 2
					a = (a2 - a1) ^ 2
					b = (b2 - b1) ^ 2
					lab = sqrt(l + a + b)
				}

				function get_color(color, second) {
					get_rgb(color)
					rgb_to_xyz(r, g, b)
					xyz_to_lab(X, Y, Z)

					min_lab = 100; max_lab = 0
					l1 = L; a1 = a; b1 = b

					#for (i=2; i<=4; i++) {
					for (i in ac) {
						if (i in ac) {
							get_rgb(ac[i])
							get_lab()
							laba[lab] = i

							if (lab > max_lab) {
								max_lab = lab
								c = ac[i]
								ci = i
							}
						}
					}

					if (second) {
						#for (li in laba) print li, laba[li]
						sal = asorti(laba, slaba)
						ci = laba[slaba[sal - 1]]
						c = ac[ci]

						delete laba
						delete slaba
					}

					delete ac[ci]
					return c
				}

			function compare_two(first, second) {
				get_rgb(first)
				rgb_to_xyz(r, g, b)
				xyz_to_lab(X, Y, Z)
				l1 = L; a1 = a; b1 = b

				get_rgb(second)
				get_lab()

				#system("~/.orw/scripts/notify.sh " lab " && sleep 2")
				return lab < 17
			}

			function get_color1() {
				mal = 0

				for (i in ac) {
					tl = al = 0
					get_rgb(ac[i])
					rgb_to_xyz(r, g, b)
					xyz_to_lab(X, Y, Z)
					l1 = L; a1 = a; b1 = b

					for (ai in aac) {
						if (ai < 5) {
							get_rgb(aac[ai])
							get_lab()
							tl += lab
						}
					}

					al = tl / length(aac)

					if (al > mal) {
						mal = al
						c = ac[i]
						ci = i
					}

					#print ac[i], al, mal
				}

				delete ac[ci]
				return c
			}

			function get_color2(ar, del) {
				mal = 0
				c = ""

				#print "RUN"

				if (!del) {
				#for (i in ac) {
					#if (!ac[i]) continue
					tl = al = mlab = skip = 0
					#get_rgb(ac[i])
					cc = ac[i]
					cc = ar[fai - 1]
					get_rgb(cc)
					rgb_to_xyz(r, g, b)
					xyz_to_lab(X, Y, Z)
					l1 = L; a1 = a; b1 = b

					#print ac[i]

					lc = 0

					for (ai in ac) {
						if (!ar[ai]) continue
						#print "hre", i, ac[i], ai, ar[ai]

						if ((del || ai < 5) && cc != ac[ai]) {
							get_rgb(ac[ai])
							get_lab()
							tl += lab

							if (lab > mlab) {
								mlab = lab
							}

							print fai, lab, aac[fai - 2], ac[i], ar[ai]

							#if (del && lab < 15 && ! ac[i] in da) {
							if (del && lab < 11) {
								#print "HERE", ac[i], ar[ai], aac[6], lab
								#ar[ai] = aac[6]
								#da[aac[6]] = 1
								#delete aac[6]
								#delete ac[i]
								delete ac[ai]
								#print "del:", i, ac[i]
								skip = 1
								break
								#for (i in ac) print "ac:", ac[i]
							} else lc++

							#print ar[ai], lab
							#if (del) print "HERE", ac[i], ar[ai], aac[6], lab
						}
					}

					#if (skip) continue

					if (lc) {
						al = tl / lc

						#print "c:", al, mal, ac[i], ar[ai]

						#if (al > mal && !(ac[i] in sa)) {
						if (al > mal && !(ac[i] in sa)) {
							print al, mal, i, ac[i], ac[i] in sa
							mal = al
							c = ac[i]
							ci = i
						}
					}
				}

				if (lengt(del)) return
				else {
					delete ac[ci]
					#print "end", c
					sa[c] = 1
					return c
				}
			}

			function similar(c1, c2) {
				split(c1, tc1, "[;_]")
				split(c2, tc2, "[;_]")

				#print c1, tc1[5], tc1[6], tc1[7]
				#print c2, tc2[5], tc2[6], tc2[7]

				for (tci=5; tci<=7; tci++) if (sqrt((tc1[tci] - tc2[tci]) ^ 2) > 45) return 0
				#{
				#	td = sqrt((tc1[tci] - tc2[tci]) ^ 2)
				#	#print tci, tc1[tci], tc2[tci], td
				#	if (td > 45) return 0
				#}
				return 1
			}

			function get_color3(ar1, ar2, del) {
				mal = 0
				c = ""

				#print "RUN"
				#system("~/.orw/scripts/notify.sh " length(del))

				for (i in ar1) {
					#print "GEF:", length(ar1), length(ar), ar1[i]

					if (!ar1[i]) {
						delete ar1[i]
						continue
					}

					tl = al = 0 #skip = 0
					get_rgb(ar1[i])
					rgb_to_xyz(r, g, b)
					xyz_to_lab(X, Y, Z)
					l1 = L; a1 = a; b1 = b

					#print ar1[i]

					lc = 0

					for (ai in ar2) {
						if (!ar2[ai]) continue
						#print "hre", i, ar1[i], ai, ar2[ai]

						if ((del || ai < 5) && ar1[i] != ar2[ai]) {
							#if (!del) ai = fai - 1

							get_rgb(ar2[ai])
							get_lab()
							tl += lab

							#if (fai == 2) slab = lab
							#if (fai == 2) { slab += lab; scc++ }
							#if (fai == 2) print lab, ar1[i], ar2[ai]

							if (del && ! dl[lab]) { dl[lab] = 1; avl += lab }
							#if (del && ! dl[lab]) { dl[lab] = 1; avl += lab; print lab, ar1[i], ar2[ai] }


							if (lab < mlab) mlab = lab
							#if (del) continue

							#if (del) print lab, ds, ar1[i], ar2[ai], dl[lab], (lab in dl)

							#ds = 13
							#ds = 14

							#if (del && lab < 15 && ! ar1[i] in da) {
							#if (del && lab < 11) {

							if (!del && similar(ar1[i], ar2[ai]) && !(ar1[i] in sc)) sc[ar1[i]] = length(aac)

							#if (del && similar(ar1[i], ar2[ai])) {
							if (del && int(lab) <= ds && length(rac) < 2) {
								#print "HERE", i, ar1[i], ai, ar2[ai], aac[6], lab, ds, length(ac), length(aac)
								#ar2[ai] = aac[6]
								#da[aac[6]] = 1
								#delete aac[6]
								#delete ar1[i]
								split(ar1[i], acp, ";")
								split(ar2[ai], arp, ";")

								#delete ar2[ai]
								#system("~/.orw/scripts/notify.sh " ar2[(acp[3] > arp[3] && ai > 1) ? ai : i])
								#delete ar2[(acp[3] > arp[3] && ai > 1) ? ai : i]

								#di = (acp[3] < arp[3]) ? ai : i

								#print "SIM:", ar1[i], ar2[ai], similar(ar1[i], ar2[ai])

									#print "REPLACE: ", (acp[4] < arp[4]) ? ar1[i] : ar2[ai]
									#print "RPC: ", ar1[1]
									#print "DELETE: " lab, ar1[i], ar2[ai], (acp[3] < arp[3]) #? ai : i

								#if (i == 1) {
								#	aac[1] = (acp[4] < arp[4]) ? ar1[i] : ar2[ai]
								#	delete ar1[i]
								#	delete ar2[ai]
								#} else delete ar2[(acp[3] < arp[3]) ? ai : i]

								#delete ar2[(acp[3] > arp[3] && ai > 1) ? ai : i]
								#delete ar2[(acp[4] > arp[4] && ai > 1) ? ai : i]
								#delete ar2[(acp[3] > arp[3] && ai > 1) ? ai : i]

								#delete ar2[(acp[1] > arp[1] && ai > 1) ? ai : i]
								adi = ((acp[1] > arp[1] ||
									(acp[1] == arp[1] && acp[4] > arp[4])) && ai > 1) ? ai : i
								rac = ar2[adi]
								delete ar2[adi]

								#if (ar1[i] ~ "^71.*") print acp[1], arp[1], acp[4], arp[4]

								#system("~/.orw/scripts/notify.sh " ar2[(acp[4] > arp[4] && ai > 1) ? ai : i])

								#if (acp[3] < arp[3]) {
								#	if (i == 1) ar1[1] = ar2[ai]
								#	else delete
								#}

								#for (zi in ar2) print zi, ar2[zi]

								#print "del:", i, ar1[i]
								#skip = 1
								break
								#for (i in ar1) print "ar1:", ar1[i]
							} else lc++

							#print ar2[ai], lab
							#if (del) print "HERE", ar1[i], ar2[ai], aac[6], lab
						}

						#if (del) for (l in dl) print ar1[i], ar2[ai], l, dl[l]
					}

					#print length(ar1), length(ar2) #, ar1[i], ar2[ai]
					#if (del) continue
					#if (skip) continue

					#if (del) system("~/.orw/scripts/notify.sh " tl / lc)

					#if (del) print avl, length(dl)

					if (lc) {
						al = tl / lc

						#split(ar1[i], acp, "[;_]")
						#al = ((tl / lc) + acp[1]) / 2

						#print "c:", al, mal, ar1[i], ar2[ai]

						if (al > mal && !(ar1[i] in sa)) {
							#print al, mal, i, ar1[i], ar1[i] in sa
							#if (fai == 2) print al, tl, lc, mal, i, ar1[i], ar1[i] in sa
							if (fai == 2) slab = al
							if (fai == 2) slab = tl
							if (fai == 2) {
								split(ar1[i], acp, "[;_]")
								sb = acp[4]
								ss = acp[3]
								ssv = acp[1] / 2
							}
							mal = al
							c = ar1[i]
							ci = i
						}
					}

					#print "END: " length(ar1), length(ar2) #, ar1[i], ar2[ai]
					#for (z in ar1) print z, ar1[z]
				}

				#print "FINAL: " length(ar1), length(ar2)
				#for (z in ar1) print z, ar1[z]

				#if (del) for (l in dl) print "sola", l, dl[l], length(dl), avl

				if (length(del)) return
				else {
					delete ar1[ci]
					#print "end", c

					if (la && fai == 2 && !skipped) {
						#for (a in aac) print a, aac[a]
						scc = length(ar2)
						#if (int(la) < 35 || int(la) > 40) scc++
						if (la < 35 || la > 40) scc++
						#if (la < 35) scc++
						z = slab / scc
						#print "SKIP", c, slab, 1.7 * la, scc, la, sprintf("%.0f", slab / scc), int(la), 1.5 * z, 1.7 * z, sb
						#print "SKIP", c, slab, la, sb, ss, ssv


						get_rgb(c)
						rgb_to_xyz(r, g, b)
						xyz_to_lab(X, Y, Z)
						l1 = L; a1 = a; b1 = b
						#print c


						get_rgb(acc[2])
						get_lab()

						#slab = 0
						#slab = lab
						#print slab

						for (a in ar1) {
							cc = ar1[a]

							get_rgb(ar1[a])
							get_lab()

							slab += lab
							#print "HERE", lab, c, cc

							#rgb_to_xyz(r, g, b)
							#xyz_to_lab(X, Y, Z)
							#l1 = L; a1 = a; b1 = b
							#get_rgb(ar2[ai])
							#get_lab()
							#tl += lab
						}

						scc = (la < 33) ? 5 : (slab > 170) ? 3 : 4
						scc = (la < 33) ? 5 : (slab > 180) ? 3 : 4
						#print slab, slab / scc, la, sqrt(int(slab / scc - la) ^ 2) #< 5
						scc = (la < 33 || slab > 220) ? 5 : (slab > 180 || slab < 150) ? 3 : 4



						scc = (la < 33 || slab > 230) ? 5 : (slab > 180 || slab < 150) ? 3 : 4
						scc = (la < 33 || slab > 240) ? 5 : (slab > 180) ? 3 : 4
						scc = (la < 33 || slab > 240) ? 5 : (slab > 155) ? 3 : 4
						#NEW ONE
						scc = (la < 33 || slab > 240 && slab < 300) ? 5 : (slab > 155) ? 3 : 4
						#scc = 3

						#scc = ((la < 33 && la >= 30) || slab > 240) ? 5 : (slab > 180 || slab < 140) ? 3 : 4
						#print slab, scc, slab / scc, la, sqrt((int(slab / scc) - int(la)) ^ 2) #< 5

						#new
						range = (slab > 120) ? 7 : 5

						#skipped = 1
						#return

						#system("~/.orw/scripts/notify.sh " sqrt((int(slab / scc) - int(la)) ^ 2))
						#aslab = sprintf("%.0f", slab / scc)
						#print  sqrt((aslab - int(la)) ^ 2) #< 5
						#if (sqrt((aslab - int(la)) ^ 2) < 5) {
						if (sqrt((int(slab / scc) - int(la)) ^ 2) < range) {
						#if (sprintf("%.0f", slab / scc) >= int(la)) {
						#if (slab / ++scc < la) {
							#print "SKIPPED", c
							#system("~/.orw/scripts/notify.sh " sqrt((int(slab / scc) - int(la)) ^ 2))
							skipped = 1
							if (length(ac) < 3) sac = c
							#sac = c
							return
						}
					}

					sa[c] = 1
					#print "HERE", c
					return c
				}
			}

			function get_next_color(ar) {
				c = ""

				cmlab = 0
				cc = aac[(fai) ? fai - 1: 1]
				get_rgb(cc)
				rgb_to_xyz(r, g, b)
				xyz_to_lab(X, Y, Z)
				l1 = L; a1 = a; b1 = b

				for (i in ar) {
					get_rgb(ar[i])
					get_lab()

					#print lab, cc, ar[i]

					if (lab > cmlab) {
						cmlab = lab
						c = ar[i]
						ci = i
					}
				}

				delete ac[ci]
				sa[c] = 1
				return c
			}

			#{ ac[NR] = $0 }
			{
				#if (/196/) next
				#if ("'"$skip"'" && NR == 3 + '${skip:-0}') next

				get_rgb($0)
				trgb = r + g + b
				rgbd = (sqrt((r - g) ^ 2) + sqrt((g - b) ^ 2)) / 2
				if ('${#light_accent_colors[*]}' >= 6 &&
					trgb / 3 > 195 && rgbd < 10) {
						bac[++bai] = $0
						next
				}

				ac[NR] = $0
				sub(";.*", "", $1)
				tsv += $1
			}

			END {
				ds = 11
				ds = sprintf("%.0f", (tsv / 6) / 10)
				ds = int((tsv / 6) / 10) + 3
				ds = int((tsv / 6) / 10) + '$average_hue'
				ds = int((tsv / 6) / 10) + 3
				#ds = 21
				#ds = 16
				#print ds

				aac[1] = ac[1]
				#aac[5] = ac[2]
				#aac[6] = ac[3]

				#delete ac[2]
				#delete ac[3]

				sa[aac[1]] = 1
				#sa[aac[5]] = 1
				#sa[aac[6]] = 1

				dc = 2
				for (di=2; di < dc + 2; di++) {
					dac[di - 1] = ac[di]
					sa[ac[di]] = 1
					delete ac[di]
				}

				ods = ds
				#ds *= 1.2
				#get_color3(dac, dac, length(dac) > 2)
				ds = ods

				for (di in dac) aac[4 + ++daci] = dac[di]

				#for (i in aac) print aac[i]

				#aac[5] = ac[3]
				#delete ac[3]
				#aac[5] = ac[length(ac)]
				#delete ac[length(ac)]

				#print get_color1()
				#print get_color1()
				#exit

				#aac[2] = get_color1()
				#aac[4] = get_color1()
				#aac[3] = get_color1()

				#if('${accent_count:-0}' > 6) get_color1()
				#for (fai=2; fai<5; fai++) aac[fai] = get_color1()

				tc = '${accent_count:-0}'

				mlab = 100
				get_color3(ac, ac, tc > 5)
				delete ac[1]
				#print mlab
				#for (i in ac) print ac[i]
				#print length(ac)
				#exit

				#for (a in ac) print la, a, ac[a]

				acl = length(ac)
				bacl = length(bac)

				if (acl < 3 && bacl) {
					for (bai=1; bai < 4 - acl; bai++) ac[bai] = bac[bai]
				}

				#for (a in ac) print la, a, ac[a]
				#exit

				#print(get_next_color(ac))
				#for (fai=2; fai<5; fai++) aac[fai] = get_next_color(ac)
				#for (ai=1; ai<=6; ai++) print aac[ai]
				#exit

				#print mlab > "mlab.log"
				#system("~/.orw/scripts/notify.sh \"" ds " " mlab " " length(ac) "\"")
				#system("~/.orw/scripts/notify.sh \"" ds " " tl / lc " " length(ac) "\"")

				#if('${accent_count:-0}' > 6) get_color3(aac)
				#if ((mlab > 12 || mlab < 5) && tc > 6) get_color3(aac)
				#print ds

				#if (length(dl) && length(ac) > 3) la = avl / length(dl)
				if (length(dl) && length(ac) >= 3) la = avl / length(dl)
				#print "LA", avl, length(dl), length(ac), la

				#for (a in ac) print la, a, ac[a]
				#exit

				#if (((mlab > 12 && mlab < 99) || mlab < 5) && length(ac) > 3) get_color3(aac, 0)
				#if ((mlab > 12 || mlab < 5) && length(ac) > 3) get_color3(aac)
				#if ((mlab > tl / lc) && length(ac) > 3) get_color3(aac)
				#if (length(ac) > 3) get_color3(aac)
				#get_color3(aac)

				#if ((mlab > 12 && mlab < 25 || mlab < 5) && '${accent_count:-0}' > 6) get_color3(aac)
				#get_color3(aac)





				#for (fai=2; fai<5; fai++) aac[fai] = get_color3(aac, 0)
				for (fai=2; fai<5; fai++) {
					if (length(ac)) {
						do {
							tac[1] = aac[fai - 1]
							cc = get_color3(ac, tac)
							#cc = get_color3(ac, aac)
						} while (!cc)
						aac[fai] = cc

						if (sac) {
							ac[length(ac)] = sac
							sac = ""
						}
					}
				}

				for (ai=1; ai<=6; ai++) print aac[ai]
				exit




				lac = aac[1]
				for (fai=2; fai<5; fai++) {
					get_rgb(lac)
					rgb_to_xyz(r, g, b)
					xyz_to_lab(X, Y, Z)
					l1 = L; a1 = a; b1 = b

					mlab = 0

					for (rac in ac) {
						if (length(ac[rac])) {
							get_rgb(ac[rac])
							get_lab()

							if (lab > mlab) {
								mlab = lab
								ri = rac
							}
						}
					}

					if (mlab) {
						#print "HERE", mlab, lac, ac[ri]
						aac[fai] = ac[ri]
						lac = aac[fai]
						delete ac[ri]
					}
				}

				for (ai in aac) print aac[ai]
				#for (ai=1; ai<=6; ai++) print aac[ai]
				exit





				#for (fai=2; fai<5; fai++) aac[fai] = get_color3(aac, 0)
				for (fai=2; fai<5; fai++) {
					if (length(ac)) {
						do
							cc = get_color3(aac)
						while (!cc)
						aac[fai] = cc
					}
				}

				#aac[3] = aac[6]

				#system("~/.orw/scripts/notify.sh " length(sc[sci]))

				#for (sci in sc) {
				#	aac[sc[sci]] = aac[6]
				#	aac[6] = sci
				#	break
				#}


				#for (fai=2; fai<6; fai++) {
				#	c = get_color1()
				#	if (fai == 2) continue
				#	aac[fai] = c
				#}

				#ts = compare_two(aac[2], aac[4])

				if (ts) {
					aac[2] = aac[4]
					aac[4] = aac[6]
				}

				#ac[1] = aac[4]
				#get_color(aac[2])
				#max_lab=20

				#if (max_lab < 15) {
				#	aac[4] = aac[2]
				#	aac[2] = aac[6]
				#}

				for (ai=1; ai<=6; ai++) print aac[ai]
				exit

				#aac[6] = ac[5]
				#aac[5] = ac[6]
				#delete ac[6]
				#delete ac[1]
				#delete ac[5]

				#aac[2] = get_color(aac[1])
				#ac[5] = aac[5]
				#aac[3] = get_color(aac[1])
				#aac[4] = get_color(aac[6])
				#aac[5] = get_color(aac[6])
				##aac[4] = get_color(aac[5])

				#aac[2] = get_color(aac[1])
				#ac[5] = aac[5]
				#aac[3] = get_color(aac[1])
				#aac[4] = get_color(aac[6])
				#aac[5] = get_color(aac[6])

				#aac[2] = get_color(aac[1])
				#ac[5] = aac[5]
				#aac[3] = get_color(aac[2])
				#aac[5] = get_color(aac[6])
				#aac[4] = get_color(aac[6])

				#aac[2] = get_color(aac[1])
				#aac[4] = get_color(aac[5])
				#aac[3] = get_color(aac[2])

				aac[2] = get_color(aac[1])

				#ac[1] = aac[6]
				#delete aac[6]
				
				#for (a in ac) print a, ac[a]

				#ac[6] = aac[5]
				#delete aac[5]
				##c = ac[4]
				##delete ac
				##ac[1] = c
				#aac[3] = get_color(aac[2])
				#aac[5] = get_color(aac[3])
				#aac[4] = get_color(aac[6])
				aac[3] = get_color(aac[2])
				#aac[4] = get_color(aac[3])
				aac[4] = (length(ac)) ? get_color(aac[3]) : aac[6]
				#aac[5] = get_color(aac[2])
				#aac[6] = get_color(aac[2])
				#aac[2] = aac[6]

				ac[1] = aac[4]
				get_color(aac[2])
				max_lab=20

				if (max_lab < 15) {
					#aac[4] = aac[5]
					aac[4] = aac[2]
					aac[2] = aac[6]
					#ac4 = aac[4]
					#aac[4] = aac[3]
					#aac[3] = ac4
					#ac3 = aac[3]
					#aac[3] = aac[5]
					#aac[5] = ac3
				}

				#aac[1] = ac[1]
				#aac[6] = ac[6]
				#aac[5] = ac[5]
				##aac[6] = ac[6]
				##delete ac[6]
				#delete ac[1]
				#delete ac[6]
				#delete ac[5]

				#aac[2] = get_color(aac[1])
				##aac[4] = get_color(aac[5])
				##aac[3] = get_color(aac[4])
				#aac[3] = get_color(aac[4])
				##aac[4] = get_color(aac[5])
				#for (i=2; i<=6; i++) if (i in ac) aac[4] = ac[i]

				for (ai=1; ai<=6; ai++) print aac[ai]
				exit


				##for (i in ac) print i, ac[i]
				##	exit
				#aac[1] = ac[1]
				#aac[6] = ac[2]
				##aac[5] = ac[5]
				##aac[6] = ac[6]
				##delete ac[6]
				#delete ac[1]
				#delete ac[2]
				##delete ac[5]

				#aac[2] = get_color(aac[1])
				#aac[3] = get_color(aac[2])
				#aac[5] = get_color(aac[6])
				#aac[4] = get_color(aac[5])
				##for (i=2; i<=6; i++) if (i in ac) aac[6] = ac[i]


				#aac[1] = ac[1]
				#aac[6] = ac[6]
				##aac[6] = ac[6]
				#delete ac[6]
				#delete ac[1]
				##delete ac[5]

				#aac[2] = get_color(aac[1])
				#aac[4] = get_color(aac[6])
				#aac[3] = get_color(aac[4])

				##aac[2] = get_color(aac[1])
				##aac[3] = get_color(aac[2])
				###aac[4] = get_color(aac[3])
				##for (i=2; i<=5; i++) if (i in ac) aac[4] = ac[i]
				#for (i=2; i<=5; i++) if (i in ac) aac[5] = ac[i]


				#aac[2] = get_color(aac[1])
				#aac[3] = get_color(aac[2])
				##aac[4] = get_color(aac[3])
				#for (i=2; i<=5; i++) if (i in ac) aac[4] = ac[i]
				#for (i=2; i<=6; i++) if (i in ac) aac[6] = ac[i]

				#aac[1] = ac[1]
				#aac[6] = ac[5]
				#delete ac[1]
				#delete ac[5]
				##aac[6] = ac[6]

				#aac[2] = get_color(aac[1])
				#aac[4] = get_color(aac[2])
				#aac[3] = get_color(aac[4])
				#for (i=2; i<=6; i++) if (i in ac) aac[5] = ac[i]

				for (ai=1; ai<=6; ai++) print aac[ai]
			}'
	}

	#ac=( $(tr ' ' '\n' <<< ${light_accent_colors[*]} |
	#	awk -F '[;_]' '{
	#			ac[$5 + $6 + $7] = $0
	#			#ac[$0] = $5 + $6 + $7
	#		} END {
	#				#asort(ac)
	#				for (a in ac) print a, ac[a]
	#			}' | sort -nrk 1,1 | cut -d ' ' -f 2) )

	#for a in ${ac[*]}; do
	#	print_color $a label
	#done
	#exit

	accents=( $(tr ' ' '\n' <<< "${final_accents[*]}" |
		awk -F ';' '{ print $2 + $3 ";" $0 }') )

	#while read c; do
	#done <<< $(awk -F ';' '{ print $2 + $3 ";" $0 }' <<< "${final_accents[*]}")

	#echo here
	#for a in ${accents[*]}; do
	#	print_color $a label
	#done
	#exit

	#sort_accents
	#exit

	#echo
	#while read color; do
	#	print_color $color label
	#done <<< $(sort_accents)
	#exit


	#accent_colors=(
	#		$(tr ' ' '\n' <<< ${light_accent_colors[*]} | sort -t ';' -nrk 4,4)
	#	)
	#
	#accent_colors=(
	#		$(tr ' ' '\n' <<< ${light_accent_colors[*]} | sort -t ';' -nrk 4,4 |
	#			awk -F ';' '
	#				$1 > msv || ($1 == msv && $3 > ms) {
	#					ms = $3
	#					msv = $1
	#					mnr = NR
	#				} { ac[NR] = $0 }
	#				END {
	#					print ac[mnr]
	#					delete ac[mnr]
	#					for(ci in ac) print ac[ci]
	#				}')
	#	)


	#tr ' ' '\n' <<< ${light_accent_colors[*]} | sort -t ';' -nrk 4,4 |
	#	awk -F ';' '
	#		$1 > msv || ($1 == msv && $4 > mv) {
	#			mv = $4
	#			msv = $1
	#			mnr = NR
	#		} { ac[NR] = $0 }
	#		END {
	#			print ac[mnr]
	#			delete ac[mnr]
	#			for(ci in ac) print ac[ci]
	#			}'
	#exit

	get_accent_difference() {
		local referent_accent=$2
		#tr ' ' '\n' <<< ${light_accent_colors[*]::${2:-4}} | awk -F '[;_]' '
		tr ' ' '\n' <<< "$1" | awk -F '[;_]' '
				function rgb_to_xyz(r, g, b) {
					R = r / 255
					G = g / 255
					B = b / 255

					R = (R > 0.04045) ? ((R + 0.055) / 1.055) ^ 2.4 : R / 12.92
					G = (G > 0.04045) ? ((G + 0.055) / 1.055) ^ 2.4 : G / 12.92
					B = (B > 0.04045) ? ((B + 0.055) / 1.055) ^ 2.4 : B / 12.92

					R *= 100
					G *= 100
					B *= 100

					X = R * 0.4124 + G * 0.3576 + B * 0.1805
					Y = R * 0.2126 + G * 0.7152 + B * 0.0722
					Z = R * 0.0193 + G * 0.1192 + B * 0.9505
				}

				function xyz_to_lab(x, y, z) {
					refx =  95.047
					refy = 100.000
					refz = 108.883

					X = x / refx
					Y = y / refy
					Z = z / refz

					X = (X > 0.008856) ? X ^ (1 / 3) : (7.787 * X) + (16 / 116)
					Y = (Y > 0.008856) ? Y ^ (1 / 3) : (7.787 * Y) + (16 / 116)
					Z = (Z > 0.008856) ? Z ^ (1 / 3) : (7.787 * Z) + (16 / 116)

					L = 116 * Y - 16
					a = 500 * (X - Y)
					b = 200 * (Y - Z)
				}

				BEGIN {
					split("'$referent_accent'", mvap)
					rah = mvap[2]; rar = mvap[5]; rag = mvap[6]; rab = mvap[7]

					rgb_to_xyz(rar, rag, rab)
					xyz_to_lab(X, Y, Z)
					l1 = L; a1 = a; b1 = b
				}

				function abs(n) {
					return sqrt(n ^ 2)
				}

				!/'$referent_accent'/ {
					#print r, g, b
					#print pr, pg, pb

					split($0, cap)
					cr = cap[5]; cg = cap[6]; cb = cap[7]

					#print rar, rag, rab
					#print cr, cg, cb

					rgb_to_xyz(cr, cg, cb)
					xyz_to_lab(X, Y, Z)
					l2 = L; a2 = a; b2 = b

					l = (l2 - l1) ^ 2
					a = (a2 - a1) ^ 2
					b = (b2 - b1) ^ 2

					cd = sqrt(l + a + b)

					#print cd, $0
					ba[NR] = cd " " $0

					if(NR == 1) { d1 = cd; h1 = $2 }
					else { d2 = cd; h2 = $2 }
				} END {
					dd = abs(d1 - d2)
					maxd = (d1 > d2) ? d1 : d2

					if(dd < 3) {
						sub("[^ ]*", abs(rah - h1), ba[1])
						sub("[^ ]*", abs(rah - h2), ba[2])
					#} else if(maxd > '$avg_value') r = "r"
					} else if(abs(maxd - '$avg_value') < 5) r = "r"
					else r = "r"

					#if(dd < 3) {
					#	sub("[^ ]*", abs(rah - h1), ba[1])
					#	sub("[^ ]*", abs(rah - h2), ba[2])
					#} else {
					#	r = "r"
					#	max = (d1 > d2) ? d1 : d2
					#	if(max < 65) r = ""
					#}

					print ba[1] "\n" ba[2] | "sort -n" r "k 1,1"
				}' | grep -o '[^ ]*$'
				#}' | sort -nrk 1,1 #| grep -o '[^ ]*$'
				#}' | sort -nrk 1,1 | grep -o '[^ ]*$' | head -1
	}

	#unset light_accent_colors
	#set_accent "${final[*]}"
	#accent_colors=( ${light_accent_colors[*]} )

	#get_accent_difference "${accent_colors[*]:2:2}" $accent_colors[0] | xargs
	#exit
	read a3 a4 <<< $(get_accent_difference "${accent_colors[*]:2:2}" $accent_colors[0] | xargs)
	#get_accent_difference "${accent_colors[*]:2:2}" $accent_colors[0] | xargs
	#exit
	accent_colors[2]=$a3
	accent_colors[3]=$a4

	#read a2 a3 <<< $(get_accent_difference "${accent_colors[*]:1:2}" $accent_colors[0] | xargs)
	#accent_colors[1]=$a2
	#accent_colors[2]=$a3

	#read a2 a3 a4 <<< $(get_accent_difference "${accent_colors[*]:1:3}" $accent_colors[0] | xargs)
	#accent_colors[1]=$a2
	#accent_colors[2]=$a3
	#accent_colors[3]=$a4









	#for accent in ${accent_colors[*]}; do
	#	print_color $accent label
	#done
	#exit


	#accent_colors=(
	#		$(tr ' ' '\n' <<< ${light_accent_colors[*]} | sort -t ';' -nrk 4,4 |
	#			awk -F ';' '
	#				$1 > msv || ($1 == msv && $3 > ms) {
	#					ms = $3
	#					msv = $1
	#					mnr = NR
	#				} { ac[NR] = $0 }
	#				END {
	#					print ac[mnr]
	#					delete ac[mnr]
	#					for(ci in ac) print ac[ci]
	#				}')
	#	)

	accent_colors=( $(sort_accents) )
	#echo ${#accent_colors[*]}

	if [[ $reverse_last ]]; then
		swap_accent=${accent_colors[-1]}
		accent_colors[-1]=${accent_colors[-2]}
		accent_colors[-2]=$swap_accent
	fi

	if ((${#accent_colors[*]} < 6)); then
		a3=${accent_colors[-2]}
		accent_colors[-2]=${accent_colors[2]}
		accent_colors[2]=$a3
		echo SWAP
	fi

	#for color in ${accent_colors[*]}; do
	#	print_color $color label
	#done

	#exit

	#
	#while read color; do
	#	print_color $color label
	#done <<< $(sort_accents)
	#exit

	#[[ $2 == -s ]] &&
	#	accent_colors=( ${accent_colors[*]::4} ${accent_colors[ -1]} ${accent_colors[ -2]} )

	((${#accent_colors[*]} == 5)) && accent_colors+=( $dbg )

	#accent_colors=( ${accent_colors[1]} ${accent_colors[0]} ${accent_colors[*]:2} )

	read {rgb,hex}_a{1..6} <<< \
		$(tr ' ' '\n' <<< "${accent_colors[*]}" |
			awk -F '_' '{ rgb = rgb " " $(NF - 1); hex = hex " " $NF }
						END { print rgb, hex }')

	if ((${#accent_colors[*]} < 6)); then
		for accent in ${light_accents[*]}; do
			print_color $accent label
		done
		echo "not enough colors, exiting.." && exit
	fi
fi

for color in rgb_{fg,{,s,p}bg} ${!rgb_a*}; do
	printf '%-8s' $color
	print_color "0_${!color}_0" label
done
#exit

#hex_sbgi=sola
#var=hex_sbg
#eval "read color index <<< \${!$var*}"
#echo ${!color} ${!index}
#exit

read ccc hex_{sbgi,pbgi,pfgi,a1i} <<< \
	$(awk -i inplace '
		{
			if($2 == "'$hex_sbg'") sbgi = NR
			else if($2 == "'$hex_pbg'") pbgi = NR
			else if($2 == "'$hex_pfg'") pfgi = NR
			else if($2 == "'$hex_a1'") a1i = NR
			else {
				if($1 ~ /^sbg[0-9]*$/) sbgc++
				else if($1 ~ /^pbg[0-9]*$/) pbgc++
				else if($1 ~ /^pfg[0-9]*$/) pfgc++
				else if($1 ~ /^a1[0-9]*$/) a1c++
			}
		}

		{ print }
			
		ENDFILE {
			if(!sbgi) print "sbg" sbgc + 1 " '$hex_sbg'"
			if(!pbgi) print "pbg" pbgc + 1 " '$hex_pbg'"
			if(!pfgi) print "pfg" pfgc + 1 " '$hex_pfg'"
			if(!a1i) print "a1" a1c + 1 " '$hex_a1'"
		}

		END {
			ccc = NR

			if(!sbgi) sbgi = ++NR
			if(!pbgi) pbgi = ++NR
			if(!pfgi) pfgi = ++NR
			if(!a1i) a1i = ++NR

			print ccc, sbgi - 1, pbgi - 1, pfgi - 1, a1i - 1
		}' ~/.config/orw/colorschemes/colors)

term_conf=~/.orw/dotfiles/.config/alacritty/alacritty.yml

for color in hex_{sbg,pbg,pfg,a1}; do
	eval "read color index <<< \${!$color*}"
	#echo ${!index}, ${!color}
	((${!index} >= ccc)) &&
		new_indexed_colors+=",\n{ index: ${!index}, color: '${!color}' }"
		#sed -i "/color0/,/^$/ { /^$/ s/.*/color${!index} = ${!color}\n/ }" $term_conf
done

#awk '
#	#BEGIN { print "'"$new_indexed_colors"'" }
#	END {
#		print "'"$new_indexed_colors"'"
#		print
#	}' $term_conf
#exit

#echo -e "$new_indexed_colors"

[[ $new_indexed_colors ]] &&
	awk -i inplace '
		BEGIN { li = '$ccc' - 1 }

		$0 ~ "index: " li "," {
			nic = "'"$new_indexed_colors"'"
			p = $0
			sub("{.*", "", p)
			gsub("\n", "\n" p, nic)
			sub("$", nic)
		}

		{ print }' $term_conf #| tail -22

#exit

#read {rgb,hex}_a5_dr <<< $(get_sbg $hex_a5 -18)
#read {rgb,hex}_a5_br <<< $(get_sbg $hex_a5 +5)

((mono)) &&
	br_dr_color=$hex_fg || br_dr_color=$hex_a5

#read {rgb,hex}_a5_dr <<< $(get_sbg $br_dr_color -12)
#read {rgb,hex}_a5_dr <<< $(get_sbg $hex_pfg +20)
#read {rgb,hex}_a5_br <<< $(get_sbg $br_dr_color +10)

if ((mono)); then
	read {rgb,hex}_a5_dr <<< $(get_sbg $hex_pfg +28)
	#read {rgb,hex}_a5_dr <<< $(get_sbg $hex_fg -10)
	read {rgb,hex}_a5_br <<< $(get_sbg $br_dr_color +10)
else
	read {rgb,hex}_a5_dr <<< $(get_sbg $hex_a5 -9)
	read {rgb,hex}_a5_br <<< $(get_sbg $hex_a5  +9)
fi

set_ob() {
	#if [[ $1 ]]; then
		cat <<- EOF
			#ob
			t $hex_a5
			tb $hex_a5
			b $hex_a5
			c $hex_a5
			it $hex_sbg
			itb $hex_sbg
			ib $hex_sbg
			ic $hex_sbg
			cbt $hex_a5_br
			mabt $hex_a5_br
			mibt $hex_a5_br
			cbth $hex_a5_dr
			mabth $hex_a5_dr
			mibth $hex_a5_dr
			ibt $hex_bg
			ibth $hex_bg
			mbg $hex_sbg
			mfg $hex_sfg
			mtbg $hex_sbg
			mtfg $hex_pfg
			msbg $hex_pbg
			msfg $hex_a1
			mb $hex_sbg
			ms $hex_sbg
			bfg $hex_sbg
			bsfg $hex_pbg
			osd $hex_sbg
			osdh $hex_a1
			osdu $hex_pbg
			s $hex_a5_dr
		EOF
	#else

		awk -i inplace '
			BEGIN { split("'"$rgb_a5"'", ca, ";") }
			/shadow-(red|green|blue)/ {
				switch ($1) {
					case /red/: c = ca[1]; break
					case /green/: c = ca[2]; break
					case /blue/: c = ca[3]; break
				}

				c = sprintf("%0.f", 100 * (c / 255))
				sub("\\.[0-9]*", "." c)
			} { print }' ~/.orw/dotfiles/.config/picom/picom.conf

		awk -i inplace '
			BEGIN {
				menu = "(border|separator|bullet.image|(title|items).bg).*.color"
				#active = "(label.text|client|handle|grip|.*(title|border|.*button.(.*bg|disabled.image)).*.color"
				active = "(label.text|client|handle|grip|.*(title|border|button..*bg)).*.color"
				button = "button.*.(hover|pressed).image.color"
				osd = "osd.(bg|label|button|border).*.color"
			}

			#$1 ~ "\\.active." button { $NF = "'$hex_pfg'" }
			$1 ~ "\\.active." button { $NF = "'$hex_a5_dr'" }
			#$1 ~ "\\.active.button.*unpressed.image.color" { $NF = "'$hex_sfg'" }
			$1 ~ "\\.active.button.*unpressed.image.color" { $NF = "'$hex_a5_br'" }
			$1 ~ "\\.active.button.*dissabled.image.color" { $NF = "'$hex_pfg'" }
			$1 ~ "\\.active.button.*toggled.image.color" { $NF = "'$hex_bg'" }

			$1 ~ "inactive.button.image.color" { $NF = "'$hex_bg'" }
			$1 ~ "inactive." button { $NF = "'$hex_bg'" }

			$1 ~ "menu.*active.text.color" { $NF = "'$hex_a1'" }
			$1 ~ "menu.*active.bg.color" { $NF = "'$hex_pbg'" }
			$1 ~ "menu.title.text.color" { $NF = "'$hex_pfg'" }
			$1 ~ "menu.items.text.color" { $NF = "'$hex_sfg'" }
			$1 ~ "menu." menu { $NF = "'$hex_sbg'" }

			$1 ~ "bullet.selected.image" { $NF = "'$hex_pbg'" }

			#$1 ~ "\\.active." active { $NF = "'$hex_sbg'" }
			$1 ~ "\\.active." active { $NF = "'$hex_a5'" }
			$1 ~ "inactive." active { $NF = "'$hex_sbg'" }

			#$1 ~ "^window.active.border.color" { $NF = "'$hex_a5'" }

			$1 ~ "osd.unhilight" { $NF = "'$hex_pbg'" }
			$1 ~ "osd.hilight" { $NF = "'$hex_a1'" }
			$1 ~ osd { $NF = "'$hex_sbg'" }

			{ print }' $ob_conf

		#cd ~/Downloads/openbox
		#frame_color="0x${hex_a5_br:1:2}, 0x${hex_a5_br:3:2}, 0x${hex_a5_br:5:2}"
		#sed -i "/^\s*primary_color/ s/0x.*\w/$frame_color/" openbox/focus_cycle_indicator.c

		#{
		#	./bootstrap
		#	./configure --sysconfdir=/etc --datarootdir=/usr/share
		#	make
		#	sudo make install
		#} &> /dev/null
	#fi
}

single_bg=true

set_bar() {
	bar_conf=$(sed -n 's/^last_.*=\([^,]*\).*/\1/p' ~/.orw/scripts/barctl.sh)
	colorscheme=$(sed -n 's/\(\([^-]*\)-[^c]*\)c\s*\([^, ]*\).*/\3/p' \
		~/.config/orw/bar/configs/$bar_conf)
	#transparency=$(sed -n '/#bar/,/^$/ { s/^bg.*#\(.*\)\w\{6\}.*/\1/p }' \
	#	~/.config/orw/colorschemes/$colorscheme.ocs)

	unset single_bg transparency
	transparency=d0

	read {rgb,hex}_bar_bg <<< $(get_sbg $hex_pbg +5 1)

	[[ ! $single_bg ]] &&
		local bar_bg="#$transparency${hex_pbg#\#}" ||
		local single_hex_bg="#$transparency${hex_bg#\#}" single_hex_fg=$hex_fg
	read {rgb,hex}_abg <<< $(get_sbg $hex_bg +8)

	((mono)) && local hex_a5=$hex_fg

	#read {rgb,hex}_jpfg <<< $(get_sbg $hex_a5 +17)
	#read {rgb,hex}_jsfg <<< $(get_sbg $hex_a5 -7)
	read {rgb,hex}_bar_pfg <<< $(get_sbg $hex_fg -11 1)
	#read {rgb,hex}_bar_lpfg <<< $(get_sbg $hex_pfg +11)
	read {rgb,hex}_bar_lpfg <<< $(get_sbg $hex_a1 -30)
	read {rgb,hex}_bar_lpbg <<< $(get_sbg $hex_pbg +5)
	#read {rgb,hex}_bar_pfg <<< $(get_sbg $hex_pfg +33)

	#cat <<- EOF
	#	bg ${single_hex_bg:-#00${bar_bg#\#}}
	#	fc ${single_hex_bg:-$hex_a5}
	#	bfc ${single_hex_bg:-$hex_bg}
	#	bbg ${single_hex_bg:-$bar_bg}
	#	jbg ${single_hex_bg:-$hex_bg}
	#	jpfg ${single_hex_fg:-$hex_a5_br}
	#	jsfg ${single_hex_fg:-$hex_a5_dr}
	#	pbg ${single_hex_bg:-$hex_bg}
	#	pfg ${single_hex_fg:-$hex_bar_pfg}
	#	sbg ${single_hex_bg:-$hex_bg}
	#	sfg ${single_hex_fg:-$hex_pfg}
	#	pbefg $hex_a1
	#	pbfg $hex_pfg
	#	mlfg $hex_a4
	#	tbfg $hex_pfg
	#	Psbg $hex_sbg
	#	Psfg $hex_sfg
	#	Apfg $hex_a4
	#	Lsfg $hex_abg
	#	Lpbg $hex_sbg
	#	Lpfg $hex_pfg
	#	Labg $hex_abg
	#	Lafg $hex_bar_pfg
	#	Lfc $hex_a1
	#EOF

	bar_bg=$hex_pbg

	cat <<- EOF
		bg ${single_hex_bg:-$bar_bg}
		fc ${single_hex_bg:-$bar_bg}
		bfc ${single_hex_bg:-#$transparency${hex_bg#\#}}
		bfc $bar_bg
		bbg ${single_hex_bg:-$bar_bg}
		jbg ${single_hex_bg:-$hex_bg}
		jpfg ${single_hex_fg:-$hex_a5_br}
		jsfg ${single_hex_fg:-$hex_a5_dr}
		pbg ${single_hex_bg:-$hex_bg}
		pfg ${single_hex_fg:-$hex_bar_pfg}
		sbg ${single_hex_bg:-$hex_bg}
		sfg ${single_hex_fg:-$hex_pfg}
		pbefg $hex_a1
		pbfg $hex_pfg
		mlfg $hex_a4
		tbfg $hex_pfg
		Psbg $hex_sbg
		Psfg $hex_sfg
		Apfg $hex_bar_pfg
		Abfg $hex_a5
		Wsbg ${single_hex_bg:-$bar_bg}
		Wpbg ${single_hex_bg:-$bar_bg}
		Lsbg #$transparency${hex_bg#\#}
		Lsfg $hex_sfg
		Lpbg #$transparency${hex_bg#\#}
		Lpfg $hex_bar_lpfg
		Labg #$transparency${hex_sbg#\#}
		Labg #$transparency${hex_bg#\#}
		Lafg $hex_bar_pfg
		Lafg $hex_a1
	EOF

	#cat <<- EOF
	#	bg $hex_bg
	#	fc $hex_bg
	#	bfc $hex_bg
	#	bbg $hex_bg
	#	jbg $hex_bg
	#	jpfg ${single_hex_fg:-$hex_a5_br}
	#	jsfg ${single_hex_fg:-$hex_a5_dr}
	#	pbg $hex_sbg
	#	pfg ${single_hex_fg:-$hex_bar_pfg}
	#	sbg $hex_sbg
	#	sfg $hex_pfg
	#	pbefg $hex_a1
	#	pbfg $hex_pfg
	#	mlfg $hex_a4
	#	tbfg $hex_pfg
	#	Psbg $hex_sbg
	#	Psfg $hex_sfg
	#	Apfg $hex_bar_pfg
	#	Abfg $hex_a5
	#	Lsbg #$transparency${hex_bg#\#}
	#	Lsfg $hex_sfg
	#	Lpbg #$transparency${hex_bg#\#}
	#	Lpfg $hex_bar_lpfg
	#	Labg #$transparency${hex_sbg#\#}
	#	Labg #$transparency${hex_bg#\#}
	#	Lafg $hex_bar_pfg
	#	Lafg $hex_a1
	#EOF
}



#eval echo \${!${type:-rgb}*} | cut -d ' ' -f 1,2,3,5,11,12
#eval echo \${!${type:-rgb}*}
#eval echo \${!${type:-rgb}*} | cut -d ' ' -f 1,2,4,5,11,12

#eval echo \${!${type:-rgb}*} | cut -d ' ' -f 1,2,4,5,11,12
#exit

#eval echo \${!${type:-rgb}*} | cut -d ' ' -f 1,2,4,5,11,12
#exit

#sed -e 's/\(^\| \)/ \$/g' -e 's/ \$[^ ]*i\b//g' \
#	<<< ${!hex*} | cut -d ' ' -f 2,3,5,6,12,13,15,16
#exit

set_bash() {
	if [[ $1 ]]; then
		#local a1i_bak=$hex_a1i
		unset hex_a1i
	else
		local type=rgb
	fi

	#eval "color_string=\$(cut -d ' ' -f 1,2,4,5,9,10 <<< \${!${type:-rgb}*} |
	#eval "color_string=\$(cut -d ' ' -f 1,2,4,5,11,12,14,15 <<< \${!${type:-hex}*} |
	#	sed -e 's/\(^\| \)/ \$/g' -e 's/ \$[^ ]*i\b//g')"
	#eval "bash_colors=( $color_string )"

	eval "color_string=\$(sed -e 's/\(^\| \)/ \$/g' -e 's/ \$[^ ]*i\b//g' \
		<<< \${!${type:-hex}*} | cut -d ' ' -f 2,3,5,6,12,13,15,16)"
	eval "bash_colors=( $color_string )"
	#echo $color_string

#	echo $color_string, ${bash_colors[*]}
#	eval echo \${!hex*} | cut -d ' ' -f 1,2,4,5,11,12
#	eval echo \${!rgb*} | cut -d ' ' -f 1,2,4,5,11,12
#	eval "echo \${!hex*} |
#		sed -e 's/\(^\| \)/ \$/g' -e 's/\$[^ ]*i\b//g'"
#	eval "echo \${!rgb*} |
#		sed -e 's/\(^\| \)/ \$/g' -e 's/\b[^ ]*i\b//g'"

	#[[ $a1i_bak ]] && hex_ai1=$a1i_bak

	local bash_bg=$(awk -F '=' '/^\s*mode/ {
			print ($2 == "rice") ? "'"${bash_colors[4]}"'" : "default"
		}' ~/.bashrc)

	cat <<- EOF
		bg=\"$bash_bg\"
		fg=\"${bash_colors[5]}\"
		sc=\"${bash_colors[5]}\"
		dc=\"${bash_colors[5]}\"
		ic=\"${bash_colors[1]}\"
		sec=\"${bash_colors[3]}\"
		gcc=\"${bash_colors[3]}\"
		gdc=\"${bash_colors[0]}\"
		vc=\"${bash_colors[2]}\"
	EOF
}

#hex_rofi_bg=$hex_sbg

set_rofi() {
	local {rgb,hex}_rofi_{s,a,}bg
	read {rgb,hex}_rofi_bg <<< $(get_sbg $hex_bg +3 0)
	#read {rgb,hex}_rofi_sbg <<< $(get_sbg $hex_sbg +3 0)
	read {rgb,hex}_rofi_abg <<< $(get_sbg $hex_sbg -5)
	read {rgb,hex}_rofi_hpfg <<< $(get_sbg $hex_pbg +15)
	read {rgb,hex}_rofi_pbg <<< $(get_sbg $hex_rofi_bg +5 0)

	#hex_rofi_bg=$hex_bg

	#echo $hex_rofi_abg, $hex_rofi_sbg, $hex_bg, $hex_sbg

	cat <<- EOF
		bg: $hex_rofi_bg;
		dmbg: $hex_sbg;
		dmfg: $hex_pfg;
		dmsbg: $hex_pbg;
		hpfg: $hex_rofi_hpfg;
		tbg: argb:f0${hex_rofi_bg#\#};
		tbg: argb:ea${hex_rofi_bg#\#};
		tbg: argb:dd${hex_rofi_bg#\#};
		mbg: argb:f0${hex_bg#\#};
		msbg: argb:70${hex_rofi_pbg#\#};
		fg: $hex_sfg;
		bc: $hex_a5;
		bc: $hex_rofi_bg;
		ibg: $hex_rofi_bg;
		ibc: $hex_pbg;
		ibc: $hex_rofi_bg;
		abg: #08080855;
		abg: #08080866;
		abg: #08080844;
		abg: ${hex_rofi_abg}b0;
		abg: ${hex_rofi_abg}dd;
		afg: $hex_pfg;
		ebg: $hex_rofi_bg;
		efg: $hex_a1;
		sbg: #e0e0e00e;
		sbg: #fafafa0a;
		sbg: #eeeeee0a;
		sbg: #cccccc0a;
		sbg: #dddddd0d;
		sbg: ${hex_rofi_pbg}b0;
		sbg: ${hex_rofi_pbg}d0;
		sfg: $hex_a1;
		sul: $hex_a1;
		lpc: $hex_fg;
		dpc: $hex_fg;
		btc: $hex_rofi_bg;
		sbtc: $hex_rofi_bg;
		btbc: $hex_rofi_bg;
		ftbg: #00000000;
		sbbg: ${hex_a1}88;
		sbsbg: #11111144;
	EOF

	#cat <<- EOF
	#	bg: $hex_sbg;
	#	tbg: argb:00${hex_sbg#\#};
	#	mbg: argb:f0${hex_bg#\#};
	#	msbg: argb:70${hex_pbg#\#};
	#	fg: $hex_sfg;
	#	bc: $hex_a5;
	#	ibg: $hex_sbg;
	#	ibc: $hex_pbg;
	#	abg: $hex_bg;
	#	afg: $hex_pfg;
	#	ebg: $hex_sbg;
	#	efg: $hex_a1;
	#	sbg: $hex_pbg;
	#	sfg: $hex_a1;
	#	sul: $hex_a1;
	#	lpc: $hex_fg;
	#	dpc: $hex_fg;
	#	btc: $hex_sbg;
	#	sbtc: $hex_sbg;
	#	btbc: $hex_sbg;
	#EOF
}

#echo ${final_accents[2]}, ${colors[${final_accents[2]}]}
#echo ${final_accents[3]}, ${colors[${final_accents[3]}]}
#
#a3_frequency=${colors[${final_accents[2]}]}
#a4_frequency=${colors[${final_accents[3]}]}
##echo $a3_frequency, $a4_frequency
##a2_frequency=${colors[${final_accents[1]}]}
##echo $a4_frequency, $a2_frequency
#
#((a3_frequency > a4_frequency + 5)) &&
#	vfg=$hex_a3 ifg=$hex_a4 ||
#	vfg=$hex_a4 ifg=$hex_a3

set_vim() {
	cat <<- EOF
		let g:bg = 'none'
		let g:fg = '$hex_vim_fg'
		let g:ifg = '$hex_a4'
		let g:vfg = '$hex_a2'
		let g:cfg = '$hex_a3'
		let g:ffg = '$hex_a5'
		let g:sfg = '$hex_a1'
		let g:nbg = 'none'
		let g:nfg = '$hex_pbg'
		let g:lbg = '$hex_sbg'
		let g:lfg = '$hex_a1'
		let g:syfg = '$hex_a3'
		let g:cmfg = '$hex_sfg'
		let g:slbg = '$hex_sbg'
		let g:slfg = '$hex_sfg'
		let g:fzfhl = '$hex_a1'
		let g:bcbg = '$hex_a5'
		let g:bdbg = '$hex_a1'
		let g:nmbg = '$hex_a4'
		let g:imbg = '$hex_a2'
		let g:vmbg = '$hex_a3'
	EOF
}


#set_vim() {
#	cat <<- EOF
#		let g:bg = 'none'
#		let g:fg = '$hex_vim_fg'
#		let g:ifg = '$hex_a4'
#		let g:vfg = '$hex_a3'
#		let g:cfg = '$hex_a2'
#		let g:ffg = '$hex_a5'
#		let g:sfg = '$hex_a1'
#		let g:nbg = 'none'
#		let g:nfg = '$hex_pbg'
#		let g:lbg = '$hex_sbg'
#		let g:lfg = '$hex_a1'
#		let g:syfg = '$hex_a2'
#		let g:cmfg = '$hex_sfg'
#		let g:slbg = '$hex_sbg'
#		let g:slfg = '$hex_sfg'
#		let g:fzfhl = '$hex_a1'
#		let g:bcbg = '$hex_a6'
#		let g:bdbg = '$hex_a1'
#		let g:nmbg = '$hex_a2'
#		let g:imbg = '$hex_a5'
#		let g:vmbg = '$hex_a6'
#	EOF
#}

#set_vim() {
#	cat <<- EOF
#		let g:bg = 'none'
#		let g:fg = '$hex_vim_fg'
#		let g:ifg = '$hex_a4'
#		let g:vfg = '$hex_a2'
#		let g:cfg = '$hex_a5'
#		let g:ffg = '$hex_a3'
#		let g:sfg = '$hex_a1'
#		let g:nbg = 'none'
#		let g:nfg = '$hex_sbg'
#		let g:lbg = '$hex_sbg'
#		let g:lfg = '$hex_a1'
#		let g:syfg = '$hex_a5'
#		let g:cmfg = '$hex_pbg'
#		let g:slbg = '$hex_sbg'
#		let g:slfg = '$hex_sfg'
#		let g:fzfhl = '$hex_a1'
#		let g:bcbg = '$hex_a6'
#		let g:bdbg = '$hex_a1'
#		let g:nmbg = '$hex_a5'
#		let g:imbg = '$hex_a5'
#		let g:vmbg = '$hex_a6'
#	EOF
#}

set_tmux() {
	cat <<- EOF
		bg='terminal'
		fg='$hex_sfg'
		bc='$hex_sbg'
		mc='$hex_a5'
		ibg='$hex_sbg'
		ifg='$hex_sfg'
		sfg='$hex_sfg'
		wbg='$hex_sbg'
		wfg='$hex_sfg'
		cbg='$hex_pbg'
		cfg='$hex_a1'
	EOF
}

set_dunst() {
	cat <<- EOF
		background = \"$hex_sbg\"
		foreground = \"$hex_fg\"
		frame_color = \"$hex_a5\"
	EOF
}

set_dunst_custom() {
	cat <<- EOF
		sbg=\"$hex_bg\"
		pbfg=\"$hex_a1\"
	EOF
}

set_nb() {
	if [[ $1 ]]; then
		cat <<- EOF
			fg $hex_pbg
			pfg $hex_sbg
			pbg default
			ifg $hex_pfg
			ibg $hex_pbg
		EOF
	else
		cat <<- EOF
			color listnormal color${hex_pbgi} default
			color listfocus color${hex_pfgi} color${hex_sbgi}
			color listnormal_unread color${hex_pfgi} default
			color listfocus_unread color${hex_a1i} color${hex_sbgi}
			color info color${hex_pfgi} color${hex_sbgi}
		EOF
	fi
}

set_vifm() {
	local slbg {sl,c,}fg
	[[ $1 ]] &&
		fg=$hex_pbg cbg=$hex_sbg cfg=$hex_a1 slbg=$hex_sbg slfg=$hex_pfg ||
		fg=$hex_pbgi cbg=$hex_sbgi cfg=$hex_a1i slbg=$hex_sbgi slfg=$hex_pfgi

	cat <<- EOF
		let \$fg = $slfg
		let \$dfg = $fg
		let \$efg = $slfg
		let \$cbg = $cbg
		let \$cfg = $cfg
		let \$sfg = $slbg
		let \$tfg = $slbg
		let \$slbg = $slbg
		let \$slfg = $slfg
	EOF
}

set_ncmpcpp() {
	#[[ $1 ]] &&
	#	mc=$hex_pbg npp=$hex_pfg pc=$hex_sbg pec=$hex_a1 ||
	#	mc=$hex_pbgi npp=$hex_pfgi pc=$hex_sbgi pec=$hex_a1i

	#[[ $1 ]] &&
		cat <<- EOF

			#ncmpcpp
			npp $hex_pfg
			np $hex_pfg
			sip $hex_pbg
			sc $hex_pbg
			mwc $hex_pbg
			etc #191e24
			c2 #DBBD7D
			pc $hex_pbg
			pec $hex_a1
			vc $hex_a1
		EOF

		awk -i inplace '
			function replace_color(color) {
				gsub("[0-9]+", color + 1)
			}

			/prefix|(window|volume|statusbar)_color/ {
				replace_color((/playing/) ? "'$hex_pfgi'" : "'$hex_pbgi'")
			}

			/(elapsed|visualizer)_color/ { replace_color("'$hex_a1i'") }
			/progressbar_color/ { replace_color("'$hex_sbgi'") }

			{ print }' $ncmpcpp_conf

		#sed -i "/foreground/ s/#\w*/$hex_a1/" ~/.config/cava/config
		sed -i "/foreground/ s/[^ ]*$/'$hex_a1'/" ~/.config/cava/config
}

set_zathura() {
	#cat <<- EOF
	#	bg = '$hex_bg'
	#	fg = '$hex_fg'
	#	hbg = '$hex_a2'
	#	hfg = '$hex_bg'
	#	sbg = '$hex_sbg'
	#	sfg = '$hex_pfg'
	#EOF

	awk -i inplace '
		/bg|light/ {
			nc = (/highlight/) ? "'"$hex_a2"'" : (/statusbar/) ? "'"$hex_sbg"'" : "'"$hex_bg"'"
		}

		/fg|dark/ {
			nc = (/highlight/) ? "'"$hex_bg"'" : (/statusbar/) ? "'"$hex_pfg"'" : "'"$hex_fg"'"
		}

		#/bg/ {
		#	switch ($2) {
		#		case /highligh/: nc = "'"$hex_a2"'"; break
		#		case /statusbar/: nc = "'"$hex_sbg"'"; break
		#		default: "'"$hex_bg"'"
		#	}
		#}

		#/fg/ {
		#	switch ($2) {
		#		case /highligh/: nc = "'"$hex_bg"'"; break
		#		case /statusbar/: nc = "'"$hex_pfg"'"; break
		#		default: "'"$hex_fg"'"
		#	}
		#}

		{
			sub("#[^\"]*", nc)
			print
		}' $zathura_conf
}

set_qb() {
	cat <<- EOF
		bg = '$hex_sbg'
		fg = '$hex_sfg'
		sbg = '$hex_bg'
		sfg = '$hex_a1'
		mfg = '$hex_a2'
		sbbg = '$hex_bg'
	EOF
}

set_home_css() {
	cat <<- EOF
		--bg: $hex_sbg;
		--fg: $hex_sfg;
		--sbg: $hex_bg;
		--sfg: $hex_pfg;
		--mfg: $hex_a5;
	EOF
}

set_sxiv() {
	awk '{
			if("'"$1"'") $1 = (NR > 1) ? "fg" : "bg"
			$NF = (NR > 1) ? "'$hex_a1'" : "'$hex_bg'"
		} { print }' $sxiv_conf
}

set_lock() {
	cat <<- EOF
		tc=${hex_fg#\#}ff
		rc=${hex_a1#\#}ff
		ic=${hex_bg#\#}dc
		wc=${hex_a5_br#\#}ff
	EOF
}

color_folders() {
	local color=hex_${1}_color

	[[ $1 == fill ]] &&
		local pattern='"fill:' ||
		local pattern='opacity:.;[^#]*\|;fill:\|color:'
	sed -i "s/\($pattern\)#\w\{6\}/\1${!color}/g" \
		~/.orw/themes/icons/{16x16,48x48}/folders/*
}

set_thunar() {
	local {rgb,hex}_hlbg
	read {rgb,hex}_hlbg <<< $(get_sbg $hex_bg +3 0)

	awk -i inplace '
		/define/ {
			switch ($2) {
				case "bg": $NF = "'"$hex_bg"';"; break
				case "sbg": $NF = "'"$hex_sbg"';"; break
				case "pbg": $NF = "'"$hex_pbg"';"; break
				case "bbg": $NF = "'"$hex_a1"';"; break
				case "hlbg": $NF = "'"$hex_hlbg"';"; break
				case "fg": $NF = "'"$hex_fg"';"; break
				case "sfg": $NF = "'"$hex_sfg"';"; break
				case "pfg": $NF = "'"$hex_pfg"';"; break
				case "afg": $NF = "'"$hex_a2"';"; break
				case "tbg": sub("([0-9]+,){3}", "'"${rgb_sbg//;/,}"'")
			}
		} { print }' $thunar_conf

		local {rgb,hex}_{fill,stroke}_color
		read {rgb,hex}_fill_color <<< $(get_sbg $hex_a4 -5)
		read {rgb,hex}_stroke_color <<< $(get_sbg $hex_a4 -20)

		color_folders fill
		color_folders stroke
}

#new_colors="$(set_nb | tr '\n' '|' | sed "s/|/\\\n$2/g")"
#echo "$new_colors"
#exit

replace_colors() {
	local conf=${1}_conf
	[[ $1 =~ bar|rofi|nb|vifm|qb|home_css|sxiv ]] && local separator=' '
	local output="$(set_$1)"
	local new_colors="$(tr '\n' '|' <<< "$output" | sed "s/|/\\\n$2/g")"

	awk -i inplace '
		function insert_new_colors() {
			print "'"$2${new_colors%\\n*}"'"
		}

		/^\s*'"${new_colors%%${separator:-=}*}"'/ { if(!length(r)) r = 1 }
		r && /^}?$/ { r = 0; insert_new_colors() }
		r { next } { print }
		ENDFILE {
			if(r) insert_new_colors()
			r = ""
		}' ${!conf}

	[[ $1 =~ bash|nb|sxiv|vifm ]] &&
		echo -e "\n#$1\n$(set_$1 print)" || echo -e "\n#$1\n$output"
}

awk -i inplace '/^[^#]*ground/ {
		if(/fore/) sub("#.*", "'$hex_fg'")
		else sub("\\(.*,", "('${rgb_bg//;/,}'")
	} { print }' ~/.config/termite/config
pidof termite &> /dev/null && killall -USR1 termite

awk -i inplace '/^\s*[^#]*ground/ {
		sub("#\\w*", ($1 ~ "^b") ? "'$hex_bg'" : "'$hex_fg'")
	} { print }' $term_conf

#exit

#awk -i inplace '
#	/^\s*background/ { sub("0x\\w*", "0x'${hex_bg#\#}'") }
#	/^\s*foreground/ { sub("0x\\w*", "0x'${hex_fg#\#}'") }
#	{ print }
#	' ~/.config/alacritty/alacritty.yml

colorscheme_name="${wallpaper_name%.*}"
colorscheme=~/.orw/dotfiles/.config/orw/colorschemes/${colorscheme_name// /_}.ocs
ob_conf=~/.orw/themes/theme/openbox-3/themerc
bash_conf=~/.orw/dotfiles/.bashrc
vim_conf=~/.orw/dotfiles/.config/nvim/colors/orw.vim
bar_conf=~/.orw/dotfiles/.config/orw/colorschemes/auto_generated.ocs
rofi_conf=~/.orw/dotfiles/.config/rofi/theme.rasi
tmux_conf=~/.orw/dotfiles/.config/tmux/tmux.conf
dunst_conf=~/.orw/dotfiles/.config/dunst/*
dunst_custom_conf=~/.orw/scripts/notify.sh
nb_conf=~/.orw/dotfiles/.config/newsboat/config
vifm_conf=~/.orw/dotfiles/.config/vifm/colors/orw.vifm
ncmpcpp_conf=~/.orw/dotfiles/.config/ncmpcpp/config*
zathura_conf=~/.orw/dotfiles/.config/zathura/zathurarc
qb_conf=~/.orw/dotfiles/.config/qutebrowser/config.py
home_css_conf=~/.orw/dotfiles/.config/qutebrowser/home.css
thunar_conf=~/.orw/dotfiles/.config/gtk-3.0/thunar.css
sxiv_conf=~/.orw/dotfiles/.config/X11/xresources
lock_conf=~/.orw/dotfiles/.config/i3lockrc

#replace_colors bar
#~/.orw/scripts/barctl.sh & #-u &
#replace_colors vim
#replace_colors rofi
#exit

reload_bash() {
	while read bash_pid; do
		kill -USR1 $bash_pid
		kill -SIGINT $bash_pid
	#done <<< $(ps aux | awk '$NF == "/bin/bash" { print $2 }')
	done <<< $(ps aux | awk '
		$NF ~ "bash$" && $7 ~ "/[1-9].?" {
			if (ot !~ $7) {
				ot = ot " " $7
				print $2
			}
		}')
}

#hsetroot -solid "$hex_sfg" &

{
	set_ob
	openbox --reconfigure &

	replace_colors bar
	~/.orw/scripts/barctl.sh & #-u &

	#replace_colors qb | sed 's/\s.*\s/ /'
	replace_colors qb | sed "s/=\s*\|'//g"
	replace_colors home_css '\t' > /dev/null

	qb_pid=$(pgrep qutebrowser)
	((qb_pid)) && qutebrowser ":config-source" &> /dev/null &

	cat <<- EOF
		
		#term
		fg $hex_fg
		bg #ff${hex_bg#\#}
	EOF

	replace_colors bash '\t' | sed 's/\(.*\)=[^"]*.\(.\w*\).*/\1 \2/'
	reload_bash
	replace_colors vim | sed 's/.*:\([^ ]*\)[^'\'']*.\(.\w*\).*/\1 \2/'
	~/.orw/scripts/reload_neovim_colors.sh &> /dev/null &

	replace_colors rofi '\t' | sed -e 's/[:;]//g' -e 's/argb/#/'
	replace_colors tmux | #awk -F '=' '{ gsub("'\''", ""); print $1, $2 }'
		awk -F '=' '{ gsub("'\''", ""); print (NR > 2) ? $1 " " $2 : $0 }'
	(($($tmux ls 2> /dev/null | wc -l))) && tmux source-file $tmux_conf &
	(($($tmux -S /tmp/tmux_hidden ls 2> /dev/null | wc -l))) &&
		tmux -S /tmp/tmux_hidden source-file ${tmux_conf%/*}/tmux_hidden.conf &

	(
		replace_colors dunst '\t'
		replace_colors dunst_custom
	) | awk -F '=' 'NR > 2 {
				if (/^(#|$)/) next

				gsub("^[^#]*|.{2}$", "", $NF)
				if (NR < 6) $1 = substr($1, 1, 1) ((NR > 4) ? "c" : "g")
			} { print (NR > 2) ? $1 " " ((NF > 1) ? $NF : "") : $0 }'
	killall dunst
	dunst &> /dev/null &

	replace_colors vifm | sed 's/\(^.*\$\|\s*=\)//g'
	[[ $(vifm --server-list) ]] && vifm --remote -c "colorscheme orw" &

	set_ncmpcpp
	~/.orw/scripts/ncmpcpp.sh -a

	replace_colors sxiv
	xrdb -merge $sxiv_conf

	replace_colors lock | sed 's/=\(.\{6\}\)\(.*\)/ #\2\1/'

	replace_colors nb
	set_zathura
	set_thunar
} > $colorscheme

exit

replace_colors dunst '\t'
replace_colors dunst_custom
set_ncmpcpp
set_zathura
set_thunar





set_bar
set_bash hex | sed 's/\(.*\)=[^"]*.\(.\w*\).*/\1 \2/'
set_vim | sed 's/.*:\([^ ]*\)[^'\'']*.\(.\w*\).*/\1 \2/'
set_rofi | sed '/tbg/! s/[:;]\|\t//g'
set_tmux | awk -F '=' '{ gsub("'\''", ""); print $1, $2 }'
set_vifm 1 | sed "s/.*\$\(\w*\).* '\?\(#\?\w*\).*/\1 \2/"

(set_dunst
set_dunst_custom) | sed -e 's/\s*=\s*/ /' -e 's/\\"//g'
exit




#ps -C run.sh --sort=start_time -o pid= | head -1 | xargs kill -SIGRTMAX
#kill -SIGRTMAX 23984
#bar_pid=$(ps -C run.sh --sort=start_time -o pid= | head -1)
#kill -SIGRTMAX $bar_pid &
#~/.orw/scripts/barctl.sh &

~/.orw/scripts/barctl.sh & #-u &
~/.orw/scripts/reload_neovim_colors.sh &

qb_pid=$(pgrep qutebrowser)
((qb_pid)) && qutebrowser ":config-source" &> /dev/null &

(($($tmux ls 2> /dev/null | wc -l))) && tmux source-file $tmux_conf &
(($($tmux -S /tmp/tmux_hidden ls 2> /dev/null | wc -l))) &&
	tmux -S /tmp/tmux_hidden source-file ${tmux_conf%/*}/tmux_hidden.conf &

[[ $(vifm --server-list) ]] && vifm --remote -c "colorscheme orw" &

~/.orw/scripts/ncmpcpp.sh -a

xrdb -merge $sxiv_conf

killall dunst
dunst &> /dev/null &
exit

set_ob
openbox --reconfigure

replace_colors qb
qb_pid=$(pgrep qutebrowser)
((qb_pid)) && qutebrowser ":config-source" &> /dev/null &

replace_colors home_css '\t'

replace_colors bash '\t'
replace_colors vim
replace_colors bar
~/.orw/scripts/barctl.sh
replace_colors rofi '\t'

replace_colors tmux
(($($tmux ls 2> /dev/null | wc -l))) && tmux source-file $tmux_conf &
(($($tmux -S /tmp/tmux_hidden ls 2> /dev/null | wc -l))) &&
	tmux -S /tmp/tmux_hidden source-file ${tmux_conf%/*}/tmux_hidden.conf &

replace_colors nb
replace_colors vifm
[[ $(vifm --server-list) ]] && vifm --remote -c "colorscheme orw" &

set_ncmpcpp
~/.orw/scripts/ncmpcpp.sh -a

replace_colors sxiv
xrdb -merge $sxiv_conf

replace_colors dunst '\t'
replace_colors dunst_custom
killall dunst
dunst &> /dev/null &
exit

exit

set_bar
set_bash hex | sed 's/\(.*\)=[^"]*.\(.\w*\).*/\1 \2/'
set_vim | sed 's/.*:\([^ ]*\)[^'\'']*.\(.\w*\).*/\1 \2/'
set_rofi | sed '/tbg/! s/[:;]\|\t//g'
set_tmux | awk -F '=' '{ gsub("'\''", ""); print $1, $2 }'
set_vifm 1 | sed "s/.*\$\(\w*\).* '\?\(#\?\w*\).*/\1 \2/"

(set_dunst
set_dunst_custom) | sed -e 's/\s*=\s*/ /' -e 's/\\"//g'
#set_dunst_custom) | sed 's/\s*=\s*[^"]*"\|."$/ /g'
exit

exit

exit

#set_rofi | awk '$1 ~ "^[^t].*[cg]:$" { gsub("[:;]", ""); print $1, $2 }'
#set_rofi | awk '!/tbg/ { gsub("[:;]|\t", ""); print }'
exit


exit
~/.orw/scripts/rice_and_shine.sh -m term -p bg "$bg"
set_vim
set_bar
