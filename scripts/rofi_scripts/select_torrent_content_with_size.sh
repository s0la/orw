#!/bin/bash

function set() {
	eval $1='$(sed "s/\(\\*\)\?\([()\&]\)/\\\\\\\\\2/g" <<< "${2:-${!1}}")'
	sed -i "s/\(^$1=\).*/\1\"${!1//\//\\/}\"/" $0
}

agregate() {
	[[ $1 ]] && local print=true

	transmission-remote -t $torrent_id -f | awk '\
		function format_output(file) {
			if(file) {
				s = sv
				cfn = n
				cfs = (st == "Yes") ? " " : " "
			} else {
				s = ts
				cfn = pfn
				cfs = (sc > 0) ? (sc == tc) ? " " : " " : " "
				#cfs = (sc > 0) ? (sc == tc) ? " " : " " : " "
			}

			tc = 0; sc = 0; ts = 0;
			ss = sprintf("%.1f MB", s)
			af = af sprintf("\n%s %-*s %s", cfs, of - length(ss), cfn, ss)
		}

		NR == 2 {
			d = '$depth'
			of = '$offset'
			p = "'$print'"
			c = "'"$current"'"
			fp = "'"$full_path"'"
			o = "x"; sp = fp; ns = index($0, "Name")
		}

		NR > 2 {
			if(!p) i = gensub("^ *([0-9]*):.*", "\\1", 1)

			st = $4; sv = $5; su = $6
			if(su ~ "kB") sv/=1024
			else if(su ~ "GB") sv*=1024

			fn = substr($0, ns)
			nd = gensub("(/?([^/]*)){" d "}(.*)", "\\2\\3", 1)
			split(nd, ndp, "/")
			cn = ndp[1]

			if(!fd) fd = (! ndp[2] && fn ~ fp && cn ~ "^" c "$")
			n = (p) ? cn : fn

			if(p) {
				if(fn ~ fp "/") {
					if(fd) {
						if(tc) format_output()
						format_output(1)
					} else {
						if(pfn && pfn != n) format_output()

						tc++
						if(st == "Yes") sc++
						pfn = n

						ts += sv
					}
				}
			} else {
				if(c ~ /^(all|none)$/) {
					did = 1
					o = (c == "all") ? "g" : "G"
				} else {
					sp = fp "/" c
				}

				if(fn ~ fp "/") {
					if(fd) {
						si = i
						did = 1
						o = (st == "Yes") ? "G" : "g"
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

id=$(xdotool getactivewindow)
read window_x window_y <<< $(wmctrl -lG | awk '$1 == "'$id'" { print $3, $4 }')

display_width=$(awk '\
	BEGIN { id = "'$id'"; wx = '${window_x:-0}'; wy = '${window_y:-0}' }
	{
		if(!id) {
			if($1 == "primary") p = $NF
			if(p && $1 == p) {
				print $2
				exit
			}
		} else {
			if(/^display/) {
				if($1 ~ /xy$/) {
					x = $2
					y = $3
				} else {
					if(wx < x + $2 && wy < y + $3) {
						print $2
						exit
					}
				}
			}
		}
	}' ~/.config/orw/config)

offset=$(awk '
	function get_value() {
		return gensub("[^0-9]*([0-9]+).*", "\\1", 1)
	}

	/window/ { nr = NR }
	/font/ { f = get_value() }
	/width/ && NR < nr + 5 { w = get_value() }
	/padding/ && NR < nr + 5 { p = get_value() }
	END { print int((('$display_width' / 100) * w - 2 * p) / (f - 2) - 7) }' .config/rofi/large_list.rasi)

depth="2"
final_depth="0"
current="done"
full_path="Buckethead"

torrent_id=$(transmission-remote -l | awk '$1 ~ /^[0-9]+/ { ti = $1 } END { print gensub("([0-9]+).*", "\\1", 1, ti) }')

if [[ -z $@ ]]; then
	depth=2
	current=""
	set full_path "$(transmission-remote -t $torrent_id -i | awk '/^\s*Name/ { sub("^[^:]*: *", ""); print }')"
else
	if [[ ${@%% *} == [![:ascii:]] ]]; then
		current=$(awk '{ si = gensub("([^ ]* *).*", "\\1", 1); sil = length(si) + 1; \
			lf = $(NF - 2); li = index($0, lf) + length(lf); \
			print substr($0, sil, li - sil) }' <<< "$@")
	else
		current=$@
	fi

	set current

	if [[ $current == done ]]; then
		transmission-remote -t $torrent_id -s &> /dev/null
		exit
	elif [[ $current == back ]]; then
		full_path="${full_path%/*}"
		((depth--))
	else
		read depth final_depth option all_ids <<< $(agregate)

		if ((!final_depth)) && [[ ! $current =~ ^(all|none)$ ]]; then
			[[ $full_path ]] && full_path+='/'
			full_path+="$current"
		fi

		[[ $option != x ]] && transmission-remote -t $torrent_id -$option $all_ids &> /dev/null
	fi
fi

agregate print

set depth
set current
set full_path
set final_depth
