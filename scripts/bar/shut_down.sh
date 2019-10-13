#!/bin/bash

si_dark_bg="%{B#363636}"

si_fg="%{F#abaeb2}"
si_dark_fg="%{F#7b7e82}"

resolution=$1
screen_width=${resolution%x*}
screen_height=${resolution#*x}

font1="Roboto Mono:size=8"
font2="icomoon_fa:size=8"

bar_width=400
bar_height=150

restart="%{A:systemctl reboot:}restart%{A}"
suspend="%{A:systemctl suspend:}suspend%{A}"
shut_down="%{A:systemctl poweroff:}shut down%{A}"

pid='$(for pid in $(pidof lemonbar); do echo $pid $(ps -p $pid -o etimes=); done | sort -n -k2 | head -n 1 | cut -d " " -f 1)'
close="%{A:kill "$pid":} %{A}"

echo -e "$si_fg%{c}$restart%{O50}$suspend%{O50}$shut_down%{r}$si_dark_fg%{T2}$close%{O10}" | lemonbar -p -B${si_dark_bg//[%\{B\}]} \
				-f "$font1" -o 5 \
				-f "$font2" -o -55 \
				-g ${bar_width}x${bar_height}+$((x + screen_width / 2 - bar_width / 2))+$((y + screen_height / 2 - bar_height / 2)) \
				-n shut_down_bar | bash
