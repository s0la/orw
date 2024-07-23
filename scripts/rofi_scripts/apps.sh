#!/bin/bash

indicator='●'
config=~/.config/orw/config

running="$(wmctrl -l | awk '\
	{
		w = $NF
		if(w ~ "vifm[0-9]?") {
			a = a ",3"
			r = r " vifm_label=\"'$indicator' \""
		} else if(w == "alacritty[0-9]?") {
			a = a ",0"
			r = r " term_label=\"'$indicator' \""
		} else if(w == "DROPDOWN") {
			a = a ",2"
			r = r " dropdown_label=\"'$indicator' \""
		} else if(w == "qutebrowser") {
			a = a ",4"
			r = r " qb_label=\"'$indicator' \""
		}
	} END { print r, "a=" a }')"

if [[ $style =~ icons|dmenu ]]; then
	[[ $running ]] && eval "running='-a ${running#*,}'"
	read {dropdown,term,vifm,qb} <<< \
		$(sed -n 's/^\(arrow_down_square_full\|term\|dir_empty\|web\).*=//p' ~/.orw/scripts/icons | xargs)
else
	[[ $running ]] && eval "$running empty='  '"
	term=alacritty dropdown=dropdown vifm=vifm qb=qutebrowser
fi

toggle
trap toggle EXIT

item_count=4
set_theme_str

app=$(cat <<- EOF | rofi -dmenu -i -theme-str "$theme_str" $running -theme main
	${term_label-$empty}$term
	${dropdown_label-$empty}$dropdown
	${vifm_label-$empty}$vifm
	${qb_label-$empty}$qb
EOF
)

run=~/.orw/scripts/run.sh
mode=$(awk '/^mode/ { print $NF }' $config)

get_title() {
	title=$(wmctrl -l | awk '$NF ~ "^'$1'[0-9]+?" { print $NF }' | sort -n | \
		awk '{
				ic = gensub("'$1'", "", 1)
				if(mc + 1 < ic) exit; else mc = (ic) ? ic : 0
			} END { if(length(mc)) mc++; print "'"$1"'" mc }')
}

case "$app" in
	*$dropdown*) ~/.orw/scripts/dropdown.sh ${app#*$dropdown};;
	*$term*)
		get_title alacritty
		alacritty -t $title &
		;;
	*$vifm*)
		get_title vifm
		spy_windows=~/.orw/scripts/spy_windows.sh
		workspace=$(xdotool get_desktop)
		class="--class=custom_size"

		[[ $mode == tiling ]] &&
			grep "^tiling_workspace.*\b$workspace\b" $spy_windows &> /dev/null &&
			width=250 height=150

		~/.orw/scripts/set_geometry.sh -c custom_size -w ${width:-400} -h ${height:-500}

		alacritty -t $title --class=custom_size -e ~/.orw/scripts/vifm.sh &
		;;
	*$qb*)
		get_title qutebrowser
		if [[ ! $app =~ private ]]; then
			qutebrowser ${app#*$qb} &
		else
			qutebrowser -s content.private_browsing true &
		fi
		;;
esac
