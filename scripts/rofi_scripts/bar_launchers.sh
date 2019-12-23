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
		{
			if("'$toggle'") s = /^#/ ? " " : " "
			gsub(/[\0-\177]/, "", $2)
			print s $2, $4
		}' $launchers
}

toggle_launchers() {
	[[ $1 =~ ^(all|none)$ ]] && all=$1 || single="${current// /\.*}"

	awk -i inplace '\
		BEGIN { 
			a = "'$all'"
			s = ! a
		}
		/'"$single"'/ {
			p = r = ""

			if(a == "all" || (s && /^#/)) {
				p = "^#"
				r = ""
			} else if((a == "none" && !/^#/) || s) {
				p = "^"
				r = "#"
			}

			if(p) sub(p, r)
		} { print }' $launchers
}

resize_launchers() {
	[[ $current ]] && single="${current// /\.*}"

	awk -i inplace -F 'I|}' '\
		/'"$single"'/ {
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
	if [[ $@ =~ ^(( | )[an]|( | )$| | |.* (toggle|resize|move)$) ]]; then
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
				[[ $@ =~ [0-9]$ ]] && value=${@##* }
				[[ $@ =~   ]] && sign=- || sign=+

				resize_launchers

				echo -e ' \n \n '
				exit
			else
				[[ $@ =~   ]] && position=a || position=i

				sed -i "/${move//\//\\\/}/d" $launchers
				sed -i "/$current/$position $move" $launchers

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
			toggle_launchers "${current// /\.*}"

			list_launchers
		else
			current="${@// /\.*}"
			set current

			if [[ $resize || $move ]]; then
				echo -e ' \n '

				[[ $resize ]] && echo -e ' '
			else
				eval move="'$(sed -n "/[^\"]*$current/p" $lines)'"
				set move

				list_launchers
			fi
		fi
	fi
fi
