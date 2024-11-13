pid='$(ps -C lemonbar -o pid= --sort=-start_time | head -1)'

separator='38'
actions+="%{O12}%{A:kill $pid && ~/.orw/scripts/lock_screen.sh:}$fg%{T3}%{T-}%{A}%{O12}"
actions+="%{O12}%{A:kill $pid && sudo systemctl reboot:}$fg%{T3}%{T-}%{A}%{O12}"
actions+="%{O12}%{A:kill $pid && openbox --exit:}$fg%{T3}%{T-}%{A}%{O12}"
actions+="%{O12}%{A:kill $pid && sudo systemctl poweroff:}$fg%{T3}%{T-}%{A}%{O12}"
actions+="%{O12}%{A:kill $pid && sudo systemctl close:}%{F#63a585}%{T3}%{T-}%{A}%{O12}"

bg='#dd151c20'
fg='#323e45'
fc='#2c383e'
font='material:size=13'
geometry='384x162+768+459'

echo -e "%{c}$actions" | lemonbar \
-p -d -B$bg -F$fg -R$fc -r 2 \
-f "$font" -g $geometry -n power_bar | bash
