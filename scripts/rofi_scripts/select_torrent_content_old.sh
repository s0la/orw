#!/bin/bash

function set() {
	eval $1='$(echo "${2:-${!1}}" | sed "s/\(\\*\)\?\([()\&]\)/\\\\\\\\\2/g")'
	sed -i "s/\(^$1=\).*/\1\"${!1//\//\\/}\"/" $0
}

agregate() {
	[[ $1 ]] && local print=true

	#transmission-remote -t $torrent_id -f | sed '$s/.*//' | awk -F '/' '\
	transmission-remote -t $torrent_id -f | awk -F '/' '\
		function format_output() {
			#cfs = (sc > 0) ? (sc == tc) ? " " : " " : " "
			if(fd) {
				cfn = n
				cfs = (s == "Yes") ? " " : " "
			} else {
				cfn = pfn
				cfs = (sc > 0) ? (sc == tc) ? " " : " " : " "
			}

			af = af "\n" cfs cfn;
			#af = af "\n" cfs cf;
			tc = 0; sc = 0;
		}

		NR == 2 {
			d = '$depth'
			p = "'$print'"
			c = "'"$current"'"
			fp = "'"$full_path"'"
			o = "x"; sp = fp; ns = index($0, "Name")
		}
		NR > 2 {
			#if(!fd) fd = (d == NF)
			fd = (d == NF)
			if(!p) i = gensub("^ *([0-9]*):.*", "\\1", 1)
			s = gensub(" *( *([^ ]*) *){4}([^ ]*) .*", "\\2", 1)
			n = (p) ? (d > 1) ? $d : substr($1, ns) : substr($0, ns)

			if(p) {
				if($0 ~ fp) {
					if(fd) {
						format_output()
					} else {
					if(pfn && pfn != n) format_output()

						tc++
						if(s == "Yes") sc++
						pfn = n
					}
				}

				#if(fd) {
				#	if($0 ~ fp) format_output()
				#} else {
				#	if(pfn && pfn != n) format_output()

				#	tc++
				#	if(s == "Yes") sc++
				#	pfn = n
				#}

				#if(fd) {
				#	if($0 ~ fp) {
				#		cfs = (s == "Yes") ? " " : " "
				#		af = af "\n" cfs n
				#	}
				#} else {
				#	if(cf == n) {
				#		tc++
				#		if(s == "Yes") sc++
				#	} else {
				#		if(cf) format_output()
				#	}
				#	cf = n; pfs = s
				#}
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
			#if(!fd) format_output()
			#if(!af) format_output()
			#print "back\ndone\nnone\nall" af

			#if(!af) format_output()
			if(!fd) format_output()
			if(d > 2) print "back"
			print "done\nnone\nall" af
		} else {
			if(!fd) d++
			print d, fd, o, substr(ai, 2)
		}
	}'
}

depth="2"
final_depth="1"
current="2006 Dmnstrtn"
full_path="Long Distance Calling \\\\(2006-2018\\\\)/2006 Dmnstrtn"

torrent_id=$(transmission-remote -l | awk '$1 ~ /^[0-9]+$/ { ti = $1 } END { print ti }')

#~/.orw/scripts/notify.sh -p "fp: $full_path\nc: $current"
#sleep 5

if [[ -z $@ ]]; then
	depth=2
	#full_path=""
	#set current "$(transmission-remote -t $torrent_id -i | awk '/^\s*Name/ { sub("^[^:]*: *", ""); print }')"
	#set full_path "$(transmission-remote -t $torrent_id -i | awk '/^\s*Name/ { sub("^[^:]*: *", ""); print }')"
	current=""
	set full_path "$(transmission-remote -t $torrent_id -i | awk '/^\s*Name/ { sub("^[^:]*: *", ""); print }')"
else
	[[ ${@%% *} == [![:ascii:]] ]] && current="${@#* }" || current="$@"
	set current

	if [[ $current == done ]]; then
		transmission-remote -t $torrent_id -s
	elif [[ $current == back ]]; then
		full_path="${full_path%/*}"
		((depth--))
	else
		read depth final_depth option all_ids <<< $(agregate)

		~/.orw/scripts/notify.sh "fd: $final_depth"

		#if ((!final_depth)) && [[ ! $current =~ all|none ]]; then
		if [[ ! $current =~ all|none ]]; then
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
