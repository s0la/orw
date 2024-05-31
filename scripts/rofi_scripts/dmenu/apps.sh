#!/bin/bash

indicator='●'

config=~/.config/orw/config
#theme=$(awk -F '[".]' 'END { print $(NF - 2) }' ~/.config/rofi/main.rasi)
#[[ $theme =~ dmenu|icons ]] && ~/.orw/scripts/set_rofi_geometry.sh apps

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
	#id=$(wmctrl -l | awk '/DROPDOWN/ { print $1 }')

	#if [[ $id ]]; then
	#	[[ $(xwininfo -id $id | awk '/Map/ {print $NF}') =~ Viewable ]] && state= || state=
	#fi

	[[ $running ]] && eval "running='-a ${running#*,}'"
	#lock= tile= vifm= term= dropdown=${state:-} qb=
	#lock= tile= vifm= term= dropdown=${state:-} qb=
	#tile= vifm= term= dropdown=${state:-} qb=
	tile=  vifm=  term=  dropdown=${state:-} qb=
	tile=  vifm=  vifm=  term=  dropdown=${state:-} qb=
	tile=  vifm=  term=  dropdown=${state:-} qb=
	tile=  vifm= term=  dropdown=${state:-} qb=
	tile=  vifm= term=  dropdown=${state:-} qb=
	tile=  vifm= term=  dropdown=${state:-} qb=
else
	[[ $running ]] && eval "$running empty='  '"
	term=alacritty dropdown=dropdown vifm=vifm qb=qutebrowser
fi

#~/.orw/scripts/notify.sh "OPENS" &
#~/.orw/scripts/signal_windows_event.sh test

#toggle_rofi() {
#	#~/.orw/scripts/notify.sh "SIG" &
#	~/.orw/scripts/signal_windows_event.sh rofi_toggle
#}

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

#trap '~/.orw/scripts/signal_windows_event.sh test' EXIT

run=~/.orw/scripts/run.sh
mode=$(awk '/^mode/ { print $NF }' $config)

#[[ $app =~ $vifm|$term|$qb && $mode != floating ]] &&
#	~/.orw/scripts/set_window_geometry.sh $mode

get_title() {
	#title=$(wmctrl -l | awk '$NF ~ "^'$1'[0-9]+?" { wc++ } END { print "'$1'" wc }')
	title=$(wmctrl -l | awk '$NF ~ "^'$1'[0-9]+?" { print $NF }' | sort -n | \
		awk '{
				ic = gensub("'$1'", "", 1)
				if(mc + 1 < ic) exit; else mc = (ic) ? ic : 0
			} END { if(length(mc)) mc++; print "'"$1"'" mc }')
}

get_command() {
	command="$@"
	command="${command## }"

	[[ $command ]] &&
		command="-e \"bash -c '~/.orw/scripts/execute_on_terminal_startup.sh $title $command'\""
}

run_term() {
	#if [[ $mode != floating ]]; then
	#	get_id='id=\$(printf \"0x%.8x\" \$(xdotool getactivewindow))'
	#	get_alignment_orientation="sed -n \\\"s/^direction/\\\$id:/p\\\" $config >> ~/.config/orw/window_alignment"
	#	alignment_command="$get_id && $get_alignment_orientation"
    #
	#	termite $class -t $title -e \
	#		"bash -c '~/.orw/scripts/execute_on_terminal_startup.sh $title \"$alignment_command\";${command:-bash}'" & &> /dev/null
	#else
	#	eval termite $class -t $title $command &> /dev/null &
	#fi

	#$run -t $title termite $class -t $title $command
	#eval termite $class -t $title "$command" &
	eval alacritty $class -t $title "$command" &

	#~/.orw/scripts/run.sh $title termite -t $title
}

case "$app" in
	*$dropdown*) ~/.orw/scripts/dropdown.sh ${app#*$dropdown};;
	*$tile*)
		get_title termite
		~/.orw/scripts/tile_terminal.sh -t $title -b ${app#*$tile};;
	*$term*)
		get_title alacritty
		#get_command "${app#*$term}"
		##echo termite $class -t $title "$command"
		#run_term
		alacritty -t $title &
		;;
	*$vifm*)
		get_title vifm
		#get_command "sleep 0.5 \&\& vifm.sh ${app#*$vifm}"

		#if [[ $mode == floating ]]; then
		#	class="--class=custom_size"
		#	~/.orw/scripts/set_geometry.sh -c custom_size -w ${width:-400} -h ${height:-500}
		#fi

		spy_windows=~/.orw/scripts/spy_windows.sh
		workspace=$(xdotool get_desktop)
		#is_tiling_workspace=$(sed -n '
		class="--class=custom_size"
		[[ $mode == tiling ]] &&
			grep "^tiling_workspace.*\b$workspace\b" $spy_windows &> /dev/null &&
			width=250 height=150

		~/.orw/scripts/set_geometry.sh -c custom_size -w ${width:-400} -h ${height:-500}

		#command="-e ~/.orw/scripts/vifm.sh"
		alacritty -t $title --class=custom_size -e ~/.orw/scripts/vifm.sh &
		;;

		#echo "termite $class -t $title '$command'"
		#exit
		#run_term;;
	*$qb*)
		get_title qutebrowser

		#[[ ! $app =~ private ]] && args="${app#*$qb}" ||
		#	args="-s content.private_browsing true"
		#$run qutebrowser "$args";;
		if [[ ! $app =~ private ]]; then
			qutebrowser ${app#*$qb} &
		else
			qutebrowser -s content.private_browsing true &
		fi
		;;
	#*$lock) ~/.orw/scripts/lock_screen.sh;;
esac
