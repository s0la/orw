#!/bin/bash

if [[ -z $@ ]]; then
	indicator=''
	indicator='●'

	#eval $(wmctrl -l | awk '\
	#	{
	#		a = $NF
	#		if(a == "vifm") r = r " vifm=\"'$indicator' \""
	#		else if(a == "termite") r = r " termite=\"'$indicator' \""
	#		else if(a == "DROPDOWN") r = r " dropdown=\"'$indicator' \""
	#		else if(a == "qutebrowser") r = r " qutebrowser=\"'$indicator' \""
	#	} END { print r }')

	##echo -e "lock\ntile\n${termite}termite\n${dropdown}dropdown\n${vifm}file manager\n${qutebrowser}web browser"
	#echo -e "lock\ntile\n${vifm}vifm\n${termite}termite\n${dropdown}dropdown\n${qutebrowser}qutebrowser"

	running="$(wmctrl -l | awk '\
		{
			a = $NF
			if(a == "vifm") r = r " vifm=\"'$indicator' \""
			else if(a == "termite") r = r " termite=\"'$indicator' \""
			else if(a == "DROPDOWN") r = r " dropdown=\"'$indicator' \""
			else if(a == "qutebrowser") r = r " qutebrowser=\"'$indicator' \""
		} END { print r }')"

	[[ $running ]] && eval "$running empty='  '"

	#echo -e "lock\ntile\n${termite}termite\n${dropdown}dropdown\n${vifm}file manager\n${qutebrowser}web browser"
	#echo -e "  lock\n  tile\n${vifm- } vifm\n${termite- } termite\n${dropdown- } dropdown\n${qutebrowser- } qutebrowser"
	echo -e "${empty}lock\
			\n${empty}tile\
			\n${vifm-$empty}vifm\
			\n${termite-$empty}termite\
			\n${dropdown-$empty}dropdown\
			\n${qutebrowser-$empty}qutebrowser"
else
	killall rofi 2> /dev/null

    case "$@" in
        *dropdown*) ~/.orw/scripts/dropdown.sh ${@#*dropdown};;
		tile*) ~/.orw/scripts/tile_terminal.sh ${@#tile};;
        *termite*) termite -t termite ${@#*termite};;
        #*file*) ~/.orw/scripts/vifm.sh ${@#*manager};;
        #*web*) qutebrowser ${@#*browser};;
        *vifm*) ~/.orw/scripts/vifm.sh ${@#*vifm};;
        *qutebrowser*) qutebrowser ${@#*browser};;
		lock) ~/.orw/scripts/lock_screen.sh;;
        #web*) firefox ${@#*browser};;
        #*file*) thunar ${@#*manager};;
    esac
fi
