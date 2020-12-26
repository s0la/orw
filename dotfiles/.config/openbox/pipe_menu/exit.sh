#!/bin/bash

#~/.config/openbox/pipe_menu/generate_menu.sh -c systemctl \
#	-i 'lock ~/.orw/scripts/lock_screen.sh' \
#	-i 'logout openbox --exit' \
#	reboot suspend poweroff

echo "<openbox_pipe_menu>"

for action in lock logout reboot suspend poweroff; do
	case $action in
		lock) command=~/.orw/scripts/lock_screen.sh;;
		logout) command='openbox --exit';;
		*) command="systemctl $action"
	esac

	cat <<- EOF
		<item label="$action">
		<action name="Execute">
		<execute>$command</execute>
		</action>
		</item>
	EOF
done

echo "</openbox_pipe_menu>"
