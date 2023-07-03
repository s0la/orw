#!/bin/bash

get_network() {
	local {connection,device}_type signal ssid
	read connection_type device_type <<< \
		$(nmcli device status |
			awk '
				{
					if (NR == 1) {
						si = index($0, "STATE")
						ci = index($0, "CONNECTION")
					} else {
						c = substr($0, si, ci - si)
						if ($1 == "'"$device"'") { dt = $2 }
						if (c ~ "^connected\\s*$") { ct = $2 }
					}
				} END { print ct, dt }')

	if [[ $connection_type ]]; then
		if [[ $connection_type == wifi ]]; then
			read signal icon ssid <<< \
				$(nmcli device wifi list |
					awk '{
						if (NR == 1) {
							ssid_index = index($0, " SSID") + 1
							mode_index = index($0, " MODE") + 1
							signal_index = index($0, " SIGNAL") + 1
						} else if ($1 == "*") {
							ssid = substr($0, ssid_index, mode_index - ssid_index)
							signal = substr($0, signal_index, 4)
							sub(" *$", "", ssid)
							sub(" *$", "", signal)

							#system("~/.orw/scripts/notify.sh \"^" signal "^\"")

							switch (signal) {
								case /^[0-2][0-9]$/:
									icon = "low"
									break
								case /^[3-6][0-9]$/:
									icon = "mid"
									break
								case /^[6-8][0-9]$/:
									icon = "high"
									break
								default: icon = "full"
							}

							print signal, icon, ssid
						}
					}')

			#~/.orw/scripts/notify.sh "wifi: $ssid $signal $icon"
			icon=$(get_icon "network_wifi_${icon}_icon")
			#~/.orw/scripts/notify.sh "wifi: $icon"

			#network+="\$Npbg\$Npfg$wifi_info"
			#~/.orw/scripts/notify.sh "wifi: $network"
		else
			connection_type="${connection_type::3}"
			icon="$(get_icon "network_eth_icon")"
		#	local network="${icon:-${type^^}}"
		fi

			#echo "${connection_type^^}: $signal $ssid"
		#else
		#	echo "${connection_type^^}"
		#fi

		#network="${connection_type^^} $signal $ssid"

		#echo "$device_type: $status" > s.log

		[[ $device && $status ]] &&
			~/.orw/scripts/notify.sh -s osd -i "${icon//[[:ascii:]]}" \
			"${ssid:-$device_type}: $status" &> /dev/null
	#else
		#echo "DISCONNECTED"
	fi

	eval network=\""$network_components"\"
}

check_network() {
	get_network
	print_module network

	nmcli monitor |
		awk '$1 ~ ":$" && $2 ~ "(connected|available)$" {
			print $1 $2
			fflush()
		}' | while IFS=':' read device status; do
			#echo "CHANGE $device: $status"
			get_network
			print_module network
		done
}

make_network_content() {
	[[ ${joiner_modules[$opt]} ]] &&
		local npfg='\${cjpfg:-\$Npfg}' nsfg='\${cjsfg:-\$Nsfg}' ||
		local npbg='$Npbg' nsbg='$Nsbg'
	network_components="$nsbg$npfg\${icon:-\${connection_type^^}}"

	for arg in ${1//,/ }; do
		value=${arg#*:}
		arg=${arg%%:*}

		[[ $wifi_components ]] ||
			wifi_components="\$inner$npbg\$Npfg"

		case $arg in
			s) wifi_components+='$inner$signal';;
			i) wifi_components+='$inner$ssid';;
		esac
	done

	network_components+="$wifi_components"

	#network_content="\$padding\${type_icon:-\${type^^}}\$padding"
	#network_content='$padding${type_icon:-${type^^}}$padding'
	network_content='$network_padding$network$network_padding'
}

#get_network
#sleep 3
#check_network
