#!/bin/bash

mode=$(awk '/^mode/ { print $NF }' ~/.config/orw/config)

if [[ $mode != tiling ]]; then
	part_up='part up' part_down='part down' ratio_up='ratio up' ratio_down='ratio down' sep=' '
fi

if [[ -z $@ ]]; then
	cat <<- EOF
		$sep$part_down
		$sep$part_up
		$sep$ratio_up
		$sep$ratio_down
	EOF
else
	[[ $@ =~ [0-9]+ ]] && value=${@: -1}

	[[ $@ =~ ^(|) ]] && direction=+ || direction=-
	[[ $@ =~ ^(|) ]] && property=part || property=ratio

	~/.orw/scripts/borderctl.sh w${property:0:1} $direction${value-1}

	#read part ratio <<< $(awk '/^(part|ratio)/ { print $NF }' ~/.config/orw/config | xargs)
	#((part $direction${value-1} < ratio)) && ~/.orw/scripts/borderctl.sh w${property:0:1} $direction${value-1}

	#~/.orw/scripts/notify.sh "${property^} is changed to ${!property}\n<b>($part/$ratio)</b>"
fi

