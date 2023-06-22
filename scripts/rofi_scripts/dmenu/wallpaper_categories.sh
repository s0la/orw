#!/bin/bash

function set() {
	eval $1='$(sed "s/\(\\*\)\?\([][()\&]\)/\\\\\\\\\2/g" <<< "${2:-${!1}}")'
	sed -i "s|\(^$1=\).*|\1\"${!1//&/\\&}\"|" $0
}

set_root() {
	~/.orw/scripts/wallctl.sh -d "$arg"
	root="$(awk '/^directory/ { print gensub("'\''", "", "g", $NF) }' ~/.config/orw/config)"
	set root
}

get_categories() {
	all_categories="$(awk '/^directory/ {
		ac = gensub("'\''", "", "g")
		print gensub(".*'"$root"'/?\\{?([^}]*).*", "\\1", 1, ac) }' ~/.config/orw/config)"
}

set_category() {
	get_categories

	if [[ $all_categories ]]; then
		[[ "$arg" =~ (^|,)(${all_categories//,/|})(,|$) ]] && modify=remove || modify=add
		flag=-M
	else
		flag=-d
	fi

	~/.orw/scripts/wallctl.sh $flag $modify "$root/$arg"
}

list_categories() {
	get_categories

	eval ls -d "$root/*/" | awk -F '/' '\
		BEGIN { r = gensub("'\''", "", "g", "'"$root"'") }
		{
			cc = $(NF - 1)
			s = (cc ~ "^(" "'"${all_categories//,/|}"'" ")$") ? " " : " "
			print s, cc
		}'
}

root="/home/sola/Pictures/wallpapers"

if [[ $@ ]]; then
	read option arg <<< "$@"

	[[ $option == set_root ]] && set_root "$arg" || set_category "$arg"
fi

echo set_root
list_categories
exit

if [[ -z $@ ]]; then
	rofi -modi "wc:$0 list" -show wc -theme list
else
	read option arg <<< "$@"

	if [[ $option == list ]]; then
		echo set_root
		list_categories
	else
		[[ $option == set_root ]] &&
			set_root "$arg" || set_category "$arg"
	fi
fi
