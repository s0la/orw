#!/bin/bash

id=$1
[[ $2 ]] && restore=1
minimized=$(xwininfo -id $id | awk '/Map/ { print $NF != "IsViewable" }')
#mode=$(awk '/^mode/ { print $NF == "floating" ? $NF : "tiling" }' ~/.config/orw/config)
orw=~/.config/orw
mode=$(awk '/^mode/ { print $NF }' $orw/config)

if ((minimized || restore)); then
	if [[ $mode != floating ]]; then
		#desktop=$(xdotool get_desktop)

		#read maxed original_properties <<< $(awk '$1 == "'$id'" {
		#	if($NF == "maxed") { print 1, $2, $3, $4, $5; exit } }' $orw/windows_properties)

		read maxed original_properties <<< $(awk '$1 == "'$id'" {
			m = ($NF == "maxed"); op = $2 " " $3 " " $4 " " $5
		} END { if(m) print m, op }' $orw/windows_properties)

		if ((!maxed || restore)); then
			if ((restore)); then
				properties=( ${original_properties[*]} )

				read {x,y}_border <<< $(awk '/_border/ { if(/^x/) x = $NF
											else print x, ($NF - (x / 2)) * 2 }' $orw/config)

				(( properties[0] += x_border ))
				(( properties[1] += y_border ))
			else
				properties=( $(wmctrl -lG | awk '$1 == "'$id'" { print $3, $4, $5, $6 }') )
			fi

			#if ((restore)); then
			#	read {x,y}_border <<< $(awk '/_border/ {
			#								if(/^x/) x = $NF
			#								else print x, ($NF - (x / 2)) * 2 }' $orw/config)
			#	properties=( $(awk '$1 == "'$id'" {
			#		print $2 + '$x_border', $3 + '$y_border', $4, $5; exit }' $orw/windows_properties) )
			#else
			#	properties=( $(wmctrl -lG | awk '$1 == "'$id'" { print $3, $4, $5, $6 }') )
			#fi

			#properties=( $(wmctrl -lG | awk '$1 == "'$id'" { print $3, $4, $5, $6 }') )

			#read {x,y}_offset <<< $(awk '/^.*offset/ {
			#			if($NF == "true") print o
			#			else o = o " " $NF }' .config/orw/confi)

			desktop=$(wmctrl -l | awk '$1 == "'$id'" { print $2 }')

			read index opposite_index <<< $(awk '$1 == "'$id':" {
					print ($NF == "h") ? 1 " " 0 : 0 " " 1
				}' $orw/windows_alignment)

			read border separator offset <<< $(awk '
						BEGIN { p = ('$index') ? "x" : "y" }
						$1 ~ "^" p { o = o " " $NF }
						$1 == "offset" { print o, $NF }' $orw/config | xargs)
							#if($NF == "true") print o
							#else if($1 ~ op) o = $NF

			original_dimension=$(awk '$1 == "'$id'" {
				print $('$opposite_index' + 4) }' $orw/windows_properties)

			#[[ $offset == true ]] && separator=$(awk -F '=' '/margin/ { print $NF }' ~/.config/orw/offsets)
			[[ $offset == true ]] && separator=$(sed -n 's/margin=//p' $orw/offsets)

			read closest_window_id ratio <<< $(wmctrl -lG | awk '
				function get_max(n1, n2) {
					return (n1 > n2) ? n1 - n2 : n2 - n1
				}

				BEGIN {
					b = '$border'
					s = '$separator'
					i = '$index' + 3
					oi = '$opposite_index' + 3
					wp = '${properties[index]}'
					wd = '${properties[index + 2]}'
					wod = '${properties[opposite_index + 2]}'
					orgd = '$original_dimension'

					if(!'${restore:-0}') m = "'$maxed'"
				}

				$2 == '$desktop' && $1 != "'$id'" {
					cwd = $(i + 2)
					cwod = $(oi + 2)
					pd = get_max(wp, $i)

					if(!length(mpd) || pd < mpd) mpd = pd
					dop[pd] = dop[pd] " " cwd ":" cwod ":" $oi ":" $1
				}

				END {
					split(dop[mpd], dopa)

					for(dopi in dopa) {
						split(dopa[dopi], cdopa, ":")

						cwd = cdopa[1]
						cwod = cdopa[2]
						cwop = cdopa[3]
						cwid = cdopa[4]
						dd = get_max(wd, cwd)

						op[dd] = op[dd] " " cwod ":" cwop ":" cwid
						if(!length(mdd) || dd < mdd) {
							mdd = dd
							d = cwd
						}
						fod += cwod - (s + b)
					}

					split(op[mdd], opa)

					for(opi in opa) {
						split(opa[opi], copa, ":")

						cod = copa[1]
						cop = copa[2]
						cid = copa[3]

						if(!length(mop) || cop < mop) {
							cwid = cid
							od = cod
						}
					}

					#printf "%.2f %s", fod / wod, cwid
					#print fod / wod, cwid
					r = ("'$mode'" == "auto" && d > od || m) ? "" : fod / wod
					print cwid, r
				}')

			read x y w h d <<< $(~/.orw/scripts/windowctl.sh -i $closest_window_id -A $ratio)
			sed -i "/^$id:/ s/.$/$d/" $orw/windows_alignment
			wmctrl -ir $id -e 0,$x,$y,$w,$h
		fi
	fi

	wmctrl -ia $id
else
	current_window_id=$(printf '0x%.8x' $(xdotool getactivewindow))

	#~/.orw/scripts/notify.sh "$window_id $current_window_id"

	if [[ $current_window_id == $id ]]; then
		[[ $mode != floating ]] && ~/.orw/scripts/windowctl.sh -A m
		xdotool getactivewindow windowminimize
	else
		wmctrl -ia $id
	fi

	#xdotool getactivewindow windowminimize
fi

exit

current_window_id=$(printf '0x%.8x' $(xdotool getactivewindow))
read {x,y}_border <<< $(awk '/border/ { print $NF }' ~/.config/orw/config | xargs)
y_border=$(((y_border - x_border / 2) * 2))

if [[ $1 ]]; then
	id=${1:-0x02800003}
	desktop=$(xdotool get_desktop)
	properties=( $(wmctrl -lG | awk '$1 == "'$id'" { print $3, $4, $5, $6 }') )
	read index opposite_index <<< $(awk '$1 == "'$id':" {
			print ($NF == "h") ? 1 " " 0 : 0 " " 1
		}' ~/.config/orw/windows_alignment)

	closest_window_id=$(wmctrl -lG | awk '
		function get_max(n1, n2) {
			return (n1 > n2) ? n1 - n2 : n2 - n1
		}

		BEGIN {
			i = '$index' + 3
			oi = '$opposite_index' + 3
			wp = '${properties[index]}'
			wd = '${properties[index + 2]}'
		}

		$2 == '$desktop' && $1 != "'$id'" {
			cwd = $(i + 2)
			pd = get_max(wp, $i)

			if(!length(mpd) || pd < mpd) mpd = pd
			dop[pd] = dop[pd] " " cwd ":" $oi ":" $1
		}

		END {
			split(dop[mpd], dopa)

			for(dopi in dopa) {
				split(dopa[dopi], cdopa, ":")

				cwd = cdopa[1]
				cwop = cdopa[2]
				cwid = cdopa[3]
				dd = get_max(wd, cwd)

				if(!length(mdd) || dd < mdd) mdd = dd
				op[dd] = op[dd] " " cwop ":" cwid
			}

			split(op[mdd], opa)

			for(opi in opa) {
				split(opa[opi], copa, ":")

				cop = copa[1]
				cid = copa[2]

				if(!length(mop) || cop < mop) cwid = cid
			}

			print cwid
		}')

	read x y w h d <<< $(~/.orw/scripts/windowctl.sh -i $closest_window_id -A)
	wmctrl -ir $id -e 0,$x,$y,$w,$h
	wmctrl -ia $id
	exit

	echo $index $opposite_index
	echo ${properties[*]}
	echo $id $x_border $y_border
else
	~/.orw/scripts/windowctl.sh -A m
	xdotool getactivewindow windowminimize
fi
