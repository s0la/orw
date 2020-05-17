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

	count_windows() {
		window_count=$(wmctrl -l | awk '/'$1'[0-9]+?/ { wc++ } END { if(wc) print wc }')

		#read mode ratio <<< $(awk '/^(mode|ratio)/ { print $NF }' ~/.config/orw/config | xargs)
		read mode ratio <<< $(awk '/^(mode|part|ratio)/ {
				if(/mode/) m = $NF
				else if(/part/ && $NF) p = $NF
				else if(/ratio/) r = p "/" $NF
			} END { print m, r }' ~/.config/orw/config | xargs)

		if [[ $mode == tiling && $window_count -gt 0 ]]; then
			read x y width height <<< $(~/.orw/scripts/windowctl.sh resize H a $ratio)
			~/.orw/scripts/set_class_geometry.sh -c tiling -x $x -y $y -w $width -h $height
		fi

		title="$1$window_count"
	}

	#mode=$(awk '/^mode/ { print $NF }' ~/.config/orw/config)

	#if [[ $mode == tile ]]; then
	#	[[ ! $@ =~ $tile ]] && command=$(~/.orw/scripts/windowctl.sh resize H a 2)
	#fi

    case "$@" in
        *$dropdown*) ~/.orw/scripts/dropdown.sh ${@#*$dropdown};;
		*$tile*) ~/.orw/scripts/tile_terminal.sh ${@#*$tile};;
		#*$term*) coproc(termite -t termite ${@#*$term} &);;
		*$term*)
			count_windows termite
			#termite -t "termite$window_count" ${@#*$term} &;;
			#termite -t "termite$window_count" ${@#*$term} -e "bash -c '~/.orw/scripts/execute_on_terminal_startup.sh termite$window_count'" &;;

			#~/.orw/scripts/set_class_geometry.sh -c size -w 100 -h 100

			[[ $mode == tiling ]] && class="--class=tiling"
			termite -t $title $class ${@#*$term} &;;
			#termite -t "termite$window_count" --class=custom_size -e \
			#	"bash -c '~/.orw/scripts/execute_on_terminal_startup.sh termite$window_count \"$command\";bash'";;
		#*$vifm*) coproc(~/.orw/scripts/vifm.sh ${@#*$vifm} &);;
		*$vifm*)
			count_windows vifm
			[[ $mode == tiling ]] && class="-c tiling"
			~/.orw/scripts/vifm.sh -t $title $class ${@#*$vifm} &;;
			#~/.orw/scripts/vifm.sh -t "vifm$window_count" -c "$command" ${@#*$vifm} &;;
			#coproc(~/.orw/scripts/vifm.sh -t "vifm$window_count" ${@#*$vifm} &);;
        *$qb*)
			[[ ! $@ =~ private ]] && qutebrowser ${@#*$browser} ||
				qutebrowser -s content.private_browsing true;;
		*$lock) ~/.orw/scripts/lock_screen.sh;;
    esac

	#sleep 0.5 && $command

	#if [[ ! $@ =~ $tile ]]; then
	#	while kill -0 $pid 2> /dev/null; do
	#		sleep 0.05
	#	done && sleep 1 && ~/.orw/scripts/windowctl.sh tile
	#fi
fi
