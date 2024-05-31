#!/bin/bash

lock_conf=~/.orw/dotfiles/.config/i3lockrc
term_conf=~/.orw/dotfiles/.config/alacritty/alacritty.toml
dunst_conf=~/.orw/dotfiles/.config/dunst/*dunstrc
picom_conf=~/.orw/dotfiles/.config/picom/picom.conf

if [[ $1 =~ bar|lock ]]; then
	[[ $1 == bar ]] && property=bg || property=ic
	[[ $3 ]] && edit="-e $3"

	~/.orw/scripts/rice_and_shine.sh -R -m $1 -p $property -t $2 -P $property "$edit"
	exit
elif [[ $1 =~ term|dunst ]]; then
	conf="$1_conf"
	[[ $1 == term ]] && pattern='opacity' || pattern='^\s*transparency'
else
	conf=picom_conf
	if [[ $1 == shadow[-_]radius ]]; then
		pattern="shadow-(radius|offset)"
	else
		#[[ $1 == rofi ]] &&
		#	pattern="opacity-rule.*Rofi" ||
		#	pattern="^\s*${1:0:1}\w*[-_]${1:1}\w* "

		[[ $1 == rofi ]] &&
			pattern="[0-9]:class.*Rofi" ||
			pattern="^\s*${1:0:1}\w*[-_]${1:1}\w* "
	fi
fi

sign=${2%%[0-9]*}
value=${2#$sign}

awk -i inplace '{ \
	if(/'"$pattern"'/ || m) {
		if (/^\s*.*_menu/) {
			m = 1
		} else {
			if (m) m = 0
			v = '$value'

			if("'$1'" == "dunst") {
				sub(/[0-9]+/, 100 - (("'$sign'") ? 100 - $NF '$sign' v : v))
			} else {
				if("'$1'" == "rofi" || "'$1'" ~ "shadow[-_]radius") {
					cv = gensub("[^0-9]*([0-9]+).*", "\\1", 1)
					f = "%d"
				} else {
					if(/^blur/) {
						max = 100
						pa = "?"
						f = "%d"
					} else {
						v/=100
						max = 1.0
						f = "%.2f"
					}

					cv = gensub(".*([0-9]\\.[0-9]+).*", "\\1", 1)
				}

				nv = ("'$sign'") ? cv '$sign' v : v
				if (nv > max) nv = max
				sub(cv, sprintf(f, nv))
			}
		}
	}
	print
}' ${!conf}

case $conf in
	#term*) killall -USR1 termite;;
	dunst*)
		command=$(ps -C dunst -o args= | awk '{ if($1 == "dunst") $1 = "'$(which dunst)'"; print }')

		killall dunst
		$command &> /dev/null &;;
		#$(which dunst) &> /dev/null &;;
	#picom*)
	#	killall picom
	#	picom -b &> /dev/null
	#	#picom --experimental-backends &> /dev/null &
esac
