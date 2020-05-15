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

		if [[ ! $explicit_prompt ]]; then
			current_prompt=$(sed -n '/#inputbar/,/children/ s/.* \(.*\),.*/\1/p' $config)
			[[ $current_prompt == prompt ]] && prompt='textbox-prompt-colon' || prompt='prompt'
		fi

		[[ $prompt ]] && prompt+=', '

		sed -i "/#inputbar/,/children/ s/\(.*\[ \).*\(entry.*\)/\1$prompt\2/" $config
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

			[[ $new_mode =~ list ]] && width=$border_width || width=0
			[[ $new_mode =~ dmenu ]] && property=bc || property=sbg

			sed -i "/import/ s/ .*/ \"$new_mode\"/" ~/.config/rofi/main.rasi

			~/.orw/scripts/borderctl.sh -c list rbw $width
			~/.orw/scripts/rice_and_shine.sh -m rofi -p dpc,sul -P $property
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
	mode=$(awk '/current/ { print (/cbg/) ? "simple" : "rice" }' $tmux_conf)

	if [[ ${1:-$mode} == simple ]]; then
		sed -i '/right\|current/ s/\wbg/bg/' $tmux_conf
		sed -i '/window-\w*-format/ s/\w\([bf]g\)/\1/g' $tmux_conf
	else
		sed -i '/right\|current/ s/$\([bf]g\)/$c\1/g' $tmux_conf
		sed -i '/window-\w*-format/ { s/$\([bf]g\)/$i\1/g; s/$\w\?\([bf]g\)/$s\1/3; s/$\w\?\([bf]g\)/$w\1/4g }' $tmux_conf
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

		state=$(awk '/'$pattern'/ { print ($1 == "#") ? "false" : "true" }' $compton_conf)

		[[ ${2:-$state} == true ]] && replace="/$pattern/ s/^/#/" || replace="/$pattern/ s/#//"
		eval sed -i "'$replace'" $compton_conf
	else
		state=$(awk '/^blur-background / { print (/true/) ? "false" : "true" }' $compton_conf)
		sed -i "/^blur-background/ s/ \w\+/ ${1:-$state}/" $compton_conf
	fi

	killall compton
	compton &> /dev/null &
}

bash_conf=~/.orw/dotfiles/.bashrc
tmux_conf=~/.orw/dotfiles/.config/tmux/tmux.conf
compton_conf=~/.orw/dotfiles/.config/compton.conf
openbox_conf=~/.orw/dotfiles/.config/openbox/rc.xml

$@
openbox --reconfigure &
