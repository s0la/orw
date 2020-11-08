#!/bin/bash

count=$3
length=${4:-55}

while read -r mail_info; do
	all_mail_info+="$mail_info\n\n"
done <<< $(curl -u "$1":"$2" --silent "https://mail.google.com/mail/feed/atom" |
	xmllint --format - 2> /dev/null | awk -F '[<>]' '
		/^ *<(name|title)/ && ! /Inbox/ {
			if('$count' && c && c > '$count') exit
			else if($2 == "title" && $3) {
				c++
				l = '$length'
				e = (length($3) > l) ? ".." : ""
				t = sprintf("\\n%.*s%s", l, $3, e)
			} else print "<b>" $3 "</b>" t }' )

~/.orw/scripts/notify.sh -f 8 -t 10 -p "\n$all_mail_info"
