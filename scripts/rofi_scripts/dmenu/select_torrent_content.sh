#!/bin/bash

function set() {
	eval $1='$(sed "s/\(\\*\)\?\([()\&]\)/\\\\\\\\\2/g" <<< "${2:-${!1}}")'
	sed -i "s/\(^$1=\).*/\1\"${!1//\//\\/}\"/" $0
}

agregate() {
	[[ $1 ]] && local print=true

	transmission-remote -t $torrent_id -f | awk -F '/' '\
		function format_output(file) {
			if(file) {
				cfn = n
				cfs = (s == "Yes") ? " " : " "
			} else {
				cfn = pfn
				cfs = (sc > 0) ? (sc == tc) ? " " : " " : " "
			}

			tc = 0; sc = 0;
			af = af "\n" cfs cfn;
		}

		NR == 2 {
			d = '$depth'
			p = "'$print'"
			c = "'"$current"'"
			fp = "'"$full_path"'"
			o = "x"; sp = fp; ns = index($0, "Name")
		}

		NR > 2 {
			if(!fd) fd = $NF == c
			if(!p) i = gensub("^ *([0-9]*):.*", "\\1", 1)

			s = gensub(" *( *([^ ]*) *){4}([^ ]*) .*", "\\2", 1)
			fn = substr($0, ns); n = (p) ? (d > 1) ? $d : substr($1, ns) : fn

			if(p) {
				if(fn ~ fp "/") {
					if(NF == d) {
						if(tc) format_output()
						format_output(1)
					} else {
						if(pfn && pfn != n) format_output()

						tc++
						if(s == "Yes") sc++
						pfn = n
					}
				}
			} else {
			if(c ~ /^(all|none)$/) {
					did = 1
					o = (c == "all") ? "g" : "G"
				} else {
					sp = fp "/" c
				}

				if(fn ~ sp) {
					if(fd) {
						si = i
						did = 1
						o = (s == "Yes") ? "G" : "g"
						exit
					} else {
						ai = ai "," i
					}
				}
			}
		} END {
		if(p) {
			if(tc) format_output()
			if(d > 2) print "back"
			print "done\nnone\nall" af
		} else {
			if(!did) d++
			print d, fd, o, si ? si : substr(ai, 2)
		}
	}'
}

depth="2"
final_depth="0"
current="back"
full_path="Long Distance Calling \\\\(2006-2018\\\\)"

torrent_id=$(transmission-remote -l | awk '$1 ~ /^[0-9]+$/ { ti = $1 } END { print ti }')
torrent_id=3

if [[ -z $@ ]]; then
	depth=2
	current=""
	set full_path "$(transmission-remote -t $torrent_id -i | awk '/^\s*Name/ { sub("^[^:]*: *", ""); print }')"
else
	[[ ${@%% *} == [![:ascii:]] ]] && current="${@#* }" || current="$@"
	set current

	if [[ $current == done ]]; then
		transmission-remote -t $torrent_id -s &> /dev/null
		exit
	elif [[ $current == back ]]; then
		full_path="${full_path%/*}"
		((depth--))
	else
		read depth final_depth option all_ids <<< $(agregate)

		~/.orw/scripts/notify.sh "fd: $final_depth"

		if ((!final_depth)) && [[ ! $current =~ ^(all|none)$ ]]; then
			[[ $full_path ]] && full_path+='/'
			full_path+="$current"
		fi

		[[ $option != x ]] && transmission-remote -t $torrent_id -$option $all_ids &> /dev/null
	fi
fi

~/.orw/scripts/notify.sh -p "fp: $full_path\nc: $current"

agregate print

set depth
set current
set full_path
set final_depth
