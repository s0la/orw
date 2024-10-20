#!/bin/bash

ocs_root=~/.config/orw/colorschemes
ocs_previews_root=$ocs_root/previews_new
ocs_previews_root=$ocs_root/wall_previews
colorshceme="$1"

[[ -d $ocs_previews_root ]] || mkdir $ocs_previews_root

for ocs in $ocs_root/${colorshceme##*/}*; do
	wall="${ocs##*/}"
	wallpaper="$(ls ~/Downloads/${wall%.*}.* 2> /dev/null | head -1)"
	[[ -f "$wallpaper" ]] || wallpaper="$(ls ~/Pictures/wallpapers/top/${wall%.*}.* 2> /dev/null)"
	#[[ -f "~/Downloads/$wall" ]] &&
	#	wallpaper="~/Downloads/$wall" ||
	#	wallpaper="~/Pictures/wallpapers/top/$wall"

	#[[ $wall == *jason* ]] &&
	#	ls "~/Downloads/$wall" && echo $wall: $wallpaper

	#[[ $wall == *masahiro* ]] && echo M: ${wall%.*}.* - $wallpaper

	if [[ -f "$wallpaper" ]]; then
		read w h vertical <<< $(file $wallpaper | awk -F ',' '{
			g = $(NF - (("'"${wallpaper##*.}"'" == "png") ? 2 : 1))
			split(g, ga, "\\s*x\\s*")
			print ga[1], ga[2], (int(ga[2]) > int(ga[1]) * 1.3)
		}')

		#echo $wall: $w - $h " > " $vertical - $wallpaper
		#continue

		awk '
			c && /^$/ { c = 0 }
			$1 ~ "#(term|tmux|vim)" { c = substr($1, 2) }

			c == "term" && $1 == "bg" { ac[1] = "#" substr($NF, length($NF) - 5) }
			c == "tmux" && $1 ~ "^[cw]bg$" { ac[++i - 4] = $NF }
			c == "vim" && $1 ~ "^[cfisv]fg$" { ac[++i + 3] = $NF }

			END {
				if ('$vertical') {
					s = "20x20"
					ps = "x160"
					pg = "west"
					po = "-"
				} else {
					s = "20x20"
					ps = "160x"
					pg = "south"
					po = "+"
				}

				#g = "\\\\( gradient:black-white -posterize 30 -white-threshold 100% \\\\)"
				#for (c in ac) pc = pc sprintf("\\\\( -size %s xc:%sa0 " g " -compose copyopacity -composite \\\\) ", s, ac[c])

				s = ('$vertical') ? "10x20" : "20x10"
				for (c in ac) pc = pc sprintf("\\\\( -size %s xc:%s \\\\) ", s, ac[c])

				#print (('$vertical') ? \
				#	"convert " pc " -append \\\\( -resize x160 '"$wallpaper"' \\\\) +append" : \
				#	"convert \\\\( -resize 160x '"$wallpaper"' \\\\) \\\\( " pc " +append \\\\) -append")

				#print "convert \\\\( -resize " ps " '"$wallpaper"' \\\\) \\\\( " pc " " po "append \\\\)" \
				#	" -compose over -gravity " pg " -composite"

				print (('$vertical') ? \
					"convert " pc " -append \\\\( -resize x160 '"$wallpaper"' \\\\) +append" : \
					"convert \\\\( -resize 160x '"$wallpaper"' \\\\) \\\\( " pc " +append \\\\) -append")
					#" -compose over -gravity " g " -composite"
			}' $ocs | xargs -I {} bash -c "{} $ocs_previews_root/${ocs##*/}.png"

			#END { for (c in ac) printf "\\\\( -size 100x12 xc:%s \\\\) ", ac[c] }' $ocs |
			#	xargs -I {} bash -c "magick {} -append $ocs_previews_root/${ocs##*/}.png"
	fi
done
