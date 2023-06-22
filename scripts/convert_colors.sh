#!/bin/bash

color=${@: -1}

set_hsv() {
	sign=${2//[0-9]}

	#case $1 in
	#	H) hue=${2:1};;
	#	S) saturation=${2:1};;
	#	V) value=${2:1};;
	#esac

	case $1 in
		h) offset_type=hue;;
		s) offset_type=saturation;;
		*) offset_type=value;;
	esac

	eval $offset_type=$2
	#~/.orw/scripts/notify.sh "$offset_type ${!offset_type}"
}

while getopts :d:hrpHS:L:V:l:v:Pcbf: flag; do
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
			sign=${OPTARG:0:1}
			offset=${OPTARG:1}

			case $flag in
				h) hue=$offset;;
				s) saturation=$offset;;
				*) value=$offset
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
			#sign=${OPTARG:0:1}
			#value=${OPTARG:1};;
		H) hsv=true;;
		[HSV])
			hsv=true
			set_hsv ${flag,} $OPTARG;;
		c) convert=true;;
		f) read current_color_fifo final_color_fifo <<< ${OPTARG/,/ };;
	esac
done

#awk --non-decimal-data '
#		function parse_hex(segment) {
#			return "0x" substr(hex, len - segment * 2 + 1, 2)
#		}
#
#		function hex_to_rgb() {
#			len = length(hex)
#			rgb = sprintf("%d %d %d", parse_hex(3), parse_hex(2), parse_hex(1))
#			#split(rgb, rgba)
#
#			#r = rgba[1] / 255
#			#g = rgba[2] / 255
#			#b = rgba[3] / 255
#		}
#
#		function rgb_to_hex() {
#			hex = sprintf("%x%x%x", r, g, b)
#			#hex = sprintf("%x%x%x", sprintf("%.0f", r * 255), sprintf("%.0f", g * 255), sprintf("%.0f", b * 255))
#		}
#
#		function rgb_to_hsl() {
#			asort(rgba)
#			min = rgba[1] / 255
#			max = rgba[3] / 255
#
#			l = (min + max) / 2
#
#			if(min == max) h = s = 0
#			else {
#				d = max - min
#				s = l > 0.5 ? d / (2 - max - min) : d / (max + min)
#
#				if(max == r) h = (g - b) / d + (g < b ? 6 : 0)
#				else if(max == g) h = (b - r) / d + 2
#				else if(max == b) h = (r - g) / d + 4
#
#				h /= 6
#			}
#		}
#
#		function rgb_to_hsv() {
#			asort(rgba)
#			min = rgba[1] / 255
#			max = rgba[3] / 255
#
#			v = max
#
#			if(min == max) h = s = 0
#			else {
#				d = max - min
#
#				s = d / max
#
#				if(max == r) h = ((max - b) / d) - ((max - g) / d)
#				else if(max == g) h = 2 + ((max - r) / d) - ((max - b) / d)
#				else if(max == b) h = 4 + ((max - g) / d) - ((max - r) / d)
#
#				h /= 6
#			}
#		}
#
#		function to_rgb(p, q, t) {
#			if(t < 0) t += 1
#			if(t > 1) t -= 1
#			if(t < 1/6) return p + (q - p) * 6 * t
#			if(t < 1/2) return q
#			if(t < 2/3) return p + (q - p) * (2/3 - t) * 6
#			return p
#		}
#
#		function hsl_to_rgb() {
#			if(s == 0) r = g = b = l
#			else {
#				q = (l < 0.5) ? l * (1 + s) : l + s - l * s
#				p = 2 * l - q
#
#				r = sprintf("%f", to_rgb(p, q, h + 1/3))
#				g = sprintf("%f", to_rgb(p, q, h))
#				b = sprintf("%f", to_rgb(p, q, h - 1/3))
#			}
#		}
#
#		function hsv_to_rgb() {
#			if(s == 0) r = g = b = v
#			else {
#				i = int(h * 6)
#				f = (h * 6) - i;
#				p = v * (1 - s)
#				q = v * (1 - s * f)
#				t = v * (1 - s * (1 - f))
#				i %= 6
#
#				if(i == 0) {
#					r = v; g = t; b = p
#				} else if(i == 1) {
#					r = q; g = v; b = p
#				} else if(i == 2) {
#					r = p; g = v; b = t
#				} else if(i == 3) {
#					r = p; g = q; b = v
#				} else if(i == 4) {
#					r = t; g = p; b = v
#				} else if(i == 5) {
#					r = v; g = p; b = q
#				}
#
#				#r = sprintf("%.0f", r)
#				#g = sprintf("%.0f", g)
#				#b = sprintf("%.0f", b)
#			}
#		}
#
#		{
#			if("'$format'" == "hex") {
#				hex = $1
#				hex_to_rgb()
#			} else if("'$format'" == "rgb") {
#				r = $1; g = $2; b = $3
#				#r = $1 / 255; g = $2 / 255; b = $3 / 255
#				rgb = r " " g " " b
#
#				#r = $1; g = $2; b = $3
#				#r = sprintf("%.0f", $1)
#				#g = sprintf("%.0f", $2)
#				#b = sprintf("%.0f", $3)
#				rgb_to_hex()
#
#				split(rgb, rgba)
#				r /= 255
#				g /= 255
#				b /= 255
#			}
#
#			#{
#			#	split(rgb, rgba)
#			#	r = rgba[1] / 255
#			#	g = rgba[2] / 255
#			#	b = rgba[3] / 255
#			#}
#
#			if(length("'$hue'") || length("'$saturation'") || length("'$value'")) {
#				rgb_to_hsv()
#
#				step = ("'$percents'") ? 100 : ("'$hue'") ? 360 : 255
#
#				if("'$hue'") h '$sign'= "'$hue'" / step
#				else if("'$saturation'") s '$sign'= "'$saturation'" / step
#				else if("'$value'") v '$sign'= "'$value'" / step
#
#				hsv_to_rgb()
#
#				h *= 360; s *= 100; v *= 100
#			}
#
#			d = "'${delimiter:-;}'"
#			r *= 255; g *= 255; b *= 255
#			printf("%x%x%x %d" d "%d" d "%d %d %.0f %.0f %.0f", r, g, b, r, g, b, h, s, v, v > 50)
#		}' <<< ${hex:-${rgb[*]: -3}}
#	exit

get_color() {
	#if ((${#hex} || ${#rgb[*]}); then
	#awk --non-decimal-data '
	read hex r g b h s v brightness <<< $(awk --non-decimal-data '
		function parse_hex(segment) {
			return "0x" substr(hex, len - segment * 2 + 1, 2)
		}

		function round_value(value) {
			return (value < 0) ? 0 : (value > 1) ? 1 : value
			#if(value < 0) return 0
			#else return (value > base) ? base : value / base
			#else if(value * base > base) return base
			#else return value * base
		}

		function hex_to_rgb() {
			len = length(hex)
			rgb = sprintf("%d %d %d", parse_hex(3), parse_hex(2), parse_hex(1))
			#split(rgb, rgba)

			#r = rgba[1] / 255
			#g = rgba[2] / 255
			#b = rgba[3] / 255
		}

		function rgb_to_hex() {
			hex = sprintf("%x%x%x", r, g, b)
			#hex = sprintf("%x%x%x", sprintf("%.0f", r), sprintf("%.0f", g), sprintf("%.0f", b))
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

				#system("~/.orw/scripts/notify.sh " h)
				#h /= 6
				h = h / 6 + 1
				#h /= 6
			}

			#h++
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

				#r = round_value(r, 1)
				#g = round_value(g, 1)
				#b = round_value(b, 1)
				#r = sprintf("%.0f", r)
				#g = sprintf("%.0f", g)
				#b = sprintf("%.0f", b)
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

			if(length("'$hue'") || length("'$saturation'") || length("'$value'") || "'$pick_color'") {
				#rgb_to_hsv()
				#system("~/.orw/scripts/notify.sh \"" hex " " r * 255 " " g * 255 " " b * 255 "\"")

				#step = ("'$percents'") ? 100 : ("'$hue'") ? 360 : 255
				#step = ("'$hue'") ? 360 : 100

				#if("'$hue'") h '$sign'= "'$hue'" / step
				#else if("'$saturation'") s '$sign'= "'$saturation'" / step
				#else if("'$value'") v '$sign'= "'$value'" / step

				#if("'$hue'") h = round_value(h + "'$hue'" / step)
				#if("'$hue'") h = round_value(h '$sign' "'$hue'" / step)
				#else if("'$saturation'") s = round_value(s '$sign' "'$saturation'" / step)
				#else if("'$value'") v = round_value(v '$sign' "'$value'" / step)

				rgb_to_hsv()

				#step = ("'$hue'") ? 360 : 100
				#if("'$hue'") h = h + "'$hue'" / step
				#else if("'$saturation'") s = round_value(s + "'$saturation'" / step)
				#else if("'$value'") v = round_value(v + "'$value'" / step)
				##system("~/.orw/scripts/notify.sh " h)

				if("'$hue'") \
					h = ("'$sign'") ? h + "'$hue'" / 360 : "'$hue'" / 360
				if("'$saturation'") \
					s = ("'$sign'") ? round_value(s + "'$saturation'" / 100) : "'$saturation'" / 100
					#s = round_value((('"$sign"') ? s + "'$saturation'" / 100 : "'$saturation'" / 100))
					#s = round_value("'$saturation'" / 100 + (('"$sign"') ? s : 0))
				if("'$value'") \
					v = ("'$sign'") ? round_value(v + "'$value'" / 100) : "'$value'" / 100
					#v = round_value((('"$sign"') ? v + "'$value'" / 100 : "'$value'" / 100))
					#v = round_value("'$value'" / 100 + (('"$sign"') ? v : 0))
				#system("~/.orw/scripts/notify.sh " h)

				hsv_to_rgb()

				h = (h * 360) % 360; s *= 100; v *= 100
				#h = (h * 360) % 360; s *= 100; v *= 100
				#h *= 360; s *= 100; v *= 100
				#h = (h * 360) % 360; s *= 100; v *= 100
				#h = round_value(h * 360)
				#s = round_value(s * 100)
				#v = round_value(v * 100)
				#h = round_value(h, 360)
				#s = round_value(s, 100)
				#v = round_value(v, 100)
			}

			#r = round_value(r, 255)
			#g = round_value(g, 255)
			#b = round_value(b, 255)
			#r = round_value(r * 255)
			#g = round_value(g * 255)
			#b = round_value(b * 255)
			d = "'"${delimiter:-;}"'"
			r *= 255; g *= 255; b *= 255
			printf("%.2x%.2x%.2x %d %d %d %d %d %d %d", r, g, b, r, g, b, h, s, v, v > 50)
			#printf("%x%x%x %d %d %d %d %.0f %.0f %.0f", r, g, b, r, g, b, h, s, v, v > 50)
			#printf("%x%x%x %d" d "%d" d "%d %d %.0f %.0f %.0f", r, g, b, r, g, b, h, s, v, v > 50)
		}' <<< ${hex:-${rgb[*]: -3}})
		#}' <<< ${hex_color:-${rgb_colors[*]: -3}}

	rgb=( $r $g $b )
	#rgb=( ${rgb//${delimiter:=;}/ } )
	#fi
}

get_color

#[[ $format == hex ]] && echo -n $hex
#[[ $format == rgb ]] && echo -n $rgb

#if [[ $hsv ]]; then
if [[ $pick_color ]]; then
	display_preview() {
		#if [[ $hex ]]; then
		convert -size 100x100 xc:"#${hex: -6}" $preview
		feh -g 100x100 --title 'image_preview' $preview &
		#echo $!
		#fi
	}

	#read x y <<< $(~/.orw/scripts/windowctl.sh -p | awk '{ print $3 + ($5 - 100), $4 + ($2 - $1) }')
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

		#echo -e "#$hex\n"

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
		#rgb="$transparency$delimiter$rgb"
		rgb=( $transparency ${rgb[*]} )
		hex="$transparency$hex"
	fi

	#if [[ ${BASH_SOURCE[0]} == $0 ]]; then
	#	fifo=/tmp/color_preview.fifo
	#	[[ ! -p $fifo ]] && mkfifo $fifo
	#	echo "#$hex" > /tmp/color_preview.fifo &
	#fi
#else

	#if [[ $current_color_fifo ]]; then
	#	echo "#$hex" > $final_color_fifo &
	#	rm $current_color_fifo
	#	exit
	#fi
fi

if [[ $convert ]]; then
	[[ $format == hex ]] && format=rgb || format=hex
fi

rgb=$(sed "s/ /${delimiter:-;}/g" <<< "${rgb[*]} ")

if [[ $both ]]; then
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

exit

if [[ $convert ]]; then
	[[ $format == hex ]] && format=rgb || format=hex
fi

[[ $format == hex || $both ]] && echo $flag "#$hex"
[[ $format == rgb || $both ]] && sed "s/ /${delimiter:-;}/g" <<< "${rgb[*]} "
