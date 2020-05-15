#!/bin/bash

config=~/.config/orw/config
theme=$(awk -F '"' 'END { print $(NF - 1) }' ~/.config/rofi/main.rasi)

get_directory() {
	read depth directory <<< $(awk '\
		/^directory|depth/ { sub("[^ ]* ", ""); print }' $config | xargs -d '\n')
	root="${directory%/\{*}"
}

#[[ $theme == icons ]] && next= prev= rand= restore= view= auto= ||
[[ $theme == icons ]] && next= prev= rand= restore= view= auto= ||
	next=next prev=prev rand=rand index=index restore=restore view=view_all interval=interval auto=autochange nl=\n

if [[ -z $@ ]]; then
	#echo -e 'next\nprev\nrand\nindex\nselect\nrestore\nview_all\ninterval\nautochange'

	#cat <<- EOF
	#	$next
	#	$prev
	#	$rand
	#	$view
	#	$index
	#	$restore
	#	$interval
	#	$auto
	#EOF

	echo -e "$next\n$prev\n$rand\n$view\n$index$nl$restore\n$interval$nl$auto"
else
	wallctl=~/.orw/scripts/wallctl.sh

	if [[ $@ =~ select ]]; then
		indicator='●'
		indicator=''

		get_directory

		current_desktop=$(xdotool get_desktop)
		current_wallpaper=$(grep "^desktop_$current_desktop" $config | cut -d '"' -f 2)

		((depth)) && maxdepth="-maxdepth $depth"

		eval find $directory/ "$maxdepth" -type f -iregex "'.*\(jpe?g\|png\)'" | sort -t '/' -k 1 |\
			awk '{ i = (/'"${current_wallpaper##*/}"'$/) ? "'$indicator'" : " "
				sub("'"${root//\'}"'/?", ""); print i, $0 }'
	else
		killall rofi

		case "$@" in
			$next*) $wallctl -o next ${@#*$next };;
			$prev*) $wallctl -o prev ${@#*$prev };;
			$rand*) $wallctl -o rand ${@#*$rand };;
			$restore*) $wallctl -r;;
			$auto*) $wallctl -A;;
			$view*) $wallctl -v;;
			$interval*) $wallctl -I ${@#* };;
			$index*) $wallctl -i ${@##* };;
			*.*)
				wall="$@"
				get_directory
				eval $wallctl -s "$root/${wall:2}";;
			*) $wallctl -o $@;;
		esac
	fi
fi
