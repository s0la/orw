pid='$(ps -C lemonbar -o pid= --sort=-start_time | head -1)'

separator='48'
actions+="%{O15}%{A:kill $pid && ~/.orw/scripts/lock_screen.sh:}%{I}%{I}%{A}%{O15}"
actions+="%{O15}%{A:kill $pid :}%{I}%{I}%{A}%{O15}"
actions+="%{O15}%{A:kill $pid && openbox --exit:}%{I}%{I}%{A}%{O15}"
actions+="%{O15}%{A:kill $pid :}%{I}%{I}%{A}%{O15}"
actions+="%{O15}%{A:kill $pid :}%{I}%{I}%{A}%{O15}"

bg='#161a1b'
fg='#80d4d9'
fc='#161a1b'
font='material:size=17'
geometry='480x162+720+459'

echo -e "%{c}$actions" | lemonbar \
-p -d -B$bg -F$fg -R$fc -r 3 \
-f "$font" -g $geometry -n power_bar | bash
