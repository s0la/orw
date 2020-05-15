#!/bin/bash

indicator=''
indicator='●'

theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)

if [[ $theme != icons ]]; then
	running="$(wmctrl -l | awk '\
		{
			a = $NF
			if(a == "vifm") r = r " vifm_label=\"'$indicator' \""
			else if(a == "termite") r = r " term_label=\"'$indicator' \""
			else if(a == "DROPDOWN") r = r " dropdown_label=\"'$indicator' \""
			else if(a == "qutebrowser") r = r " qb_label=\"'$indicator' \""
		} END { print r }')"

	lock=lock tile=tile vifm=vifm term=termite dropdown=dropdown qb=qutebrowser
	[[ $running ]] && eval "$running empty='  '"
else
	lock= tile= vifm= term= dropdown= qb=
fi

if [[ -z $@ ]]; then
	cat <<- EOF
		${empty}$lock
		${empty}$tile
		${vifm_label-$empty}$vifm
		${term_label-$empty}$term
		${dropdown_label-$empty}$dropdown
		${qb_label-$empty}$qb
	EOF
else
	killall rofi 2> /dev/null

    case "$@" in
        *$dropdown*) ~/.orw/scripts/dropdown.sh ${@#*$dropdown};;
		*$tile*) ~/.orw/scripts/tile_terminal.sh ${@#*$tile};;
        *$term*) termite -t termite ${@#*$term};;
        *$vifm*) ~/.orw/scripts/vifm.sh ${@#*$vifm};;
        *$qb*)
			[[ ! $@ =~ private ]] && qutebrowser ${@#*$browser} ||
				qutebrowser -s content.private_browsing true;;
		*$lock) ~/.orw/scripts/lock_screen.sh;;
    esac
fi
