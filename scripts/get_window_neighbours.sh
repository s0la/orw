#!/bin/bash

id=$(printf "0x%.8x" $(xdotool getactivewindow))
properties=( $(wmctrl -lG | awk '$1 == "'$id'" { print $NF, $3, $4, $5, $6 }') )

mode=$(awk '/class.*\*/ { print "tiling" }' ~/.config/openbox/rc.xml)

if [[ $mode == tiling ]]; then
	get_ids() {
		[[ $1 == h ]] && index=3 start_index=2 || index=4 start_index=1
		desktop=$(xdotool get_desktop)
		start=${properties[start_index]}
		end=$((start + ${properties[start_index + 2]}))

		read $1_size $1_ids <<< $(wmctrl -lG | sort -nk $index,$index | awk '\
				function set_current_window() {
					cp = p
					cd = d
					cid = $1
				}

				$2 == '$desktop' && $1 != "'$id'" {
					p = $'$index'
					s = $('$start_index' + 2)
					d = $('$start_index' + 4)
						e = s + d

					if(s >= '$start' && e <= '$end') {
						if(cp) {
							if(cp == p) {
								cd += d
								cid = cid " " $1
							} else {
								if(cd > max) {
									max = cd
									id = cid
									set_current_window()
								}
							}
						} else {
							set_current_window()
						}
					}
				} END { print (cd > max) ? cd " " cid : max " " id }')
	}

	get_ids h
	get_ids v

	((h_size > v_size)) && orientation=h || orientation=v
	ids=${orientation}_ids
fi

#~/.orw/scripts/notify.sh "id: ${!ids}"
#~/.orw/scripts/notify.sh "id: ${ids[*]}"

#{ [[ $ids ]] && sleep 0.5 && for id in ${!ids}; do
#	~/.orw/scripts/windowctl.sh -i $id tile $orientation
#	~/.orw/scripts/notify.sh "id: $id"
#  done
#} &

[[ $ids ]] && nohup ~/.orw/scripts/close_window.sh $id "${!ids}" &
wmctrl -ic $id

name=${properties[0]}
tmux_command='tmux -S /tmp/tmux_hidden'
tmux_session=$($tmux_command ls | awk -F ':' '$1 == "'$name'" { print $1 }')

[[ $tmux_session ]] && $tmux_command kill-session -t $tmux_session
