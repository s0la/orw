#!/bin/bash

lock_conf=~/.orw/dotfiles/.config/i3lockrc
term_conf=~/.orw/dotfiles/.config/termite/config
dunst_conf=~/.orw/dotfiles/.config/dunst/dunstrc
compton_conf=~/.orw/dotfiles/.config/compton.conf

if [[ $1 =~ bar|lock ]]; then
	[[ $1 == bar ]] && property=bg || property=ic
	~/.orw/scripts/rice_and_shine.sh -R -m $1 -p $property -t $2 -P $property
	exit
elif [[ $1 == lock ]]; then
	pattern=blur
	conf=lock_conf
elif [[ $1 =~ term|dunst ]]; then
	conf="$1_conf"
	[[ $1 == term ]] && pattern='^background' || pattern='^\s*transparency'
else
	conf=compton_conf
	[[ $1 == rofi ]] && pattern="opacity-rule.*Rofi" || pattern="^\s*${1:0:1}\w*(-|_)${1:1}\w* "
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
				$NF = 100 - (("'$sign'") ? 100 - $NF '$sign' v : v)
			} else {
				if("'$1'" == "rofi") {
					cv = gensub("[^0-9]*([0-9]+).*", "\\1", 1)
				} else {
					if(/^blur/) {
						pa = "?"
						f = "%d"
					} else {
						v/=100
						f = "%.2f"
					}

					cv = gensub(".*([0-9])(\\.[0-9]+)" pa ".?$", "\\1\\2", 1)
				}

				sub(cv, sprintf(f, ("'$sign'") ? cv '$sign' v : v))
			}
		}
	}
	print
}' ${!conf}

case $conf in
	term*) killall -USR1 termite;;
	dunst*)
		killall dunst
		$(which dunst) &> /dev/null &;;
	compton*)
		killall compton
		compton &> /dev/null &
esac
