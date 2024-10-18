#!/bin/bash

#nmcli dev wifi | awk '
#			{
#				if(NR == 1) {
#					c = 0
#					mi = index($0, " MODE")
#					si = index($0, "SIGNAL")
#					ssidi = index($0, " SSID")
#				} else {
#					s = substr($0, si, 3)
#
#					if(s == 100) si = ($NF != "--") ? "" : ""
#					else if(s > 90) si = ($NF != "--") ? "" : ""
#					else if(s > 70) si = ($NF != "--") ? "" : ""
#					else if(s > 30) si = ($NF != "--") ? "" : ""
#					else si = ($NF != "--") ? "" : ""
#
#					ssid = substr($0, ssidi, (mi - ssidi) - 1)
#					sub("\\s+$", "", ssid)
#
#					a = ($1 == "*") ? "connected" : ""
#					if(a) cn = NR - 2
#
#					#system("~/.orw/scripts/notify.sh " s)
#					o = '$offset' - length(ssid) -  length(si)
#
#					an = an sprintf("%s%s%*s\\\\n", si, ssid, o, ((a) ? "connected" : ""))
#				}
#			} END { print cn, an }'
#exit

(
	for range in     ; do
		~/.orw/scripts/notify.sh -s osd -t 1 -r 303 -C 'pfg' -i $range "scanning.."
		sleep 0.4
	done
) &

id=$(printf "0x%.8x" $(xdotool getactivewindow))
read window_x window_y <<< $(wmctrl -lG | awk '$1 == "'$id'" { print $3, $4 }')

#display_width=$(awk '\
#	BEGIN {
#		wx = '$window_x'
#		wy = '$window_y'
#	}
#
#	/^display/ {
#		if ($1 ~ /size$/) { w = $2; h = $3 }
#		else if ($1 ~ /xy$/) {
#			if (wx < $2 + w && wy < $3 + h) { print w; exit }
#		}
#	}' ~/.config/orw/config)

#offset=$(awk '
#	function get_value() {
#		return gensub("[^0-9]*([0-9]+).*", "\\1", 1)
#	}
#
#	$1 == "font:" { f = get_value() }
#	$1 == "window-width:" { ww = get_value() }
#	$1 == "window-padding:" { wp = get_value() }
#	$1 == "element-padding:" { ep = get_value() }
#	END {
#		rw = int('$display_width' * ww / 100)
#		iw = rw - 2 * (wp + ep)
#		print int(iw / (f - 0))
#	}' ~/.config/rofi/list.rasi)

#rofi_width=$(awk '
#		function get_value() {
#			return gensub(".* ([0-9]+).*", "\\1", 1)
#		}
#
#		{
#			if (NR == FNR) {
#				if (/^\s*font/) f = get_value()
#				if (/^\s*window-width/) ww = get_value()
#				if (/^\s*switcher-width/) sw = get_value()
#				if (/^\s*window-padding/) wp = get_value()
#				if (/^\s*element-padding/) ep = get_value()
#			} else {
#				if ($1 == "orientation") {
#					if ($2 == "horizontal") {
#						p = '${x:-1}'
#						pf = 2
#					} else {
#						p = '${y:-1}'
#						pf = 3
#					}
#				}
#
#				if (/^display_[0-9]_size/) { w = $2 }
#				if (/^display_[0-9]_xy/ && p > $pf) {
#					rw = int(w * (ww - sw - 2 * wp) / 100)
#					rw -= 2 * ep
#					print int(rw / f)
#					exit
#				}
#			}
#		}' ~/.config/{rofi/list.rasi,orw/config})

rofi_width=$(awk '
		function get_value() {
			return gensub(".* ([0-9]+).*", "\\1", 1)
		}

		{
			if (NR == FNR) {
				if (/^\s*font/) f = get_value()
				if (/^\s*window-width/) ww = get_value()
				if (/^\s*list-padding/) lp = get_value()
				if (/^\s*window-padding/) wp = get_value()
				if (/^\s*element-padding/) ep = get_value()
			} else {
				if ($1 == "orientation") {
					if ($2 == "horizontal") {
						p = '${x:-1}'
						pf = 2
					} else {
						p = '${y:-1}'
						pf = 3
					}
				}

				if (/^display_[0-9]_size/) { w = $2 }
				if (/^display_[0-9]_xy/ && p > $pf) {
					rw = int(w * (ww - sw - 2 * 0) / 100)
					rw -= 2 * (lp + ep)
					print int((rw / f) * 1.12)
					exit
				}
			}
		}' ~/.config/{rofi/list.rasi,orw/config})

list_networks() {
	awk '
		NR == FNR && /^[^#]*(wifi|lock_full)/ {
			i = $0
			sub(".*=", "", i)

			switch ($0) {
				case /unlock/: pui = i; break;
				case /lock_/: pli = i; break;
				case /empty/: ei = i; break;
				case /high/: hi = i; break;
				case /mid/: mi = i; break;
				case /low/: li = i; break;
				default: fi = i; break;
			}
		}

		NR > FNR {
			if (FNR == 1) {
				cn = " "
				bi = index($0, "BARS")
				moi = index($0, " MODE")
				sii = index($0, "SIGNAL")
				ssidi = index($0, " SSID")
			} else {
				s = substr($0, sii, 3)

				if(s < 10) si = ei
				else if(s < 40) si = li
				else if(s < 70) si = mi
				else si = hi
				if ($NF == "--") pi = pui
				else { pi = pli; h = h "," FNR - 2 }

				ssid = substr($0, ssidi, (moi - ssidi) - 1)
				sub("\\s+$", "", ssid)

				if ($1 == "*") a = FNR - 2
				#an = an "\n" si " " pi " " ssid
				o = '$rofi_width' - length(ssid) -  length($(NF - 1))
				#print '$rofi_width', length(ssid), o, ssid
				b = substr($0, bi, 4)
				an = an "\n" sprintf("%s%*s", b, '$rofi_width', ssid)
				#an = an "\n" $(NF - 1) " " ssid
			}
		} END { print "-a " a "\n-u " substr(h, 2) an }' \
			~/.orw/scripts/icons <(nmcli dev wifi)
		#} END { print ((cn ~ "[0-9]") ? "-a " cn : " ") an }' \
}

	#IFS=$'\n' read -d '' active all_networks <<< \
	#	$(nmcli dev wifi | awk '
	#		{
	#			if(NR == 1) {
	#				cn = " "
	#				mi = index($0, " MODE")
	#				si = index($0, "SIGNAL")
	#				ssidi = index($0, " SSID")
	#			} else {
	#				s = substr($0, si, 3)

	#				if(s == 100) si = ($NF != "--") ? "" : ""
	#				else if(s > 90) si = ($NF != "--") ? "" : ""
	#				else if(s > 70) si = ($NF != "--") ? "" : ""
	#				else if(s > 30) si = ($NF != "--") ? "" : ""
	#				else si = ($NF != "--") ? "" : ""

	#				ssid = substr($0, ssidi, (mi - ssidi) - 1)
	#				sub("\\s+$", "", ssid)

	#				#a = ($1 == "*") ? "connected" : ""
	#				#if(a) cn = NR - 2
	#				if ($1 == "*") cn = NR - 2

	#				#system("~/.orw/scripts/notify.sh " s)
	#				#o = '$offset' - length(ssid) -  length(si)

	#				#an = an sprintf("%s%s%*s\\\\n", si, ssid, o, ((a) ? "connected" : ""))
	#				an = an "\n" si " " ssid
	#			}
	#		} END { print ((cn ~ "[0-9]") ? "-a " cn : " ") an }')

	
IFS=$'\n' read -d '' active hilight all_networks < <(list_networks)
[[ $active != *[0-9]* ]] && unset active
[[ $hilight != *[0-9]* ]] && unset hilight

theme_str='window { padding: 0%; }'

read index signal network_name <<< $(echo -e "$all_networks" |
	rofi -dmenu -format 'i s' $hilight $active -theme-str "$theme_str" -theme list)

if [[ $network_name ]]; then
	get_password() {
		password=$(sed -n "s/^$network_name: //p" ~/.orw/scripts/auth/networks)
	}

	notify_on_finish() {
		while kill -0 $pid 2> /dev/null; do
			sleep 1
		done && ~/.orw/scripts/notify.sh "Successfully ${state-connected to} <b>$network_name</b>"
	}

	if [[ $active ]]; then
		state='disconnected from'
		command="nmcli connection down '$network_name'"
	else
		if [[ "${hilight#* }" =~ (^|,)$index|$index(,|$) ]]; then
			get_password

			if [[ ! $password ]]; then
				killall rofi
				~/.orw/scripts/set_geometry.sh -t network_input -w 300 -h 100
				alacritty -t network_input -e \
					bash -c "~/.orw/scripts/network_auth.sh ${network_name//\'/\\\'}" $> /dev/null
				get_password
			fi

			password_arg=password
		fi

		command="nmcli device wifi connect '$network_name' $password_arg $password"
	fi

	coproc (eval $command &> /dev/null &)
	pid=$((COPROC_PID + 1))
	coproc (notify_on_finish &)
fi
