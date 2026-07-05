pid='$(ps -C lemonbar -o pid= --sort=-start_time | head -1)'

separator='38'
actions+="%{O12}%{A:kill $pid && ~/.orw/scripts/lock_screen.sh:}$fg%{T3}%{T-}%{A}%{O12}"
actions+="%{O12}%{A:kill $pid && sudo systemctl reboot:}$fg%{T3}%{T-}%{A}%{O12}"
actions+="%{O12}%{A:kill $pid && openbox --exit:}$fg%{T3}%{T-}%{A}%{O12}"
actions+="%{O12}%{A:kill $pid && sudo systemctl poweroff:}$fg%{T3}%{T-}%{A}%{O12}"
actions+="%{O12}%{A:kill $pid && sudo systemctl close:}%{F#b78b8b}%{T3}%{T-}%{A}%{O12}"

bg='#ff232323'
fg='#4d4d4d'
fc='#ff232323'
font='material:size=13'
geometry='384x162+768+459'

echo -e "%{c}$actions" | lemonbar \
-p -d -B$bg -F$fg -R$fc -r 2 \
-f "$font" -g $geometry -n power_bar | bash &> /dev/null
