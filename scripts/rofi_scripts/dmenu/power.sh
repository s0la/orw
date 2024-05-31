#!/bin/bash

#theme=$(awk -F '[".]' 'END { print $(NF - 2) }' ~/.config/rofi/main.rasi)
#[[ $theme =~ dmenu|icons ]] && ~/.orw/scripts/set_rofi_geometry.sh power
[[ ! $style =~ icons|dmenu ]] &&
	lock=lock loggout=loggout reboot=reboot suspend=suspend off=poweroff sep=' '

icon_lock=
icon_logout=
icon_reboot=
icon_off=

icon_lock=
icon_lock=
icon_logout=
icon_reboot=
icon_off=

icon_lock=
icon_lock=
icon_logout=
icon_reboot=
icon_off=
icon_off=
icon_suspend=
#toggle_rofi() {
#	~/.orw/scripts/signal_windows_event.sh rofi_toggle
#}

#icon_lock='*'
#icon_lock='*'
#icon_logout='*'
#icon_reboot='*'
#icon_off='*'
#icon_off='*'
#icon_suspend='*'

toggle
trap toggle EXIT

while
	item_count=5
	set_theme_str

	action=$(cat <<- EOF | rofi -dmenu -theme-str "$theme_str" -theme main
		$icon_lock$sep$lock
		$icon_logout$sep$loggout
		$icon_reboot$sep$reboot
		$icon_suspend$sep$suspend
		$icon_off$sep$off
	EOF
	)

	[[ $action ]]
do
	yes_icon=
	no_icon=
	yes_icon=
	no_icon=

	[[ $style != *icons ]] &&
		yes_label=yes no_label=no

	if [[ $action =~ $icon_lock ]]; then
		#sleep 0.1
		~/.orw/scripts/lock_screen.sh
		exit
	else
		item_count=2
		set_theme_str

		confirmation=$(echo -e "$yes_icon$yes_label\n$no_icon$no_label" |
			rofi -dmenu -theme-str "$theme_str" -theme main)

		[[ $confirmation == "$yes_icon$yes_label" ]] &&
			case "$action" in
				$icon_logout*) openbox --exit;;
				$icon_reboot*) systemctl reboot;;
				$icon_suspend) systemctl suspend;;
				$icon_off*) systemctl poweroff ;;
			esac && exit
	fi
done
