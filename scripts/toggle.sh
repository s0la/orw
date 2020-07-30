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
			dmenu_color=$(awk -F '[ ;]' '\
				/^\s*(b[cg]|ibc)/ {
							if(!bg) bg = $(NF - 1)
							else if(!bc) bc = $(NF - 1)
							else ibc = $(NF - 1)
						} END {
							print (bg == bc) ? "ibc" : "bc"
						}' $path/theme.rasi)

			#[[ $new_mode =~ list ]] && width=$border_width || width=0
			#[[ $new_mode =~ dmenu ]] && property=bc || property=sbg

			[[ $new_mode == dmenu ]] && width=0 property=$dmenu_color || width=$border_width property=sbg

			sed -i "/import/ s/ .*/ \"$new_mode\"/" ~/.config/rofi/main.rasi

			~/.orw/scripts/borderctl.sh -c list rbw $width
			~/.orw/scripts/rice_and_shine.sh -m rofi -p dpc,sul -P $property
		else
			if [[ $current_mode == icons && $# -gt 1 ]]; then
				#awk '/children.*listview/ { print gensub(/(\[).*(listview.*)/, (/inputbar/) ? "\\1 \\2" : "\\1 inputbar, \\2", 1) }' $path/icons.rasi
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
}

ncmpcpp() {
	config=~/.orw/dotfiles/.config/ncmpcpp/config
	eval configs=$config*

	mode=$(awk '/^song_list/ { print /[0-9]+/ ? "single" : "dual" }' ~/.config/ncmpcpp/config)

	if [[ ${1:-$mode} == single ]]; then
		#sed -i '/suffix/ s/0[^"]*/0/' $configs
		sed -i '/suffix/ s/"./"/' $configs
		sed -i '/^song_list/ s/".*"/"{%a - %t} $R {%l}"/' $configs
	else
		read npp mc <<< $(sed -n '/\(main_window\|now_playing_prefix\)/ s/[^0-9]*\([0-9]\+\).*/\1/p' $config | xargs)

		#sed -i '/suffix/ s/0/0●/' $configs
		sed -i '/suffix/ s/"/"●/' $configs
		sed -i "/^song_list/ s/\".*\"/\"\$($npp){%a} \$($mc) {%t} \$R \"/" $configs
	fi

	~/.orw/scripts/ncmpcpp.sh -a
}

blur() {
	if [[ $1 ]]; then
		[[ $1 == bar ]] && pattern=Bar || pattern='^[^o]*Rofi'

		state=$(awk '/'$pattern'/ { print ($1 == "#") ? "false" : "true" }' $picom_conf)

		[[ ${2:-$state} == true ]] && replace="/$pattern/ s/^/#/" || replace="/$pattern/ s/#//"
		eval sed -i "'$replace'" $picom_conf
	else
		state=$(awk '/^blur-background / { print (/true/) ? "false" : "true" }' $picom_conf)
		sed -i "/^blur-background/ s/ \w\+/ ${1:-$state}/" $picom_conf
	fi

	killall picom
	picom --experimental-backends &> /dev/null &
}

wm() {
	if [[ $1 =~ offset|reverse|direction ]]; then
		read mode state <<< $(awk '/^'$1'/ {
			if("'$2'") {
				m = "'$2'"
			} else {
				if("'$1'" == "direction") m = ($NF == "h") ? "v" : "h"
				else m = ($NF == "true") ? "false" : "true"
			}

			if(length(m) > 1) s = (m == "true") ? "ON" : "OFF"
			else s = (m == "h") ? "horizontal" : "vertical"

			print m, s
		}' $orw_conf)

		#~/.orw/scripts/notify.sh -pr 222 "<b>${1^^}</b> is <b>$state</b>"
		case $1 in
			direction) [[ $mode == h ]] && icon=  || icon=;;
			direction) [[ $mode == h ]] && icon=  || icon=;;
			offset) [[ $mode == true ]] && icon=  || icon=;;
			*) icon=
		esac

		~/.orw/scripts/notify.sh osd $icon "$1: $mode"

		sed -i "/^$1/ s/\w*$/$mode/" $orw_conf
	else
		read mode pattern monitor <<< $(awk '/^mode/ {
			nm = ("'$1'") ? "'$1'" : (/floating/) ? "tiling" : "floating"
			m = (nm == "selection") ? "Mouse" : "Actiove"
			p = (nm == "floating") ? "tiling" : "\*"
			print nm, p, m
		}' $orw_conf)

		sed -i "/^mode/ s/\w*$/$mode/" $orw_conf
		sed -i "0,/monitor/ { /monitor/ s/>.*</>$monitor</ }" $openbox_conf
		sed -i "/class.*\(tiling\|\*\)/ s/\".*\"/\"$pattern\"/" $openbox_conf

		#[[ $2 ]] || ~/.orw/scripts/notify.sh -pr 333 "<b>WM</b> switched to <b>$mode</b> mode"
		if [[ ! $2 ]]; then
			[[ $mode == floating ]] && icon= || icon=
			#~/.orw/scripts/notify.sh osd $icon "<bold>Mode: $mode</bold>"
			~/.orw/scripts/notify.sh osd $icon "Mode: $mode"
		fi
	fi
}

bash_conf=~/.orw/dotfiles/.bashrc
orw_conf=~/.orw/dotfiles/.config/orw/config
tmux_conf=~/.orw/dotfiles/.config/tmux/tmux.conf
picom_conf=~/.orw/dotfiles/.config/picom/picom.conf
openbox_conf=~/.orw/dotfiles/.config/openbox/rc.xml

$@
openbox --reconfigure &
