#!/bin/bash

agregate() {
	[[ $1 ]] && local print=true

	transmission-remote -t $torrent_id -f | awk -F '/' '\
		function format_output() {
			#cfs = (sc > 0) ? (sc == tc) ? " " : " " : " "
			cfs = (sc > 0) ? (sc == tc) ? " " : " " : " "
			#cfs = (sc > 0) ? (sc == tc) ? " " : " " : " "

			af = af "\n" cfs cf;
			tc = 0; sc = 0;
		}

		NR == 2 {
			d = '$depth'
			c = "'"$current"'"
			fp = "'"$full_path"'"
			o = "x"
			ns = index($0, "Name")
			p = "'$print'"; sp = fp
		}
		NR > 2 {
			if(!fd) fd = (d == NF)
			if(!p) i = gensub("^ *([0-9]*):.*", "\\1", 1)
			s = gensub(" ( *([^ ]*) *){4}([^ ]*) .*", "\\2", 1, $1)
			n = (p) ? (d > 1) ? $d : substr($1, ns) : substr($0, ns)

			if(p) {
				if(fd) {
					if($0 ~ c) {
						cfs = (s == "Yes") ? " " : " "
						af = af "\n" cfs n
					}
				} else {
					if(cf == n) {
						tc++
						if(s == "Yes") sc++
					} else {
						if(cf) format_output()
					}
					cf = n; pfs = s
				}
			} else {
				if(c ~ /all|none/) {
				o = (c == "all") ? "g" : "G"
				} else {
					if(fd) {
						sp = fp "/" c
					}
				}

				if($0 ~ sp) {
					if(fd) o = (s == "Yes") ? "G" : "g"
					ai = ai "," i
				}
			}
		} END {
		if(p) {
			if(!fd) format_output()
			print "back\ndone\nnone\nall" af
		} else {
			if(!fd) d++
			print d, fd, o, substr(ai, 2)
		}
	}'
}

depth=1
rofi='rofi -dmenu -theme large_list'

while getopts :i:f: flag; do
	case $flag in
		i) torrent_id=$OPTARG;;
		f) torrent_id=$(awk '/'"$OPTARG"'/ { print $1 }');;
	esac
done

((!torrent_id)) && torrent_id=$(transmission-remote -l | awk '$1 ~ /^[0-9]+$/ { ti = $1 } END { print ti }')

if ((torrent_id)); then
	while [[ ! $full_path =~ done$ ]]; do
		current=$(agregate print | $rofi | sed 's/[()]/\\\\&/g')
		[[ ${current%% *} == [![:ascii:]] ]] && current="${current#* }"

		if [[ $current == back ]]; then
			current="${full_path%/*}"
			unset full_path
			((depth--))
		else
			read depth final_depth option all_ids <<< $(agregate)

			if ((final_depth)) || [[ $current =~ all|none ]]; then
				current="$full_path"
			else
				if [[ ! $current =~ all|none ]]; then
					[[ $full_path ]] && full_path+='/'
					full_path+="$current"
				fi
			fi

			[[ $option != x ]] && transmission-remote -t $torrent_id -$option $all_ids
		fi
	done
else
	~/.orw/scripts/notify.sh "No torrent was found in transmission's list, please add torrent first."
fi
