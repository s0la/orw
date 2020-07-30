#!/bin/bash

if [[ -z $@ ]]; then
	echo -e 'stop\nstart'
else
	[[ $(pidof rofi) ]] && killall rofi

	case ${@%% *} in
		run) simplescreenrecorder --start-hidden;;
		start) ~/.orw/scripts/record_screen.sh ${@#start};;
			#icon=  message='recording started'
		stop)
			#icon=  message='recording stoped'
			pid=$(ps -ef | awk '/ffmpeg.*(mp4|mkv)/ && !/awk/ { print $2 }')
			~/.orw/scripts/notify.sh osd   'recording stoped'
			kill $pid;;
	esac

	#~/.orw/scripts/notify.sh osd $icon "$message"
fi
