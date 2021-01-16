#!/bin/bash

root="/home/ablive/Pictures/wallpapers"
selection=""
category=""
multi_categories=""

function set() {
	eval $1='$(sed "s/\(\\*\)\?\([][()\&]\)/\\\\\\\\\2/g" <<< "${2:-${!1}}")'
	sed -i "s|\(^$1=\).*|\1\"${!1//&/\\&}\"|" $0
}

list_categories() {
	eval ls -d "$root/*/" | awk -F '/' '\
		BEGIN {
			s = "'$selection'"

			if(s) {
				print "set"
				print "add"
				print "remove"
			}

			print "set_root"
			print "selection"
			print "━━━━━━━━━"
		} {
		c = $(NF - 1)
		if("'$selection'") s = (c ~ /^('"${multi_categories//,/|}"')$/) ? " " : " "
		print s c
	}'
}

if [[ -z $@ ]]; then
	list_categories
else
	case $@ in
		set_root*)
			root="${@#* }"
			list_categories
			set root "${root/\~/$HOME}";;
		selection)
			[[ $selection ]] && unset selection || selection=true
			list_categories
			set selection;;
		set|add|remove)
			if [[ $multi_categories ]]; then
				[[ $multi_categories =~ , ]] &&
					categories="{'${multi_categories//,/\',\'}'}" ||
					category=$multi_categories
			fi

			[[ $@ == set ]] && flag="-d" || flag="-M" modify="$@"
			~/.orw/scripts/xwallctl.sh $flag $modify "$root/${categories:-$category}"

			unset category multi_categories selection
			list_categories

			set category
			set multi_categories
			set selection;;
		*)
			if [[ $selection ]]; then
				multi_categories="$(awk '{
					if(/^('"${multi_categories//,/|}"')$/) p = ",?" $0
					else { p = "$"; r = ("'"$multi_categories"'") ? "," $0 : $0 }

					print gensub(p, r, 1, "'"$multi_categories"'")
				}' <<< "${@#* }")"

				list_categories
				set multi_categories
			else
				set category "$@"
				echo -e 'set\nadd\nremove'
			fi
	esac
fi
