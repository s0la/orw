#!/bin/bash

colorscheme=$4
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
			eval $(sed -n 's/power_\(.*=\)[^}]*.\(.\).*/\1\2/p' ~/.orw/scripts/bar/icons);;
		#[0-9]*) [[ $arg =~ x ]] && width_ratio=${arg%x*} height_ratio=${arg#*x} || equal_ratio=$arg;;
		s[0-9]*) main_font_size=${arg:1};;
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

main_font="${main_font_type:-Iosevka Orw}:size=${main_font_size:-9}"
#~/.orw/scripts/notify.sh "mf: $main_font"

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
	} nr && (/^$/ || (b && NR > nr + b)) { exit }' ~/.config/orw/colorschemes/$colorscheme.ocs)

close="%{A:kill "$pid":} %{A}"
eval "all=\"$pfg%{c}$actions%{r}%{T2}$sfg$close%{O$close_offset}\""
echo -e "$all" | lemonbar -B $bg -p -g $geometry -f "$main_font" -o 0 -f "$close_font" -o -$offset -n power_bar | bash
