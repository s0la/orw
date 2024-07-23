#!/bin/bash

find_current() {
	for dir in ${all[*]}; do
		current=$path/$1_$dir
		[[ ! -d $current ]] && break
	done
}

folders() {
	set_size() {
		path="${path%[0-9][0-9]x*}$1x$1/folders"
		current="${current%[0-9][0-9]x*}$1x$1/${current##*/}"

		mv $path $current
		mv ${path}_$new $path
	}

	all=( flat papirus )
	path=~/.orw/themes/icons/16x16

	find_current folders

	[[ ${current##*_} == flat ]] && new=papirus || new=flat

	if [[ $current != $1 ]]; then
		set_size 16
		set_size 48
	fi
}

buttons() {
	all=( ox box bars fat owl fira turq dots real plus slim bar_slim small default numix round sharp arrow elegant surreal )
	path=~/.themes/orw/openbox-3
	find_current buttons

	[[ ${current##*_} == default ]] && new=numix || new=default

	if [[ $current != $1 ]]; then
		mkdir $current
		mv $path/*.xbm $current &> /dev/null

		mv $path/buttons_${1:-$new}/*.xbm $path &> /dev/null
		rmdir $path/buttons_${1:-$new}
	fi
}

rofi() {
	path=~/.config/rofi
	current_mode=$(sed -n 's/.*\"\(\w*\)\"/\1/p' $path/main.rasi)

	if [[ $1 == prompt ]]; then
		shift

		while getopts :c:p: flag; do
			case $flag in
				c) config=$OPTARG;;
				p)
					explicit_prompt=true

					case $OPTARG in
						none) prompt='';;
						prompt) prompt='prompt';;
						colon) prompt='textbox-prompt-colon';;
					esac
			esac
		done

		config=~/.config/rofi/${config:-$current_mode}.rasi

		if [[ $current_mode == icons ]]; then
			awk -i inplace '{
				if(/ horibox /) {
					$0 = gensub(/(\[).*(horibox.*)/, (/inputbar/) ? "\\1 \\2" : "\\1 inputbar, \\2", 1)
				}

				print
				}' $path/icons.rasi
			exit
		else
			if [[ ! $explicit_prompt ]]; then
				current_prompt=$(sed -n '/#inputbar/,/children/ s/.* \(.*\),.*/\1/p' $config)
				[[ $current_prompt == prompt ]] && prompt='textbox-prompt-colon' || prompt='prompt'
			fi

			[[ $prompt ]] && prompt+=', '

			sed -i "/#inputbar/,/children/ s/\(.*\[ \).*\(entry.*\)/\1$prompt\2/" $config
		fi
	elif [[ $1 == sidebar ]]; then
		sidebar_mode=$(awk -F '[; ]' '/sidebar/ { print ($(NF - 1) == "true") ? "false" : "true" }' $path/config.rasi)
		sed -i "/sidebar/ s/ \w[^;]*/ ${2:-$sidebar_mode}/" $path/config.rasi 
	elif [[ $1 =~ ^(or|loc) ]]; then
		option=$1 && shift

		last_v_margin=9px
		last_h_margin=76px
		last_v_location=west
		last_h_location=south

		getopts c: config
		[[ $config ]] && mode=$OPTARG && shift 2
		conf=~/.orw/dotfiles/.config/rofi/${mode:-icons}.rasi

		eval $(awk -F '[ ;]' '\
			/window-orientation:/ {
				co = $(NF - 1)
				o = ("'${option:0:1}'" == "o")

				if(o) {
					no = ("'$1'") ? "'$1'" : \
						(co == "vertical") ? "horizontal" : "vertical"
					sub(co, no)
				 }
			}

			/window-location:/ {
				cl = $(NF - 1)
				ro = (o) ? no : co

				#nl = (o) ? (ro == "horizontal") ? nl = "center" : "'$last_location'" : \
				#	("'$1'") ? "'$1'" : (cl == "east") ? "west" : "east"

				nl = (o) ? (ro == "horizontal") ? nl = "'$last_h_location'" : "'$last_v_location'" : \
					("'$1'") ? "'$1'" : (co == "horizontal") ? \
					(cl == "center") ? "south" : "center" : (cl == "east") ? "west" : "east"

				sub(cl, nl)
			}

			/window-margin:/ {
				#mv = gensub(/.* ([0-9.]+%).*/, "\\1", 1)
				#if(ro == "horizontal") p = "%"
				mv = gensub(/.* ([0-9.]+px).*/, "\\1", 1)
				if(ro == "horizontal") p = "px"
				sub(mv, 0)

				#system("~/.orw/scripts/notify.sh " mv)

				#if(ro == "vertical") {
				#	if(ro != co) mv = "'$last_margin'"
				#	mi = (nl == "east") ? 2 : 4
				#	#$0 = gensub($(NF - mi), mv, 1)
				#	$0 = gensub(/[0-9]+/, mv, mi)
				#}

				if(ro != co) {
					lm = mv
					mv = (ro == "vertical") ? "'$last_v_margin'" : "'$last_h_margin'"
				}

				if(!lm) lm = mv

				mi = (ro == "vertical") ? (nl == "east") ? 2 : 4 : (nl == "south") ? 3 : 1
				$0 = gensub(/[0-9]+/, mv, mi)
			} { wo = wo "\n" $0 }
			END {
				#print "last_location=" nl, "last_margin=" mv
				print "co=" co, "no=" ro, "ll=" cl, "lm=" lm
				print substr(wo, 2)
			}' $conf | { read -r wo; { echo "$wo" >&1; cat > $conf; } })

		if [[ $option =~ ^or && $no != $co ]]; then
			sed -i "/^\s*last_${co:0:1}_margin/ s/[0-9.]\+px/$lm/" $0
			sed -i "/^\s*last_${co:0:1}_location/ s/\w*$/$ll/" $0
		fi
	else
		if [[ $1 ]]; then
			new_mode=$1
		else
			[[ $current_mode == fullscreen ]] && new_mode=list || new_mode=fullscreen
		fi

		if [[ $new_mode != $current_mode ]]; then
			if [[ $current_mode == fullscreen || $new_mode == fullscreen ]]; then
				font=$(sed -n 's/.*font.*\( [0-9]\+\).\{2,\}/\1/p' $path/theme.rasi)

				[[ $new_mode == fullscreen ]] && sign=+ || sign=-
				sed -i "/font/ s/[0-9]\+/$((font $sign 4))/" $path/theme.rasi
			fi

			border_width=$(awk '/^border/ { print $NF }' ~/.orw/themes/theme/openbox-3/themerc)
			border_color=$(awk -F '[ ;]' '\
				/^\s*(b[cg]|ibc)/ {
					if(!bg) bg = $(NF - 1)
					else if(!bc) bc = $(NF - 1)
					else ibc = $(NF - 1)
				} END {
					print (bg == bc) ? "ibc" : "bc"
				}' $path/theme.rasi)

			if [[ $new_mode == dmenu ]]; then
				property=reb
			else
				[[ $new_mode == list && $border_color == ibc ]] &&
					property=rib || property=rwb
			fi

			sed -i "/import/ s/ .*/ \"$new_mode\"/" ~/.config/rofi/main.rasi

			~/.orw/scripts/borderctl.sh -c $new_mode $property $border_width
			~/.orw/scripts/rice_and_shine.sh -m rofi -p dpc,sul -P ${border_color:-sbg}
		else
			if [[ $current_mode == icons && $# -gt 1 ]]; then
				awk -i inplace '{
					if(/ horibox /) {
						$0 = gensub(/(\[).*(horibox.*)/, (/inputbar/) ? "\\1 \\2" : "\\1 inputbar, \\2", 1)
					}

					print
					}' $path/icons.rasi
				exit
			fi
		fi
	fi
}

function bash() {
	if [[ $1 == edge ]]; then
		pattern=edge_mode mode1=flat mode2=sharp explcit_mode=$2
	else
		pattern=mode mode1=rice mode2=simple explcit_mode=$1
	fi

	awk -i inplace -F '=' '/^\s*'$pattern'=/ { em = "'$explcit_mode'"; m1 = "'$mode1'"; m2 = "'$mode2'"; \
		m = (em == "") ? ($NF == m1) ? m2 : m1 : em; gsub("\\w*$", m) }; { print }' $bash_conf
}

vim() {
	awk -i inplace '/^let s:swap/ { $NF = !$NF } { print }' ~/.config/nvim/plugin/statusline.vim 
}

tmux() {
	if [[ $1 == justify ]]; then
		awk -i inplace '{
			if(/justify/) $NF = ("'$2'") ? "'$2'" : (/left/) ? "centre" : "left"
		} { print }' $tmux_conf
	else
		mode=$(awk '/current/ { print (/cbg/) ? "simple" : "rice" }' $tmux_conf)

		if [[ ${1:-$mode} == simple ]]; then
			sed -i '/right\|current/ s/\wbg/bg/' $tmux_conf
			sed -i '/window-\w*-format/ s/\w\([bf]g\)/\1/g' $tmux_conf
		else
			sed -i '/right\|current/ s/$\([bf]g\)/$c\1/g' $tmux_conf
			sed -i '/window-\w*-format/ { s/$\([bf]g\)/$i\1/g; s/$\w\?\([bf]g\)/$s\1/3; s/$\w\?\([bf]g\)/$w\1/4g }' $tmux_conf
		fi
	fi

	$(which tmux) source-file $tmux_conf
}

titlebar() {
	awk -i inplace '/name="\*"/ { nr = NR + 1 }
		{
			if(nr == NR) {
				s = gensub(".*>(.*)<.*", "\\1", 1)
				sub(s, s == "no" ? "yes" : "no")
			}
		} { print }' $openbox_conf

	openbox --reconfigure
	reconfigured=true

	read {x,y}_border <<< $(~/.orw/scripts/print_borders.sh open)

	eval $(awk -i inplace '\
			/^mode/ { m = $NF }
			/^[xy]_border/ { sub($NF, (/^x/) ? '$x_border' : '$y_border') }
			{ wo = wo "\n" $0 }
			END {
				print "mode=" m
				print substr(wo, 2)
			}' $orw_conf | { read -r wo; { echo "$wo" >&1; cat > $orw_conf; } })
}

ncmpcpp() {
	config=~/.orw/dotfiles/.config/ncmpcpp/config
	eval configs=$config*

	mode=$(awk '/^song_list/ { print /[0-9]+/ ? "single" : "dual" }' ~/.config/ncmpcpp/config)

	if [[ ${1:-$mode} == single ]]; then
		sed -i '/suffix/ s/"./"/' $configs
		sed -i '/^song_list/ s/".*"/"{%a - %t} $R {%l}"/' $configs
	else
		read npp mc <<< $(sed -n '/\(main_window\|now_playing_prefix\)/ s/[^0-9]*\([0-9]\+\).*/\1/p' $config | xargs)
		sed -i '/suffix/ s/"/"●/' $configs
		sed -i "/^song_list/ s/\".*\"/\"\$($npp){%a} \$($mc) {%t} \$R \"/" $configs
	fi

	~/.orw/scripts/ncmpcpp.sh -a
}

blur_and_shadow() {
	if [[ $1 =~ bar|rofi ]]; then
		awk -i inplace '{
			if(!s) s = (/^'$property'.*-exclude/)
			if(s && /'${1^}'/) {
				if($1 == "#") sub($1, "")
				else sub(/^/, "#")
				s = 0
			}
		} { print }' $picom_conf
	else
		awk -F '[ ;]' -i inplace \
			'/^'$property' / {
				s = $(NF - 1)
				ns = (s == "true") ? "false" : "true"
				sub(s, ("'$1'") ? "'$1'" : ns)
			} { print }' $picom_conf
	fi
}

blur() {
	property=blur-background
	blur_and_shadow $1
}

shadow() {
	property=shadow
	blur_and_shadow $1
}

wm() {
	if [[ $1 =~ full|ratio|offset|reverse|direction ]]; then
		read wm_mode mode state icon <<< $(awk '
			/^mode/ { wmm = $NF }
			/^'$1'/ {
				if("'$2'") {
					m = "'$2'"
				} else {
					if("'$1'" == "direction") m = ($NF == "h") ? "v" : "h"
					else m = ($NF == "true") ? "false" : "true"
				}

				if(length(m) > 1) s = (m == "true") ? "ON" : "OFF"
				else s = (m == "h") ? "horizontal" : "vertical"

				$NF = m
			}
			/^part/ { p = $NF }
			/^ratio/ { r = 100 / $NF * p }
			/^use_ratio/ {
				if($1 ~ "'$1'") {
					if(r < 13) i = ""
					else if(r <= 25) i = ""
					else if(r < 38) i = ""
					else if(r <= 50) i = ""
					else if(r < 63) i = ""
					else if(r <= 75) i = ""
					else i = ""
				}
			}

			/^direction/ {
				if ($1 == "'$1'") {
					switch (m) {
						case "h":
							i = ""
							break
						case "v":
							i = ""
							break
						default: i = ""
					}
				} else d = $NF
			}

			/^reverse/ {
				if($1 == "'$1'") i = ""
				rv = ($NF == "true")
			}
			/^full/ {
				if($1 == "'$1'") {
					if(d = "h") i = (rv) ? "" : ""
					else i = (rv) ? "" : ""
				}
			}

			END { print wmm, m, s, i }' $orw_conf)

		if [[ $1 == offset ]]; then
			icon=

			offset_file=${orw_conf%/*}/offsets
			[[ -f $offset_file ]] && eval $(grep offset $offset_file | xargs) ||
				{ ~/.orw/scripts/notify.sh "No offset specified, use windowctl to specify offset." && exit; }
			read default_{x,y}_offset <<< $(awk '/[xy]_offset/ { print $NF }' $orw_conf | xargs)

			delta_x=$((x_offset - default_x_offset))
			delta_y=$((y_offset - default_y_offset))

			[[ $mode == true ]] && sign=+ || sign=-

			~/.orw/scripts/offset_tiled_windows.sh -x $sign$delta_x -y $sign$delta_y
		fi

		~/.orw/scripts/notify.sh -r 105 -s osd -i $icon "$1: $mode"

		sed -i "/^$1/ s/\w*$/$mode/" $orw_conf
		~/.orw/scripts/signal_windows_event.sh update
	else
		read mode direction pattern monitor <<< $(awk '
			/^mode/ {
				nm = ("'$1'") ? "'$1'" : (/floating/) ? "tiling" : "floating"
				m = (nm == "selection") ? "Mouse" : "Active"
				p = (nm == "floating") ? "tiling" : "\*"
			}

			/^direction/ {
				print nm, $NF, p, m
			}' $orw_conf)

		sed -i "/^mode/ s/\w*$/$mode/" $orw_conf
		sed -i "0,/monitor/ { /monitor/ s/>.*</>$monitor</ }" $openbox_conf
		sed -i "/class.*\(tiling\|\*\)/ s/\".*\"/\"$pattern\"/" $openbox_conf

		[[ $mode == floating ]] && opacity=100
		~/.orw/scripts/opacityctl.sh ao ${opacity:-0}

		if ((!opacity)); then
			source ~/.orw/scripts/set_window_opacity.sh

			while read id; do
				set_opacity 100
			done <<< $(wmctrl -l | awk '$NF != "DROPDOWN" { print $1 }')
		fi

		if [[ ! $2 ]]; then
			case $mode in
				tiling)
					icon=
					[[ $direction == "h" ]] && icon= || icon=;;
				stack) icon=;;
				stack) icon=;;
				auto) icon=;;
				*) icon=;;
			esac

			~/.orw/scripts/notify.sh -r 105 -s osd -i $icon "Mode: $mode"
		fi
	fi
}

notify() {
	notify_conf=~/.orw/scripts/system_notification.sh
	mode=$(awk -F '=' '/^theme/ { print ("'$1'") ? "'$1'" : ($NF == "osd") ? "vertical" : "osd" }' $notify_conf)

	~/.orw/scripts/notify.sh "System notification theme changed to <b>$mode</b>"

	sed -i "/^theme/ s/\w*$/$mode/" $notify_conf
}

bash_conf=~/.orw/dotfiles/.bashrc
orw_conf=~/.orw/dotfiles/.config/orw/config
tmux_conf=~/.orw/dotfiles/.config/tmux/tmux.conf
picom_conf=~/.orw/dotfiles/.config/picom/picom.conf
openbox_conf=~/.orw/dotfiles/.config/openbox/rc.xml

$@
[[ $reconfigured ]] || openbox --reconfigure &
