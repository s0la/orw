#!/bin/bash

while read -r mail_info; do
	all_mail_info+="$mail_info\n\n"
done <<< $(curl -u "$1":"$2" --silent "https://mail.google.com/mail/feed/atom" |
	xmllint --format - 2> /dev/null | awk -F '[<>]' '/name|title/ && ! /Inbox/ \
	{ if($2 == "title" && $3) t = " - " $3; else { print $3 t } }' )

~/.orw/scripts/notify.sh -f 9 -t 10 -p "$all_mail_info"
