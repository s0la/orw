pid='$(ps -C lemonbar -o pid= --sort=-start_time | head -1)'

separator='24'
actions+="%{O15}%{A:kill $pid && ~/.orw/scripts/lock_screen.sh:}%{I+20}%{I-}%{A}%{O15}"
actions+="%{O15}%{A:kill $pid && sudo systemctl reboot:}%{I+20}%{I-}%{A}%{O15}"
actions+="%{O15}%{A:kill $pid && openbox --exit:}%{I+20}%{I-}%{A}%{O15}"
actions+="%{O15}%{A:kill $pid && sudo systemctl poweroff:}%{I+20}%{I-}%{A}%{O15}"
actions+="%{O15}%{A:kill $pid :}%{I+20}%{I-}%{A}%{O15}"

bg='#bb1a1f20'
fg='#313839'
fc='#252b2c'
font='material:size=17'
geometry='240x162+360+459'

echo -e "%{c}$actions" | lemonbar \
-p -d -B$bg -F$fg -R$fc -r 3 \
-f "$font" -g $geometry -n power_bar | bash
