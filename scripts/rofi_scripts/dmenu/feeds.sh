#!/bin/bash

titles=$(awk '/^\s+feed/ { t = t gensub(/[^"]*"([^"]*).*/, "|\\1", 1) } END { print substr(t, 2) }' ~/.sfeed/sfeedrc)

~/.orw/scripts/notify.sh -r 501 -s osd -i   'scanning..' &
sfeed_update &> /dev/null

eval articles=( $(sfeed_plain ~/Documents/feeds/* | \
	awk '$1 == "N" { print gensub("[^0-9]*[0-9]{4}-([0-9:\\- ]*).*('"$titles"')\\s*(.*)", "\"\\1 \\3\"", 1) }' | \
	sort -nrk 1,2 ) )

killall dunst

list_articles() {
	echo newsboat
	echo ━━━━━━━━

	for article in "${articles[@]}"; do
		echo "$article"
	done | awk '{
			sub("(- ?(\\w*…|Upwork)|http).*", "")
			print gensub(" ", "  ", 2)
		}'
	#| rofi -dmenu -format 'i' -theme large_list
}

article_index=$(list_articles | rofi -dmenu -format 'i' -theme large_list)

#article_index=$(for article in "${articles[@]}"; do
#	echo "$article"
#done | awk '{
#		sub("(- ?(\\w*…|Upwork)|http).*", "")
#		print gensub(" ", "  ", 2)
#	}' | rofi -dmenu -format 'i' -theme large_list)

if [[ $article_index ]]; then
	if ((article_index)); then
		article_url=${articles[article_index - 2]##* }
		pids=( $(pidof firefox) )
		firefox $article_url &
		((${#pids[*]})) && wmctrl -a firefox
		exit

		output=$(qutebrowser $article_url 2>&1)

		if [[ $output =~ existing ]]; then
			~/.orw/scripts/notify.sh -p "${output#* * }"
			sleep 0.5
			wmctrl -a qutebrowser
		fi
	else
		alacritty -t newsboat -e newsboat
	fi
fi

#sfeed_plain ~/Documents/feeds/* | awk '{ print gensub("(^[N :0-9\-]*).*", "\\1", 1) }'
#sfeed_plain ~/Documents/feeds/* | awk '{ print gensub("[^0-9]*[0-9]{4}-([0-9:\\- ]*).*('"$titles"')\\s*(.*)\\s*http.*", "\\1 \\3", 1) }'
#sfeed_plain ~/Documents/feeds/* | awk '{ print gensub("[^0-9]*[0-9]{4}-([0-9:\\- ]*).*(\\s{3,})(.*)\\s*http.*", "\\1 \\3", 1) }'
