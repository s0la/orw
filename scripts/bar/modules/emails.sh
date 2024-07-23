#!/bin/bash

get_emails() {
	label='MAIL'
	icon="$(get_icon "emails")"

	((emails)) && old_emails=$emails
	read emails notification <<< $(\
		curl -su $username:$app_password "https://mail.google.com/mail/feed/atom" |
		xmllint --format - 2> /dev/null | awk -F '[><]' '
			/<(fullcount|title|name)/ && ! /Inbox/ {
				if($2 ~ /count/) c = $3
				else if($2 == "title" && $3) t = $3
				else {
					print c, "<b>" $3 "</b>\\\\n" t
					exit
				}
		}')
}

set_emails_actions() {
	[[ $(which mutt 2> /dev/null) ]] &&
		local action1='alacritty -e mutt' ||
		local action1="~/.orw/scripts/notify.sh -p 'Mutt is not found..'"
	local action3="~/.orw/scripts/show_mail_info.sh $username $app_password 5"
	actions_start="%{A:$action1:}%{A3:$action3:}"
	actions_end="%{A}%{A}"
}

check_emails() {
	local actions_{start,end} label icon
	set_emails_actions

	while true; do
		get_emails
		print_module emails

		((old_emails && old_emails < emails)) &&
			~/.orw/scripts/notify.sh -t 10 -p "new mail:\n\n$notification"

		sleep 60
	done
}

make_emails_content() {
	email_auth=~/.orw/scripts/auth/email

	if [[ ! -f $email_auth ]]; then
		~/.orw/scripts/set_geometry.sh -t input -w 300 -h 150
		alacritty -t email_input -e ~/.orw/scripts/email_auth.sh &> /dev/null &&
			~/.orw/scripts/barctl.sh &> /dev/null
	fi

	local email_auth=~/.orw/scripts/auth/email
	read username {,app_}password <<< $(awk '{ print $NF }' $email_auth | xargs)
}
