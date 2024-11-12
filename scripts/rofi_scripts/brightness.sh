#!/bin/bash

if [[ $style =~ icons|dmenu ]]; then
	read up down default <<< \
		$(sed -n 's/^\(arrow_\(up\|down\).*empty\|brightness_mid\).*=//p' ~/.orw/scripts/icons | xargs)
else
	default='default' up='brightness up' down='brightness down' sep=' '
fi

toggle
trap toggle EXIT

while
	read row brightness <<< $(cat <<- EOF | rofi -dmenu -i -format 'i s' -selected-row ${row:-1} $active -theme main
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

	~/.orw/scripts/brightnessctl.sh ${default_value:-${direction}${value:-10}}
	unset default_{,value}
done
