#!/bin/bash

make_power_action() {
	[[ $2 ]] && local power_action="&& $2"
	[[ $2 && ! $power_offset ]] && local separator='%{O$separator}'
	local icon=$(get_icon "power_bar_${1// /_}") offset=$power_offset
	echo "actions+=\"$offset%{A:kill \$pid $power_action:}${icon:-$1}%{A}$offset$separator\"\\n"
	#local action="$offset%{A:kill \$pid $power_action:}${icon:-$1}%{A}$offset"
	#echo "actions+='$action'" >> $power_bar
}

assign_power_args() {
	case $arg in
		i) 
			power_font_type="material"
			eval $(sed -n 's/power_bar_\(.*=\)[^}]*.\(.\).*/\1\2/p' ~/.orw/scripts/bar/icons)
			;;
		s) power_width_ratio=${value%x*} power_height_ratio=${value#*x};;
		f) power_font_size=$value;;
		o) power_offset="%{O$value}";;
		a)
			action_args=$value
			action_count=${#action_args}

			for action_index in $(seq ${#action_args}); do
				case ${action_args:action_index - 1:1} in
					l) power_actions+="$(make_power_action 'logout' 'openbox --exit')";;
					r) power_actions+="$(make_power_action 'reboot' 'sudo systemctl reboot')";;
					s) power_actions+="$(make_power_action 'suspend' 'sudo systemctl suspend')";;
					o) power_actions+="$(make_power_action 'power off' 'sudo systemctl poweroff')";;
					L) power_actions+="$(make_power_action 'lock' '~/.orw/scripts/lock_screen.sh')";;
				esac
			done
	esac
}

launch_power_bar() {
	echo -e "$power_bar_content" | \
		lemonbar -d -p -B $power_bar_bg -F $power_bar_fg -R ${Pfc:-$fc} -r 3 \
		-f "$power_bar_font" -o 0 -g $power_bar_geometry -n power_bar | bash
}

make_power_bar_script() {
	#local close_offset=20 width_ratio=20 height_ratio=20

	power_actions+="$(make_power_action 'close')"

	local height=$((display_height * power_height_ratio / 100))
	local width=$((display_width * power_width_ratio / 100))
	local y=$((y + (display_height - height) / 2))
	local x=$((x + (display_width - width) / 2))
	local separator=$((width / ((action_count + 1) * 2)))
	#local offset=$((height / 2 - close_offset))

	local geometry="${width}x${height}+${x}+${y}"
	local font_size="size=${power_font_size:-9}"
	local font="${power_font_type:-Iosevka Orw}:$font_size"

	#local P{{p,s}{b,f}g,fc}
	#eval $(awk '$1 == "#bar" { b = 1 }
	#	b && $1 ~ "^(P?s[bf]g|.*c)" { print gensub(" ", "=", 1) }
	#	b && $1 == "" { exit }' $colorscheme)

	#power_bar_bg=$sbg
	#power_bar_fg=$sfg

	((${#bg} > 7)) &&
		local transparency=${bg:1:2}

	cat <<- EOF > $power_bar
		pid='\$(ps -C lemonbar -o pid= --sort=-start_time | head -1)'

		separator='$separator'
		$(echo -e "$power_actions")

		bg='#$transparency${Psbg//[%{B\#\}]}'
		fg='${Psfg//[%{F\}]}'
		fc='${Pfc:-$fc}'
		font='$font'
		geometry='$geometry'

		echo -e "%{c}\$actions" | lemonbar \\
			-p -d -B\$bg -F\$fg -R\$fc -r 3 \\
			-f "\$font" -g \$geometry -n power_bar | bash
	EOF
}

make_power_content() {
	power_bar=$modules_dir/power_bar.sh
	power_width_ratio=20 power_height_ratio=20
	#local main_font_{type,size} offset

	assign_args power

	power_content='$power_padding$power$power_padding'
}

set_power_actions() {
	actions_start="%{A:bash $power_bar:}" actions_end="%{A}"
}

get_power() {
	label=POW
	icon=$(get_icon "Power")
	power=$icon
	set_power_actions
	print_module power
}

check_power() {
	local action_{start,end}
	get_power
}
