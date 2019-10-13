#!/bin/bash

if [[ -z $@ ]]; then
	~/.orw/scripts/notify.sh "Scanning available networks.."

	id=$(printf "0x%.8x" $(xdotool getactivewindow))
	read window_x window_y <<< $(wmctrl -lG | awk '$1 == "'$id'" { print $3, $4 }')

	display_width=$(awk '\
		BEGIN { wx = '$window_x'; wy = '$window_y' }
		/^display/ {
		if($1 ~ /xy$/) {
			x = $2
			y = $3
		} else {
			if(wx < x + $2 && wy < y + $3) {
				print $2
				exit
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
		END { print int((('$display_width' / 100) * w - 2 * p) / (8 - 2) - 7) }' .config/rofi/list.rasi)

	nmcli dev wifi | awk '{ \
		if(NR == 1) {
			si = index($0, "SSID")
			mi = index($0, "MODE")
		} else {
			nn = substr($0, si, (mi - si) - 1)
			o = '$offset' - length(nn)
			printf "%s %s %*s\n", $NF != "--" ? " " : " ", nn, o, $1 == "*" ? "connected" : ""
		}
	}'
else
	get_password() {
		password=$(sed -n "s/^$network_name: //p" ~/.orw/scripts/auth/networks)
	}

	read protected network_name <<< $@
	[[ $network_name =~ connected$ ]] && network_name="${network_name% *}"

	if [[ $protected ==  ]]; then
		get_password

		if [[ ! $password ]]; then
			killall rofi
			termite -t network_auth -e "bash -c \"~/.orw/scripts/network_auth.sh ${network_name//\'/\\\'}\"" $> /dev/null
			get_password
		fi

		password="password $password"
	fi

	nmcli device wifi connect "$network_name" "$password"
fi
