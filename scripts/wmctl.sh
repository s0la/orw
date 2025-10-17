#!/bin/bash

set_value() {
	local property="$1" value="$2" index="$3" active="$4" option="$5" state
	read state active <<< $(awk -i inplace '
			/^'$property'/ {
				v = "'"$value"'"
				i = "'"$index"'"
				a = "'"${active#* }"'"

				$NF = (v) ? (v ~ "[-+][0-9]*") ? $NF + v : v \
					: ($NF == "true") ? "false" : "true"

				if ($NF == "false") gsub(",?" i "|" i ",?", "", a)
				else if ($NF == "true") a = (a) ? a "," i : i

				s = (v) ? v : ($NF == "true") ? "enabled" : "disabled"
			} { print }

			END { print s, (a) ? "-a " a : "" }
		' ~/.config/orw/config)

	if [[ ! $option ]]; then
		case $property in
			direction) option="${value}.*_${property}";;
			full|reverse)
				option=$(awk '
					$1 == "reverse" { r = ($NF == "true") }
					$1 == "direction" {
						if ($NF == "h") f = (r) ? "left" : "right"
						else f = (r) ? "top" : "bottom"
						print f "_side"
					}' ~/.config/orw/config)
				;;
			*) option="$property"
		esac

		option=$(sed -n "/^[^#]/ s/$option.*=//p" ~/.orw/scripts/icons)
	fi

	~/.orw/scripts/notify.sh -r 22 -t 1200m -s osd -i $option "$property: ${state^^}" &> /dev/null
	~/.orw/scripts/signal_windows_event.sh update

	echo $state $active
}

for a in "${@:2}"; do
	args+="'$a' "
done

eval $1 $args
