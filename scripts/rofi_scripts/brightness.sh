#!/bin/bash

if [[ $style =~ icons|dmenu ]]; then
	read up down default <<< \
		$(sed -n 's/^\(arrow_\(up\|down\).*empty\|brightness\).*=//p' ~/.orw/scripts/icons | xargs)
else
	default='default' up='brightness up' down='brightness down' sep=' '
fi

toggle
trap toggle EXIT

while
	active=$(awk '/^[^#].*[0-9]+%/ {
		l = gensub(/.* ([0-9]+)%.*/, "\\1", 1)
		if(l == 50) print "-a 1" }' ~/.orw/scripts/system_notification.sh)

	read row brightness <<< $(cat <<- EOF | rofi -dmenu -i -format 'i s' -selected-row ${row:-0} $active -theme main
		$up
		$default
		$down
	EOF
	)

	[[ $brightness ]]
do
	case $brightness in
		$default*) default_value=50;;
		*)
			[[ $brightness =~ $up ]] && direction=+ || direction=-
			[[ $brightness =~ [0-9]+ ]] && mulitplier=${brightness: -1}
			[[ $mulitplier ]] && value=$((mulitplier * 10))
	esac

	~/Desktop/set_brightness.sh $direction ${default_value:-10}
done
