#!/bin/bash

wallpaper_dir=~/Pictures/wallpapers
cache_dir=~/Pictures/wallpapers/cache

[[ $@ ]] &&
	wallpaper_categories="${@}" ||
	wallpaper_categories=$(sed -n 's/^directory.*\///p' ~/.config/orw/config)

for category in ${wallpaper_categories//[\',]/ }; do
	[[ -d $cache_dir/$category ]] || mkdir -p $cache_dir/$category
	while read wallpaper; do
		[[ -f "$wallpaper_dir/$category/$wallpaper" ]] &&
			magick "$wallpaper_dir/$category/$wallpaper" -resize 200x "$cache_dir/$category/$wallpaper"
	done <<< $(comm -23 <(ls -1 $wallpaper_dir/$category/* | sed 's/.*\///' | sort) \
				<(ls -1 $cache_dir/$category/* | sed 's/.*\///' | sort))
	#done <<< $(comm -23 <(ls -1 $wallpaper_dir/$category/* | head -15 | xargs -n 1 basename | sort) \
	#			<(ls -1 $cache_dir/$category/* | xargs -n 1 basename | sort))
done
