colors=~/.config/orw/colorschemes/colors
termite_conf=~/.orw/dotfiles/.config/termite/config

sed -i '/color0/,/^$/d' $termite_conf
awk -i inplace 'NR == FNR { a[ci++] = "color" FNR  - 1 " = " $NF } \
	 { if(/palette/) { print "#palette"; for(rci = 0; rci < ci; rci++) print a[rci]; print "" } else print }' $colors $termite_conf

killall -USR1 termite
