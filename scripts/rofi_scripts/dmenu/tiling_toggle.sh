#!/bin/bash

theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)

[[ $theme != icons ]] &&
	wm_mode=wm_mode full=full use_ratio=use_ratio offset=offset reverse=reverse direction=direction sep=' '
[[ $theme =~ dmenu|icons ]] && ~/.orw/scripts/set_rofi_geometry.sh tiling_toggle

#read wm_icon offset_icon reverse_icon direction_icon active <<< \
#	$(awk '{
#		if(/^mode/) {
#			#wm = ($NF == "floating") ? "" : ""
#			#wm = ($NF == "floating") ? "" : ""
#			#wm = ($NF == "floating") ? "" : ""
#			#wm = ($NF == "floating") ? "" : ""
#			#wm = ($NF == "floating") ? "" : ""
#			if($NF == "floating") {
#				wm = ""
#			} else {
#				#a = a ",0"
#				wm = ""
#			}
#		} else if(/^offset/) {
#			#o = ($NF == "true") ? "" : ""
#			#o = ($NF == "true") ? "" : ""
#			if($NF == "true") {
#				a = a ",1"
#				o = ""
#			} else {
#				o = ""
#			}
#		} else if(/^reverse/) {
#			if($NF == "true") a = a ",2"
#			r = ""
#			r = ""
#			r = ""
#		} else if(/^direction/) {
#			#d = ($NF == "h") ? "" : " "
#			#d = ($NF == "h") ? "" : ""
#			d = ($NF == "h") ? "" : ""
#		}
#	} END {
#		print wm, o, r, d, a
#	}' ~/.config/orw/config)

#read wm_icon full_icon offset_icon reverse_icon direction_icon active <<< \
#	$(awk '{
#		if(/^mode/) wm = ($NF == "floating") ? "" : ""
#		else if(/^direction/) d = ($NF == "h") ? "" : ""
#		else if(/^full/) {
#			f = "  "
#			f = ""
#			if($NF == "true") a = a ",1"
#		else if(/^offset/) {
#			o = ""
#			if($NF == "true") a = a ",2"
#		} else if(/^reverse/) {
#			r = ""
#			r = ""
#			if($NF == "true") a = a ",3"
#		}
#	} END {
#		print wm, f, o, r, d, a
#	}' ~/.config/orw/config)
#
#[[ $active ]] && active="-a ${active#,}"

get_state() {
	read wm_icon wm_active full_icon use_ratio_icon offset_icon reverse_icon direction_icon active <<< \
		$(awk '{
			if(/^mode/) {
				#wm = ($NF == "floating") ? "" : ""
				m = $NF

				if(m == "tiling") { wm = ""; wma = 1 }
				else if(m == "auto") { wm = ("'$orientation'" == "h") ? "" : ""; wma = 2 }
				else if(m == "stack") { wm = ""; wma = 3 }
				else if(m == "floating") { wm = ""; wma = 0 }
				else if(m == "floating") { wm = ""; wma = 0 }
				else { wm = ""; wma = 4 }
			}
			else if(/^direction/) {
				dir = $NF
				d = (dir == "h") ? "" : ""
			} else if(/^full/) {
				f = "  "
				f = ""
				
				#        
				if(dir == "h") {
					f = (rev) ? "" : ""
					f = (rev) ? "" : ""
				} else {
					f = (rev) ? "" : ""
					f = (rev) ? "" : ""
				}

				if($NF == "true") a = a ",1"
			} else if(/^use_ratio/) {
				ur = ""
				ur = ""
				ur = "    "
				ur = ""
				ur = ""
				if($NF == "true") a = a ",2"
			} else if(/^offset/) {
				o = ""
				if($NF == "true") a = a ",3"
			} else if(/^reverse/) {
				r = ""
				r = ""
				rev = ($NF == "true")
				if(rev) a = a ",4"
			}
		} END {
			print wm, wma, f, ur, o, r, d, a
		}' ~/.config/orw/config)

	[[ $active ]] && active="-a ${active#,}"
}

id=$(printf '0x%.8x' $(xdotool getactivewindow))
orientation=$(wmctrl -lG | awk '$1 == "'$1'" { print ($5 > $6) ? "v" : "h" }')
#reverse=$(awk '/^reverse/ { print ($NF == "true") }' ~/.config/orw/config)
#read width height <<< $(wmctrl lG | awk '$1 == "'$1'" { print ($5 > $6) ? "h" : "v" }')

#while
get_state
action=$(cat <<- EOF | rofi -dmenu $active -theme main
	$wm_icon$sep$wm_mode
	$full_icon$sep$full
	$use_ratio_icon$sep$use_ratio
	$offset_icon$sep$offset
	$reverse_icon$sep$reverse
	$direction_icon$sep$direction
EOF
)

#	[[ $action ]]
#do
if [[ $action ]]; then
	#[[ $action =~ $full_icon ]] && option=full
	#[[ $action =~ $offset_icon ]] && option=offset
	#[[ $action =~ $reverse_icon ]] && option=reverse
	#[[ $action =~ $direction_icon ]] && option=direction
	#[[ $action =~ $use_ratio_icon ]] && option=use_ratio
	#[[ $action =~ $wm_icon ]] && mode="${@#*$wm_icon$sep$wm_mode}"

	case $action in
		*$full_icon*) option=full;;
		*$offset_icon*) option=offset;;
		*$reverse_icon*) option=reverse;;
		*$direction_icon*) option=direction;;
		*$use_ratio_icon*) option=use_ratio;;
		*$wm_icon*) #mode="${@#*$wm_icon$sep$wm_mode}"
			#[[ $theme == icons ]] &&
			#	~/.orw/scripts/set_rofi_geometry.sh tiling_toggle 5 &&
			#	floating=  tiling=  auto=  stack=  selection=  ||
			#	floating=floating tiling=tiling auto=auto stack=stack selection=selection

			[[ $theme == icons ]] &&
				wm_mode_icons=(           ) &&
				~/.orw/scripts/set_rofi_geometry.sh tiling_toggle 5

			wm_modes=( floating tiling auto stack selection )

			[[ $theme == icons ]] && rep=wm_mode_icons || rep=wm_modes
			eval modes=( \${$rep[*]} )

			mode_index=$(for mode in ${modes[*]}; do
				echo "$mode"
			done | rofi -dmenu -a $wm_active -format i -theme main)

			[[ $mode_index ]] && mode=${wm_modes[mode_index]}
	esac

	[[ $option || $mode ]] && ~/.orw/scripts/toggle.sh wm $option $mode
fi
