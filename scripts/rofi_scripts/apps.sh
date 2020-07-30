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
	#lock= tile= vifm= term= dropdown= qb=
	#lock= tile= vifm= term=  dropdown= qb=

	#lock= tile= vifm= term= dropdown= qb=
	#lock= tile= vifm= term= dropdown= qb=
	#lock=   tile= vifm= term= dropdown= qb=

	#lock=  tile= vifm= term= dropdown= qb=

	id=$(wmctrl -l | awk '/DROPDOWN/ { print $1 }')

	if [[ $id ]]; then
		#[[ $(xwininfo -id $id | awk '/Map/ {print $NF}') =~ Viewable ]] && state= || state=
		[[ $(xwininfo -id $id | awk '/Map/ {print $NF}') =~ Viewable ]] && state= || state=
	fi

	lock= tile= vifm= term= dropdown=${state:-} qb=

	#lock= tile= vifm= term= dropdown= qb=
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

	#mode=$(awk '/class.*(tiling|\*)/ { print (/\*/) }' ~/.config/orw/config)
	#mode=$(awk '/class.*(tiling|\*)/ { print (/\*/) ? "tiling" : "\\\*" }' ~/.config/openbox/rc.xml)
	#mode=$(awk '/class.*(selection|\*)/ { print (/\*/) ? "tiling" : "selection" }' ~/.config/openbox/rc.xml)
	#[[ $mode == selection ]] && class='--class=selection'
	#[[ $mode == tiling && $@ =~ $vifm|$term|$qb ]] && ~/.orw/scripts/tile_window.sh

	#count_windows() {
	#	mode=$(awk '/^mode/ { print $NF }' ~/.config/orw/config)
	#	window_count=$(wmctrl -l | awk '/'$1'[0-9]+?/ { wc++ } END { if(wc) print wc }')

	#	#if ((window_count)); then
	#	#	read mode ratio <<< $(awk '/^(mode|part|ratio)/ {
	#	#			if(/mode/) m = $NF
	#	#			else if(/part/ && $NF) p = $NF
	#	#			else if(/ratio/) r = p "/" $NF
	#	#		} END { print m, r }' ~/.config/orw/config | xargs)

	#	#	if [[ $mode == tiling && $window_count -gt 0 ]]; then
	#	#		read monitor x y width height <<< $(~/.orw/scripts/windowctl.sh resize H a $ratio)
	#	#		~/.orw/scripts/set_geometry.sh -c tiling -m $monitor -x $x -y $y -w $width -h $height
	#	#	fi
	#	#fi

	#	#title="$1$window_count"
	#}

	#mode=$(awk '/^mode/ { print $NF }' ~/.config/orw/config)

	#if [[ $mode == tile ]]; then
	#	[[ ! $@ =~ $tile ]] && command=$(~/.orw/scripts/windowctl.sh resize H a 2)
	#fi

	mode=$(awk '/^mode/ { print $NF }' ~/.config/orw/config)

	[[ $@ =~ $vifm|$term|$qb && $mode != floating ]] &&
		~/.orw/scripts/set_window_geometry.sh $mode
	#[[ $mode != floating ]] && ~/.orw/scripts/set_window_geometry.sh $mode
	#[[ $@ =~ $vifm|$term|$qb && $mode != floating ]] &&
	#	~/.orw/scripts/windowctl.sh -i none -A

	get_title() {
		title=$(wmctrl -l | awk '$NF ~ "^'$1'[0-9]+?" { wc++ } END { print "'$1'" wc }')
	}

	#get_command() {
	#	command="$@"
	#	command="${command## }"

	#	if [[ $command ]]; then
	#		if [[ $command =~ -c ]]; then
	#			shopt -s extglob
	#			command="${command/-c?( )/}"

	#			class='--class=selection'

	#			read x y w h <<< \
	#			$(~/.orw/scripts/windowctl.sh -C -p | awk '{ print gensub(/([0-9]+ ){2}/, "", 1) }')
	#			~/.orw/scripts/set_geometry.sh -c custom_size -x $x -y $y -w $w -h $h
	#		fi

	#		[[ $command ]] &&
	#			command="-e \"bash -c '~/.orw/scripts/execute_on_terminal_startup.sh $title $command'\""
	#	fi
	#}

	get_command() {
		command="$@"
		command="${command## }"

		[[ $command ]] &&
			command="-e \"bash -c '~/.orw/scripts/execute_on_terminal_startup.sh $title $command'\""
	}

	tile_term() {
		get_title termite
		~/.orw/scripts/tile_terminal.sh -t $title -b "$@"
	}

	run_term() {
		#if [[ $mode == tiling ]] && ((!window_count)); then
		#if [[ ! $mode =~ floating|selection ]] && ((!window_count)); then
		#	tile_term $command
		#else
		#	[[ $mode != floating ]] && ~/.orw/scripts/set_window_geometry.sh $mode
		#	eval termite -t $title $command
		#fi

		#[[ $mode != floating ]] && ~/.orw/scripts/set_window_geometry.sh $mode
		eval termite $class -t $title $command
	}

    case "$@" in
        *$dropdown*) ~/.orw/scripts/dropdown.sh ${@#*$dropdown};;
		*$tile*)
			get_title termite
			~/.orw/scripts/tile_terminal.sh -t $title -b ${@#*$tile};;
		#*$term*) coproc(termite -t termite ${@#*$term} &);;
		*$term*)
			#count_windows termite

			#get_title termite
			#get_command "${@#*$term}"

			#if [[ $mode == tiling ]]; then
			#	((window_count)) &&
			#		termite -t $title $command ||
			#		~/.orw/scripts/tile_terminal.sh $command
			#else
			#	eval termite -t $title "$command"
			#	#termite -t $title -e "~/.ore/scripts/execute_on_terminal_startup $title $custom_size $command"
			#fi;;

			get_title termite
			get_command "${@#*$term}"
			run_term;;

			#[[ $mode != tiling ]] &&
			#	termite -t termite$window_count ${@#*$term} ||
			#	~/.orw/scripts/tiling_terminal.sh ${@#*$term};;

			#termite -t "termite$window_count" --class=custom_size -e \
			#	"bash -c '~/.orw/scripts/execute_on_terminal_startup.sh termite$window_count \"$command\";bash'";;
		#*$vifm*) coproc(~/.orw/scripts/vifm.sh ${@#*$vifm} &);;
		*$vifm*)
			#count_windows termite
			#title=$(wmctrl -l | awk '$NF ~ "^vifm[0-9]+?" { wc++ } END { print "vifm" wc }')
			
			get_title vifm
			get_command "vifm.sh ${@#*$vifm}"

			if [[ $mode == floating ]]; then
				class="--class=custom_size"
				~/.orw/scripts/set_geometry.sh -c custom_size -w ${width:-400} -h ${height:-500}
			fi

			run_term;;

			#if [[ $mode == tiling ]]; then
			#	((window_count)) &&
			#		~/.orw/scripts/vifm.sh -t $title ${@#*$vifm} ||
			#		~/.orw/scripts/tile_terminal.sh ~/.orw/scripts/vifm.sh ${@#*$vifm}
			#else
			#	~/.orw/scripts/vifm.sh -t $title ${@#*$vifm}
			#fi;;

			#[[ $mode != tiling ]] && 
			#	~/.orw/scripts/vifm.sh -t $title ${@#*$vifm} ||
			#	~/.orw/scripts/tiling_terminal.sh -t $title -e "'bash -c \"~/.orw/scripts/vifm.sh ${@#*$vifm}\"'";;
				#~/.orw/scripts/vifm_window.sh -t vifm$window_count ${@#*$vifm} ||
				#~/.orw/scripts/tiling_terminal.sh $window_count -e "'bash -c \"~/.orw/scripts/vifm.sh ${@#*$vifm}\"'";;

			#~/.orw/scripts/vifm.sh -t "vifm$window_count" -c "$command" ${@#*$vifm} &;;
			#coproc(~/.orw/scripts/vifm.sh -t "vifm$window_count" ${@#*$vifm} &);;
        *$qb*)
			[[ ! $@ =~ private ]] && qutebrowser ${@#*$qb} ||
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
