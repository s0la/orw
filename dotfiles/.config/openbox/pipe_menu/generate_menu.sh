#!/bin/bash

while getopts :m:c:is flag; do
	case $flag in
		m)
			while read -r menu; do
				menus+=( "$menu" )
			done <<< $(echo -e ${OPTARG//,/\\n});;
		c) command="$OPTARG";;
		i) shift $((OPTIND - 1));;
		s) same_name=true;;
	esac
done

function make_item() {
	[[ $command =~ (playlist|mount).sh$ ]] && replacement=' ' || replacement='__'

	cat <<- EOF
		<item label="${1//_/$replacement}">
			<action name="Execute">
				<execute>$2</execute>
			</action>
		</item>
	EOF
}

function make_item_as_menu() {
	echo "${menus[index]}"
	((index += 1))
}

function make_menu() {
	for item in "$@"; do
		[[ $item == menu && $menus ]] && make_item_as_menu || make_item ${item%%:*} "$command ${item#*:}"
	done
}

cat <<- EOF
	<openbox_pipe_menu>
	$(make_menu "$@")
	</openbox_pipe_menu>
EOF
