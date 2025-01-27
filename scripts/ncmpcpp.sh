#!/bin/bash

function show_status() {
	[[ $1 =~ (true|yes) ]] && local status=yes
	sed -i "/^statusbar_visibility/ s/\".*/\"${status:-no}\"/" ~/.orw/dotfiles/.config/ncmpcpp/config{,_cover_art}
}

function show_progressbar() {
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
}

function get_cover_properties() {
	read {x,y}_padding <<< $(awk '
								nr && NR > nr { exit }
								NR < nr { print $NF }
								/padding/ { nr = NR + 3 }' ~/.config/alacritty/alacritty.toml | xargs)

	read pane_{count,width,height} <<< \
		$(tmux -S /tmp/tmux_hidden display -p -F '#{window_panes} #{window_width} #{window_height}' -t ncmpcpp_with_cover_art)

	read orientation direction {,opposite_}pane x y cover_{width,height} size ratio <<< $(wmctrl -lG | \
		awk '$NF == "ncmpcpp_with_cover_art" {
			xp = '$x_padding'
			yp = '$y_padding'
			pw = '$pane_width'
			ph = '$pane_height'
			w = $5
			h = $6
			uh = ((h - 2 * p) / ph)
			uw = ((w - 2 * p) / pw)

			if (w > h) {
				r = int(100 / ((w - 2 * xp) / (h - 2 * yp)))
				fw = s = int((h - 2 * p) / uw)
				d = "h x"
				fh = ph
				p = 0
			} else {
				r = int(100 / ((h - 2 * yp) / (w - 2 * xp)))
				fh = s = int((w - 2 * p) / uh)
				y = ph - fh
				d = "v y"
				fw = pw
				p = 1
			}

			print d, p, !p, 0, 0, fw, fh, s, r }')
}

function draw_cover_art() {
	cover=$(~/.orw/scripts/get_cover_art.sh)
	[[ -f "$cover" ]] && args="draw $x $y $cover_width $cover_height $cover"
	command="~/.orw/scripts/ueberzug_wrapper.sh $args"
	echo "~/.orw/scripts/ueberzug_wrapper.sh $args" > ~/ub.log

	tmux_name="ncmpcpp_with_cover_art"
	tmux_base="tmux -S /tmp/tmux_hidden"

	if ((pane_count == 1)); then
		initialize='export blank=true && source ~/.bashrc && ~/.orw/scripts/ueberzug_parser.sh'
		$tmux_base split-pane -${orientation}bl ${ratio}% -t $tmux_name:0.0
		$tmux_base send -t $tmux_name:0.$pane "$initialize" Enter
	else
		$tmux_base resize-pane -$direction $size -t $tmux_name:0.$pane
		$tmux_base select-pane -t $tmux_name:0.$opposite_pane
		eval "$command"
		exit
	fi

	$tmux_base send -t $tmux_name:0.$pane "clear" Enter
	$tmux_base select-pane -t $tmux_name:0.$opposite_pane
	eval "$command"
	exit
}

base_command='tmux -S /tmp/tmux_hidden -f ~/.config/tmux/tmux_hidden.conf'

while getopts :pvscdaRVCP:S:L:D:r:w:h:i flag; do
	case $flag in
		p)
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
			show_progressbar ${progressbar-no}
			[[ $@ == *-L* ]] && config="--config-file $HOME/.config/alacritty/cava.toml"
			;;
		s)
			width=${width-450}
			height=${height-600}
			title=ncmpcpp_split

			status=no
			progressbar=no

			#command="new -s $title ncmpcpp \; splitw -p 20 cava \; selectp -U"
			command="new -s $title ncmpcpp \; splitw -p 30 ncmpcpp -s visualizer -c ~/.config/ncmpcpp/config_visualizer \; selectp -U"
			;;
		c)
			padding=$(awk '/padding/ {
				p = gensub(/[^0-9]*([0-9]+).*/, "\\1", 1)
				print p * 2; exit }' ~/.config/gtk-3.0/gtk.css)

			title=ncmpcpp_with_cover_art
			[[ $@ =~ -i ]] &&
				width=${width-$((600 + padding))} height=${height-$((180 + padding))}

			if ((width > height)); then
				progressbar=yes
				orientation=h
			else
				progressbar=no
				orientation=v
				back=b
			fi

			show_progressbar $progressbar
			show_status $progressbar

			command="new -s $title ~/.orw/scripts/ueberzug_parser.sh \; "
			command+="splitw -${orientation}${back}l 80% ncmpcpp -c ~/.config/ncmpcpp/config_cover_art";;
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
			[[ $flag == S ]] && show_status $OPTARG || show_progressbar $OPTARG
			(($# + 1 == OPTIND)) && exit 0;;
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
			if ! wmctrl -a "${title-ncmpcpp}"; then
				width=${width:-900}
				height=${height:-500}

				[[ $title ]] || show_status yes

				workspace=$(xdotool get_desktop)
				mode=$(awk '/class.*(selection|\*)/ {
					print (/\*/) ? "tiling" : "selection" }' ~/.config/openbox/rc.xml)

				if [[ $mode == tiling ]]; then
					if grep "^tiling.*\b$workspace\b" ~/.orw/scripts/spy_windows.sh &> /dev/null; then
						[[ $title == visualizer ]] &&
							width=100 height=100 || width=350 height=250
						unset pre
					fi
				fi

				~/.orw/scripts/set_geometry.sh -c custom_size -w $width -h $height

				alacritty $config -t ${title:=ncmpcpp} --class=${class:-custom_size} \
					-e bash -c "${pre:-$0 -P ${progressbar-yes}} && \
					$base_command ${command-new -s $title ncmpcpp}" &> /dev/null &
				exit
			fi
		esac
done

show_status ${status:-yes}
show_progressbar ${progressbar-yes}
eval "$base_command ${command-new -s ncmpcpp ncmpcpp}"
