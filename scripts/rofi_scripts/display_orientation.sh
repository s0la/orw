#!/bin/bash

item_count=2
set_theme_str

index=$(sed -n 's/^rofi_.*al=//p' ~/.orw/scripts/icons |
	rofi -dmenu -format d -theme-str "$theme_str" -theme main)

xrandr --auto

displays=(
	$(xrandr -q | awk '
	/connected/ {
		p = ($3 == "primary")
		gsub("([0-9]+x[0-9]+)?\\+", " ", $(3 + p))
		print $(3 + p), $1
	}' | sort -nk $index,$index | awk '{ print $NF }')
)

((index > 1)) &&
	orientation='--below' || orientation='--right-of'

for display in ${!displays[*]}; do 
	((display)) && outputs+=" $orientation "
	outputs+="${displays[display]}"
done

command="xrandr --output $outputs"
#sed -i "s/xrandr.*/$command/" ~/.orw/dotfiles/.config/X11/xinitrc
sed -i "s/xrandr.*/$command/" ~/.orw/dotfiles/.config/openbox/autostart.sh
eval "$command"

~/.orw/scripts/generate_orw_config.sh display
~/.orw/scripts/wallctl.sh -r &
