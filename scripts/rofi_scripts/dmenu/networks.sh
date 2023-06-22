#!/bin/bash

(
	for range in     ; do
		~/.orw/scripts/notify.sh -r 303 -t 1 -s osd -i $range "scanning.."
		sleep 0.4
	done
) &

id=$(printf "0x%.8x" $(xdotool getactivewindow))
read window_x window_y <<< $(wmctrl -lG | awk '$1 == "'$id'" { print $3, $4 }')

display_width=$(awk '\
	BEGIN {
		wx = '$window_x'
		wy = '$window_y'
	}

	/^display/ {
		if($1 ~ /xy$/) {
			x = $2
			y = $3
		} else if($1 ~ /size$/) {
			if(wx < x + $2 && wy < y + $3) {
				print $2
				exit
			}
		}
	}' ~/.config/orw/config)

offset=$(awk '
	function get_value() {
		return gensub("[^0-9]*([0-9]+).*", "\\1", 1)
		#return gensub(".* ([0-9]+).*", "\\1", 1)
	}

	$1 == "font:" { f = get_value() }
	$1 == "window-width:" { ww = get_value() }
	$1 == "window-padding:" { wp = get_value() }
	$1 == "element-padding:" { ep = get_value() }
	END {
		rw = int('$display_width' * ww / 100)
		iw = rw - 2 * (wp + ep)
		print int(iw / (f - 2))
		#print int((('$display_width' * ww / 100) - 2 * (wp + ep)) / (f - 2))
	}' .config/rofi/list.rasi)

	read active all_networks <<< \
		$(nmcli dev wifi | awk '{ \
			if(NR == 1) {
				c = 0
				mi = index($0, " MODE")
				si = index($0, "SIGNAL")
				ssidi = index($0, " SSID")
			} else {
				s = substr($0, si, 3)

				#if(s == 100) si = ""
				#else if(s > 90) si = ""
				#else if(s > 70) si = ""
				#else if(s > 30) si = ""
				#else si = ""

				if(s == 100) si = ($NF != "--") ? "" : ""
				else if(s > 90) si = ($NF != "--") ? "" : ""
				else if(s > 70) si = ($NF != "--") ? "" : ""
				else if(s > 30) si = ($NF != "--") ? "" : ""
				else si = ($NF != "--") ? "" : ""

				ssid = substr($0, ssidi, (mi - ssidi) - 1)

				a = ($1 == "*") ? "connected" : ""
				if(a) cn = NR - 2

				#system("~/.orw/scripts/notify.sh " s)
				o = '$offset' - length(ssid) - length(a)

				#printf "%s %s %*s\n", $NF != "--" ? " " : si, ssid, o, a ? "connected" : ""
				#an = an sprintf("%s %s %*s\\\\n", $NF != "--" ? " " : si, ssid, o, a ? "connected" : "")
				an = an sprintf("%s%s %*s\\\\n", si, ssid, o, a ? "connected" : "")
			}
		} END { print cn, an }')

	read protected network_name <<< $(echo -e "$all_networks" | rofi -dmenu -a $active -theme list)
#else

	if [[ $network_name ]]; then
		get_password() {
			password=$(sed -n "s/^$network_name: //p" ~/.orw/scripts/auth/networks)
		}

		notify_on_finish() {
			while kill -0 $pid 2> /dev/null; do
				sleep 1
			done && ~/.orw/scripts/notify.sh "Successfully ${state-connected to} to <b>$network_name</b>"
		}

		#read protected network_name <<< $@

		if [[ $network_name =~ connected$ ]]; then
			network_name="${network_name% *}"
			state='disconnected from'
			connected=true
		fi

		if [[ $protected ==  ]]; then
			get_password

			if [[ ! $password ]]; then
				killall rofi
				~/.orw/scripts/set_geometry.sh -t network_input -w 300 -h 100
				termite -t network_input -e \
					"bash -c \"~/.orw/scripts/network_auth.sh ${network_name//\'/\\\'}\"" $> /dev/null
				get_password
			fi

			password_arg=password
		fi

		[[ $connected ]] && command="nmcli connection down '$network_name'" ||
			command="nmcli device wifi connect '$network_name' $password_arg '$password'"

		coproc (eval $command &> /dev/null &)
		pid=$((COPROC_PID + 1))
		coproc (notify_on_finish &)
	fi
