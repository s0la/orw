pid='$(ps -C lemonbar -o pid= --sort=-start_time | head -1)'

separator='48'
actions+="%{O15}%{A:kill $pid && ~/.orw/scripts/lock_screen.sh:}%{I+20}%{I-}%{A}%{O15}"
actions+="%{O15}%{A:kill $pid && sudo systemctl reboot:}%{I+20}%{I-}%{A}%{O15}"
actions+="%{O15}%{A:kill $pid && openbox --exit:}%{I+20}%{I-}%{A}%{O15}"
actions+="%{O15}%{A:kill $pid && sudo systemctl poweroff:}%{I+20}%{I-}%{A}%{O15}"
actions+="%{O15}%{A:kill $pid :}%{I+20}%{I-}%{A}%{O15}"

bg='#1c1920'
fg='#332f39'
fc='#27232c'
font='material:size=17'
geometry='480x162+720+459'

echo -e "%{c}$actions" | lemonbar \
-p -d -B$bg -F$fg -R$fc -r 3 \
-f "$font" -g $geometry -n power_bar | bash
