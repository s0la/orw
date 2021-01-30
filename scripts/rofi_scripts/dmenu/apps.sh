#!/bin/bash

indicator='●'

config=~/.config/orw/config
theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)
[[ $theme =~ dmenu|icons ]] && ~/.orw/scripts/set_rofi_geometry.sh apps

running="$(wmctrl -l | awk '\
	{
		w = $NF
		if(w == "vifm") {
			a = a ",3"
			r = r " vifm_label=\"'$indicator' \""
		} else if(w == "termite") {
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

if [[ $theme == icons ]]; then
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
	tile=tile vifm=vifm term=termite dropdown=dropdown qb=qutebrowser
fi

app=$(cat <<- EOF | rofi -dmenu -i $running -theme main
	${term_label-$empty}$term
	${empty}$tile
	${dropdown_label-$empty}$dropdown
	${vifm_label-$empty}$vifm
	${qb_label-$empty}$qb
EOF
)

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
	eval termite $class -t $title "$command"

	#~/.orw/scripts/run.sh $title termite -t $title
}

case "$app" in
	*$dropdown*) ~/.orw/scripts/dropdown.sh ${app#*$dropdown};;
	*$tile*)
		get_title termite
		~/.orw/scripts/tile_terminal.sh -t $title -b ${app#*$tile};;
	*$term*)
		get_title termite
		get_command "${app#*$term}"
		run_term;;
	*$vifm*)
		get_title vifm
		get_command "sleep 0.5 \&\& vifm.sh ${app#*$vifm}"

		if [[ $mode == floating ]]; then
			class="--class=custom_size"
			~/.orw/scripts/set_geometry.sh -c custom_size -w ${width:-400} -h ${height:-500}
		fi

		run_term;;
	*$qb*)
		get_title qutebrowser

		#[[ ! $app =~ private ]] && args="${app#*$qb}" ||
		#	args="-s content.private_browsing true"
		#$run qutebrowser "$args";;
		[[ ! $app =~ private ]] && qutebrowser ${app#*$qb} ||
			qutebrowser -s content.private_browsing true;;
	#*$lock) ~/.orw/scripts/lock_screen.sh;;
esac
