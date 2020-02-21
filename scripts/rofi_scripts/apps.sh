#!/bin/bash

if [[ -z $@ ]]; then
	indicator=''
	indicator='●'

	running="$(wmctrl -l | awk '\
		{
			a = $NF
			if(a == "vifm") r = r " vifm=\"'$indicator' \""
			else if(a == "termite") r = r " termite=\"'$indicator' \""
			else if(a == "DROPDOWN") r = r " dropdown=\"'$indicator' \""
			else if(a == "qutebrowser") r = r " qutebrowser=\"'$indicator' \""
		} END { print r }')"

	[[ $running ]] && eval "$running empty='  '"

	cat <<- EOF
		${empty}lock
		${empty}tile
		${vifm-$empty}vifm
		${termite-$empty}termite
		${dropdown-$empty}dropdown
		${qutebrowser-$empty}qutebrowser
	EOF
else
	killall rofi 2> /dev/null

    case "$@" in
        *dropdown*) ~/.orw/scripts/dropdown.sh ${@#*dropdown};;
		*tile*) ~/.orw/scripts/tile_terminal.sh ${@#*tile};;
        *termite*) termite -t termite ${@#*termite};;
        *vifm*) ~/.orw/scripts/vifm.sh ${@#*vifm};;
        *qutebrowser*)
			[[ ! $@ =~ private ]] && qutebrowser ${@#*browser} ||
				qutebrowser -s content.private_browsing true;;
		*lock) ~/.orw/scripts/lock_screen.sh;;
    esac
fi
