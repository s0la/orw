#!/bin/bash

value=$1
icons=""
selection=""
icons_file=~/.orw/scripts/bar/icons

set() {
	sed -i "/^\<$1\>/ s/\".*\"/\"${2:-${!1}}\"/" $0
}

list_icons() {
	awk -F '[=%}]' '\
		BEGIN {
			print "resize"
			print "selection"
			print "━━━━━━━━━"
		} {
			if("'$selection'") s = (/^('$icons')_icon/) ? " " : " "
			print s $4 "  " $1
		}' $icons_file
}
 
if [[ -z $@ ]]; then
	list_icons
else
	case $@ in
		*[![:alpha:]])
			if [[ $@ =~   ]]; then
				unset selection icons
				set selection
				set icons

				list_icons
			else
				[[ $@ =~   ]] && sign=+
				[[ $@ =~   ]] && sign=-

				arg=${@#* }
				value="$sign${arg:-1}"

				[[ $selection ]] && multiple=_icon

				awk -i inplace '/^('${icons:-.*}')'$multiple'/ {
					cv = gensub(".*([-+][0-9]+).*", "\\1", 1)
					nv = cv '$value'
					s = (nv >= 0) ? "+" : ""
					sub(cv, s nv)
				} { print }' $icons_file

				echo -e ' \n \n '
			fi;;
		resize) echo -e ' \n \n ';;
		selection)
			[[ $selection ]] && selection='' || selection=true
			set selection
			list_icons;;
		*)
			if [[ $selection ]]; then
				icons=$(awk -F '"' '/^\<icons\>/ {
					ci = gensub(".* (.*)_icon.*", "\\1", 1, "'"$@"'")
					if(ci ~ "^(" $2 ")$") sub("|?" ci "|?", "", $2)
					else sub("$", "|" ci, $2)
					sub("^\\|", "", $2)
					print $2
				}' $0)

				set icons
				list_icons
			else
				set icons "${@#*  }"
				echo -e ' \n \n '
			fi
	esac
fi
