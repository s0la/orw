#!/bin/bash

colorscheme=~/.config/orw/colorschemes/$4.ocs
close_offset=20
close_font="icomoon_material_tile:size=10"
close_font="remix:size=15"

pid="\\\$(ps -C lemonbar -o pid= --sort=-start_time | head -1)"

[[ $2 =~ x ]] && width_ratio=${2%x*} height_ratio=${2#*x} || equal_ratio=$2

for arg in ${3//,/ }; do
	case $arg in
		i) 
			main_font_type="icomoon_material_tile"
			main_font_type="remix"
			eval $(sed -n 's/power_bar_\(.*=\)[^}]*.\(.\).*/\1\2/p' ~/.orw/scripts/bar/icons);;
		#[0-9]*) [[ $arg =~ x ]] && width_ratio=${arg%x*} height_ratio=${arg#*x} || equal_ratio=$arg;;
		s[0-9]*) main_font_size=${arg:1};;
		o[0-9]*) offset="%{${arg^}}";;
		*)
			action_count=${#arg}

			for action_index in $(seq ${#arg}); do
				#[[ ! $offset ]] && ((action_index % ${#arg})) && actions+='%{O$separator}'

				#[[ ! $offset ]] && ((action_index % ${#arg})) && ~/.orw/scripts/notify.sh "$action_index: $((action_index % ${#arg}))"

				case ${arg:action_index - 1:1} in
					l) actions+="$offset%{A:kill "$pid" && openbox --exit:}${logout_icon:-logout}%{A}$offset";;
					r) actions+="$offset%{A:kill "$pid" && systemctl reboot:}${reboot_icon:-reboot}%{A}$offset";;
					s) actions+="$offset%{A:kill "$pid" && systemctl suspend:}${suspend_icon:-suspend}%{A}$offset";;
					o) actions+="$offset%{A:kill "$pid" && systemctl poweroff:}${power_off_icon:-power off}%{A}$offset";;
					L) actions+="$offset%{A:kill "$pid" && ~/.orw/scripts/lock_screen.sh:}${lock_icon:-lock}%{A}$offset";;
				esac

				[[ ! $offset ]] && actions+='%{O$separator}'
			done
	esac
done

main_font="${main_font_type:-Iosevka Orw}:size=${main_font_size:-9}"
#~/.orw/scripts/notify.sh "mf: $main_font"

#read geometry offset separator <<< $(awk -F '[_ ]' '{
read geometry separator <<< $(awk -F '[_ ]' '{
			if(/^orientation/ && $NF ~ /^v/) v = 1

			if($1 == "primary") {
				s = '${1-0}'
				d = (s) ? s : $NF
				x = 0
			}

			if($1 == "display" && $3 == "xy") {
				if($2 < d) {
					x += $4

					if(v) {
						rx += $4
						ry += $5
					}
				} else {
					w = int($3 * '${width_ratio:-$equal_ratio}' / 100)
					h = int($4 * '${height_ratio:-$equal_ratio}' / 100)
					s = int(w / ('$action_count' * 2))
					o = int(h / 2 - '$close_offset')
					x += int(($3 - w) / 2)
					y = int(($4 - h) / 2)
					#y = 100
					#print w "x" h "+" x "+" y, o, s
					print w "x" h "+" x "+" y, s
					exit
				}
			}
		}' ~/.config/orw/config)

#eval $(awk '\
#	/#bar/ { 
#		nr = NR
#		b = '${base:-0}'
#	} nr && NR > nr {
#		if($1 ~ "^(b?bg|.*c)$") c = $2
#		else {
#			l = length($1)
#			p = substr($1, l - 1, 1)
#			c = "%{" toupper(p) $2 "}"
#		}
#
#		if($1) print $1 "=\"" c "\""
#	} nr && (/^$/ || (b && NR > nr + b)) { exit }' ~/.config/orw/colorschemes/$colorscheme.ocs)

eval $(awk '$1 ~ "^(P?s[bf]g|.*c)" { print gensub(" ", "=", 1) }' $colorscheme)

close="%{A:kill "$pid":} %{A}"
actions+="$offset%{A:kill "$pid":}${close_icon:-close}%{A}$offset"

#~/.orw/scripts/notify.sh "bg: $bg"
bg=${Psbg:-$sbg}
fg=${Psfg:-$sfg}
#~/.orw/scripts/notify.sh "bg: $bg"
#echo -e "$actions" > ~/Desktop/pow_bar

eval "content=\"%{c}%{B$bg}%{F$fg}$actions\""
#eval "all=\"$pfg%{c}$actions%{r}%{T2}$sfg$close%{O$close_offset}\""
#echo -e "$all" | lemonbar -B $bg -p -g $geometry -f "$main_font" -o 0 -f "$close_font" -o -$offset -n power_bar | bash

#echo -e "%{c}$actions" | \
echo -e "$content" | \
	lemonbar -d -p -B $bg -F $fg -R ${Pfc:-$fc} -r 3 \
	-f "$main_font" -o 0 -g $geometry -n power_bar | bash
