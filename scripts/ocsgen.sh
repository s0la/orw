#!/bin/bash

print_color() {
	local br hsv rgb hex prefix="$3"
	read hsv rgb hex <<< "${1//_/ }"

	#[[ $2 ]] && local label="${3:-$hsv  $rgb  $hex}"
	if [[ $2 ]]; then
		[[ $2 == label ]] &&
			local label="$hsv  $rgb  $hex" || local label="$2"
	fi

	printf "$prefix\033[48;2;${rgb%;}m    \033[0m\033[38;2;${rgb%;}m  $label  \033[0m\n"
}

get_sbg() {
	local type sign=${2//[0-9]} saturation=$3 value=${2#[+-]} opposite_sign

	[[ $1 =~ ^# ]] && type=h || type=r
	if [[ $sign && ! $saturation ]]; then
		[[ $sign == - ]] && opposite_sign=+ || opposite_sign=-
		saturation=$opposite_sign$((value / 2))
	fi

	~/.orw/scripts/convert_colors.sh -${type}bV $sign$value -S ${saturation:--0} "$1"
}

print_sbg() {
	local type sign=${2//[0-9]} saturation=$3 value=${2#[+-]}

	[[ $1 =~ ^# ]] && type=h || type=r
	[[ $sign && ! $saturation ]] && saturation=$((value / 2))

	echo ~/.orw/scripts/convert_colors.sh -${type}bV $sign$value -S ${saturation:--0} "$1"
}

print_accents() {
	local prefix accents=( ${!1} ) skip_index="$2"
	for accent in ${!accents[*]}; do
		if (($# == 2)); then
			label=label
		else
			prefix="$((accent + 1))  "
			[[ ${accents[accent]} == $most_vibrant ]] &&
				local label='(most vibrant accent)' || local label=''
		fi

		[[ $skip_index != *"$((accent + 1))"* ]] &&
			print_color ${accents[accent]} "$label" "$prefix" ||
			skip+="${accents[accent]##*_}|"
	done

	[[ $skip ]] && skip="${skip%|}"
}

yet_another_sort() {
	local wallpaper="$1"
	magick "$wallpaper" -scale 50x50! \
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
				else {
					ac = ac " [" cc "]=" NR

					if(h > maxh) maxh = h
					if(h < minh) minh = h

					if(!h) {
						cc = sprintf("%.0f;%.0f;%.0f;_%.0f;%.0f;%.0f;_#%s", \
							360, s * 100, v * 100, r, g, b, hex)
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

while getopts :aAw:sS:i:m:M:npd:I:kN opt; do
	case $opt in
		a) accents_only=true;;
		A) no_accents=true;;
		w) wallpaper=$OPTARG;;
		s) switch_last=true;;
		S) skip="${OPTARG//,/\|}";;
		i) sorting_index=$OPTARG;;
		m) main_accent_index=$OPTARG;;
		M) main_accent_sort_index=$OPTARG;;
		p) compare_to_previous=true;;
		n) no_brightning=true;;
		d) dark_accent=$OPTARG;;
		I) matching_index=$OPTARG;;
		k) keep_all=true;;
		N) non_interactive=true;;
	esac
done

[[ ! -f $wallpaper ]] &&
	echo "$wallpaper not found, exiting.." && exit

wallpaper_name="${wallpaper##*/}"
read dbg average_hue_step saturation value colors <<< $(yet_another_sort "$wallpaper")
declare -A colors
eval colors=( $colors )

get_colors() {
	[[ $1 == accents ]] &&
		local pattern='^let.*[ivcsf]fg' file=~/.config/nvim/colors/orw.vim ||
		local pattern='ground' format='0;_' file=~/.config/alacritty/alacritty.toml

	awk --non-decimal-data '
		BEGIN { f = "'"$format"'" }

		function parse_hex(segment) {
			return "0x" substr(hex, (!!f) + len - segment * 2, 2)
		}

		function get_colors(hex) {
			len = length(hex)
			return sprintf(f "%d;%d;%d;_%s", parse_hex(3), parse_hex(2), parse_hex(1), hex)
		}

		/'"$pattern"'/ {
			hex = $NF
			gsub("\"", "", hex)
			print get_colors(hex)
		}' $file | xargs
}

if [[ $accents_only ]]; then
	read accent_{bg,fg} <<< $(get_colors base)
	accent_fg=$(~/.orw/scripts/convert_colors.sh -ha ${accent_fg##*_} | tr ' ' '_')
	read hsv {rgb,hex}_bg <<< ${accent_bg//_/ }
fi

mono_treshold=0

get_mono_accent() {
	tr ' ' '\n' <<< ${!colors[*]} | sort -n |
		awk -F '[;_]' '
			function add_hue() {
				{
					if ($1 - ph < 25) {
						ahd += $1 - ph
						hc++
					}

					ph = $1

					if ($3 > $2 * 1.3) {
						asv[$2 + $3] = $0
						svs[++i] = $2 + $3
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
				for (c in asv) {
					print c, asv[c]
				}
			}'
}

read average_hue mono{,_accent} <<< $(get_mono_accent)

if ((mono)); then
	bg_v=8
	fg_v=75
	sign=+
	main_bg="$(get_sbg "#111111")"
	mono_dbg=$(awk -F ';' '{ v = 8 + $3; printf "#%.2x%.2x%.2x", v, v, v  }' <<< $dbg)
	main_bg=$(get_sbg $mono_dbg)
	org_fg="0;0;81;_206;206;206;_#cecece"
	read {rgb,hex}_fg <<< $(get_sbg "#aaaaaa")
	hex_term_fg=$hex_fg
else
	sorted_colors=( $(tr ' ' '\n' <<< ${!colors[*]} | sort -n) )
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

		((80 - fg_value < 10)) && #[[ ! $accents_only ]] &&
			colors[$new_fg]=${colors[$org_fg]} sorted_colors[$fgi]=$new_fg
	fi

	[[ $accent_fg ]] && org_fg=$accent_fg

	((value < 50)) &&
		mode=dark || mode=light
fi

set_mode() {
	[[ ${mode,} == d* ]] &&
		main_bg=$dbg main_fg=$org_fg bg_v=8 fg_v=60 sign=+ ||
		main_bg=$org_fg main_fg=$dbg bg_v=70 fg_v=40 sign=-

	read {rgb,hex}_fg <<< $(get_sbg "${main_fg##*_}" $fg_v 5)
	read {hsv,rgb,hex}_term_fg <<< $(~/.orw/scripts/convert_colors.sh -haV +10 -S -10 "$hex_fg")

	if [[ ! $accents_only ]]; then
		bg_s=$(cut -d ';' -f 2 <<< $main_bg)
		((bg_s > 50)) && bg_s=50
		read {rgb,hex}_bg <<< $(get_sbg ${main_bg##*_} $bg_v $bg_s)
	fi

	read {rgb,hex}_tbg <<< $(get_sbg $hex_bg +3)
	read {rgb,hex}_sbg <<< $(get_sbg $hex_bg ${sign}5)
	read {rgb,hex}_sfg <<< $(get_sbg $hex_sbg ${sign}12)
	read {rgb,hex}_pbg <<< $(get_sbg $hex_sbg ${sign}5)
	read {rgb,hex}_pfg <<< $(get_sbg $hex_pbg ${sign}7)

	if [[ $mode == dark ]]; then
		read {rgb,hex}_tbg <<< $(get_sbg $hex_bg +3)
		read {rgb,hex}_sbg <<< $(get_sbg $hex_bg ${sign}5)
		read {rgb,hex}_sfg <<< $(get_sbg $hex_sbg ${sign}12)
		read {rgb,hex}_pbg <<< $(get_sbg $hex_sbg ${sign}5)
		read {rgb,hex}_pfg <<< $(get_sbg $hex_pbg ${sign}10)
	else
		term_bg_s=$(cut -d ';' -f 2 <<< $dbg)
		((term_bg_s > 50)) && term_bg_s=50
		read term_{rgb,hex}_bg <<< $(get_sbg ${dbg##*_} 8 $term_bg_s)
		read term_{rgb,hex}_sbg <<< $(get_sbg $term_hex_bg +5)
		read term_{rgb,hex}_sfg <<< $(get_sbg $term_hex_sbg +12)
		read term_{rgb,hex}_pbg <<< $(get_sbg $term_hex_sbg +5)
		read term_{rgb,hex}_pfg <<< $(get_sbg $term_hex_pbg +15)
		read term_{rgb,hex}_fg <<< $(get_sbg "${org_fg##*_}" 75 10)
		read {hsv,rgb,hex}_term_fg <<< $(~/.orw/scripts/convert_colors.sh -haV +10 -S -10 "$term_hex_fg")
	fi
}

set_mode

if ((mono)); then
	set_mono_accents() {
		local type=$1 ai=2 sign s=25

		for color in ${type}_{bg,fg,pfg,sbg}; do
			[[ $color == *_fg ]] && sign=- || sign=+

			read {rgb,hex}_a$ai <<< $(get_sbg "${!color}" "+$s")
			((ai++))
			((s -= ai - 3))
		done
	}

	set_mono_accents hex

	read {rgb,hex}_a1 <<< $(get_sbg ${mono_accent##*_} +10)
	echo $hex_a1, $rgb_a1, $hex_a2, $rgb_a2, $hex_a3, $rgb_a3
else
	yet_another_get_step2() {
		tr ' ' '\n' <<< "$1" | awk -F ';' '
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
						if(!(pai in rm)) {
							set_previous(aaa[pai])
							nde = (c0 || abs(h, prh) <= as || (h > 320 && abs(0, prh) <= as))

							if(nde) {
								rgb_to_xyz(pr, pg, pb)
								xyz_to_lab(X, Y, Z)
								l2 = L; a2 = a; b2 = b

								l = (l2 - l1) ^ 2
								a = (a2 - a1) ^ 2
								b = (b2 - b1) ^ 2

								pt = '${2:-13}'
								if(v <= 30 && prv <= 30) pt = int(pt / 2)
								else {
									if(ci > 15 && aac <= 6) pt -= 2
									else if(v > 65 && prv > 65) pt *= 0.7
								}

								lab_d = int(sprintf("%.0f", sqrt(l + a + b)))
								nde = sqrt(l + a + b) < pt
								nde = lab_d < pt

								if(nde) {
									kp = (v <= prv && s < 2 * prs)
									if(!kp) {
										#print "HERE"
										sub(pc, "", fa)
										delete aaa[pai]

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

					if (aac > 1 && h - lh < 50) thd += h - lh
					lh = h; ls = s; lv = v
				}

				h = cp[1]; s = cp[2]; v = cp[3]
				msv = s + v
				pmsv = msv
				msvc = ac[ci]
			}

			{
				c = sqrt(($2 - $3) ^ 2)

				b = $2 >= 5 && !(c > 30 && $3 > $2 && $2 > 65) &&
					!($2 < 20 && $3 < 20) && ($3 > 10) && c <= 70

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

				for(ci in ac) {
					split(ac[ci], cp, ";")
					ch = cp[1]
					if(ch == 360) c0 = 1

					if(ci == 1 || ch - ph < 15) {
						ce = (NR < 20) ? 0 : ch - ph < aad[di]
						if(ci == 1 || ((sc < 3 && ce) || (sc >= 3 && ce))) {
							if(ci == 1 || (cp[2] + cp[3] > msv) ||
								(cp[2] + cp[3] == msv && cp[3] > v)) {
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
				aac = length(aaa)
				print aac, int(tsv / aac), int(tv / aac), int(ts / aac), fa
			}'
	}

	treshold=13

	while
		read accent_count avg_{sv,value,saturation} sorted_accents <<< \
			$(yet_another_get_step2 "${accents[*]:-${sorted_colors[*]}}" $treshold)

		if [[ ! $accent_sign ]]; then
			((accent_count > 6)) && accent_sign=+ || accent_sign=-
		fi

		if ((!accent_limit)); then
			((accent_count > 10)) &&
				accent_limit=8 || accent_limit=7
		fi

		accent_limit=9

		[[ $reverse ]] && unset reverse || reverse=r

		accents=( $(tr ' ' '\n' <<< $sorted_accents | sort -n$reverse) )

		#for c in ${accents[*]}; do
		#	print_color $c label
		#done

		((accent_count > accent_limit))
	do
		(( treshold += 2 ))
	done

	compensate_accents() {
		local exclude="${final_accents[*]:-${accents[*]}}"
		local count_diff=$((6 - accent_count))

		if ((count_diff)); then
			while read extra_accent; do
				#echo extra
				#print_color $extra_accent label
				final_accents+=( $extra_accent )
				accents+=( $extra_accent )
			done <<< $(tr ' ' '\n' <<< "${sorted_colors[*]}" | awk -F ';' '
				BEGIN {
					av = "'$value'"
					aav = "'$avg_value'"

					as = "'$saturation'"
					aas = "'$avg_saturation'"

					asv = ("'$saturation'" + "'$value'") / 1
					aasv = "'$avg_sv'"

					ci = split("'"${accents[*]}"'", fa, " ")
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
					prsv = prc[1]; prh = prc[1]; prs = prc[2]; prv = prc[3]
					pr = prc[5]; pg = prc[6]; pb = prc[7]
				}

				function is_different() {
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

							nde = sqrt(l + a + b) < 10
						}

						pai--
					} while(pai && !nde)

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

	((${#accents[*]} < 6)) && compensate_accents
	accent_count=${#accents[*]}

	if ((accent_count < 6)); then
		final_accents=( ${accents[*]} )
		compensate_accents
		final_accents=(
			$(tr ' ' '\n' <<< ${final_accents[*]} |
			awk -F ';' '{ print $2 + $3, $0 }' |
			sort -t ';' -k 1,1nr -k 3,3nr | grep -o '[^ ]*$')
		)
	else
		final_count=${#final_accents[*]}
		final_accents=( $(tr ' ' '\n' <<< ${accents[*]} | sort -t ';' -k 3,3nr -k 2,2nr) )
	fi

	((avg_value < 50)) && avg_value=$((100 - avg_value))

	set_accent() {
		((avg_value > 50)) &&
			local avg_value=$avg_value ||
			local avg_value=$((100 - avg_value))

		for accent in $1; do
			read h s v r g b <<< $(cut -d ';' -f 1,2,3,4,5,6 <<< $accent | tr '[;_]' ' ')

			sv=$((s + v))
			a=$((sv / 2 - 13))

			if [[ $no_brightning ]]; then
				light_accent=$(get_sbg ${accent##*_} +1)
				light_accent_colors+=( "${sv};${h};${s};${v}_${light_accent// /_}" )
				continue
			fi

			value_diff=$((s - a - accent_deviation))
			if ((s > v)); then
				if ((s > 3 * v)); then
					value=$(((s - 3 * v) * 5))
					((value > 30)) && value=30 sat=30
					light_accent=$(get_sbg ${accent##*_} +$value -${sat:-0})
				else
					((a + 1 >= v)) && multiplier=1.3 || multiplier=2.5
					((a + 1 >= v)) && multiplier=1.3 || multiplier=2

					value=$(bc <<< "($value_diff * $multiplier) / 1 + 0")
					((value > 100)) && value=90
					light_accent=$(get_sbg ${accent##*_} +${value#-} -5)
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
							multiplier=0.8
						else
							value=$((value_diff + accent_deviation)) multiplier=1.6
							((value > 10)) && value=10
							((value < 5)) && value=5
							multiplier=2
						fi
					else
						if ((avg_value - v > ${value_diff#-})); then
							value=$((avg_value - v))
							((avg_value - v > 2 * ${value_diff#-})) &&
								multiplier=0.5 || multiplier=0.8
						else
							value=$((v - a)) multiplier=0.4
							value=$((v - a)) multiplier=0.3
							multiplier=1
							((v > 3 * s)) && value=$s
						fi
					fi

					value_diff=$(bc <<< "(5 * $multiplier) / 1")
					light_accent=$(get_sbg ${accent##*_} +${value_diff#-})

					((avg_value -= 5))
				else
					if ((v > 75)); then
						((s > 60)) &&
							light_accent=$(get_sbg ${accent##*_} +$((v - s))) || light_accent="${accent#*_}"

					elif ((v >= 3 * (s - 1))); then
						((v < 70)) && value=10 || value=+5
						((s < 20)) &&
							light_accent=$(get_sbg ${accent##*_} $((v + value)) $((s + value))) ||
							light_accent=$(get_sbg ${accent##*_} $((v + 18)) $((s + 5)))
					else
						((v > 2 * s)) &&
							value=10 || value=5

						light_accent=$(get_sbg ${accent##*_} +$value)
						value=10
						#echo 20 $value: $accent
					fi
				fi
			fi

			((value < 9)) && light_accent=$(get_sbg ${accent##*_} +10)

			light_ac=$(~/.orw/scripts/convert_colors.sh -ha "${light_accent##*_}" | awk -F ';' '{
					la = $2 + $3 ";" $0
					gsub(" ", "_", la)
					print la
				}')

			light_accent_colors+=( $light_ac )
			((accent_deviation+=1))
		done
	}

	set_accent "${final_accents[*]}"

	#for la in ${light_accent_colors[*]}; do
	#	print_color $la label
	#done

	most_vibrant=$(tr ' ' '\n' <<< ${light_accent_colors[*]} | sort -t ';' -nrk 1,1 | head -1)

	sort_accents() {
		local dark_count=$(((${#light_accent_colors[*]} + 3 / 2) / 3))

		darkest=$(tr ' ' '\n' <<< ${light_accent_colors[*]} | grep -v "$most_vibrant$skip" |
			sort -t ';' -nk 4,4 -k 3,3n | head -$dark_count | xargs)
		most_vibrant=$(tr ' ' '\n' <<< ${light_accent_colors[*]} | grep -v "^${darkest/ /\\|}$skip" |
			sort -nrt ';' -k ${main_accent_sort_index:-1},${main_accent_sort_index:-1} -k 4,4 | head -1)
		accent_count=${#light_accent_colors[*]}

		(
			echo -e "$most_vibrant\n${darkest// /\\n}"
			#tr ' ' '\n' <<< ${light_accent_colors[*]} | grep -v "$most_vibrant\|${darkest// /\\|}$skip" |
			tr ' ' '\n' <<< ${light_accent_colors[*]} | grep -v "$most_vibrant\|${darkest// /\\|}" |
				sort -t ';' -nrk 4,4
		) | awk '
				BEGIN { acl = '${#light_accent_colors[*]}' }

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
					r = cp[6]; g = cp[7]; b = cp[8]
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

			function similar(c1, c2) {
				split(c1, tc1, "[;_]")
				split(c2, tc2, "[;_]")

				for (tci=5; tci<=7; tci++) if (sqrt((tc1[tci] - tc2[tci]) ^ 2) > 45) return 0
				return 1
			}

			function get_color(ar1, ar2, del, range) {
				mal = 0
				c = ""

				tr = (range) ? range : 10

				for (i in ar1) {
					if (!ar1[i]) {
						delete ar1[i]
						continue
					}

					if (i > tr) continue

					tl = al = 0 #skip = 0
					get_rgb(ar1[i])
					rgb_to_xyz(r, g, b)
					xyz_to_lab(X, Y, Z)
					l1 = L; a1 = a; b1 = b

					lc = 0

					for (ai in ar2) {
						if (!ar2[ai] || ai > tr) continue

						if ((del || int(ai) < 10) && ar1[i] != ar2[ai]) {
							get_rgb(ar2[ai])
							get_lab()
							tl += lab

							if (del && ! dl[lab]) { dl[lab] = 1; avl += lab }

							if (lab > mlab) mlab = lab

							if (i <= dc + 1 && ai <= dc + 1) {
								pds = 12
								pds = 11
								pds = 10
								clab = sprintf("%.0f", lab)
							} else {
								pds = (ds < 10) ? 10 : ds + ((ds < 19) ? -1 : -3)
								clab = int(lab)
								clab = sprintf("%.0f", lab)
							}

							pc = (tr < 10) ? 1 : ((i <= dal - ddsai && ai <= dal - ddsai && acl > 5) ||
								(i > dal - ddsai && ai > dal - ddsai))

							pc = (tr < 10) ? 1 : ((i <= dal && ai <= dal && acl > 5) || (i > dal && ai > dal))

							split(ar1[i], acp, "[;_]")
							split(ar2[ai], arp, "[;_]")
							hd = sqrt((acp[2] - arp[2]) ^ 2)
							tdh = ((acp[2] >= 330 && arp[2] <= 10) || (arp[2] >= 330 && acp[2] <= 10))

							if (del && pc && dc >= 2 && acl >= 6 && (hd <= 40 || tdh)) {
								aci = get_color_index(acp)
								ari = get_color_index(arp)

								svd = sqrt((acp[1] - arp[1]) ^ 2)
								pds += (lab < 200 && aci == ari && sqrt((acp[3] - arp[3]) ^ 2) <= 35) ? hd / 2 * 7 : -5
								#print lab, ds, pds, clab, ar1[i], ar2[ai], svd, aci, ari, (del && pc && int(clab) < pds )
							}





							#if (del) print i, ai, dal, lab, clab, pds, ds, ar1[i], ar2[ai], dl[lab], (lab in dl), pds, pc, i, ai, dc, length(ac), (del && pc && int(lab) <= pds && length(ac) > 5), pc, i, ai, dc + 0, pc, i, ai, pds, dal, ddsai
							#if (!del) print lab, ds, ar1[i], ar2[ai], dl[lab], (lab in dl), pds, pc, i, ai, dc, length(ac), (del && pc && int(lab) <= pds && length(ac) > 5)




							if (!del && similar(ar1[i], ar2[ai]) && !(ar1[i] in sc)) sc[ar1[i]] = length(aac)

							if (del && pc && int(clab) < pds && acl > 5) {
								#print "HERE", i, ar1[i], ai, ar2[ai], lab, ds, clab, pds, dal, ddsai, acl

								if (i <= dal && odc - ddsai == 1) continue

								as = sqrt((acp[3] - arp[3]) ^ 2)
								av = sqrt((acp[4] - arp[4]) ^ 2)
								asv = (as + av) / 2
								if ((asv <= 5 || (sqrt((acp[2] - arp[2]) ^ 2) < 95)) ||
									((acp[2] > 315 && arp[2] < 45) || (arp[2] > 315 && acp[2] < 45))) {
										if ("'"$matching_index"'") { cpi = '${matching_index:-0}'; scpi = 4 }
										else if ('${matching_index:-4}' == 4) { cpi = 4; scpi = 3 }
										else { cpi = 3; scpi = 4 }

										con = (ds < 20) ? acp[cpi] > arp[cpi] : acp[cpi] < arp[cpi]
										con = acp[cpi] > arp[cpi]

										adi = ((con || (acp[cpi] == arp[cpi] && acp[scpi] > arp[scpi])) && ai > 1) ? ai : i

										rac = ar2[adi]
										delete ar2[adi]
										dsa[++dsai] = rac
										if (adi <= dal) ddsai++

										if (rac == aac[1]) {
											kc = ar2[(adi == i) ? ai : i]
											mva = kc
											for (av in ac) if (int(ac[av]) > int(mva)) mva = ac[av]

											if (kc == mva) aac[1] = kc
											else {
												kcsv = kc
												mvasv = mva
												sub(";.*", "", kcsv)
												sub(";.*", "", mvasv)
												aac[1] = (mvasv - kcsv > 20) ? mva : kc
											}
										}

										acl--

										if ((dc == 3 && acl == 7) || (dc == 2 && acl == 5)) { dc--; dal = dc + ddsai }
										break
								}
							} else lc++
						}
					}

					if (lc) {
						al = int(sprintf("%.0f", tl / lc))

						split(ar1[i], acp, "[;_]")

						if (al >= mal) {
							if (fai == 2) {
								slab = tl
								sb = acp[4]
								ss = acp[3]
								ssv = acp[1] / 2
							}

							#print "MAX", al, mal, acp[3], alh

							if ((al == mal && acp[3] > alh) || al > mal) {
								mal = al
								alh = acp[3]
								c = ar1[i]
								ci = i
							}
						}

						continue
					}
				}

				if (length(del)) return
				else {
					delete ar1[ci]

					if (la && fai == 2 && !skipped) {
						scc = length(ar2)
						if (la < 35 || la > 40) scc++
						z = slab / scc

						get_rgb(c)
						rgb_to_xyz(r, g, b)
						xyz_to_lab(X, Y, Z)
						l1 = L; a1 = a; b1 = b

						get_rgb(acc[2])
						get_lab()

						for (a in ar1) {
							cc = ar1[a]

							get_rgb(ar1[a])
							get_lab()

							slab += lab * 1
						}

						#NEW TRY
						scc = (slab > 240 && slab < 300) ? 5 : \
							(sprintf("%.0f", slab) >= 155 || (slab > 80 && slab < 110)) ? 3 : 4

						#scc = (slab > 240 && slab < 300) ? 5 : \
						#scc = (slab > 265 && slab < 300) ? 5 : \

						#scc = (slab > 235 && slab < 300) ? 5 : \
						scc = (slab > 235 && slab < 280) ? 5 : \
							(slab > 160 || (slab > 80 && slab < 110)) ? 3 : 4
							#(slab > 160 || (slab > 80 && slab < 120)) ? 3 : 4
							#(slab > 165 || (slab > 80 && slab < 105)) ? 3 : 4
							#(slab > 170 || (slab > 80 && slab < 110)) ? 3 : 4
						range = 6
						sd = sqrt((int(slab / scc) - int(la)) ^ 2)
						#print slab, scc, slab / scc, la, sqrt((int(slab / scc) - int(la)) ^ 2), c, acl #< 5

						ignore = 1

						if ((!ignore && sd && sd <= range && acl > 3) && c < 99) {
							skipped = 1
							if (acl <= 4 && ds > 10) sac = c
							return
						}
					}

					sa[c] = 1
					return c
				}
			}

			function get_base_color_delta(value) {
				return sqrt(value ^ 2)
			}

			function get_color_index(color) {
				if (length(color[1])) { lh = color[2]; s = color[3]; v = color[4]; r = color[6]; g = color[7]; b = color[8] }

				li = 0
				svd = sqrt((s - v) ^ 2)

				if ((s < 10 && svd > 55) || (s < 15 && svd > 65)) return li

				if (lh <= 30 && sqrt((r - g) ^ 2) > 20) {
					if ((length(color[1]) && r > 240 && sqrt((r - g) ^ 2) < 110) || !(b < g)) return li

					if (lh >= 5 &&
						(v > 55 && (sqrt((r - g) ^ 2) < ((r > 240) ? 140 : (r > 200) ? 110 : (r > 155) ? 55 : 30))) ||
						(v < 55 && 0)) {
					#if (lh >= 5 && (sqrt((r - g) ^ 2) < (((r < 160) ? 30 : (r < 200) ? 50 : (r < 240) ? 80 : 100) + ((lh > 10) ? 0 : 0)))) {
						li = 8
						ls = r + g
					} else {
						li = (b < 150) ? 6 : 5
						ls = r - g
					}
				} else if (lh > 25 && lh < 100 && g > 70) {
					if ((lh > 40 && g + ((r >= 165) ? -20 : (r > 130) ? 15 : 0) >= r) ||
						(lh < 45 && g + ((r > 130 && r < 180) ? 15 : 5) > r))
						{ li = 4; ls = g } else { li = 8; ls = r + g }
				} else if (lh >= 100 && lh < 180) {
					if ((g > 200 && g - b > 30) ||
						(g < 200 && g >= 165 && g > b + ((r > 120) ? 10 : 15)) ||
						((g < 165 || v < 50) && g > b + ((r > 110) ? 10 : 0))) { li = 4; ls = g + s }
						else { li = 3; ls = b + s }
				} else if (lh >= 180 && lh < 280 && s && (s > 10 || sqrt((s - v) ^ 2) <= 55)) {
					if (lh > 230) {
						if ((v > 50 && s >= 10 &&
							sqrt((r - b) ^ 2) < ((b > 200) ? 60 : (b > 170) ? 50 : 35))) { li = 5; ls = r + s }
						else if (s > 17 || (g + 10 > b && r < g + 5)) { li = (g + 10 > b) ? 4 : 2; ls = ((li == 2) ? b : g) + s }
					} else {
						if ((v < 55 && g >= 100 && g < 130 &&
							(sqrt((g - b) ^ 2) > 5 || g - r > 10)) ||
							(v > 25 && g < 100 && g > 60 && b < 100 && g + 10 > b) ||
							#sqrt((g - b) ^ 2) > ((g - r > 10) ? 10 : 5)) ||
							(g > 170 && g + 5 >= b && sqrt((r - b) ^ 2))) { li = 4; ls = g + s }
						else {
							li = (b - g > ((r < 50) ? 50 : (r > 110 && r < 145) ? 20 : ((b > 210) ? (sqrt((r - g) ^ 2) > 10 ? 60 : 35) : 35)) ||
								(v < 70 && b - g >= 15 && !bcs[2]) || (v < 45 && b > g)) ? 2 : 3; ls = b + s }
					}
				}

				else if (lh >= 280 && r > 100) {
					if (g + 10 > r) {
						li = 4; ls g + s
					} else if (s > 10) {
						if (lh >= 355) {
							if (sqrt((r - g) ^ 2) < 35) { li = 8; ls = r + g } else { li = 6; ls = r}
					} else if (sqrt((r - b) ^ 2) > \
						((r > 205) ? 100 : (r > 165) ? 80 : (r > 130) ? 50 : 30) ||
						((r > 100 && b < 100) && r - b < 33))
							{ li = 6; ls = r - g } else { li = 5; ls = r + s }
					}
				}

				return li
			}

			function get_base_colors() {
				lh = ccp[2]; ls = ccp[1]; s = ccp[3]; v = ccp[4]
				li = get_color_index()
				if (!bcs[li] || (ccp[1] >= 50 && ccp[3] >= 10 && ls - bcs[li] > 0)) { bc[li] = $0; bcs[li] = ls }
			}

			{
				split($0, ccp, "[;_]")
				r = ccp[6]; g = ccp[7]; b = ccp[8]
				rgba[1] = r; rgba[2] = g; rgba[3] = b
				asort(rgba)

				get_base_colors()

				if ("'"$skip"'" && /'"$skip"'/) {
					if (NR == 1) rmva = 1
					next
				}

				sbc = ((r > 210 && g > 210 && b > 185) ||
					(r > 185 && g > 210 && b > 210))

				rgbs = r + g + b
				rgbd = int((rgba[3] - rgba[1]) / 1)

				d1 = sqrt((rgba[1] - rgba[2]) ^ 2)
				d2 = sqrt((rgba[2] - rgba[3]) ^ 2)
				fd = sqrt((d1 - d2) ^ 2)

				#print rgbs / 3, fd, rgbd, r, g, b, $0
				if (ccp[1] <= 100 && ((acl > 6 && acl <= 9 && (sbc || (rgbs / 3 > 190 && \
					((d1 < 30 && d2 < 30 && fd <= 10 && d1 + d2 < 40) || (rgbd < 30))))) ||
					(acl > 7 && rgbs / 3 >= 210))) {
							if (NR == 1) rmva = 1
							if (ccp[1] > 100) bac[++bai] = $0
							acl--
							next
				}

				if (rmva && ccp[1] > mvav) { mva = $0; mvav = ccp[1] }

				ac[++i] = $0
				sub(";.*", "", $1)
				tsv += $1
			}

			function compare_all(i1, v1, i2, v2) {
				if (v1 && v2) {
					split(v1, dp1, "[;_]")
					split(v2, dp2, "[;_]")
					return (dp1[si] == dp2[si]) ? \
						dp1[3] - dp2[3] : dp1[si] - dp2[si]
						#i2 > i1 : dp1[si] - dp2[si]
				}
			}

			function compare_dark(i1, v1, i2, v2) {
				if (v1 && v2) return v1 > v2
			}

			END {
				acl = length(ac)
				si = '${sorting_index:-4}'
				ds = int('$avg_saturation' / 3 * 1.9) - 4 # - 7 #+ 3
				ds += ((ds < 20) ? 1 : -sprintf("%.0f", (ds / 10) * (ds / 10 - 0)) - 0)

				tc = '${accent_count:-0}'

				mlab = 100
				aac[1] = (mva) ? mva: ac[1]
				sa[aac[1]] = 1
				asort(ac, ac, "compare_all")

				dc = '$dark_count'
				dal = (ac[dc] > 70) ? (acl > 5) ? 2 : 1 : dc
				dc = (acl > 7) ? 3 : (acl > 5) ? 2 : 1
				odc = dal = dc

				delete bcs

				#for (x in ac) print x, ac[x]
				#print ""

				get_color(ac, ac, tc > 5)

				#for (x in ac) print x, ac[x]
				#print ""

				if (dc != odc && acl > 6) get_color(ac, ac, 1)

				dc = (acl > 7) ? 3 : (acl > 5) ? 2 : 1

				acl = 0
				for (a in ac) {
					if (ac[a]) {
						if (++ca > dc) acl++
						else {
							if (!dis) dis = a
							rdc++
						}
						hai = a
					}
				}

				if (acl <= 6) dal = 2

				bacl = length(bac)

				#NEW APPROACH
				if (acl + bacl < 4) dc = rdc - (4 - acl)
				else dal = 2

				#if (acl >= 3) dc = (acl + rdc + bai > 7) ? 3 : (acl + rdc + bai > 5) ? 2 : 1
				if (acl >= 3) dc = (acl + rdc > 7) ? 3 : (acl + rdc > 5) ? 2 : 1

				##NEW TRY
				dac[1] = ac[dis]

				odis = dis
				if (dc > 1) dac[2] = ac[dis + ((dc > 2) ? 2 : 1)]

				if (dc > 1) {
					do {
						nd = ac[dis++ + ((dc > 2) + '${dark_accent:-1}')]
					} while (nd ~ /^\s*$/)

					dac[2] = nd
				}

				while (rmda < dc) {
					if (ac[odis + rda] !~ /^\s*$/) {
						#print "DEL", odis, rda, rmda, ac[odis + rda]
						delete ac[odis + rda]
						rmda++
					}
					rda++
				}

				delete dac[0]
				asort(dac, dac, "compare_dark")
				for (a in ac) if (ac[a] == aac[1]) { delete ac[a]; acl-- }

				if (length(dl) && length(ac) >= 3) la = avl / length(dl)

				for (fai=2; fai<5; fai++) {
					if (length(ac)) {
						do {
							tac[1] = aac[fai - 1]
							cc = ("'"$compare_to_previous"'") ? \
								get_color(ac, tac) : get_color(ac, aac) 
						} while (!cc || (!cc && fai == 2 && sac))
						aac[fai] = cc

						if (fai > 2 && bai) {
							for (bai; bai; bai--) ac[bai] = bac[bai]
							bai = 0
						}

						if (sac) {
							ac[length(ac)] = sac
							sac = ""
						}
					}
				}

				for (bci=1; bci<=8; bci++) printf "%s ", ((bc[bci]) ? bc[bci] : 0)
				print ""

				for (di in dac) aac[4 + ++daci] = dac[di]
				for (ai=1; ai<=6; ai++) print aac[ai]
			}'
	}

	if [[ $no_accents ]]; then
		accent_colors=( $(get_colors accents) )
	else
		accents=( $(tr ' ' '\n' <<< "${final_accents[*]}" |
			awk -F ';' '{ print $2 + $3 ";" $0 }') )

		swap=

		print_accents light_accent_colors[@]
		if [[ ! $skip && ! $non_interactive ]]; then
			read -p 'Skip accent? (single or comma-separated list) ' skip_index

			[[ $skip_index ]] &&
				tput -x clear &&
				print_accents light_accent_colors[@] "$skip_index"
		fi

		IFS=$'\n' read -d '' base_colors accent_colors <<< $(sort_accents)
		base_colors=( $base_colors )
		accent_colors=( $accent_colors )

		base_colors[0]="0;_${rgb_sfg}_${hex_sfg}"
		base_colors[6]="0;_${rgb_term_fg}_${hex_term_fg}"

		#sort_accents
		#exit

		#sorted_accents=( $(sort_accents) )
		#for a in ${accent_colors[*]}; do
		#	print_color $a label
		#done
		#exit

		if [[ $switch_last ]]; then
			swap_accent=${accent_colors[-1]}
			accent_colors[-1]=${accent_colors[-2]}
			accent_colors[-2]=$swap_accent
		fi

		if [[ $swap ]] && ((${#accent_colors[*]} < 6)); then
			a3=${accent_colors[-2]}
			accent_colors[-2]=${accent_colors[2]}
			accent_colors[2]=$a3
			echo SWAP
		fi
	fi

	if [[ ! $non_interactive ]]; then
		id=$(xdotool getactivewindow)
		color_fifo=/tmp/picked_color.fifo
		color_config=~/.config/alacritty/alacritty_color_preview.toml

		options=(
			'[s]wap'
			"$main_accent"
			"[M]ode ($mode)"
			'[S]ave color'
			'[a]djust color'
			'[A]djust all colors'
		)

		((${#accent_colors[*]} > 5)) &&
			options+=( '[k]eep all colors (only 5 by default)' )

		while
			tput -x clear

			for color in ${!accent_colors[*]}; do
				#printf 'accent%d: ' $((color + 1))
				echo -ne "$((color + 1))  "
				print_color "${accent_colors[color]}" label
			done

			read -rn 1 -p $'Change colors: [y/N] ' option

			[[ $option && $option != [Nn] ]]
		do
			main_rgb="${accent_colors[${main_accent_index:-2} - 1]#*_}"
			main_rgb="${main_rgb%;*}"
			options[1]="\033[38;2;${main_rgb}m[m]ain color\033[0m"

			for option_index in "${!options[@]}"; do
				((!option_index)) && echo -e "\n"
				echo -e "${options[option_index]}"
			done

			read -rn 1 -p $'\nOption: ' option

			if [[ "${options[*]}" == *\[$option\]* ]]; then
				case $option in
					s)
						read -p $'\nEnter accent indices to swap, comma-separated (e.g. 1,2): ' indices
						i1=${indices%,*} i2=${indices#*,}
						swap_accent=${accent_colors[i2-1]}
						accent_colors[i2-1]=${accent_colors[i1-1]}
						accent_colors[i1-1]=$swap_accent
						;;
					M)
						while
							read -p $'\nSelect mode: [D]ark or [L]ight? ' mode
							[[ ${mode,} != [dl]* ]]
						do
							echo "$mode is not a valid mode, select light or dark.."
							sleep 2
						done

						[[ ${mode,} == d* ]] &&
							mode=dark || mode=light
						options[2]="[M]ode ($mode)"

						set_mode
						;;
					m|S)
						while
							read -p $'\nEnter the index of main accent color '"(1-${#accent_colors[*]}): " accent_index
							((accent_index > ${#accent_colors[*]}))
						do
							echo "$accent_index is outside the index range (1-${#accent_colors[*]}).."
							sleep 2
						done

						if [[ $option == S ]]; then
							read -p 'Enter color name: ' color_name
							saved_color=${accent_colors[accent_index - 1]##*_}

							awk '
								$NF == "'"$saved_color"'" { $1 = "'"$color_name"'"; c = 1}
								{ print }
								END { if (!c) print "'"$color_name $saved_color"'" }' \
									~/.config/orw/colorschemes/colors
								exit
						else
							main_accent_index=$accent_index
						fi
						;;
					a)
						read -rn 1 -p $'\nEnter index of an accent you would like to change: ' index
						accent=${accent_colors[index-1]}

						[[ -p $color_fifo ]] && rm $color_fifo
						mkfifo $color_fifo

						alacritty -t color_preview --config-file=$color_config -e ~/.orw/scripts/color.sh ${accent##*_} &
						picked_color=$(cat $color_fifo)
						new_accent=$(~/.orw/scripts/convert_colors.sh -ah $picked_color | tr ' ' '_')
						accent_colors[index-1]=$new_accent

						wmctrl -ia $id
						clear

						[[ -p $color_fifo ]] && rm $color_fifo
						;;
					A)
						while
							read -rn 1 -p $'\n[h]ue, [s]aturation or [v]alue? ' hsv_option
							[[ $hsv_option != [hsv] ]]
						do
							echo "$hsv_option is not a valid option, choose again.."
							sleep 2
						done

						read -p $'\nOffset/value: ' hsv_value

						for accent in ${!accent_colors[*]}; do
							offset_color="$(~/.orw/scripts/convert_colors.sh -hca -$hsv_option $hsv_value ${accent_colors[accent]##*_})"
							accent_colors[accent]="0;${offset_color// /_}"
						done
						;;
					k) keep_all=true;;
				esac
			else
				echo "Option $option is not supported, choose again.."
			fi

			echo
		done
	else
		echo -e "\nChosen colors:\n"
		for color in ${!accent_colors[*]}; do
			#printf 'accent%d: ' $((color + 1))
			echo -ne "$((color + 1))  "
			print_color "${accent_colors[color]}" label
		done
	fi

	((${#accent_colors[*]} == 5)) &&
		accent_colors=( ${accent_colors[*]::4} $dbg ${accent_colors[-1]} )
	[[ $keep_all ]] && cfg_hex=${accent_colors[4]##*_}
fi

read {rgb,hex}_a{1..6} <<< \
	$(tr ' ' '\n' <<< "${accent_colors[*]}" |
		awk -F '_' '{ rgb = rgb " " $(NF - 1); hex = hex " " $NF }
					END { print rgb, hex }')

eval hex_ma=\$hex_a${main_accent_index:-2}
term_hex_ma=$hex_ma

if ((${#accent_colors[*]} < 6)) && [[ ! $no_accents ]]; then
	for accent in ${light_accents[*]}; do
		print_color $accent label
	done

	echo "not enough colors, exiting.."
	exit
fi

test() {
	set_vim() {
		cat <<- EOF
			let g:bg = 'none'
			let g:fg = '$hex_term_fg'
			let g:sfg = '$hex_a1'
			let g:vfg = '$hex_a2'
			let g:cfg = '${cfg_hex:-$hex_a3}'
			let g:ifg = '$hex_a4'
			let g:ffg = '$hex_a6'
			let g:nbg = 'none'
			let g:nfg = '$hex_pbg'
			let g:lbg = '$hex_sbg'
			let g:lfg = '$hex_a2'
			let g:syfg = '$hex_a3'
			let g:cmfg = '$hex_sfg'
			let g:slbg = '$hex_sbg'
			let g:slfg = '$hex_sfg'
			let g:fzfhl = '$hex_a2'
			let g:bcbg = '$hex_a6'
			let g:bdbg = '$hex_a2'
			let g:nmbg = '$hex_a4'
			let g:imbg = '$hex_a1'
			let g:vmbg = '$hex_a3'
		EOF
	}

	set_rofi() {
		local {rgb,hex}_rofi_{s,a,}bg
		read {rgb,hex}_rofi_abg <<< $(get_sbg $hex_sbg -5)
		read {rgb,hex}_rofi_hpfg <<< $(get_sbg $hex_pbg ${sign}15)
		read {rgb,hex}_rofi_pbg <<< $(get_sbg $hex_tbg ${sign}5)

		[[ $sign == + ]] &&
			bg_transparency=e esbg='#ffffff04' ||
			bg_transparency=d esbg='#00000014'

		cat <<- EOF
			bg: $hex_tbg;
			dmbg: $hex_tbg;
			dmbg: $hex_sbg;
			dmfg: $hex_pfg;
			dmsbg: $hex_pbg;
			hpfg: $hex_rofi_hpfg;
			tbg: argb:f0${hex_tbg#\#};
			tbg: argb:ea${hex_tbg#\#};
			tbg: argb:dd${hex_tbg#\#};
			tbg: argb:${bg_transparency}0${hex_tbg#\#};
			tbg: $hex_tbg${bg_transparency}0;
			tbg: argb:${bg_transparency}a${hex_tbg#\#};
			mbg: argb:f0${hex_bg#\#};
			msbg: argb:70${hex_rofi_pbg#\#};
			fg: $hex_sfg;
			bc: $hex_a6;
			bc: $hex_tbg;
			ibg: $hex_tbg;
			ibc: $hex_pbg;
			ibc: $hex_tbg;
			abg: #08080855;
			abg: #08080866;
			abg: #08080844;
			abg: ${hex_rofi_abg}b0;
			abg: ${hex_rofi_abg}dd;
			afg: $hex_pfg;
			ebg: $hex_tbg;
			esbg: $esbg;
			efg: $hex_ma;
			sbg: #e0e0e00e;
			sbg: #fafafa0a;
			sbg: #eeeeee0a;
			sbg: #cccccc0a;
			sbg: #dddddd0d;
			sbg: ${hex_rofi_pbg}b0;
			sbg: ${hex_rofi_pbg}d0;
			sfg: $hex_ma;
			sul: $hex_ma;
			lpc: $hex_fg;
			dpc: $hex_fg;
			btc: $hex_tbg;
			sbtc: $hex_tbg;
			btbc: $hex_tbg;
			ftbg: #00000000;
			sbbg: ${hex_ma}aa;
			sbsbg: #11111144;
			smbg: #03030333;
		EOF
	}

	under_join_bar() {
		#read {rgb,hex}_a2_dr <<< $(get_sbg $hex_a2 -22)
		#read {rgb,hex}_a2_br <<< $(get_sbg $hex_a2  +15)
		read {rgb,hex}_ma_dr <<< $(get_sbg $hex_ma -18)
		read {rgb,hex}_ma_br <<< $(get_sbg $hex_ma  +18)

		local {{rgb,hex}_,}bar_bg
		read {rgb,hex}_bar_bg <<< $(get_sbg $hex_bg +3)

		local transparency=dd

		local single_hex_bg=$hex_tbg
		local single_hex_bg="#$transparency${hex_bar_bg#\#}"

		cat <<- EOF
			bg ${single_hex_bg:-$bar_bg}
			fc ${single_hex_bg:-$bar_bg}
			pfc ${single_hex_bg:-$hex_ma_br}
			sfc ${single_hex_bg:-$hex_a6_dr}
			sfc ${single_hex_bg:-$hex_bg}
			pfc ${single_hex_bg:-$hex_ma_br}
			sfc ${single_hex_bg:-$hex_a6_dr}
			sfc $hex_sfg
			bfc ${single_hex_bg:-#$transparency${hex_bg#\#}}
			bfc ${single_hex_bg:-$bar_bg}
			bbg ${single_hex_bg:-$bar_bg}
			bbg $hex_bg
			jbg ${single_hex_bg:-$hex_bg}
			jpfg ${single_hex_fg:-$hex_a6_br}
			jsfg ${single_hex_fg:-$hex_a6_dr}
			jpfg ${single_hex_fg:-$hex_bar_pfg}
			jsfg ${single_hex_fg:-$hex_pfg}
			pbg ${single_hex_bg:-$hex_bg}
			pfg ${single_hex_fg:-$hex_bar_pfg}
			pfg $hex_bar_pfg
			sbg ${single_hex_bg:-$hex_bg}
			sfg ${single_hex_fg:-$hex_pfg}
			pbefg $hex_ma
			pbfg $hex_pfg
			mlfg $hex_a4
			msbg $hex_tbg
			mpfg $hex_bar_pfg
			mpbg $hex_pbg
			tbfg $hex_pfg
			Apfg $hex_bar_pfg
			Abfg $hex_a6
			Acbfg $hex_a6_dr
			Wsfg $hex_pfg
			Wpfg $hex_bar_pfg
			Nsbg $hex_pbg
			Tsbg $hex_pbg
			Tpbg $hex_pbg
			Ppbg $hex_ma
			Ppfg $hex_ma_br
			Ppfc $hex_ma_br
			Bpbg $hex_pbg
			tsbg $hex_pbg
		EOF
	}

	set_bar() {
		bar_conf=$(sed -n 's/^last_.*=\([^,]*\).*/\1/p' ~/.orw/scripts/barctl.sh)
		colorscheme=$(sed -n 's/\(\([^-]*\)-[^c]*\)c\s*\([^, ]*\).*/\3/p' \
			~/.config/orw/bar/configs/$bar_conf)
		#transparency=$(sed -n '/#bar/,/^$/ { s/^bg.*#\(.*\)\w\{6\}.*/\1/p }' \
		#	~/.config/orw/colorschemes/$colorscheme.ocs)

		unset single_bg transparency
		transparency=d0

		read {rgb,hex}_bar_bg <<< $(get_sbg $hex_pbg +5 -1)

		[[ ! $single_bg ]] &&
			local bar_bg="#$transparency${hex_pbg#\#}" ||
			local single_hex_bg="#$transparency${hex_bg#\#}" single_hex_fg=$hex_fg
		read {rgb,hex}_abg <<< $(get_sbg $hex_bg +8)

		((mono)) && local hex_a6=$hex_fg

		read {rgb,hex}_bar_pfg <<< $(get_sbg $hex_fg -15 -5)
		read {rgb,hex}_bar_lpbg <<< $(get_sbg $hex_pbg +5)
		read {rgb,hex}_bar_lpfg <<< $(get_sbg $hex_pfg +11)

		bar_bg=$hex_pbg

		local {rgb,hex}_a2_{b,d}r

		under_join_bar
	}

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

	#vim_conf=~/.orw/dotfiles/.config/nvim/colors/orw.vim
	#replace_colors vim | sed 's/.*:\([^ ]*\)[^'\'']*.\(.\w*\).*/\1 \2/'
	rofi_conf=~/.orw/dotfiles/.config/rofi/theme.rasi
	replace_colors rofi '\t'
	bar_conf=~/.orw/dotfiles/.config/orw/colorschemes/auto_generated.ocs
	replace_colors bar
}

#image_height=$(file $wallpaper | awk -F ',' '{
#		g = $(NF - (("'"${wallpaper##*.}"'" == "png") ? 2 : 1))
#		sub(".*x[^0-9]*", "", g)
#		print 10 / int(100 / (g / 100))
#	}')

vertical=$(file "$wallpaper" | awk -F ',' '{
		g = $(NF - (("'"${wallpaper##*.}"'" == "png") ? 2 : 1))
		split(g, ga, "\\s*x\\s*")
		print (ga[2] > ga[1])
	}')

gradient="\( gradient:black-white -posterize 30 -white-threshold 90% \)"

#((avg_saturation > 25)) &&
#	preview_opacity='aa' || preview_opacity='dd'

for rgb_color in rgb_{fg,{,s,p}bg} ${!rgb_a*}; do
	printf '%-8s' $rgb_color
	print_color "0_${!rgb_color}_0" label
	hex_color=${rgb_color/rgb/hex}

	[[ $hex_color =~ hex_(fg|a5) ]] && continue
	#preview_colors+="\( -size 20x15 xc:${!hex_color} $gradient -compose copyopacity -composite \) "
	((vertical)) &&
		preview_colors+="\( -size 8x20 xc:${!hex_color}$preview_opacity \) " ||
		preview_colors+="\( -size 20x8 xc:${!hex_color}$preview_opacity \) "

	#((vertical)) &&
	#	preview_colors+="\( -size 20x20 xc:${!hex_color}a0 \( $gradient \) -compose copyopacity -composite \) " ||
	#	preview_colors+="\( -size 13x33 xc:${!hex_color}a0 \( $gradient \) -compose copyopacity -composite -rotate 90 \) "
done

set_term() {
	awk '
		NR == FNR { bc[NR] = $0 }

		NR > FNR && /ground/ {
			sub("#\\w*", ($1 ~ "^b") ? "'${term_hex_bg:-$hex_bg}'" : "'$hex_term_fg'")
			ac = ac "," substr($1, 1, 1) "g " substr($NF, 2, 7)
		}

		nr && nr >= NR {
			c = bc[++bci]
			if (c) {
				split(c, acr, "_")
				c = ""
				if (b) {
					split(acr[2], rgb, ";")
					for (i in rgb) if (rgb[i]) {
						cv = rgb[i] + 30
						c = c "" sprintf("%.2x", (cv > 255) ? 255 : cv)
					}
					c = "#" c
				} else c = acr[3]

				sub("#[^\"]+", c)
			}

			ac = ac "," ((b) ? "br_" : "") $1 " " substr($NF, 2, 7)
		}

		/colors.(bright|normal)/ { bci = 0; nr = NR + 8; b = (/bright/) }
		NR > FNR { cf = cf "\n" $0 }
		END { print ",#term" ac cf }
		' <(tr ' ' '\n' <<< "${base_colors[*]}") $term_conf |
			{ read -r ac; tr "," "\n" <<< "$ac"; cat > $term_conf; }
}






#sleep 3
#term_conf=~/.orw/dotfiles/.config/alacritty/alacritty.toml
#set_term > ~/test.ocs

#test
#exit


#unset hex_ma{i,}
#echo ${!rgb*} #| cut -d ' ' -f 12,13
#sed -e 's/\(^\| \)/\1\$/g' -e 's/ \$[^ ]*i\b//g' <<< ${!rgb*} 
##echo ${!hex*}
#sed -e 's/\(^\| \)/\1\$/g' -e 's/ \$[^ ]*i\b//g' <<< ${!rgb*} | cut -d ' ' -f 2,3,5,6,12,13,17,18
##eval echo $(sed -e 's/\(^\| \)/ \$/g' -e 's/ \$[^ ]*i\b//g' <<< ${!rgb*} | cut -d ' ' -f 2,3,5,6,12,13,17,18)
##exit
##eval $(sed -e 's/\(^\| \)/ \$/g' -e 's/ \$[^ ]*i\b//g' \
##	<<< \${!hex*} | cut -d ' ' -f 2,3,5,6,12,13,16,17)
##exit

#sed -e 's/\(^\| \)/ \$/g' -e 's/ \$[^ ]*i\b//g' <<< ${!rgb*} 
#unset hex_ma
#sed -e 's/\(^\| \)/\1\$/g' -e 's/ \$[^ ]*i\b//g' <<< ${!rgb*} | cut -d ' ' -f 1,2,4,5,12,13,17,18
#sed -e 's/\(^\| \)/\1\$/g' -e 's/ \$[^ ]*i\b//g' <<< ${!hex*} | cut -d ' ' -f 1,2,4,5,12,13,17,18
#exit

#unset hex_mai
#sed -e 's/\(^\| \)/ \$/g' -e 's/ \$[^ ]*i\b//g' \
#		<<< ${!hex*} | cut -d ' ' -f 2,3,5,6,12,13,16,17
#exit

[[ $mode == light ]] && term_prefix='term_'
read ccc ${term_prefix}hex_{sbgi,pbgi,pfgi,mai} <<< \
	$(awk -i inplace '
		{
			if($2 == "'${term_hex_sbg:-$hex_sbg}'") sbgi = NR
			else if($2 == "'${term_hex_pbg:-$hex_pbg}'") pbgi = NR
			else if($2 == "'${term_hex_pfg:-$hex_pfg}'") pfgi = NR
			else if($2 == "'$hex_ma'") mai = NR
			else {
				if($1 ~ /^sbg[0-9]*$/) sbgc++
				else if($1 ~ /^pbg[0-9]*$/) pbgc++
				else if($1 ~ /^pfg[0-9]*$/) pfgc++
				else if($1 ~ /^ma[0-9]*$/) mac++
			}
		}

		{ print }
			
		ENDFILE {
			if(!sbgi) print "sbg" sbgc + 1 " '${term_hex_sbg:-$hex_sbg}'"
			if(!pbgi) print "pbg" pbgc + 1 " '${term_hex_pbg:-$hex_pbg}'"
			if(!pfgi) print "pfg" pfgc + 1 " '${term_hex_pfg:-$hex_pfg}'"
			if(!mai) print "ma" mac + 1 " '$hex_ma'"
		}

		END {
			ccc = NR

			if(!sbgi) sbgi = ++NR
			if(!pbgi) pbgi = ++NR
			if(!pfgi) pfgi = ++NR
			if(!mai) mai = ++NR

			print ccc, sbgi - 1, pbgi - 1, pfgi - 1, mai - 1
		}' ~/.config/orw/colorschemes/colors)

#echo $hex_mai, $term_hex_mai, $hex_ma, $term_hex_ma

#echo $term_hex_sbgi, $term_hex_pbgi, $term_hex_pfgi, $term_hex_mai
#echo $term_hex_sbg, $term_hex_pbg, $term_hex_pfg, $term_hex_mi
#echo $hex_sbgi, $hex_pbgi, $hex_pfgi, $hex_mai
#exit

term_conf=~/.orw/dotfiles/.config/alacritty/alacritty.toml

for color in hex_{sbg,pbg,pfg,ma}; do
	eval "read color index <<< \${!$term_prefix$color*}"
	((${!index} >= ccc)) &&
		new_indexed_colors+="\n\n[[colors.indexed_colors]]\ncolor = \\\"${!color}\\\"\nindex = ${!index}"
done

#awk -i inplace '
#	NR == FNR { bc[NR] = $0 }
#	#nr && nr >= NR {
#	#	c = bc[++bci]
#	#	if (c) {
#	#		sub("^.*_", "", c)
#	#		sub("#[^\"]+", c)
#	#	}
#	#}
#
#	nr && nr >= NR {
#		c = bc[++bci]
#		if (c) {
#			split(c, acr, "_")
#			c = ""
#			if (b) {
#				split(acr[2], rgb, ";")
#				for (i in rgb) if (rgb[i]) {
#					cv = rgb[i] + 30
#					c = c "" sprintf("%.2x", (cv > 255) ? 255 : cv)
#				}
#				c = "#" c
#			} else c = acr[3]
#
#			sub("#[^\"]+", c)
#		}
#	}
#
#	/colors.(bright|normal)/ { bci = 0; nr = NR + 8; b = (/bright/) }
#
#	NR > FNR { print }' \
#		<(tr ' ' '\n' <<< "${base_colors[*]}") $term_conf

set_term_old() {
	awk '
		NR == FNR { bc[NR] = $0 }

		NR > FNR && /ground/ {
			sub("#\\w*", ($1 ~ "^b") ? "'$hex_bg'" : "'$hex_term_fg'")
			ac = ac "," substr($1, 1, 1) "g " substr($NF, 2, 7)
		}

		nr && nr >= NR {
			c = bc[++bci]
			if (c) {
				split(c, acr, "_")
				c = ""
				if (b) {
					split(acr[2], rgb, ";")
					for (i in rgb) if (rgb[i]) {
						cv = rgb[i] + 30
						c = c "" sprintf("%.2x", (cv > 255) ? 255 : cv)
					}
					c = "#" c
				} else c = acr[3]

				sub("#[^\"]+", c)
			}

			ac = ac "," $1 " " substr($NF, 2, 7)
		}

		/colors.(bright|normal)/ { bci = 0; nr = NR + 8; b = (/bright/) }
		NR > FNR { cf = cf "\n" $0 }
		END { print "#term" ac cf }
		' <(tr ' ' '\n' <<< "${base_colors[*]}") ~/.config/alacritty/alacritty.toml |
			{ read -r ac; tr "," "\n" <<< "$ac"; cat > ~/.config/alacritty/alacritty.toml; }
}

[[ $new_indexed_colors ]] &&
	awk -i inplace '{ print } ENDFILE { print "'"${new_indexed_colors#\\n}"'" }' $term_conf

((mono)) &&
	br_dr_color=$hex_fg || br_dr_color=$hex_a6

if ((mono)); then
	read {rgb,hex}_a6_dr <<< $(get_sbg $hex_pfg +28)
	read {rgb,hex}_a6_br <<< $(get_sbg $br_dr_color +10)
else
	read {rgb,hex}_a6_dr <<< $(get_sbg $hex_a6 -9)
	read {rgb,hex}_a6_br <<< $(get_sbg $hex_a6  +9)
fi

set_ob() {
	local hex_a6_br=$hex_pfg hex_a6_dr=$hex_pbg
	cat <<- EOF
		#ob
		t $hex_a6_dr
		tb $hex_a6_dr
		b $hex_a6_dr
		c $hex_a6_dr
		it $hex_sbg
		itb $hex_sbg
		ib $hex_sbg
		ic $hex_sbg
		cbt $hex_a6_br
		mabt $hex_a6_br
		mibt $hex_a6_br
		cbth $hex_sfg
		mabth $hex_sfg
		mibth $hex_sfg
		ibt $hex_sbg
		ibth $hex_a6_br
		mbg $hex_sbg
		mfg $hex_pfg
		mtbg $hex_sbg
		mtfg $hex_pfg
		msbg $hex_pbg
		msfg $hex_ma
		mb $hex_sbg
		ms $hex_sbg
		bfg $hex_sbg
		bsfg $hex_pbg
		osd $hex_sbg
		osdh $hex_ma
		osdu $hex_pbg
		s $hex_a6_dr
	EOF

	local {rgb,hex}_{gradient_to,label}
	read {rgb,hex}_gradient_to <<< $(get_sbg $hex_a6_dr +5 -2)
	read {rgb,hex}_label <<< $(get_sbg $hex_a6_dr +3 -1)

	awk -i inplace '
		BEGIN {
			menu = "(border|separator|bullet.image|(title|items).bg).*.color:"
			active = "(label.text|client|handle|grip|.*(title|border|button..*bg)).*.color:"
			button = "button.*\\.(hover|pressed).image.color:"
			button_end = "..*.image.color:"
			osd = "osd.(bg|label|button|border).*.color:"
		}

		$1 ~ "inactive.button.image.color" { $NF = "'$hex_bg'" }
		$1 ~ "inactive." button { $NF = "'$hex_bg'" }

		$1 ~  "menu" {
			if ($1 ~ "menu.*active.text.color") $NF = "'$hex_ma'"
			if ($1 ~ "menu.*active.bg.color") $NF = "'$hex_pbg'"
			if ($1 ~ "menu.title.text.color") $NF = "'$hex_pfg'"
			if ($1 ~ "menu.items.text.color") $NF = "'$hex_pfg'"
			if ($1 ~ "menu." menu) $NF = "'$hex_sbg'"
		}

		$1 ~ "bullet.selected.image" { $NF = "'$hex_pbg'" }

		#$1 ~ "inactive." active { $NF = "'$hex_a6_dr'" }
		#$1 ~ "\\.active." active { $NF = "'$hex_a6_br'" }

		#$1 ~ "button" {
		#	if ($1 ~ "\\.active." button) $NF = "'$hex_pbg'"
		#	if ($1 ~ "\\.active.button.max" button_end) $NF = "'$hex_a2'"
		#	if ($1 ~ "\\.active.button.close" button_end) $NF = "'$hex_a1'"
		#	if ($1 ~ "\\.active.button.iconify" button_end) $NF = "'$hex_a3'"
		#}

		$1 ~ "inactive." active { $NF = "'$hex_sbg'" }
		$1 ~ "inactive.button..*" button_end { $NF = "'$hex_sbg'" }

		$1 ~ "\\.active." active { $NF = "'$hex_a6_dr'" }
		$1 ~ "\\.active.button..*" button_end { $NF = "'$hex_sfg'" }
		$1 ~ "\\.active." button { $NF = "'$hex_a6_br'" }

		$1 ~ "\\.active.label.*color" { $NF = "'$hex_a6_dr'" }
		$1 ~ "colorTo" { $NF = "'$hex_a6_dr'" }

		$1 ~ "osd.unhilight" { $NF = "'$hex_pbg'" }
		$1 ~ "osd.hilight" { $NF = "'$hex_ma'" }
		$1 ~ osd { $NF = "'$hex_sbg'" }

		{ print }' $ob_conf
}

bar_under_dock() {
	bar_bg="#00${hex_pbg:1}"
	cat <<- EOF
		bg ${single_hex_bg:-$bar_bg}
		fc ${single_hex_bg:-$bar_bg}
		pfc ${single_hex_bg:-$hex_a6_br}
		sfc ${single_hex_bg:-$hex_a6_dr}
		sfc ${single_hex_bg:-$hex_pbg}
		bfc ${single_hex_bg:-#$transparency${hex_bg#\#}}
		bfc $bar_bg
		bbg ${single_hex_bg:-$bar_bg}
		jbg ${single_hex_bg:-$hex_bg}
		jpfg ${single_hex_fg:-$hex_a6_br}
		jsfg ${single_hex_fg:-$hex_a6_dr}
		jpfg ${single_hex_fg:-$hex_bar_pfg}
		jsfg ${single_hex_fg:-$hex_pfg}
		pbg ${single_hex_bg:-$hex_bg}
		pfg ${single_hex_fg:-$hex_bar_pfg}
		sbg ${single_hex_bg:-$hex_bg}
		sfg ${single_hex_fg:-$hex_pfg}
		pbefg $hex_ma
		pbfg $hex_pfg
		mlfg $hex_a4
		tbfg $hex_pfg
		Psbg $hex_sbg
		Psfg $hex_sfg
		Apfg $hex_bar_pfg
		Abfg $hex_a6
		Acbfg $hex_a6_dr
		Wsbg $bar_bg
		Wsbg $hex_bg
		Wpbg $bar_bg
		Wpbg $hex_bg
		Wsfg $hex_pfg
		Lsbg #$transparency${hex_bg#\#}
		Lsbg $bar_bg
		Lsbg $hex_bg
		Lsfg $hex_sfg
		Lpbg #$transparency${hex_bg#\#}
		Lpbg $bar_bg
		Lpbg $hex_bg
		Lpfg $hex_bar_lpfg
		Lpfg $hex_bar_lpfg
		Labg #$transparency${hex_sbg#\#}
		Labg #$transparency${hex_bg#\#}
		Labg $hex_bar_lpbg
		Labg $hex_sbg
		Lafg $hex_bar_pfg
		Lafg $hex_ma
		Lafg $hex_fg
		Lsfc $hex_a6_dr
		Lsfc $hex_pbg
	EOF
}

bar_under_dock_joined() {
	read {rgb,hex}_a2_dr <<< $(get_sbg $hex_a2 -22)
	read {rgb,hex}_a2_br <<< $(get_sbg $hex_a2  +5)

	cat <<- EOF
		bg ${single_hex_bg:-$bar_bg}
		fc ${single_hex_bg:-$bar_bg}
		pfc ${single_hex_bg:-$hex_a2_br}
		sfc ${single_hex_bg:-$hex_a6_dr}
		sfc ${single_hex_bg:-$hex_bg}
		bfc ${single_hex_bg:-#$transparency${hex_bg#\#}}
		bfc $bar_bg
		bbg ${single_hex_bg:-$bar_bg}
		jbg ${single_hex_bg:-$hex_bg}
		jpfg ${single_hex_fg:-$hex_a6_br}
		jsfg ${single_hex_fg:-$hex_a6_dr}
		jpfg ${single_hex_fg:-$hex_bar_pfg}
		jsfg ${single_hex_fg:-$hex_pfg}
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
		Abfg $hex_a6
		Acbfg $hex_a6_dr
		Wsbg $bar_bg
		Wsbg $hex_bg
		Wpbg $bar_bg
		Wpbg $hex_bg
		Wsfg $hex_pfg
		Wsfc $hex_a2_dr
		Lsbg #$transparency${hex_bg#\#}
		Lsbg $bar_bg
		Lsbg $hex_bg
		Lsfg $hex_sfg
		Lpbg #$transparency${hex_bg#\#}
		Lpbg $bar_bg
		Lpbg $hex_bg
		Lpfg $hex_bar_lpfg
		Lpfg $hex_bar_lpfg
		Labg #$transparency${hex_sbg#\#}
		Labg #$transparency${hex_bg#\#}
		Labg $hex_bar_lpbg
		Labg $hex_sbg
		Lafg $hex_bar_pfg
		Lafg $hex_ma
		Lafg $hex_fg
		Lsfc $hex_a2_dr
	EOF
}

under_join_bar() {
	#read {rgb,hex}_a2_dr <<< $(get_sbg $hex_a2 -22)
	#read {rgb,hex}_a2_br <<< $(get_sbg $hex_a2  +15)
	read {rgb,hex}_ma_dr <<< $(get_sbg $hex_ma -18)
	read {rgb,hex}_ma_br <<< $(get_sbg $hex_ma  +18)

	local {{rgb,hex}_,}bar_bg
	read {rgb,hex}_bar_bg <<< $(get_sbg $hex_bg +3)

	local transparency=ff

	local single_hex_bg=$hex_tbg
	local single_hex_bg="#$transparency${hex_bar_bg#\#}"

	cat <<- EOF
		bg ${single_hex_bg:-$bar_bg}
		fc ${single_hex_bg:-$bar_bg}
		pfc ${single_hex_bg:-$hex_ma_br}
		sfc ${single_hex_bg:-$hex_a6_dr}
		sfc ${single_hex_bg:-$hex_bg}
		pfc ${single_hex_bg:-$hex_ma_br}
		sfc ${single_hex_bg:-$hex_a6_dr}
		sfc $hex_sfg
		bfc ${single_hex_bg:-#$transparency${hex_bg#\#}}
		bfc ${single_hex_bg:-$bar_bg}
		bbg ${single_hex_bg:-$bar_bg}
		bbg $hex_bg
		jbg ${single_hex_bg:-$hex_bg}
		jpfg ${single_hex_fg:-$hex_a6_br}
		jsfg ${single_hex_fg:-$hex_a6_dr}
		jpfg ${single_hex_fg:-$hex_bar_pfg}
		jsfg ${single_hex_fg:-$hex_pfg}
		pbg ${single_hex_bg:-$hex_bg}
		pfg ${single_hex_fg:-$hex_bar_pfg}
		pfg $hex_bar_pfg
		sbg ${single_hex_bg:-$hex_bg}
		sfg ${single_hex_fg:-$hex_pfg}
		pbefg $hex_ma
		pbfg $hex_pfg
		mlfg $hex_a4
		msbg $hex_tbg
		mpfg $hex_bar_pfg
		mpbg $hex_pbg
		tbfg $hex_pfg
		Apfg $hex_bar_pfg
		Abfg $hex_a6
		Acbfg $hex_a6_dr
		Wsfg $hex_pfg
		Wpfg $hex_bar_pfg
		Nsbg $hex_pbg
		Tsbg $hex_pbg
		Tpbg $hex_pbg
		Ppbg $hex_ma
		Ppfg $hex_ma_br
		Ppfc $hex_ma_br
		Bpbg $hex_pbg
		tsbg $hex_pbg
	EOF
}

duo_bar() {
	#read {rgb,hex}_a2_dr <<< $(get_sbg $hex_a2 -22)
	#read {rgb,hex}_a2_br <<< $(get_sbg $hex_a2  +15)
	read {rgb,hex}_ma_dr <<< $(get_sbg $hex_ma -11)
	read {rgb,hex}_ma_br <<< $(get_sbg $hex_ma  +11)

	local {{rgb,hex}_,}bar_bg
	read {rgb,hex}_bar_bg <<< $(get_sbg $hex_bg +3)

	local bar_bg=$hex_bg
	#local transparency=ff
	#local single_hex_bg=$hex_tbg
	#local single_hex_bg="#$transparency${hex_bar_bg#\#}"
	#local single_hex_bg="#$transparency${hex_bar_bg#\#}"

	cat <<- EOF
		bg ${single_hex_bg:-$bar_bg}
		fc ${single_hex_bg:-$bar_bg}
		pfc ${single_hex_bg:-$hex_ma_br}
		sfc ${single_hex_bg:-$hex_a6_dr}
		sfc ${single_hex_bg:-$hex_bg}
		pfc ${single_hex_bg:-$hex_ma_br}
		sfc ${single_hex_bg:-$hex_a6_dr}
		sfc $hex_sfg
		bfc ${single_hex_bg:-#$transparency${hex_bg#\#}}
		bfc ${single_hex_bg:-$bar_bg}
		bbg ${single_hex_bg:-$bar_bg}
		bbg $hex_bg
		jbg ${single_hex_bg:-$hex_bg}
		jpfg ${single_hex_fg:-$hex_a6_br}
		jsfg ${single_hex_fg:-$hex_a6_dr}
		jpfg ${single_hex_fg:-$hex_bar_pfg}
		jsfg ${single_hex_fg:-$hex_pfg}
		pbg ${single_hex_bg:-$hex_pbg}
		pfg ${single_hex_fg:-$hex_bar_pfg}
		pfg $hex_bar_pfg
		sbg ${single_hex_bg:-$hex_sbg}
		sfg ${single_hex_fg:-$hex_pfg}
		pbefg $hex_ma
		pbfg $hex_pfg
		mlfg $hex_a4
		mpfg $hex_bar_pfg
		mpbg $hex_pbg
		tbfg $hex_pfg
		Apfg $hex_bar_pfg
		Abfg $hex_a6
		Acbfg $hex_a6_dr
		Wsbg $bar_bg
		Wpbg $bar_bg
		Wpfg $hex_ma
		Nsbg $hex_sbg
		Ppbg $hex_ma
		Ppfg $hex_ma_br
		tsbg $hex_sbg
	EOF
}

colors_bar() {
	#read {rgb,hex}_a2_dr <<< $(get_sbg $hex_a2 -22)
	#read {rgb,hex}_a2_br <<< $(get_sbg $hex_a2  +15)
	read {rgb,hex}_ma_dr <<< $(get_sbg $hex_ma -18)
	read {rgb,hex}_ma_br <<< $(get_sbg $hex_ma  +18)

	local {{rgb,hex}_,}bar_bg
	read {rgb,hex}_bar_bg <<< $(get_sbg $hex_bg +3)

	local bar_bg=$hex_bg
	#local transparency=ff
	#local single_hex_bg=$hex_tbg
	#local single_hex_bg="#$transparency${hex_bar_bg#\#}"

	read cyan green magenta red yellow <<< $(awk '
		/red|green|yellow|magenta|cyan/ { print substr($NF, 2, 7) }
		' $term_conf | head -5 | xargs)

	cat <<- EOF
		bg ${single_hex_bg:-$bar_bg}
		fc ${single_hex_bg:-$bar_bg}
		pfc ${single_hex_bg:-$hex_ma_br}
		sfc ${single_hex_bg:-$hex_a6_dr}
		sfc ${single_hex_bg:-$hex_bg}
		pfc ${single_hex_bg:-$hex_ma_br}
		sfc ${single_hex_bg:-$hex_a6_dr}
		sfc $hex_sfg
		bfc ${single_hex_bg:-#$transparency${hex_bg#\#}}
		bfc ${single_hex_bg:-$bar_bg}
		bbg ${single_hex_bg:-$bar_bg}
		bbg $hex_bg
		jbg ${single_hex_bg:-$hex_bg}
		jpfg ${single_hex_fg:-$hex_a6_br}
		jsfg ${single_hex_fg:-$hex_a6_dr}
		jpfg ${single_hex_fg:-$hex_bar_pfg}
		jsfg ${single_hex_fg:-$hex_pfg}
		pbg ${single_hex_bg:-$hex_pbg}
		pfg ${single_hex_fg:-$hex_bar_pfg}
		pfg $hex_bar_pfg
		sbg ${single_hex_bg:-$hex_sbg}
		sfg ${single_hex_fg:-$hex_pfg}
		pbefg $hex_ma
		pbfg $hex_pfg
		mlfg $hex_a4
		mpfg $hex_bar_pfg
		tbfg $hex_pfg
		Apfg $hex_bar_pfg
		Abfg $hex_a6
		Acbfg $hex_a6_dr
		Wsbg $bar_bg
		Wpbg $bar_bg
		Nsbg $hex_sbg
		Tsbg $magenta
		Tpbg $hex_pbg
		Ppbg $hex_ma
		Ppfg $hex_ma_br
		esbg $red
		vsbg $yellow
		Bpbg $green
		tsbg $hex_sbg
	EOF
}

uno_bar() {
	#read {rgb,hex}_a2_dr <<< $(get_sbg $hex_a2 -22)
	#read {rgb,hex}_a2_br <<< $(get_sbg $hex_a2  +15)
	read {rgb,hex}_ma_dr <<< $(get_sbg $hex_ma -18)
	read {rgb,hex}_ma_br <<< $(get_sbg $hex_ma  +18)

	local {{rgb,hex}_,}bar_bg
	read {rgb,hex}_bar_bg <<< $(get_sbg $hex_bg +3)

	local bar_bg=$hex_bg
	#local transparency=ff
	#local single_hex_bg=$hex_tbg
	#local single_hex_bg="#$transparency${hex_bar_bg#\#}"

	cat <<- EOF
		bg ${single_hex_bg:-$bar_bg}
		fc ${single_hex_bg:-$bar_bg}
		pfc ${single_hex_bg:-$hex_ma_br}
		sfc ${single_hex_bg:-$hex_a6_dr}
		sfc ${single_hex_bg:-$hex_bg}
		pfc ${single_hex_bg:-$hex_ma_br}
		sfc ${single_hex_bg:-$hex_a6_dr}
		sfc $hex_sfg
		bfc ${single_hex_bg:-#$transparency${hex_bg#\#}}
		bfc ${single_hex_bg:-$bar_bg}
		bbg ${single_hex_bg:-$bar_bg}
		bbg $hex_bg
		jbg ${single_hex_bg:-$hex_bg}
		jpfg ${single_hex_fg:-$hex_a6_br}
		jsfg ${single_hex_fg:-$hex_a6_dr}
		jpfg ${single_hex_fg:-$hex_bar_pfg}
		jsfg ${single_hex_fg:-$hex_pfg}
		pbg ${single_hex_bg:-$hex_sbg}
		pfg ${single_hex_fg:-$hex_bar_pfg}
		pfg $hex_bar_pfg
		sbg ${single_hex_bg:-$hex_sbg}
		sfg ${single_hex_fg:-$hex_pfg}
		pbefg $hex_ma
		pbfg $hex_pfg
		mlfg $hex_a4
		mpfg $hex_bar_pfg
		mpbg $hex_pbg
		tbfg $hex_pfg
		Apfg $hex_bar_pfg
		Abfg $hex_a6
		Acbfg $hex_a6_dr
		Wsbg $bar_bg
		Wpbg $bar_bg
		Nsbg $hex_sbg
		tsbg $hex_sbg
		Tpbg $hex_pbg
		Ppbg $hex_ma
		Ppfg $hex_ma_br
	EOF
}

mono_bar() {
	#read {rgb,hex}_a2_dr <<< $(get_sbg $hex_a2 -22)
	#read {rgb,hex}_a2_br <<< $(get_sbg $hex_a2  +15)
	read {rgb,hex}_ma_dr <<< $(get_sbg $hex_ma -18)
	read {rgb,hex}_ma_br <<< $(get_sbg $hex_ma  +18)

	local {{rgb,hex}_,}bar_bg
	read {rgb,hex}_bar_bg <<< $(get_sbg $hex_bg +3)

	local transparency=ff
	local single_hex_bg=$hex_tbg
	local single_hex_bg="#$transparency${hex_bar_bg#\#}"
	local single_hex_fg=$hex_bar_pfg

	cat <<- EOF
		bg ${single_hex_bg:-$bar_bg}
		fc ${single_hex_bg:-$bar_bg}
		pfc ${single_hex_bg:-$hex_ma_br}
		sfc ${single_hex_bg:-$hex_a6_dr}
		sfc ${single_hex_bg:-$hex_bg}
		pfc ${single_hex_bg:-$hex_ma_br}
		sfc ${single_hex_bg:-$hex_a6_dr}
		sfc $hex_sfg
		bfc ${single_hex_bg:-#$transparency${hex_bg#\#}}
		bfc ${single_hex_bg:-$bar_bg}
		bbg ${single_hex_bg:-$bar_bg}
		bbg $hex_bg
		jbg ${single_hex_bg:-$hex_bg}
		jpfg ${single_hex_fg:-$hex_a6_br}
		jsfg ${single_hex_fg:-$hex_a6_dr}
		jpfg ${single_hex_fg:-$hex_bar_pfg}
		jsfg ${single_hex_fg:-$hex_pfg}
		pbg ${single_hex_bg:-$hex_sbg}
		pfg ${single_hex_fg:-$hex_bar_pfg}
		pfg $hex_bar_pfg
		sbg ${single_hex_bg:-$hex_sbg}
		sfg ${single_hex_fg:-$hex_pfg}
		pbefg $hex_ma
		pbfg $hex_pfg
		mlfg $hex_a4
		msbg $hex_tbg
		mpfg $hex_bar_pfg
		mpbg $hex_pbg
		tbfg $hex_pfg
		Apfg $hex_bar_pfg
		Abfg $hex_a6
		Acbfg $hex_a6_dr
		Wsbg $bar_bg
		Wpbg $bar_bg
		Nsbg $hex_sbg
		Ppbg $hex_ma
		Ppfg $hex_ma_br
		tsbg $hex_sbg
	EOF
}

split_join_bar() {
	#read {rgb,hex}_a2_dr <<< $(get_sbg $hex_a2 -22)
	read {rgb,hex}_a2_dr <<< $(get_sbg $hex_a2 -10)
	read {rgb,hex}_a2_br <<< $(get_sbg $hex_a2  +10)

	local {{rgb,hex}_,}bar_bg
	read {rgb,hex}_bar_bg <<< $(get_sbg $hex_bg +3)

	local transparency=f0

	local single_hex_bg="#$transparency${hex_bar_bg#\#}"
	local single_hex_bg=$hex_tbg

	cat <<- EOF
		bg ${single_hex_bg:-$bar_bg}
		fc ${single_hex_bg:-$bar_bg}
		pfc ${single_hex_bg:-$hex_a2_br}
		sfc ${single_hex_bg:-$hex_a6_dr}
		sfc ${single_hex_bg:-$hex_bg}
		pfc ${single_hex_bg:-$hex_a2_br}
		sfc ${single_hex_bg:-$hex_a6_dr}
		sfc $hex_sfg
		bfc ${single_hex_bg:-#$transparency${hex_bg#\#}}
		bfc ${single_hex_bg:-$bar_bg}
		bbg ${single_hex_bg:-$bar_bg}
		bbg $hex_bg
		jbg ${single_hex_bg:-$hex_bg}
		jpfg ${single_hex_fg:-$hex_a6_br}
		jsfg ${single_hex_fg:-$hex_a6_dr}
		jpfg ${single_hex_fg:-$hex_bar_pfg}
		jsfg ${single_hex_fg:-$hex_pfg}
		pbg ${single_hex_bg:-$hex_bg}
		pfg ${single_hex_fg:-$hex_bar_pfg}
		pfg $hex_bar_pfg
		sbg ${single_hex_bg:-$hex_bg}
		sfg ${single_hex_fg:-$hex_pfg}
		mlfg $hex_a4
		msbg $hex_tbg
		mpfg $hex_bar_pfg
		mpbg $hex_pbg
		msfc $hex_a2
		pbefg $hex_a2_br
		pbfg $hex_a2_dr
		tbfg $hex_pfg
		Apfg $hex_bar_pfg
		Abfg $hex_a6
		Acbfg $hex_a6_dr
		Wsfg $hex_pfg
		Wpfg $hex_bar_pfg
		Wpfc $hex_a2_dr
		Wsbg $hex_pbg
		Wpbg $hex_pbg
		Nsbg $hex_pbg
		Tsbg $hex_pbg
		Tpbg $hex_pbg
	EOF
}

bar_under_dock_joined_reversed() {
	local hex_bg=$bar_bg
	cat <<- EOF
		bg ${single_hex_bg:-$hex_bg}
		fc ${single_hex_bg:-$bar_sbg}
		pfc ${single_hex_bg:-$hex_a6_br}
		sfc ${single_hex_bg:-$hex_a6_dr}
		sfc ${single_hex_bg:-$hex_sbg}
		bfc ${single_hex_bg:-#$transparency${hex_sbg#\#}}
		bfc $hex_bg
		bbg ${single_hex_bg:-$bar_sbg}
		jbg ${single_hex_bg:-$hex_sbg}
		jpfg ${single_hex_fg:-$hex_a6_br}
		jsfg ${single_hex_fg:-$hex_a6_dr}
		jpfg ${single_hex_fg:-$hex_bar_pfg}
		jsfg ${single_hex_fg:-$hex_pfg}
		pbg ${single_hex_bg:-$hex_sbg}
		pfg ${single_hex_fg:-$hex_bar_pfg}
		sbg ${single_hex_bg:-$hex_sbg}
		sfg ${single_hex_fg:-$hex_pfg}
		pbefg $hex_ma
		pbfg $hex_pfg
		mlfg $hex_a4
		tbfg $hex_pfg
		Psbg $hex_sbg
		Psfg $hex_sfg
		Apfg $hex_bar_pfg
		Abfg $hex_a6
		Acbfg $hex_a6_dr
		Wsbg $bar_sbg
		Wsbg $hex_sbg
		Wpbg $bar_sbg
		Wpbg $hex_sbg
		Wsfg $hex_pfg
		Lsbg #$transparency${hex_sbg#\#}
		Lsbg $bar_sbg
		Lsbg $hex_sbg
		Lsfg $hex_sfg
		Lpbg #$transparency${hex_sbg#\#}
		Lpbg $bar_sbg
		Lpbg $hex_sbg
		Lpfg $hex_bar_lpfg
		Lpfg $hex_bar_lpfg
		Labg #$transparency${hex_sbg#\#}
		Labg #$transparency${hex_sbg#\#}
		Labg $hex_bar_lpbg
		Labg $hex_sbg
		Lafg $hex_bar_pfg
		Lafg $hex_ma
		Lafg $hex_fg
		Lsfc $hex_a6_dr
	EOF
}

set_bar() {
	bar_conf=$(sed -n 's/^last_.*=\([^,]*\).*/\1/p' ~/.orw/scripts/barctl.sh)
	colorscheme=$(sed -n 's/\(\([^-]*\)-[^c]*\)c\s*\([^, ]*\).*/\3/p' \
		~/.config/orw/bar/configs/$bar_conf)
	#transparency=$(sed -n '/#bar/,/^$/ { s/^bg.*#\(.*\)\w\{6\}.*/\1/p }' \
	#	~/.config/orw/colorschemes/$colorscheme.ocs)

	unset single_bg transparency
	transparency=d0

	read {rgb,hex}_bar_bg <<< $(get_sbg $hex_pbg +5 -1)

	[[ ! $single_bg ]] &&
		local bar_bg="#$transparency${hex_pbg#\#}" ||
		local single_hex_bg="#$transparency${hex_bg#\#}" single_hex_fg=$hex_fg
	read {rgb,hex}_abg <<< $(get_sbg $hex_bg +8)

	((mono)) && local hex_a6=$hex_fg

	read {rgb,hex}_bar_pfg <<< $(get_sbg $hex_fg -15 -5)
	read {rgb,hex}_bar_lpbg <<< $(get_sbg $hex_pbg +5)
	read {rgb,hex}_bar_lpfg <<< $(get_sbg $hex_pfg +11)

	bar_bg=$hex_pbg
	hex_bar_pfg=$hex_fg

	local {rgb,hex}_a2_{b,d}r

	#under_join_bar
	#colors_bar
	duo_bar
	#uno_bar
	#mono_bar
}

set_bash() {
	[[ $1 ]] &&
		local ma_hex=$hex_ma && unset hex_ma{,i} || local type=rgb

	[[ $mode == light ]] &&
		local rgb_pbg=$term_rgb_pbg rgb_pfg=$term_rgb_pfg rgb_tbg=$term_rgb_tbg \
		hex_pbg=$term_hex_pbg hex_pfg=$term_hex_pfg hex_tbg=$term_hex_tbg

	eval "color_string=\$(sed -e 's/\(^\| \)/\1\$/g' -e 's/ \$[^ ]*i\b//g' \
		<<< \${!${type:-hex}*} | cut -d ' ' -f 1,2,3,6,12,13,16,17)"
	eval "bash_colors=( $color_string )"

	[[ $ma_hex ]] && hex_ma=$ma_hex

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

set_rofi() {
	local {rgb,hex}_rofi_{s,a,}bg
	read {rgb,hex}_rofi_abg <<< $(get_sbg $hex_sbg -5)
	read {rgb,hex}_rofi_hpfg <<< $(get_sbg $hex_pbg +15)
	read {rgb,hex}_rofi_pbg <<< $(get_sbg $hex_tbg +5)

	cat <<- EOF
		bg: $hex_tbg;
		dmbg: $hex_tbg;
		dmbg: $hex_sbg;
		dmfg: $hex_pfg;
		dmsbg: $hex_pbg;
		hpfg: $hex_rofi_hpfg;
		tbg: argb:f0${hex_tbg#\#};
		tbg: argb:ea${hex_tbg#\#};
		tbg: argb:dd${hex_tbg#\#};
		tbg: argb:f0${hex_tbg#\#};
		mbg: argb:f0${hex_bg#\#};
		msbg: argb:70${hex_rofi_pbg#\#};
		fg: $hex_sfg;
		bc: $hex_a6;
		bc: $hex_tbg;
		ibg: $hex_tbg;
		ibc: $hex_pbg;
		ibc: $hex_tbg;
		abg: #08080855;
		abg: #08080866;
		abg: #08080844;
		abg: ${hex_rofi_abg}b0;
		abg: ${hex_rofi_abg}dd;
		afg: $hex_pfg;
		ebg: $hex_tbg;
		efg: $hex_ma;
		sbg: #e0e0e00e;
		sbg: #fafafa0a;
		sbg: #eeeeee0a;
		sbg: #cccccc0a;
		sbg: #dddddd0d;
		sbg: ${hex_rofi_pbg}b0;
		sbg: ${hex_rofi_pbg}d0;
		sfg: $hex_ma;
		sul: $hex_ma;
		lpc: $hex_fg;
		dpc: $hex_fg;
		btc: $hex_tbg;
		sbtc: $hex_tbg;
		btbc: $hex_tbg;
		ftbg: #00000000;
		sbbg: ${hex_ma}aa;
		sbsbg: #11111144;
		smbg: #03030333;
	EOF
}

set_rofi() {
	local {rgb,hex}_rofi_{s,a,}bg
	read {rgb,hex}_rofi_abg <<< $(get_sbg $hex_sbg -5)
	read {rgb,hex}_rofi_hpfg <<< $(get_sbg $hex_pbg ${sign}15)
	read {rgb,hex}_rofi_pbg <<< $(get_sbg $hex_tbg ${sign}5)

	[[ $sign == + ]] &&
		bg_transparency=e esbg='#ffffff04' ||
		bg_transparency=c esbg='#00000014'

	bg_transparency=e
	cat <<- EOF
		bg: $hex_tbg;
		dmbg: $hex_tbg;
		dmbg: $hex_sbg;
		dmfg: $hex_pfg;
		dmsbg: $hex_pbg;
		hpfg: $hex_rofi_hpfg;
		tbg: argb:f0${hex_tbg#\#};
		tbg: argb:ea${hex_tbg#\#};
		tbg: argb:dd${hex_tbg#\#};
		tbg: argb:${bg_transparency}8${hex_tbg#\#};
		tbg: $hex_tbg${bg_transparency}0;
		tbg: argb:${bg_transparency}d${hex_tbg#\#};
		mbg: argb:f0${hex_bg#\#};
		msbg: argb:70${hex_rofi_pbg#\#};
		fg: $hex_pfg;
		bc: $hex_a6;
		bc: $hex_tbg;
		ibg: $hex_tbg;
		ibc: $hex_pbg;
		ibc: $hex_tbg;
		abg: #08080855;
		abg: #08080866;
		abg: #08080844;
		abg: ${hex_rofi_abg}b0;
		abg: ${hex_rofi_abg}dd;
		abg: #00000030;
		afg: $hex_sfg;
		ebg: $hex_tbg;
		esbg: $esbg;
		efg: $hex_ma;
		sbg: #e0e0e00e;
		sbg: #fafafa0a;
		sbg: #eeeeee0a;
		sbg: #cccccc0a;
		sbg: #dddddd0d;
		sbg: ${hex_rofi_pbg}b0;
		sbg: ${hex_rofi_pbg}d0;
		sfg: $hex_ma;
		sul: $hex_ma;
		lpc: $hex_fg;
		dpc: $hex_fg;
		btc: $hex_tbg;
		sbtc: $hex_tbg;
		btbc: $hex_tbg;
		ftbg: #00000000;
		sbbg: ${hex_ma}aa;
		sbsbg: #11111144;
		smbg: #03030333;
	EOF
}

set_vim() {
	cat <<- EOF
		let g:bg = 'none'
		let g:fg = '$hex_term_fg'
		let g:sfg = '$hex_a1'
		let g:vfg = '$hex_a2'
		let g:cfg = '${cfg_hex:-$hex_a3}'
		let g:ifg = '$hex_a4'
		let g:ffg = '$hex_a6'
		let g:nbg = 'none'
		let g:nfg = '${term_hex_pbg:-$hex_pbg}'
		let g:lbg = '${term_hex_sbg:-$hex_sbg}'
		let g:lfg = '$hex_a2'
		let g:syfg = '$hex_a3'
		let g:cmfg = '${term_hex_sfg:-$hex_sfg}'
		let g:slbg = '${term_hex_sbg:-$hex_sbg}'
		let g:slfg = '${term_hex_sfg:-$hex_sfg}'
		let g:fzfhl = '$hex_a2'
		let g:bcbg = '$hex_a6'
		let g:bdbg = '$hex_a2'
		let g:nmbg = '$hex_a4'
		let g:imbg = '$hex_a1'
		let g:vmbg = '$hex_a3'
	EOF
}

set_tmux() {
	cat <<- EOF
		bg='terminal'
		fg='${term_hex_sfg:-$hex_sfg}'
		bc='${term_hex_sbg:-$hex_sbg}'
		mc='$hex_a6'
		ibg='${term_hex_sbg:-$hex_sbg}'
		ifg='${term_hex_sfg:-$hex_sfg}'
		sfg='${term_hex_sfg:-$hex_sfg}'
		wbg='${term_hex_sbg:-$hex_sbg}'
		wfg='${term_hex_sfg:-$hex_sfg}'
		cbg='${term_hex_pbg:-$hex_pbg}'
		cfg='$hex_ma'
	EOF
}

set_dunst() {
	cat <<- EOF
		background = \"$hex_tbg\"
		foreground = \"$hex_fg\"
		frame_color = \"$hex_a6\"
	EOF
}

set_dunst_custom() {
	[[ $mode == dark ]] &&
		local sbg=$hex_pbg || local sbg=$hex_sbg
	cat <<- EOF
		sbg=\"$sbg\"
		pbfg=\"$hex_ma\"
	EOF
}

set_nb() {
	if [[ $1 ]]; then
		cat <<- EOF
			fg ${term_hex_pbg:-$hex_pbg}
			pfg ${term_hex_sbg:-$hex_sbg}
			pbg default
			ifg ${term_hex_pfg:-$hex_pfg}
			ibg ${term_hex_pbg:-$hex_pbg}
			EOF
	else
		cat <<- EOF
			color listnormal color${hex_pbgi} default
			color listfocus color${hex_pfgi} color${hex_sbgi}
			color listnormal_unread color${hex_pfgi} default
			color listfocus_unread color${hex_mai} color${hex_sbgi}
			color info color${hex_pfgi} color${hex_sbgi}
		EOF
	fi
}

set_vifm() {
	local slbg {sl,c,}fg
	[[ $1 ]] &&
		fg=$hex_pbg cbg=$hex_sbg cfg=$hex_ma slbg=$hex_sbg slfg=$hex_pfg ||
		fg=$hex_pbgi cbg=$hex_sbgi cfg=$hex_mai slbg=$hex_sbgi slfg=$hex_pfgi

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
	cat <<- EOF

		#ncmpcpp
		npp ${term_hex_pfg:-$hex_pfg}
		np ${term_hex_pfg:-$hex_pfg}
		sip ${term_hex_pbg:-$hex_pbg}
		sc ${term_hex_pbg:-$hex_pbg}
		mwc ${term_hex_pbg:-$hex_pbg}
		etc #191e24
		c2 #DBBD7D
		pc ${term_hex_pbg:-$hex_pbg}
		pec $hex_ma
		vc $hex_ma
	EOF

	awk -i inplace '
		function replace_color(color) {
			gsub("[0-9]+", color + 1)
		}

		/prefix|(window|volume|statusbar)_color/ {
			replace_color((/playing/) ? "'${term_hex_pfgi:-$hex_pfgi}'" : "'${term_hex_pbgi:-$hex_pbgi}'")
		}

		/(elapsed|visualizer)_color/ { replace_color("'${term_hex_mai:-$hex_mai}'") }
		/progressbar_color/ { replace_color("'${term_hex_sbgi:-$hex_sbgi}'") }

		{ print }' $ncmpcpp_conf

	sed -i "/^[^;].*color_1\|foreground/ s/[^ ]*$/'$hex_ma'/" ~/.config/cava/config
	sed -i "/^[^;].*color_2/ s/[^ ]*$/'$hex_a1'/" ~/.config/cava/config
}

set_zathura() {
	awk -i inplace '
		/bg|light/ { nc = (/highlight/) ? "'"$hex_a2"'" : (/statusbar/) ? "'"$hex_sbg"'" : "'"$hex_bg"'" }
		/fg|dark/ { nc = (/highlight/) ? "'"$hex_bg"'" : (/statusbar/) ? "'"$hex_pfg"'" : "'"$hex_fg"'" }
		{ sub("#[^\"]*", nc); print }' $zathura_conf
}

set_qb() {
	cat <<- EOF
		bg = '$hex_sbg'
		fg = '$hex_sfg'
		sbg = '$hex_bg'
		sfg = '$hex_ma'
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
		--mfg: $hex_a6;
	EOF
}

set_sxiv() {
	awk '
		/^Sxiv/ {
			p = substr($1, 6, 1)
			if ("'"$1"'") $1 = p "g"
			$NF = ((p == "b") ? "'$hex_bg'" : "'$hex_ma'")
			print
		}' $sxiv_conf
}

set_lock() {
	cat <<- EOF
		tc=${hex_fg#\#}ff
		rc=${hex_ma#\#}ff
		ic=${hex_bg#\#}dc
		wc=${hex_a6_br#\#}ff
	EOF
}

color_folders() {
	local color=hex_${1}_color

	[[ $1 == fill ]] &&
		local pattern='"fill:' ||
		local pattern='opacity:.;[^#]*\|;fill:\|color:'
	sed -i "s/\($pattern\)#\w\{6\}/\1${!color}/g" ~/.orw/themes/icons/{16x16,48x48}/folders/*
}

set_thunar() {
	awk -i inplace '
		/define/ {
			switch ($2) {
				case "bg": $NF = "'"$hex_bg"';"; break
				case "sbg": $NF = "'"$hex_sbg"';"; break
				case "pbg": $NF = "'"$hex_pbg"';"; break
				case "bbg": $NF = "'"$hex_ma"';"; break
				case "hlbg": $NF = "'"$hex_tbg"';"; break
				case "fg": $NF = "'"$hex_fg"';"; break
				case "sfg": $NF = "'"$hex_sfg"';"; break
				case "pfg": $NF = "'"$hex_pfg"';"; break
				case "afg": $NF = "'"$hex_a2"';"; break
				case "tbg": sub("([0-9]+,){3}", "'"${rgb_bg//;/,}"'")
			}
		} { print }' $thunar_conf

		local {rgb,hex}_{fill,stroke}_color
		read {rgb,hex}_fill_color <<< $(get_sbg $hex_ma -5)
		read {rgb,hex}_stroke_color <<< $(get_sbg $hex_ma -20)

		color_folders fill
		color_folders stroke
}

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
previews_dir=${colorscheme%/*}/wall_previews

reload_bash() {
	while read bash_pid; do
		kill -USR1 $bash_pid
		kill -SIGINT $bash_pid
	done <<< $(ps aux | awk '
		$NF ~ "bash$" && $7 ~ "/[1-9].?" {
			if (ot !~ $7) {
				#ot = ot " " $7
				print $2
			}
		}')
}

[[ -d $previews_dir ]] || mkdir $previews_dir

#wallpaper="$(sed 's/[()]/\\&/g' <<< "$wallpaper")"

((vertical)) &&
	preview_command="convert $preview_colors -append \( -resize x160 \"$wallpaper\" \) +append" ||
	preview_command="convert \( -resize 160x \"$wallpaper\" \) \( $preview_colors +append \) -append"
#eval "magick $preview_colors -append ${colorscheme%/*}/previews/${colorscheme##*/}.png"
eval "$preview_command '$previews_dir/${colorscheme##*/}.png'" &> /dev/null

{
	set_ob
	openbox --reconfigure &

	replace_colors bar
	~/.orw/scripts/barctl.sh & #-u &

	replace_colors qb | sed "s/=\s*\|'//g"
	replace_colors home_css '\t' > /dev/null

	qb_pid=$(pgrep qutebrowser)
	((qb_pid)) && qutebrowser ":config-source" &> /dev/null &

	set_term
	replace_colors bash '\t' | sed 's/\(.*\)=[^"]*.\(.\w*\).*/\1 \2/'
	reload_bash
	replace_colors vim | sed 's/.*:\([^ ]*\)[^'\'']*.\(.\w*\).*/\1 \2/'
	~/.orw/scripts/reload_neovim_colors.sh &> /dev/null &

	replace_colors rofi '\t' | sed -e 's/[:;]//g' -e 's/argb/#/'
	replace_colors tmux | awk -F '=' '{ gsub("'\''", ""); print (NR > 2) ? $1 " " $2 : $0 }'
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
} > $colorscheme 2> /dev/null
