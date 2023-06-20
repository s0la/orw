#!/bin/bash

function show_status() {
	[[ $1 =~ (true|yes) ]] && local status=yes
	sed -i "/^statusbar_visibility/ s/\".*/\"${status:-no}\"/" ~/.orw/dotfiles/.config/ncmpcpp/config{,_cover_art}
}

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

	sed -i "/^progressbar_look/ s/\".*/\"$vis_bar\"/" ~/.config/ncmpcpp/config_visualizer
	sed -i "/^progressbar_look/ s/\".*/\"$list_bar\"/" ~/.config/ncmpcpp/config{,_cover_art}
	#sed -i "/^statusbar_visibility/ s/\".*/\"$vis_status\"/" ~/.ncmpcpp/config_visualizer
	#sed -i "/^statusbar_visibility/ s/\".*/\"$list_status\"/" ~/.ncmpcpp/config{,_cover_art}
}

function get_cover_properties() {
	#ratio=${ratio-90}
	#padding=$(sed -n 's/[^0-9]*\([0-9]\+\).*/\1/p' ~/.config/gtk-3.0/gtk.css 2> /dev/null)

	#if [[ ! $width && ! $height ]]; then
	#	read width height <<< $(wmctrl -lG | \
	#	awk '$NF == "ncmpcpp_with_cover_art" { print $5 - ('$padding' * 2), $6 - ('$padding' * 2) }')
	#fi

	#sed -i "/^execute/ s/[0-9]\+/$ratio/" ~/.orw/dotfiles/.config/ncmpcpp/config_cover_art

	#read s x y r <<< $(awk 'BEGIN { \
	#	r = 0.'$ratio'; w = '$width'; h = '$height'; \
	#	if (h < 300 && r >= 0.8) { x = int('$padding' + (h * (1 - r)) / 2); div = h; a = 1 } \
	#	else { x = ('$padding' + 2); div = int(h * r); a = 1 }; \
	#	s = int(h * r); y = int((h - s + ('$padding' / 2)) / 2); w = int(100 - (100 / (w / div)) - a); print s, x, y, w}')


	#read pane_count pane_width pane_height <<< \
	#	$(tmux -S /tmp/tmux_hidden display -p -F '#{window_panes} #{window_width} #{window_height}' -t ncmpcpp_with_cover_art)

	#read x y cover_width cover_height ratio <<< $(awk '\
	#	$NF == "ncmpcpp_with_cover_art" {
	#		p = '$padding'
	#		pw = '$pane_width'
	#		ph = '$pane_height'
	#		w = $1
	#		h = $2
	#		cw = (w - 2 * p) / pw
	#		ch = (h - 2 * p) / ph
	#		x = int(p / cw)
	#		y = int(p / ch)
	#		r = int((h - 2 * p) / w * 100)
	#		cw = int(pw / 100 * r)
	#		print x, y, cw, ph - 2 * y, 100 - r
	#	}' <<< echo $width $height)

	padding=$(awk '/padding/ { print gensub(/[^0-9]*([0-9]+).*/, "\\1", 1); exit }' ~/.config/gtk-3.0/gtk.css)

	read pane_count pane_width pane_height <<< \
		$(tmux -S /tmp/tmux_hidden display -p -F '#{window_panes} #{window_width} #{window_height}' -t ncmpcpp_with_cover_art)

	read x y cover_width cover_height width ratio <<< $(wmctrl -lG | \
		awk '$NF == "ncmpcpp_with_cover_art" {
			p = '$padding'
			pw = '$pane_width'
			ph = '$pane_height'
			w = $5
			h = $6
			uh = ((h - 2 * p) / ph)
			uw = ((w - 2 * p) / pw)

			cw = int((h - 2 * p) / uw)
			r = int(100 / ((w - 2 * p) / (h - 2 * p)))

			print 0, 0, cw, ph, cw + 1, r }')
}

function draw_cover_art() {
	#cover=$(~/.orw/scripts/get_cover_art.sh)

	##[[ -f "$cover" ]] && echo -e "0;1;$x;$y;$s;$s;;;;;$cover\n3;" | /usr/lib/w3m/w3mimgdisplay || 
	##	$base_command send -t ncmpcpp_with_cover_art:0.0 'clear' Enter
	#[[ -f "$cover" ]] && local args="draw $x $y $cover_width $cover_height $cover"
	#~/.orw/scripts/ueberzug_wrapper.sh "$args"
	##~/Desktop/ub.sh "$args"
	#	#$base_command send -t ncmpcpp_with_cover_art:0.0 'clear' Enter
	#exit

	cover=$(~/.orw/scripts/get_cover_art.sh)
	[[ -f "$cover" ]] && args="draw $x $y $cover_width $cover_height $cover"
	command="~/.orw/scripts/ueberzug_wrapper.sh $args"

	tmux_name="ncmpcpp_with_cover_art"
	tmux_base="tmux -S /tmp/tmux_hidden"

	if ((pane_count == 1)); then
		$tmux_base split-pane -hbp $ratio -t $tmux_name:0.0
		initialize='export blank=true && source ~/.bashrc && ~/.orw/scripts/ueberzug_parser.sh'
		$tmux_base send -t $tmux_name:0.0 "$initialize" Enter
	else
		$tmux_base resize-pane -x $width -t $tmux_name:0.0
		$tmux_base select-pane -t $tmux_name:0.1
		eval "$command"
		exit
	fi

	$tmux_base send -t $tmux_name:0.0 "clear" Enter
	$tmux_base select-pane -t $tmux_name:0.1
	eval "$command"
	exit
}

#[[ $(awk '/class.*\*/' ~/.config/openbox/rc.xml) ]]
(($(sed -n '/class.*\*/=' ~/.config/openbox/rc.xml))) && close=~/.orw/scripts/get_window_neighbours.sh
	#close='nohup ~/.orw/scripts/close_window.sh &'
base_command='TERM=xterm-256color tmux -S /tmp/tmux_hidden -f ~/.config/tmux/tmux_hidden.conf'

while getopts :pvscdaRVCP:S:L:D:r:w:h:i flag; do
	case $flag in
		p)

			#[[ $V ]] && layout="move -h 2/3 -v 2/4 resize -h 1/3 -v 1/4" ||
			#	layout="move -v 3/7 -h 8/12 resize -v 3/7 -e r -h 3/4 -l +21 -r +21"

			width=${width:-500}
			height=${height:-350}
			title=ncmpcpp_playlist

			[[ ! $pre ]] && pre="~/.orw/scripts/windowctl.sh "

			[[ $V ]] && edge=b orientation=-v reverse_orientation=h ||
				edge=r orientation=-h reverse_orientation=v

			layout="move -e $edge $orientation 1/2 -c $reverse_orientation"
			pre+="$layout && sleep 0.1 > /dev/null"

			command="new -s $title ncmpcpp";;
		v)
			title=visualizer
			progressbar=yes

			[[ ! $pre ]] && pre="~/.orw/scripts/windowctl.sh "

			running_playlist=$(tmux -S /tmp/tmux_hidden ls 2> /dev/null | cut -d ':' -f 1)

			if [[ $running_playlist ]]; then
				mirror_args="$(wmctrl -lG | awk '$NF == "'$running_playlist'" {
					print ($5 > $6) ? "xe+10,y,h -h 300" : "x,ye+10,w -v 120" }')"
				pre+="-M $running_playlist $mirror_args"
			else
				if [[ $V ]]; then
					width=${width:-500}
					height=${height:-150}
					edge=t orientation=-v reverse_orientation=h progressbar=yes
				else
					width=${width:-250}
					height=${height:-350}
					edge=l orientation=-h reverse_orientation=v
				fi

				layout="move -e $edge $orientation 2/2 -c $reverse_orientation"
				pre+="$layout && sleep 0.1 > /dev/null"
			fi

			command="new -s $title cava"
			show_progessbar ${progressbar-no};;
		s)
			width=${width-450}
			height=${height-600}
			title=ncmpcpp_split

			#progressbar=no
			show_status no

			command="new -s $title ncmpcpp \; splitw -p 20 cava \; selectp -U";;
		c)
			padding=$(awk '/padding/ {
				p = gensub(/[^0-9]*([0-9]+).*/, "\\1", 1)
				print p * 2; exit }' ~/.config/gtk-3.0/gtk.css)

			#[[ $@ =~ -i ]] && width=${width-630} height=${height-250}
			[[ $@ =~ -i ]] && width=${width-$((600 + padding))} height=${height-$((180 + padding))}
			title=ncmpcpp_with_cover_art

			#get_cover_properties
			show_progessbar yes

			#command="new -s ncmpcpp_with_cover_art \; splitw -h -p $r ncmpcpp -c ~/.orw/dotfiles/.config/ncmpcpp/config_cover_art";;
			#command="new -s ncmpcpp_with_cover_art ~/Desktop/read_ub.sh \; splitw -h -p $ratio ncmpcpp -c ~/.orw/dotfiles/.config/ncmpcpp/config_cover_art";;
			#init_ueberzug='export blank=true && source ~/.bashrc && ~/Desktop/read_ub.sh'
			#command="new -s ncmpcpp_with_cover_art ~/Desktop/read_ub.sh \; splitw -hp 80 ncmpcpp -c ~/.config/ncmpcpp/config_cover_art";;
			#command="new -s ncmpcpp_with_cover_art ~/.orw/scripts/ueberzug_parser.sh";;
			command="new -s $title ~/.orw/scripts/ueberzug_parser.sh \; "
			command+="splitw -hp 80 ncmpcpp -c ~/.config/ncmpcpp/config_cover_art";;
			#command="new -s ncmpcpp_with_cover_art ncmpcpp -c ~/.orw/dotfiles/.config/ncmpcpp/config_cover_art";;
		d)
			~/.orw/scripts/ncmpcpp.sh $display $V -v -i
			until [[ $(wmctrl -l | awk '$NF ~ "visualizer"') ]]; do continue; done
			~/.orw/scripts/ncmpcpp.sh $display $V -p -i
			exit;;
		C)
			arg=${!OPTIND}

			if [[ $arg && ! $arg =~ ^- ]]; then
				class=$arg
				shift
			else
				get_cover_properties && draw_cover_art
			fi;;
		[PS])
			[[ $flag == S ]] && show_status $OPTARG || show_progessbar $OPTARG
			(($# + 1 == OPTIND)) && exit 0;;
		#S) show_status $OPTARG && exit;;
		#P) show_progessbar $OPTARG && exit;;
		L) pre="~/.orw/scripts/windowctl.sh $OPTARG";;
		D)
			display="-D $OPTARG"
			pre="~/.orw/scripts/windowctl.sh -d $OPTARG move";;
		V) V=-V;;
		R)
			ratio=$(sed -n 's/^execute.*[^0-9]\([0-9]\+\).*/\1/p' ~/.orw/dotfiles/.config/ncmpcpp/config_cover_art)
			command="send -t ncmpcpp_with_cover_art:0.0 'clear && sleep 0.1 && $0 -r $ratio -C' Enter";;
		r) ratio=$OPTARG;;
		a)
			for session in $(tmux -S /tmp/tmux_hidden ls 2> /dev/null | awk -F ':' '{ print $1 }'); do
				case $session in
					*play*) pane=0;;
					*cover*) pane=1;;
					*split*) pane=1;;
					visualizer) pane=0;;
				esac

				tmux -S /tmp/tmux_hidden respawn-pane -k -t ${session}:0.$pane
			done && exit;;
		w) width=$OPTARG;;
		h) height=$OPTARG;;
		i)
			#if ! xdotool search --name "'${title-ncmpcpp}'"; then
			if ! wmctrl -a "${title-ncmpcpp}"; then
				width=${width:-900}
				height=${height:-500}

				[[ $title ]] || show_status yes

				#mode=$(awk '/class.*\*/ { print "tiling" }' ~/.config/openbox/rc.xml)
				workspace=$(xdotool get_desktop)
				mode=$(awk '/class.*(selection|\*)/ {
					print (/\*/) ? "tiling" : "selection" }' ~/.config/openbox/rc.xml)

				if [[ $mode == tiling ]]; then
					#tiling_workspace=$(grep "^tiling.*\b$workspace\b" ~/.orw/scripts/spy_windows.sh)
					#if [[ $tiling_workspace ]]; then
					if grep "^tiling.*\b$workspace\b" ~/.orw/scripts/spy_windows.sh; then
						[[ $title == visualizer ]] &&
							width=100 height=100 || width=350 height=250
						unset pre
					fi
				fi

				#if [[ $mode ]]; then
				#	unset pre

				#	if [[ $mode == selection ]]; then
				#		class=selection
				#		~/.orw/scripts/set_window_geometry.sh $mode
				#	fi
				#else
				#	~/.orw/scripts/set_geometry.sh -c custom_size -w $width -h $height
				#fi

				#[[ $mode == tiling ]] &&
				#	class='*' && unset pre ||
				#	~/.orw/scripts/set_geometry.sh -c custom_size -w $width -h $height

				#if [[ $mode == tiling ]]; then
				#	[[ $title != visualizer ]] &&
				#		width=350 height=250
				#	unset pre
				#fi

				~/.orw/scripts/set_geometry.sh -c custom_size -w $width -h $height

				#echo "-e \"bash -c '~/.orw/scripts/execute_on_terminal_startup.sh ${title-ncmpcpp} \
				#	\"${pre:-$0 -P ${progressbar-yes}} && $base_command ${command-new -s $title ncmpcpp}\";$close'"
				#exit
				#termite -t ${title:=ncmpcpp} --class=${class:-custom_size}
				#exit

				termite -t ${title:=ncmpcpp} --class=${class:-custom_size} \
					-e "bash -c '${pre:-$0 -P ${progressbar-yes}} && \
					$base_command ${command-new -s $title ncmpcpp}'"

				#termite -t ${title:=ncmpcpp} --class=${class:-custom_size} \
				#	-e "bash -c '~/.orw/scripts/execute_on_terminal_startup.sh ${title-ncmpcpp} \
				#	\"${pre:-$0 -P ${progressbar-yes}} && $base_command ${command-new -s $title ncmpcpp}\"'" &> /dev/null &

					#\"${pre:-$0 -P ${progressbar-yes}} && $base_command ${command-new -s $title ncmpcpp}\";$close'" &> /dev/null &
					#\"${pre:-$0 -P ${progressbar-yes}} && $base_command ${command-new -s $title ncmpcpp}\"'" &> /dev/null &
					#\"${pre:-$0 -P ${progressbar-yes}} && $base_command ${command-new -s ncmpcpp ncmpcpp}\";$close'" &> /dev/null &
				exit
			fi
		esac
done

show_status yes
show_progessbar ${progressbar-yes}
eval "$base_command ${command-new -s ncmpcpp ncmpcpp}"
