#!/bin/bash

while getopts :b:d:l:f: flag; do
	case $flag in
		l) length=$OPTARG;;
		f) filter=$OPTARG;;
		d) hex_dark=$OPTARG;;
		b) hex_bright=$OPTARG;;
	esac
done

colorctl=~/.orw/scripts/colorctl.sh
all_colors=~/.config/orw/colorschemes/colors

clean="$(tput sgr0)"
dark=$($colorctl -cs ';' -h ${hex_dark-'#404040'})
bright=$($colorctl -cs ';' -h ${hex_bright-'#bbbbbb'})

colors="$(awk -Wposix '\
	BEGIN {
		l = '${length:-30}'
		br = "'$bright'"
		dr = "'$dark'"
	}
	/'$filter'/ {
		r = substr($2,2,2)
		g = substr($2,4,2)
		b = substr($2,6,2)
		rgb = sprintf("%d;%d;%d;", "0x" r, "0x" g, "0x" b)
		split(rgb, rgba, ";")
		r = rgba[1]; g = rgba[2]; b = rgba[3]

		bi = (0.3 * r + 0.6 * g + 0.1 * b) / 255
		cl = length(NR) + length($1) + length($2)
		p = sprintf("%*s", int((l - cl) / 2), " ")
		e = (cl % 2 > 0) ? " " : ""

		printf "\033[48;2;%s38;2;%s2m%s %d %s %s %s%s\033[0m\n\n", \
			rgb, (bi > 0.5) ? dr : br, p, NR, $1, $2, p, e }' $all_colors)"

echo -e "\n$colors\n"
