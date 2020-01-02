#!/bin/bash

move=''
place=''
toggle=''
resize=''
current=''

launchers=~/.orw/scripts/bar/launchers.sh

set() {
	sed -i "/^$1/ s/'.*'/'${!1//\//\\\/}'/" $0
}

list_launchers() {
	[[ $move ]] && move_state= 
	[[ $resize ]] && resize_state=  || resize_state=
	[[ $toggle ]] && toggle_state=  || toggle_state=

	awk -F '"' '\
		BEGIN {
			if("'$move_state'") print "'$move_state' move"
			print "'$toggle_state' toggle"
			print "'$resize_state' resize"
			print "━━━━━━━━━━"

			if("'$toggle'") {
				print " all"
				print " none"
				print "━━━━━━━━"
			}

			if("'$resize'") {
				print " all"
				print "━━━━━━"
			}
		}

		/^#?icon/ {
			nr = NR + 1
			i = gensub(/[\0-\177]/, "", "g", $2)
			if("'$toggle'") s = /^#/ ? " " : " "
		} NR == nr { print s i, $2 }' $launchers
}

toggle_launchers() {
	[[ $1 =~ ^(all|none)$ ]] && all=$1 || single="${current#* }"

	awk -i inplace '\
		BEGIN { a = "'$all'" }
		{
			if(/#'"${single:-###}"'/) { s = 1 }
			if(/^$/) { s = 0 }

			p = r = ""

			if($0) {
				if((a == "all" || s) && /^#.*"/) {
					p = "^#"
					r = ""
				} else if((a == "none" || s) && (!/^#/ && /.*"/)) {
					p = "^"
					r = "#"
				}
			}

			if(p) sub(p, r)
		} { print }' $launchers
}

resize_launchers() {
	[[ $current ]] && single="${current%% *}"

	awk -i inplace -F 'I|}' '\
		/^#?icon.*'"$single"'/ {
		v = $2 '$sign' '${value:-1}'
		if(v >= 0) s = "+"
		sub("[+-][^}]*", s v)
		} { print }' $launchers
}

if [[ -z $@ ]]; then
	list_launchers

	unset current
	set current
else
	if [[ $@ =~ ^(( | )[an]|( | )[0-9]?$| | |.* (toggle|resize|move)$) ]]; then
		if [[ $@ =~   ]]; then
			continue
		elif [[ $@ =~ ( | ) ]]; then
			if [[ $toggle ]]; then
				toggle_launchers ${@##* }
			else
				unset current
				set current

				echo -e ' \n \n '
				exit
			fi
		elif [[ $@ =~ ( | ) ]]; then
			if [[ $resize ]]; then
				[[ $@ =~   ]] && sign=- || sign=+

				resize_launchers

				echo -e ' \n \n '
				exit
			else
				move_whole=$(sed -n "/^#$move/,/^$/p" $launchers)

				[[ $@ =~   ]] && direction=sl after_line='\n' || direction=el before_line='\ \n'
				line=$(awk '/^#'"${current#* }"'/ { sl = NR } sl && /^$/ { el = NR; exit } END { print '$direction' }' $launchers)

				sed -i "/^#$move/,/^$/d" $launchers

				if ((line)); then
					sed -i "${line}i$before_line${move_whole//$'\n'/\\n}$after_line" $launchers
				else
					~/.orw/scripts/notify.sh "HERE"
					echo -e "\n$move_whole" >> $launchers
				fi

				last_line=$(sed -n '$p' $launchers)
				[[ $last_line ]] || sed -i '$d' $launchers

				unset move current
				set current
				set move
			fi
		else
			var=${@#* }

			[[ $var == move  ]] && eval $var='' ||
				eval $var="$(awk -F ''\''' '/^'$var'/ { print $2 ? "" : "on" }' $0)"

			set $var
		fi

		list_launchers
	else
		if [[ $toggle ]]; then
			current="${@#* }"
			toggle_launchers

			list_launchers
		else
			current="$@"
			set current

			if [[ $resize || $move ]]; then
				echo -e ' \n '

				[[ $resize ]] && echo -e ' '
			else
				move="${current#* }"
				set move

				list_launchers
			fi
		fi
	fi
fi
