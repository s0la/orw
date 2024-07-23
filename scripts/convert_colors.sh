#!/bin/bash

color=${@: -1}

set_hsv() {
	local sign=${2//[0-9]}

	case $1 in
		h) offset_type=hue;;
		s) offset_type=saturation;;
		*) offset_type=value;;
	esac

	eval $offset_type=$2
}

while getopts :d:hrpH:S:L:V:l:v:Pcabf:B flag; do
	case $flag in
		P) pick_color=true;;
		d) delimiter="$OPTARG";;
		h)
			format=hex
			hex=${color: -6};;
		r)
			format=rgb
			[[ $delimiter ]] ||
				delimiters=${color//[0-9]} delimiter=${delimiter:0:1}
			rgb=( ${color//${delimiter:=;}/ } );;
		p) percents=true;;
		[hsvl]) set_hsv $flag $OPTARG;;
		[hsvl])
			offset=$OPTARG

			case $flag in
				h) hue=$offset;;
				s) saturation=$offset;;
				v) value=$offset;;
			esac;;
		l)
			sign=${OPTARG:0:1}
			lightness=${OPTARG:1};;
		l) print_lightness=true;;
		v)
			sign=${OPTARG:0:1}
			value=${OPTARG:1};;
		v) print_value=true;;
		b) both=true flag=-n;;
		[HSV])
			hsv=true
			set_hsv ${flag,} $OPTARG;;
		c) convert=true;;
		f) read current_color_fifo final_color_fifo <<< ${OPTARG/,/ };;
		a) all=true;;
		B) balance=true;;
	esac
done

get_color() {
	read hex r g b h s v brightness <<< $(awk --non-decimal-data '
		function parse_hex(segment) {
			return "0x" substr(hex, len - segment * 2 + 1, 2)
		}

		function round_value(value) {
			return (value < 0) ? 0 : (value > 1) ? 1 : value
		}

		function hex_to_rgb() {
			len = length(hex)
			rgb = sprintf("%d %d %d", parse_hex(3), parse_hex(2), parse_hex(1))
		}

		function rgb_to_hex() {
			hex = sprintf("%x%x%x", r, g, b)
		}

		function rgb_to_hsl() {
			asort(rgba)
			min = rgba[1] / 255
			max = rgba[3] / 255

			l = (min + max) / 2

			if(min == max) h = s = 0
			else {
				d = max - min
				s = l > 0.5 ? d / (2 - max - min) : d / (max + min)

				if(max == r) h = (g - b) / d + (g < b ? 6 : 0)
				else if(max == g) h = (b - r) / d + 2
				else if(max == b) h = (r - g) / d + 4

				h /= 6
			}
		}

		function rgb_to_hsv() {
			asort(rgba)
			min = rgba[1] / 255
			max = rgba[3] / 255

			v = max

			if(min == max) h = s = 0
			else {
				d = max - min

				s = d / max

				if(max == r) h = ((max - b) / d) - ((max - g) / d)
				else if(max == g) h = 2 + ((max - r) / d) - ((max - b) / d)
				else if(max == b) h = 4 + ((max - g) / d) - ((max - r) / d)

				h = h / 6 + 1
			}
		}

		function to_rgb(p, q, t) {
			if(t < 0) t += 1
			if(t > 1) t -= 1
			if(t < 1/6) return p + (q - p) * 6 * t
			if(t < 1/2) return q
			if(t < 2/3) return p + (q - p) * (2/3 - t) * 6
			return p
		}

		function hsl_to_rgb() {
			if(s == 0) r = g = b = l
			else {
				q = (l < 0.5) ? l * (1 + s) : l + s - l * s
				p = 2 * l - q

				r = sprintf("%f", to_rgb(p, q, h + 1/3))
				g = sprintf("%f", to_rgb(p, q, h))
				b = sprintf("%f", to_rgb(p, q, h - 1/3))
			}
		}

		function hsv_to_rgb() {
			if(s == 0) r = g = b = v
			else {
				i = int(h * 6)
				f = (h * 6) - i;
				p = v * (1 - s)
				q = v * (1 - s * f)
				t = v * (1 - s * (1 - f))
				i %= 6

				if(i == 0) {
					r = v; g = t; b = p
				} else if(i == 1) {
					r = q; g = v; b = p
				} else if(i == 2) {
					r = p; g = v; b = t
				} else if(i == 3) {
					r = p; g = q; b = v
				} else if(i == 4) {
					r = t; g = p; b = v
				} else if(i == 5) {
					r = v; g = p; b = q
				}
			}
		}

		{
			if("'$format'" == "hex") {
				hex = $1
				hex_to_rgb()
			} else if("'$format'" == "rgb") {
				r = $1; g = $2; b = $3
				rgb = r " " g " " b
				rgb_to_hex()
			}

			{
				split(rgb, rgba)
				r = rgba[1] / 255
				g = rgba[2] / 255
				b = rgba[3] / 255
			}

			if(length("'$hue'") || length("'$saturation'") || length("'$value'") ||
				"'"$all"'" || "'"$pick_color"'" || "'"$balance"'") {

				rgb_to_hsv()

				if("'$hue'") \
					h = ("'$hue'" ~ "^[+-]") ? h + "'$hue'" / 360 : "'$hue'" / 360
				if("'$saturation'") \
					s = ("'$saturation'" ~ "^[+-]") ? \
						round_value(s + "'$saturation'" / 100) : "'$saturation'" / 100
				if("'$value'") \
					v = ("'$value'" ~ "^[+-]") ? \
						round_value(v + "'$value'" / 100) : "'$value'" / 100

				hsv_to_rgb()

				h = (h * 360) % 360; s *= 100; v *= 100
			}

			d = "'"${delimiter:-;}"'"
			r *= 255; g *= 255; b *= 255
			printf("%.2x%.2x%.2x %d %d %d %d %d %d %d", r, g, b, r, g, b, h, s, v, v > 50)
		}' <<< ${hex:-${rgb[*]: -3}})

	rgb=( $r $g $b )
}

get_color

if [[ $balance ]]; then
	org_hex=$hex
	org_h=$h org_s=$s org_v=$v
	((v > 70)) && value=-25 || value=+25
	get_color

	echo "$org_h $org_s $org_v #$org_hex #$hex"
	exit
fi

if [[ $pick_color ]]; then
	display_preview() {
		magick -size 100x100 xc:"#${hex: -6}" $preview
		feh -g 100x100 --title 'image_preview' $preview &
	}

	read x y <<< $(xwininfo -int -id $(xdotool getactivewindow) | awk '
			/Absolute/ { if(/X/) x = $NF; else y = $NF }
			/Relative/ { if(/X/) xb = $NF; else yb = $NF }
			/Width/ { w = $NF }
			/Height/ { print x - 2 * xb + w - 100, y }')
	~/.orw/scripts/set_geometry.sh -t image_preview -x $x -y $y

	preview=/tmp/color_preview.png

	while
		clear
		if [[ $current_color_fifo ]]; then
			echo "#$hex" > $current_color_fifo &
		else
			display_preview
		fi

		for property in hue saturation value done; do
			short=${property:0:1}
			echo -n "$short) $property "
			[[ ${!short} ]] && echo -e "(${!short})"
		done

		read -rsn 1 -p $'\n\n' choice

		[[ $choice != d ]]
	do
		read -p $'Offset: ' offset
		set_hsv ${choice} $offset

		[[ $format == rgb ]] && unset hex
		get_color
		unset $offset_type

		[[ $current_color_fifo ]] || kill $!
	done

	[[ $current_color_fifo ]] || kill $!

	if [[ $transparency ]]; then
		rgb=( $transparency ${rgb[*]} )
		hex="$transparency$hex"
	fi
fi

if [[ $convert ]]; then
	[[ $format == hex ]] && format=rgb || format=hex
fi

rgb=$(sed "s/ /${delimiter:-;}/g" <<< "${rgb[*]} ")

if [[ $all ]]; then
	final_color="$h;$s;$v; $rgb #$hex"
elif [[ $both ]]; then
	final_color="$rgb #$hex"
else
	[[ $format == hex ]] && final_color="#$hex" || final_color=$rgb
fi

if [[ $current_color_fifo ]]; then
	echo "$final_color" > $final_color_fifo &
	rm $current_color_fifo
else
	echo "$final_color"
fi
