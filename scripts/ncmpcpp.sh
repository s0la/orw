#!/bin/bash

[[ ! -f ~/.config/orw/config ]] && ~/.orw/scripts/generate_orw_config.sh
font_width=$(sed -n 's/font_width //p' ~/.config/orw/config)
font_height=$(sed -n 's/font_height //p' ~/.config/orw/config)

function show_progessbar() {
	if [[ $1 =~ (true|yes) ]]; then
		vis_bar='   '
		vis_status="no"
		list_bar='━━━'
		list_status="yes"
	else
		vis_bar='━━━'
		vis_status="yes"
		list_bar='   '
		list_status="no"
	fi

	sed -i "/^progressbar_look/ s/\".*/\"$list_bar\"/" ~/.ncmpcpp/config
	sed -i "/^statusbar_visibility/ s/\".*/\"$list_status\"/" ~/.ncmpcpp/config
	sed -i "/^progressbar_look/ s/\".*/\"$list_bar\"/" ~/.ncmpcpp/config_cover_art
	sed -i "/^statusbar_visibility/ s/\".*/\"$list_status\"/" ~/.ncmpcpp/config_cover_art
	sed -i "/^progressbar_look/ s/\".*/\"$vis_bar\"/" ~/.ncmpcpp/config_visualizer
	sed -i "/^statusbar_visibility/ s/\".*/\"$vis_status\"/" ~/.ncmpcpp/config_visualizer
}

function get_cover_properties() {
	ratio=${ratio-90}
	padding=$(sed -n 's/[^0-9]*\([0-9]\+\).*/\1/p' ~/.config/gtk-3.0/gtk.css 2> /dev/null)

	if [[ ! $width && ! $height ]]; then
		read width height <<< $(wmctrl -lG | \
		awk '$NF == "ncmpcpp_with_cover_art" { print $5 - ('$padding' * 2), $6 - ('$padding' * 2) }')
	fi

	sed -i "/^execute/ s/[0-9]\+/$ratio/" ~/.ncmpcpp/config_cover_art

	read s x y r <<< $(awk 'BEGIN { \
		r = 0.'$ratio'; w = '$width'; h = '$height'; \
		if (h < 300 && r >= 0.8) { x = int('$padding' + (h * (1 - r)) / 2); div = h; a = 1 } \
		else { x = ('$padding' + 2); div = int(h * r); a = 1 }; \
		s = int(h * r); y = int((h - s + ('$padding' / 2)) / 2); w = int(100 - (100 / (w / div)) - a); print s, x, y, w}')
}

function draw_cover_art() {
	cover=$(~/.orw/scripts/get_cover_art.sh)

	[[ -f "$cover" ]] && echo -e "0;1;$x;$y;$s;$s;;;;;$cover\n3;" | /usr/lib/w3m/w3mimgdisplay || 
		$base_command send -t ncmpcpp_with_cover_art:0.0 'clear' Enter
	exit
}

base_command='TERM=xterm-256color tmux -S /tmp/ncmpcpp -f ~/.tmux_ncmpcpp.conf'

while getopts :pvscdaRVCP:S:L:D:r:w:h:i flag; do
	case $flag in
		p)
			width=70
			height=70
			title=ncmpcpp_playlist

			[[ ! $pre ]] && pre="~/.orw/scripts/windowctl.sh "

			[[ $V ]] && layout="move -h 2/3 -v 2/4 resize -h 1/3 -v 1/4" ||
				layout="move -v 3/7 -h 8/12 resize -v 3/7 -e r -h 3/4 -l +21 -r +21"

			pre+="$layout && sleep 0.1 > /dev/null"

			command='new -s playlist ncmpcpp';;
		v)
			width=70
			height=70
			title=visualizer

			[[ ! $pre ]] && pre="~/.orw/scripts/windowctl.sh "

			[[ $V ]] && layout="move -h 2/3 -v 3/4 resize -h 1/3 -v 1/4" progressbar=yes ||
				layout="move -v 3/7 -h 2/4 resize -v 3/7 -h 1/3"

			pre+="$layout && sleep 0.1 > /dev/null"

			command='new -s visualizer cava'
			show_progessbar ${progressbar-no};;
		s)
			width=${width-55}
			height=${height-40}
			title=ncmpcpp_split

			progressbar=no

			command='new -s split ncmpcpp \; splitw -p 25 cava \; selectp -U';;
		c)
			[[ $@ =~ -i ]] && width=${width-550} height=${height-200}
			title=ncmpcpp_with_cover_art

			get_cover_properties
			show_progessbar yes

			command="new -s ncmpcpp_with_cover_art \; splitw -h -p $r ncmpcpp -c ~/.ncmpcpp/config_cover_art";;
		d)
			~/.orw/scripts/ncmpcpp.sh $display $V -v -i
			until [[ $(wmctrl -l | awk '$NF ~ "visualizer"') ]]; do continue; done
			~/.orw/scripts/ncmpcpp.sh $display $V -p -i
			exit;;
		C) get_cover_properties && draw_cover_art;;
		P) show_progessbar $OPTARG && exit;;
		L) pre="~/.orw/scripts/windowctl.sh $OPTARG";;
		D)
			display="-D $OPTARG"
			pre="~/.orw/scripts/windowctl.sh -d $OPTARG move";;
		V) V=-V;;
		R)
			ratio=$(sed -n 's/^execute.*[^0-9]\([0-9]\+\).*/\1/p' ~/.ncmpcpp/config_cover_art)
			command="send -t ncmpcpp_with_cover_art:0.0 'clear && sleep 0.1 && $0 -r $ratio -C' Enter";;
		r) ratio=$OPTARG;;
		a)
			for session in $(tmux -S /tmp/ncmpcpp ls 2> /dev/null |awk -F ':' '{print $1}'); do
				case $session in
					*play*) pane=0;;
					*cover*) pane=1;;
					*split*) pane=1;;
					visualizer) pane=0;;
				esac

				tmux -S /tmp/ncmpcpp respawn-pane -k -t ${session}:0.$pane
			done && exit;;
		w) width=$OPTARG;;
		h) height=$OPTARG;;
		i)
			if ! wmctrl -a ${title-ncmpcpp}; then
				width=${width:-900}
				height=${height:-500}

				~/.orw/scripts/set_class_geometry.sh -c size -w $width -h $height

				termite -t ${title-ncmpcpp} --class=custom_size \
					-e "bash -c '~/.orw/scripts/execute_on_terminal_startup.sh ${title-ncmpcpp} \
					\"${pre:-$0 -P ${progressbar-yes}} && $base_command ${command-new -s ncmpcpp ncmpcpp}\"'" &> /dev/null &
				exit
			fi
		esac
done

show_progessbar ${progressbar-yes}
eval "$base_command ${command-new -s ncmpcpp ncmpcpp}"
