#!/bin/bash


	#sudo unbuffer btmon | awk '
	#	/Powered:/ { print $2, "bluetooth" }
	#	#/Adv Monitor app/ { print }
	#	/onnect Complete/ { s = $4 }
	#	s && /Address:/ {
	#		gsub("^.*Address:\\s+", "")
	#		print s, $1
	#		s = ""
	#	}'
	#exit

make_bluetooth_content() {
	bluetooth_icon=$icons
	local joiner_group_index=${joiner_modules[B]}
	[[ ! $joiner_group_index ]] &&
		bluetooth_distance="\$inner" ||
		bluetooth_distance="%{O${joiners[joiner_group_index - 1]%% *}}"
}

get_bluetooth_devices() {
	local device=$1
	bluetoothctl info $device | awk '
		$1 == "Device" { d = $2 }
		$1 == "Icon:" { sub(".*-", "", $NF); ad[d] = $NF }
		END { for (d in ad) printf "[%s]=%s ", d, ad[d] }'
}

get_bluetooth() {
	local fg show_full
	label=BT icon="$(get_icon 'bluetooth=')"
	show_full=$(awk '$1 == "bluetooth_full" { print $NF }' $bar_config)
	#read bluetooth fg <<< $(bluetooth show |
	#	awk '/PowerState/ { print $NF, (($NF == "on") ? "p" : "s") }')
	[[ $bluetooth ]] ||
		#bluetooth=$(bluetoothctl show | awk '/PowerState/ { print $NF }')
		bluetooth=$(bluetoothctl show | sed -n 's/.*PowerState:\s*\([^ ]*\).*/\1/p')
		#bluetooth=$(bluetooth | awk '{ print $NF }')
	[[ $bluetooth_icon == only && ${bluetooth,,} == on ]] && icon="\${cjpfg:-\$Bpfg}$icon"
	#~/.orw/scripts/notify.sh -t 11 "$bluetooth $icon"

	if ((show_full)); then
		for bluetooth_device in ${!bluetooth_devices[*]}; do
			icon+="$bluetooth_distance\${cjpfg:-\${jpfg}}$(get_icon ${bluetooth_devices[$bluetooth_device]})"
		done
	fi
}

set_bluetooth_actions() {
	[[ ${bluetooth,,} == on ]] &&
		local toggle=off || local toggle=on

	local notify="~/.orw/scripts/system_notification.sh bluetooth $toggle"
	local action3="sudo bluetoothctl power $toggle &> /dev/null && $notify"
	local action1="sed -i '/^bluetooth/ y/01/10/' $bar_config"

	actions_start="%{A1:$action1:}%{A3:$action3:}"
	actions_end="%{A}%{A}"
}

check_bluetooth() {
	rfkill unblock bluetooth

	declare -A bluetooth_devices
	eval bluetooth_devices=( $(get_bluetooth_devices) )

	get_bluetooth
	set_bluetooth_actions
	#~/.orw/scripts/notify.sh -t 5 "BT: $bluetooth"
	print_module bluetooth

	while read device state; do
		#~/.orw/scripts/notify.sh -t 5 "BT: $device: $state"
		case $device in
			bluetooth)
				bluetooth=$state
				set_bluetooth_actions
				;;
			bluetooth) get_bluetooth $state;;
			*)
				[[ ${state,} == disconnect ]] &&
					unset bluetooth_devices[$device] ||
					eval bluetooth_devices+=( $(get_bluetooth_devices $device) )
				#eval "bluetooth_devices$(get_bluetooth_devices $device)"
				;;
				#if [[ $state == Connect ]]; then
				#	read device_icon <<< $(awk -F '[= ]' '
				#		NR == FNR && /^\s*Icon/ {
				#			sub(".*-", "", $NF)
				#			i = $NF
				#		}
				#		NR > FNR && $1 == i {
				#			print $NF
				#		}' <(bluetoothctl show $device) $icons_file)
				#	icon+="\$inner\$cjpfg$icon"
				#fi
				#;;
		esac

		get_bluetooth
		print_module bluetooth
	done < <(sudo unbuffer btmon | awk '
		/Powered:/ { print "bluetooth", (($2 == "Enabled") ? "on" : "off"); fflush() }
		/onnect Complete/ { s = $4 }
		s && /Address:/ {
			gsub("^.*Address:\\s+", "")
			print $1, s; fflush()
			s = ""
		}')
}
