#!/bin/bash

if [[ $style =~ icons|dmenu ]]; then
	include='.*circle_empty\|list\|random'
	exclude='Workspace\|plus\|minus\|x\|arrow_\(left\|right\)'
	read up down prev next play stop pause pl random <<< \
		$(sed -n "/^\($exclude\)/! s/^\($include\).*=//p" ~/.orw/scripts/icons | xargs)
	toggle=$(mpc | awk -F '[][]' 'NR == 2 { s = $2 }
		END { print (s == "playing") ? "'"$pause"'" : "'"$play"'" }')
else
	toggle=play stop=stop next=next prev=prev random=random up=volume_up down=volume_down controls=controls pl=playlist sep=' '
fi

handle_volume() {
	volume="$action"
	[[ ${volume##* } =~ [0-9] ]] && local multiplier="${volume##* }" volume="${volume% *}"
	[[ ${volume%% *} == $up ]] && direction=+ || direction=-

	mpc -q volume $direction$((${multiplier:-1} * 5))
	~/.orw/scripts/system_notification.sh mpd_volume osd &
}

item_count=8
set_theme_str

toggle
trap toggle EXIT

while
	active=$(mpc | awk 'END { if($6 == "on") print "-a 4" }')

	read row action <<< $(cat <<- EOF | rofi -dmenu -format 'i s' -theme-str "$theme_str" -selected-row ${row:-1} $active -theme main
		$prev
		$toggle
		$stop
		$next
		$random
		$up
		$down
		$pl
	EOF
	)

	if [[ $action ]]; then
		case "$action" in
			$toggle*) mpc -q toggle;;
			$up*|$down*) handle_volume;;
			$pl*) ~/.orw/scripts/rofi_scripts/art_playlist.sh &;;
			$stop*) mpc -q stop;;
			$next*) mpc -q next;;
			$prev*) mpc -q prev;;
			$random*) mpc -q random;;
			*) mpc -q ${action#* };;
		esac
	fi

	[[ $action =~ $prev|$next|$up|$down|$random ]]
do
	continue
done
