#!/bin/bash

si_dark_bg="%{B#363636}"

si_fg="%{F#abaeb2}"
si_dark_fg="%{F#7b7e82}"

resolution=$1
screen_width=${resolution%x*}
screen_height=${resolution#*x}

#font1="Roboto Mono:size=8"
font1="Iosevka Orw:size=8"
font2="icomoon_fa:size=8"
font3="icomoon_fa:size=16"

bar_width=500
bar_height=150

pid='$(ps -C lemonbar -o pid= --sort=-start_time | head -1)'

close="%{A:kill "$pid":} %{A}"
logout="%{A:kill "$pid" && openbox --exit:}logout%{A}"
reboot="%{A:kill "$pid" && systemctl reboot:}reboot%{A}"
suspend="%{A:kill "$pid" && systemctl suspend:}suspend%{A}"
power_off="%{A:kill "$pid" && systemctl poweroff:}power off%{A}"
lock="%{A:kill "$pid" && ~/.orw/scripts/lock_screen.sh:}lock%{A}"

#logout="%{A:openbox --exit:} %{A}"
#reboot="%{A:systemctl reboot:} %{A}"
#suspend="%{A:systemctl suspend:} %{A}"
#power_off="%{A:systemctl poweroff:} %{A}"
#lock="%{A:~/.orw/scripts/lock_screen.sh:} %{A}"

#pid="$(ps aux | awk '$NF == \"shut_down_bar\" { print $2 }')"
#close="%{A:kill $(ps aux | awk '$NF == \"shut_down_bar\" { print $2 }'):} %{A}"
#pid='$(ps -C lemonbar -o pid= --sort=-start_time | head -1)'
#close="%{A:kill \$(ps -C lemonbar -o pid= --sort=-start_time | head -1):} %{A}"

all="$si_fg%{c}$lock%{O45}$reboot%{O45}$logout%{O45}$power_off%{r}$si_dark_fg%{T2}$close%{O15}"
#all="$reboot%{O50}$logout%{O50}$suspend%{O50}$shut_down"

#pid='$(for pid in $(pidof lemonbar); do echo $pid $(ps -p $pid -o etimes=); done | sort -n -k2 | head -n 1 | cut -d " " -f 1)'
#close="%{A:kill "$pid":} %{A}"

#echo -e "$si_fg%{c}$reboot%{O50}$suspend%{O50}$shut_down%{r}$si_dark_fg%{T2}$close%{O10}" | lemonbar -p -B${si_dark_bg//[%\{B\}]} \
#echo -e "$si_fg%{c}$all%{r}$si_dark_fg%{T2}$close%{O10}" | lemonbar -p -B${si_dark_bg//[%\{B\}]} \
echo -e "$all" | lemonbar -p -B${si_dark_bg//[%\{B\}]} \
				-f "$font1" -o 5 \
				-f "$font2" -o -55 \
				-g ${bar_width}x${bar_height}+$((x + screen_width / 2 - bar_width / 2))+$((y + screen_height / 2 - bar_height / 2)) \
				-n shut_down_bar | bash
