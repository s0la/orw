#!/bin/bash

if [[ -z $@ ]]; then
	echo -e 'stop\nstart'
else
	[[ $(pidof rofi) ]] && killall rofi

	case ${@%% *} in
		run) simplescreenrecorder --start-hidden;;
		start)
			[[ $@ =~ " " ]] && filename="${@##* }" || filename="$(date +"%Y-%m-%d-%H:%M")"
			~/.orw/scripts/record_screen.sh $filename;;
		stop)
			pid=$(ps -ef | awk '/ffmpeg.*(mp4|mkv)/ && !/awk/ { print $2 }')
			kill $pid;;
	esac
fi
