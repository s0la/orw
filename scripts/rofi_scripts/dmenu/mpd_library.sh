#!/bin/bash

get_rofi_width() {
	read x y <<< $(xdotool getactivewindow getwindowgeometry |
		sed -n '2s/.*\s\([0-9]*\),\([0-9]*\).*/\1 \2/p')

	rofi_width=$(awk '
			function get_value() {
				return gensub(".* ([0-9]+).*", "\\1", 1)
			}

			{
				if (NR == FNR) {
					if (/^\s*font/) f = get_value()
					if (/^\s*window-width/) ww = get_value()
					if (/^\s*switcher-width/) sw = get_value()
					if (/^\s*window-padding/) wp = get_value()
					if (/^\s*element-padding/) ep = get_value()
				} else {
					if ($1 == "orientation") {
						if ($2 == "horizontal") {
							p = '${x:-1}'
							pf = 2
						} else {
							p = '${y:-1}'
							pf = 2
						}
					}

					if (/^display_[0-9]_size/) { w = $2 }
					if (/^display_[0-9]_xy/ && $pf > p) {
						rw = int(w * (ww - sw - 2 * wp) / 100)
						rw -= 2 * ep
						print int(rw / (f - 2) / 2 - 1)
						exit
					}
				}
			}' ~/.config/{rofi/sidebar.rasi,orw/config})

	dashed_separator=$(printf '━ %.0s' $(eval echo {0..$rofi_width}))
}

#get_rofi_width
#dashed_separator="$1"
#shfit

set_current() {
	current="$1"
	current_replacement=$(sed 's/[/&]/\\&/g' <<< "$1")
	sed -i "s/\(^current[^\"]*\"\)[^\"]*/\1$current_replacement/" $0
}

back() {
	[[ $current =~ / ]] && current="${current%/*}" || current=''
	set_current "$current"
}

notify_on_finish() {
	while kill -0 $pid 2> /dev/null; do
		sleep 1
	done && ~/.orw/scripts/notify.sh "Music library updated."
}

set_dashed_separator() {
	sed -i "/^dashed_separator/ s/''/'$dashed_separator'/" $0
}

current=""
#dashed_separator='━━━━━━━━━━━━━━━━━━━━━━━━━━━'

if [[ -z $@ ]]; then
	set_current ''
else
	#arg="$@"
	#arg="${arg#* }"

	[[ $@ == ━* ]] &&
		read dashed_separator arg <<< "$@"

	case "$arg" in
		'') set_current '';;
		back) back;;
		#'')
		#	dashed_separator=$1
		#	set_dashed_separator
		#	set_current ''
		#	;;
		update)
			coproc (mpc -q update &)
			pid=$((COPROC_PID + 1))
			coproc (notify_on_finish &);;
		refresh);;
		add_all)
			mpc add "$current"
			back;;
		*.mp3|*.ogg)
			[[ $current ]] && current+='/'
			mpc add "$current${arg// /\ }";;
		*)
			file="${arg// /\ }"
			[[ $current ]] && current+="/$file" || current="$file"
			set_current "$current";;
	esac
fi

[[ $current ]] && echo -e 'back'
echo -en "update\nrefresh\nadd_all\n$dashed_separator\0nonselectable\x1ftrue\n"
#echo -en "-------------\0nonselectable\x1ftrue\n"
#echo -e 'update\nrefresh\nadd_all\n\x0f'

mpc ls "$current" | awk -F '/' '!/m3u$/ { print $NF }'
