#!/bin/bash

close_offset=20
close_font="icomoon_fa:size=8"
main_font="Iosevka Orw:size=15"

pid="\\\$(ps -C lemonbar -o pid= --sort=-start_time | head -1)"

for arg in ${2//,/ }; do
	case $arg in
		i) 
			main_font="icomoon_fa:size=25"
			eval $(sed -n 's/power_\(.*=\)[^}]*.\(.\).*/\1\2/p' ~/.orw/scripts/bar/icons);;
		[0-9]*) [[ $arg =~ x ]] && width_ratio=${arg%x*} height_ratio=${arg#*x} || equal_ratio=$arg;;
		*)
			action_count=${#arg}

			for action_index in $(seq ${#arg}); do
				((action_index - 1)) && actions+='%{O$separator}'

				case ${arg:action_index - 1:1} in
					l) actions+="%{A:kill "$pid" && openbox --exit:}${logout_icon:-logout}%{A}";;
					r) actions+="%{A:kill "$pid" && systemctl reboot:}${reboot_icon:-reboot}%{A}";;
					s) actions+="%{A:kill "$pid" && systemctl suspend:}${suspend_icon:-suspend}%{A}";;
					o) actions+="%{A:kill "$pid" && systemctl poweroff:}${power_off_icon:-power off}%{A}";;
					L) actions+="%{A:kill "$pid" && ~/.orw/scripts/lock_screen.sh:}${lock_icon:-lock}%{A}";;
				esac
			done
	esac
done

read geometry offset separator <<< $(awk -F '[_ ]' '{
			if(/^orientation/ && $NF ~ /^v/) v = 1

			if($1 == "primary") {
				s = '${1-0}'
				d = (s) ? s : $NF
				x = 0
			}

			if($1 == "display" && NF == 4) {
				if($2 < d) {
					x += $3

					if(v) {
						rx += $3
						ry += $4
					}
				} else {
					w = int($3 * '${width_ratio:-$equal_ratio}' / 100)
					h = int($4 * '${height_ratio:-$equal_ratio}' / 100)
					s = int(w / ('$action_count' * 2))
					o = int(h / 2 - '$close_offset')
					x += int(($3 - w) / 2)
					y = int(($4 - h) / 2)
					print w "x" h "+" x "+" y, o, s
					exit
				}
			}
		}' ~/.config/orw/config)

eval $(awk '\
	/#bar/ { 
		nr = NR
		b = '${base:-0}'
	} nr && NR > nr {
		if($1 ~ "^(b?bg|.*c)$") c = $2
		else {
			l = length($1)
			p = substr($1, l - 1, 1)
			c = "%{" toupper(p) $2 "}"
		}

		if($1) print $1 "=\"" c "\""
	} nr && (/^$/ || (b && NR > nr + b)) { exit }' ~/.config/orw/colorschemes/bar_power.ocs)

close="%{A:kill "$pid":} %{A}"
eval "all=\"$pfg%{c}$actions%{r}%{T2}$sfg$close%{O$close_offset}\""

#resolution=$1
#screen_width=${resolution%x*}
#screen_height=${resolution#*x}

#font1="Roboto Mono:size=8"

#bar_width=500
#bar_height=150

#logout="%{A:openbox --exit:} %{A}"
#reboot="%{A:systemctl reboot:} %{A}"
#suspend="%{A:systemctl suspend:} %{A}"
#power_off="%{A:systemctl poweroff:} %{A}"
#lock="%{A:~/.orw/scripts/lock_screen.sh:} %{A}"

#pid="$(ps aux | awk '$NF == \"shut_down_bar\" { print $2 }')"
#close="%{A:kill $(ps aux | awk '$NF == \"shut_down_bar\" { print $2 }'):} %{A}"
#pid='$(ps -C lemonbar -o pid= --sort=-start_time | head -1)'
#close="%{A:kill \$(ps -C lemonbar -o pid= --sort=-start_time | head -1):} %{A}"

#all="%{B$bg}$pfg%{c}$lock%{O45}$reboot%{O45}$logout%{O45}$power_off%{r}%{T2}$close%{O$close_offset}"
#all="%{B$bg}$pfg%{c}$lock%{O33}$logout%{r}$sfg$close%{O15}"
#all="$reboot%{O50}$logout%{O50}$suspend%{O50}$shut_down"

#pid='$(for pid in $(pidof lemonbar); do echo $pid $(ps -p $pid -o etimes=); done | sort -n -k2 | head -n 1 | cut -d " " -f 1)'
#close="%{A:kill "$pid":} %{A}"

#echo -e "$si_fg%{c}$reboot%{O50}$suspend%{O50}$shut_down%{r}$si_dark_fg%{T2}$close%{O10}" | lemonbar -p -B${si_dark_bg//[%\{B\}]} \
#echo -e "$si_fg%{c}$all%{r}$si_dark_fg%{T2}$close%{O10}" | lemonbar -p -B${si_dark_bg//[%\{B\}]} \
				#-g ${bar_width}x${bar_height}+$((x + screen_width / 2 - bar_width / 2))+$((y + screen_height / 2 - bar_height / 2)) \
echo -e "$all" | lemonbar -B $bg -p -g $geometry -f "$main_font" -o 0 -f "$close_font" -o -$offset -n power_bar | bash
