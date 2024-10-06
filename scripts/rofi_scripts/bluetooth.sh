#!/bin/bash

list_devices() {
	awk -F '[= ]' '
		BEGIN { i = ("'"$style"'" ~ "icons") }
		NR == FNR && $1 == "Device" { addr = $2 }
		NR == FNR && $1 ~ ((i) ? "Icon" : "Name") ":" {
			sub("^.*:\\s*" ((i) ? "(.*-)?" : ""), "")
			d = $0
			ad[d] = addr
		}

		#NR == FNR && /Connected/ { if ($NF == "yes") a = a "," d }
		NR == FNR && /Connected/ { if ($NF == "yes") aad[d] = 1 }

		i && NR > FNR && $1 in ad {
			ad[$NF] = ad[$1]
			delete ad[$1]

			if ($1 in aad) {
				aad[$NF] = 1
				delete aad[$1]
			}
		}
		
		END {
			for (addr in ad) printf "[\"%s\"]=\"%s\" ", addr, ad[addr]
			print ""
			for (adi in aad) printf "%s ", adi
			#print "\n" substr(a, 2)
		}' <(bluetoothctl devices | awk '{ print $2 }' | xargs -rn1 bluetoothctl info) $icons
}

rfkill unblock bluetooth

#read {scan,action}_icon <<< $(sed -n 's/^.*\(scan\|action\)=//p' $icons | xargs)
read {scan,action}_icon <<< $(sed -n 's/^bluetooth_.*=//p' $icons | xargs)
for sec in {1..4}; do
	((sec % 2)) && fg='sbg' || fg='pbfg'
	~/.orw/scripts/notify.sh -s osd -t 1100m -r 11 -C $fg -i "$scan_icon" 'scanning..'
	sleep 0.8
done &

style=list
bluetoothctl --timeout 4 scan on &> /dev/null
IFS=$'\n' read -d '' {,active_}device_list <<< $(list_devices)
eval declare -A devices=( "$device_list" )
#devices[]='999999'

device_index=0
[[ $active_device_list ]] &&
	for device in "${!devices[@]}"; do
		[[ "$active_device_list" == *$device* ]] && active+="$device_index,"
		#[[ "$device" == *$active_device_list* ]] && active+="$device_index,"
		((device_index++))
	done

[[ $active ]] && active="-a ${active%,}"

submenu=( Pair Trust Connect Transfer )
[[ $style != *icons* ]] &&
	submenu_labels=( ${submenu[*]} ) ||
	submenu_labels=( $(sed -nE "s/^($(tr " " "|" <<< ${submenu[*],,}))=//p" $icons) )
submenu_options="${submenu[*]}"
suboptions_count=${#submenu[*]}
item_count=${#devices[*]}
base_count=$item_count

adjust_active() {
	local sign new_active submenu_count existing_active="${active#* }"
	((item_count > base_count)) &&
		sign=- submenu_count=$suboptions_count || sign=+

	for ex_active in ${existing_active//,/ }; do
		((ex_active <= device_index)) &&
			new_active+=",$ex_active"
		((ex_active > device_index + submenu_count)) &&
			new_active+=",$((ex_active $sign suboptions_count))"
		#echo $ex_active, $device_index, $suboptions_count: $new_active
	done

	[[ $new_active ]] &&
		active="-a ${new_active#,}" || unset active
}

#base_count=3
#item_count=3

while
	set_theme_str
	[[ $style == list ]] &&
		theme_str+="window { padding: 0%; }"
	read index option < <(
		#for device in "${!devices[@]}"; do
		for device in "${!devices[@]}"; do
			echo "$device" #${devices[$device]}
			#[[ $device == $option ]] && echo -e "${submenu_options// /$'\n'}"
			[[ "$device" == "$option" ]] && ((item_count > base_count)) &&
				tr ' ' '\n' <<< ${submenu_labels[*]}
		done | rofi -dmenu -format 'i s' -selected-row ${index:-0} \
			$active $hilight -theme-str "$theme_str" -theme $style
	)

	if [[ $option ]]; then
		if [[ ${submenu_labels[*]} == *"$option"* ]]; then
			sub_index=$((index - (device_index + 1)))
			[[ ${active#* } =~ (^|,)$index|$index(,|$) ]] &&
				case ${submenu[sub_index],} in
					pair) action=remove;;
					trust) action=untrust;;
					connect) action=disconnect;;
					transfer)
						#obexctl disconnect "$selected_device"
						~/.orw/scripts/notify.sh -s osd -t 1100m -r 11 -i "$action_icon" "FILE TRANSFER: OFF" &> /dev/null
						new_active="${active/,$index}"
				esac || action=${submenu[sub_index],} on=yes

			if [[ ${submenu[sub_index],} == transfer ]]; then
				if [[ $active != *$index* ]]; then
					pidof obexd &> /dev/null ||
						/usr/libexec/bluetooth/obexd -r ~/Downloads/bluetooth -adn &> /dev/null &
					#obexctl connect "$selected_device"
					~/.orw/scripts/notify.sh -s osd -t 1100m -r 11 -i "$action_icon" "FILE TRANSFER: ON" &> /dev/null
					new_active="$active,$index"
				fi
			else
				#~/.orw/scripts/notify.sh -s osd -t 5 -i "$action_icon" "${action^^}ING.." &> /dev/null
				for sec in {1..6}; do
					((sec % 2)) && fg='sbg' || fg='pbfg'
					~/.orw/scripts/notify.sh -s osd -t 1100m -r 11 -C $fg -i "$action_icon" "${action^^}ING.." &> /dev/null
					sleep 1
				done &

					#bluetoothctl --timeout=22 scan on &
					##bluetoothctl --timeout=15 scan on |
					##	awk '/NEW.*'"$selected_device"'/' &
					#sleep 5
					#echo bluetoothctl $action $selected_device
					#bluetoothctl $action $selected_device
					#exit



				/usr/bin/expect <<- EOF &> /dev/null
					set timeout 3
					spawn bluetoothctl
					send "scan on\n"

					send "$action $selected_device\n"

					expect "Confirm passkey" {
						send "yes\n"
					}

					expect -re {[Ss]uccessful} {
						send "scan off\nquit\n"
						exit 0
					}
				EOF
					#expect -re {${action^}.* successful} {
					#expect -re {.*Device ${action:1:}ed.*} {



				#(
				#	#bluetoothctl --timeout=25 scan on &
				#	bluetoothctl --agent NoInputNoOutput --timeout=22 scan on &
				#	#bluetoothctl --timeout=25 scan on &
				#	sleep 3
				#	echo "$action $selected_device" | bluetoothctl
				#) &> /dev/null
				##pid=$$

				#for i in {0..10}; do
				#	sleep 1
				#done
				#kill $pid

				#echo bluetoothctl $action $selected_device
				until
					new_active=$(bluetoothctl info $selected_device |
						awk '$1 == "'"${submenu[sub_index]}"'ed:" {
								if ($NF == "'${on:-no}'") {
									i = '$index'
									a = "'"${active#* }"'"

									#system("~/.orw/scripts/notify.sh \"" i " " a "\"")

									if ("'"$on"'") print "-a " a ((a) ? "," : "") i
									else {
										if (a ~ "," i ",") s = ","
										sub("(^" i ",?|,?" i "$|," i ",)", s, a)
										if (a) print "-a " a
									}
								}
							}')

					echo "$A: $active $action $selected_device"

					[[ $new_active ]]
				do
					sleep 2
					((try_count > 5)) && break
					((try_count++))
				done
			fi

			[[ $new_active ]] && active=$new_active
			option=$device_option
		else
			if ((item_count > base_count)); then
				unset hilight
				adjust_active
				((item_count -= ${#submenu[*]}))
			else
				device_index=$index
				device_option=$option
				selected_device=${devices["$option"]}

				adjust_active

				#echo D: $index, $option, ${devices["$option"]}

				subactive=$(bluetoothctl info $selected_device | awk '
					match($1, "('"${submenu_options// /\\\|}"')ed:") {
						d++
						if ($NF == "yes") a = a "," '$index' + d
					} END { if (a) print substr(a, 2) }' 2> /dev/null)

				if [[ $subactive ]]; then
					[[ $active ]] &&
						active+=",$subactive" ||
						active="-a $subactive"
				fi

				for sub_index in ${!submenu[*]}; do
					((sub_index)) && hilight+=','
					hilight+="$((index + 1 + sub_index))"
				done

				[[ $hilight ]] && hilight="-u $hilight"

				((item_count == base_count)) && ((item_count += ${#submenu[*]}))
				#echo $option, $device, $item_count, $selected_device, $active
			fi
		fi
	fi

	#echo $option
	[[ $option ]]
do
	continue
done
exit









list_devices() {
	awk -F '[= ]' '
		BEGIN { i = ("'"$style"'" ~ "icons") }
		NR == FNR && $1 == "Device" { d = $2 }
		NR == FNR && $1 ~ ((i) ? "Icon" : "Name") ":" {
			sub("^.*:\\s*" ((i) ? "(.*-)?" : ""), "")
			ad[$0] = d
		}

		i && NR > FNR && $1 in ad {
			ad[$NF] = ad[$1]
			delete ad[$1]
		}
		
		END { for (d in ad) printf "[\"%s\"]=\"%s\" ", d, ad[d] }' 2> /dev/null \
			<(bluetoothctl devices | awk '{ print $2 }' | xargs -rn1 bluetoothctl info) $icons
}

scan_icon=$(sed -n 's/^.*scan=//p' $icons)
for sec in {1..4}; do
	((sec % 2)) && fg='sbg' || fg='pbfg'
	~/.orw/scripts/notify.sh -s osd -t 1100m -r 11 -C $fg -i "$scan_icon" 'scanning..'
	sleep 1
done &

style=horizontal_icons
bluetoothctl --timeout 4 scan on &> /dev/null

declare -A devices submenu
eval devices=( $(list_devices) )

submenu_options=( Pair Trust Connect )
for option in ${submenu_options[*]}; do
	[[ $style == *icons* ]] &&
		label="$(sed -n "s/^${option,}=//p" $icons)" || label=${option,}
	submenu[$label]=${option,}
done
	#submenu=( $(sed -nE "s/^($(tr " " "|" <<< ${submenu[*],,}))=//p" $icons) )

item_count=${#devices[*]}
set_theme_str

#bluetoothctl info $selected_device | awk -F '[: ]' '
#bluetoothctl info 96:79:11:0E:B1:5B | awk '
##match($1, "('"${submenu_options// /\\\|}"')ed:") {
#	#{ print substr($1, 0, length($1) - 1), $0, "'"${submenu_options[*]}"'" ~ substr($1, 0, length($1) - 1), "'"${submenu_options[*]}"'" }
#	"'"${submenu_options[*]}"'" ~ substr($1, 0, length($1) - 3) {
#		if ($NF == "yes") a = a "," '$index' + ++d
#	} END { if (a) print "-a " substr(a, 2) }'
#exit

while
	set_theme_str
	read index option < <(
		for device in "${!devices[@]}"; do
			echo "$device"
			[[ $device == $option ]] && ((item_count > ${#devices[*]})) &&
				tr ' ' '\n' <<< ${!submenu[*]}
				#echo -e "${submenu_options// /$'\n'}"
		done | rofi -dmenu -format 'i s' -selected-row ${index:-0} $active $hilight \
			-theme-str "$theme_str" -theme $style
	)

	if [[ $option ]]; then
		if [[ ${!submenu[*]} == *"$option"* ]]; then
				#echo $option, $index
				[[ $style == *icons* ]] && option=${submenu[$option]}
				[[ ${active#* } =~ (^|,)$index|$index(,|$) ]] &&
					case $option in
						trust) action=untrust;;
						connect) action=disconnect;;
						pair) action=cancel-pairing;;
					esac || action=${option,}

				bluetoothctl $action $selected_device
				#item_count=${#devices[*]}
				option=$selected_device
				echo $item_count
		else
			if ((item_count > ${#devices[*]})); then
				((item_count -= ${#submenu[*]}))
			else
				selected_device=${devices["$option"]}
				active=$(bluetoothctl info $selected_device | awk '
					"'"${submenu_options[*]}"'" ~ substr($1, 0, length($1) - 3) {
						if ($NF == "yes") a = a "," '$index' + ++d
					} END { if (a) print "-a " substr(a, 2) }')
				((item_count == ${#devices[*]})) && ((item_count += ${#submenu[*]}))
			fi
		fi
	fi

	[[ $option ]]
do
	continue
done
exit



while
	read index device <<< $(tr ' ' '\n' <<< ${!devices[*]} |
		rofi -dmenu -format 'd s' $active $hilight -theme $style)
	((index))
do
	continue
done
exit

parse_content() {
	awk '
		{ print }
		NR == '${index:-0}' { for (i=1; i<=3; i++) print "'$item'." i }
		END { printf "\0urgent\x1f0,2\n\0keep-selection\x1ftrue\n" }
		'
}

parse_content() {
	awk '
		{ print }
		NR == '${index:-0}' {
			o = "'"${opts[*]}"'"
			gsub(" ", "\n", o)
			print o
		}'
}

declare -A options=(
			[1]='* +'
			[2]='% -'
		)

ar=( 1 2 3 )
base_count=${#ar[*]}
item_count=$base_count

while
	set_theme_str
	echo $item_count, $theme_str
	read index item <<< \
		$(tr ' ' '\n' <<< ${ar[*]} | parse_content |
		rofi -dmenu -format 'd s' $hilight $active -theme-str "$theme_str" -theme main)

	if [[ ${options[$item]} ]]; then
		#opts=( ${options[$item]} )
		read -a opts <<< ${options[$item]}
		(( item_count += ${#opts[*]} ))

		hilight=''
		for opt in ${!opts[*]}; do
			hilight+=",$((index + opt))"
		done

		hilight="-u ${hilight#,}"
		active="-a $index"
	fi

	echo $index $item
	[[ $item ]]
do
	continue
done
exit

if [[ -z $@ ]]; then
	tr ' ' '\n' <<< ${ar[*]}
else
	for i in ${!ar[*]}; do
		echo $i
		[[ ${ar[i]} == $1 ]] && ind=$i && echo -e 'sola\ncar\nnaj'
	done

	echo -en "\0urgent\x1f$ind\n"
	echo -en "\0keep-selection\x1ftrue\n"
fi
exit
exit

parse_content() {
	awk '
		{ print }
		NR == '${index:-0}' { for (i=1; i<=3; i++) print "'$item'." i }
		'
}

while
	read index item <<< \
		$(cat <<- EOF | parse_content | rofi -dmenu -format 'd s' -theme main
				1
				2
				3
			EOF
		)

	echo $index $item
	[[ $item ]]
do
	continue
done
