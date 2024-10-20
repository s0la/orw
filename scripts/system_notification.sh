#!/bin/bash

theme=default
replace_id=102
[[ $1 =~ mpd ]] && theme=${2:-vertical}

if [[ $1 == bluetooth ]]; then
	theme=osd
	[[ $2 ]] &&
		state=$2 || state="$(bluetoothctl show | sed -n 's/.*PowerState:\s*//p')"
	value="BLUETOOTH: $state"
	icon=$(sed -n 's/bluetooth=//p' ~/.orw/scripts/icons)
else
	case $1 in
		mpd*) command='mpc volume';;
		brightness)
			theme=osd
			command="echo ' $2%'";;
		*)
			theme=mini
			command='amixer -D pulse get Master'
			;;
	esac

	read value level_value empty_value icon <<< $(awk '
				BEGIN { s = "'$theme'" }

				("'$1'" ~ "system" && /^ *Front/) || "'$1'" !~ "system" {
					v = gensub(/.*[ \[]([0-9]+)%.*/, "\\1", 1)
					m = (!v || $NF ~ "off")

					#if(s == "vertical") st = 10
					#else st = ("'$theme'" == "default") ? 10 : 5

					switch ("'"$theme"'") {
						case "vertical": st = 10; break
						case "mini": st = 10; break
						case "osd": st = 5; break
						default: st = 6
					}

					t = int(100 / st)
					l = int(v / st)

					b = "'$1'" == "brightness"
					if(!v || $NF ~ "off") i = ""
					else if(v < 35) i = (b) ? "" : ""
					else if(v < 65) i = (b) ? "" : ""
					else i = (b) ? "" : ""

					printf "%d %.0f %.0f %s", v, l, t - l, i
					exit
				}' <<< $($command))

	[[ $1 =~ mpd ]] && icon= replace_id=103
	#[[ $theme == mini ]] && value="-v $value%" || bar="-b $level_value/$empty_value"
	[[ $theme == mini ]] && value="-v $value%"
	bar="-b $level_value/$empty_value"
fi

~/.orw/scripts/notify.sh -r $replace_id -s $theme -t 2200m -i $icon "$bar" "$value" &> /dev/null &
#echo ~/.orw/scripts/notify.sh -r $replace_id -s $theme -t 2200m -i $icon "${bar:-$value}" #&> /dev/null &
