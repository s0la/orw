#!/bin/bash

function set() {
	eval $1='$(sed "s/\(\\*\)\?\([][()\&+\`]\)/\\\\\\\\\2/g" <<< "${2:-${!1}}")'
	sed -i "s|\(^$1=\).*|\1\"${!1//&/\\&}\"|" $0
}

function un_set() {
	for var in "$@"; do
		unset $var
		set $var
	done
}

list() {
	transmission-remote -l
}

list_torrents() {
	[[ $selection ]] && echo -e 'stop\nstart\nremove\n'
	echo -e 'selection\n━━━━━━━━━'

	list -l | awk 'NR == 1 {
			i = index($0, "Name")
		}
		#$2 ~ "[0-9]+%" {
		NR > 1 {
			s = ("'$selection'") ? ($1 ~ "^('${multiple_torrents//,/|}')\\*?$") ? " " : " " : $2
			printf("%-*s%s\n", (s ~ "%$") ? 6 : 6, s, substr($0, i))
		}'
}

get_current_torrent_id() {
	current_torrent_id=$(list | awk '/'"$current"'$/ { print gensub("([0-9]*)\\*?", "\\1", 1, $1) }')
}

current=""
selection=""
multiple_torrents=""

if [[ -z $@ ]]; then
	un_set current_torrent_id multiple_torrents
	list_torrents
else
	#if [[ $@ =~ ^[[:alpha:]] ]]; then
	if [[ ! $@ =~ ^[0-9]|n/a ]]; then
		case $@ in
			stop)
				flag=S
				action=stopped;;
			start)
				flag=s
				action=started;;
			remove)
				flag=r
				action=removed;;
			selection) echo -e 'back\nenable\ndisable\nselect_all\ndiscard_all';;
			*_all)
				set selection true

				if [[ $@ =~ select ]]; then
					multiple_torrents=$(list | awk '\
						$2 ~ /^[0-9]+%$/ {
							id = gensub("([0-9]*)\\*?", "\\1", 1, $1)
							mt = mt "," id
						} END { print substr(mt, 2) }')

					set multiple_torrents
				else
					un_set multiple_torrents
				fi;;
			*able) [[ $@ =~ ^en ]] && set selection true || un_set selection;;
			content)
				killall rofi

				get_current_torrent_id
				~/.orw/scripts/rofi_scripts/select_torrent_content_with_size.sh \
					set_torrent_id "$current_torrent_id"
				~/.orw/scripts/rofi_scripts/torrents_group.sh select_torrent_content

				un_set current_torrent_id
				exit 0;;
		esac

		if [[ $flag ]]; then
			[[ ! $multiple_torrents ]] && get_current_torrent_id

			read torrent_count torrent_names <<< "$(list | awk '\
				NR == 1 {
					i = index($0, "Name")
					ti = gensub(",", "|", "g", "'${multiple_torrents:-$current_torrent_id}'")
				}
				$2 ~ /[0-9]+%/ {
					id = gensub("([0-9]+)\\*?", "\\1", 1, $1)
					if(id ~ "^(" ti ")$") { tn = tn "\\\\n" substr($0, i); tc++ }
				} END { print tc, tn }')"

			if ((torrent_count)); then
				((torrent_count == 1)) &&
					notification="torrent <b>${torrent_names#\\n}</b> is $action" ||
					notification="torrents:\n<b>$torrent_names</b>\n\nare $action"
			fi

			~/.orw/scripts/notify.sh -p "$notification"
			transmission-remote -t ${multiple_torrents:-$current_torrent_id} -$flag &> /dev/null

			un_set current_torrent_id multiple_torrents
		fi

		[[ $@ != selection ]] && list_torrents
	else
		set current "${@#* }"

		if [[ $selection ]]; then
			multiple_torrents=$(list | awk '\
				$0 ~ "'"$current"'$" {
					mt = "'$multiple_torrents'"
					id = gensub("([0-9]*)\\*?", "\\1", 1, $1)

					if(mt ~ "\\<" id "\\>") {
						if(mt != id) {
							if(mt ~ id "$") e = ","
							else s = ","
						}

						nmt = gensub(e "\\<" id "\\>" s, "", 1, mt)
					} else {
						nmt = mt "," id
					}

					print nmt
				}')

			set multiple_torrents ${multiple_torrents#,}
			list_torrents
		else
			echo -e 'back\nstop\nstart\nremove\ncontent'
		fi
	fi
fi
