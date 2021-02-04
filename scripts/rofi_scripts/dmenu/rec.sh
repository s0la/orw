#!/bin/bash

theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)
#       
[[ $theme =~ dmenu|icons ]] && ~/.orw/scripts/set_rofi_geometry.sh rec
[[ $theme == icons ]] && start= stop=  || start=start stop=stop
[[ $theme == icons ]] && start= stop=  || start=start stop=stop
[[ $theme == icons ]] && start= stop=  || start=start stop=stop
[[ $theme == icons ]] && start= stop=  || start=start stop=stop
#action=$(echo -e 'stop\nstart' | rofi -dmenu $active)

pid=$(pidof ffmpeg)
((pid)) && active='-a 0'

action=$(cat <<- EOF |  rofi -dmenu $active -theme main
	$start
	$stop
EOF
)

if [[ $action ]]; then
	case ${action%% *} in
		$start)
			if [[ $theme == icons ]]; then
				fifo=/tmp/rec_file_name.fifo
				[[ -p $fifo ]] && rm $fifo
				mkfifo $fifo

				command="read -p 'Enter file name: ' filename && echo \"\$filename\" > $fifo"

				width=300
				height=100
				read window_x window_y <<< $(~/.orw/scripts/windowctl.sh -p | cut -d " " -f 3,4)
				read x y <<< $(~/.orw/scripts/get_display.sh $window_x $window_y | \
					awk '{ print int(($4 - '$width') / 2), int(($5 - '$height') / 2) }')

				~/.orw/scripts/set_geometry.sh -c input -x $x -y $y -w 300 -h 100
				termite -t rec_file_name_input --class=input -e "bash -c \"$command\"" &> /dev/null &

				read filename < $fifo

				rm $fifo
			else
				filename=${action#$start}
			fi

			~/.orw/scripts/set_geometry.sh -c input -w 120 -h 120

			~/.orw/scripts/record_screen.sh "$filename";;
			#~/.orw/scripts/notify.sh "filename: $filename";;
				#"bash -c \"~/.orw/scripts/network_auth.sh ${network_name//\'/\\\'}\"" $> /dev/null
			#~/.orw/scripts/record_screen.sh ${action#start};;
		$stop)
			pid=$(ps -ef | awk '/ffmpeg.*(mp4|mkv)/ && !/awk/ { print $2 }')
			#~/.orw/scripts/notify.sh -s osd -i   'recording stoped'
			~/.orw/scripts/notify.sh -s osd -i   'recording stoped'
			kill $pid;;
	esac
fi
