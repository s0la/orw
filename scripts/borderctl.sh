#!/bin/bash

orw_conf=~/.config/orw/config
dunst_conf=~/.orw/dotfiles/.config/dunst/dunstrc
theme_conf=~/.orw/themes/theme/openbox-3/themerc
openbox_conf=~/.orw/dotfiles/.config/openbox/rc.xml
lock_conf=~/.orw/dotfiles/.config/i3lockrc
rofi_path=~/.orw/dotfiles/.config/rofi
rofi_list_conf=list

while getopts :c: flag; do
	case $flag in
		c)
			mode=$OPTARG
			[[ $3 =~ ^r ]] && mode+=.rasi

			shift 2;;
	esac
done

[[ $1 =~ ^r && ! $mode ]] &&
	mode=$(awk -F '"' 'END { print $(NF - 1) }' $rofi_path/main.rasi)

if [[ $2 =~ [0-9]+ ]]; then
	#sign=${2%%[0-9]*}
	#new_value=${2#"$sign"}
	new_value=$2
	sign=${new_value%%[0-9]*}
fi

if [[ $3 ]]; then
	second_sign=${3%%[0-9]*}
	second_arg=${3#$second_sign}
fi

case $1 in
	w*)
		property="${1: -1}"
		[[ $property == [xy] ]] && property+=_offset

		read property value <<< $(awk '/^'$property'/ { print; exit }' $orw_conf)

		if [[ $property == m* ]]; then
			awk -i inplace '/^margin/ { $NF += '${new_value}' } { print }' ~/.config/orw/config
			~/.orw/scripts/signal_windows_event.sh update
			exit
		elif [[ $property =~ offset ]]; then
			min=0
		else
			read part ratio <<< $(awk '/^(part|ratio)/ { print $NF }' $orw_conf | xargs)
			min=1
		fi

		[[ $sign ]] && check_value=$((value + new_value)) || check_value=$new_value

		style='-s osd'

		if ((check_value >= min)); then
			message="<b>${property/_/ }</b> changed to <b>$check_value</b>"
			message="${property^^}: $check_value"

			if [[ $property == part ]]; then
				[[ $check_value -lt $ratio ]] &&
					new_ratio="$check_value/$ratio" ||
					check_value=$part new_ratio="$part/$ratio" style='' \
					message="<b>${property^}</b> must be lower then ratio (<b>$ratio</b>)"
			fi

			sed -i "/$property/ s/$value/$check_value/" $orw_conf
		else
			message="<b>$check_value</b> must be higher than <b>$min</b>!"
		fi

		[[ ! $3 ]] && ~/.orw/scripts/notify.sh -pr 22 $style -i ${icon:-} "$message"
		~/.orw/scripts/signal_windows_event.sh update
		exit
		;;
	r*)
		[[ $1 == rl ]] && rofi_config=config.rasi

		awk -i inplace '\
			$1 ~ "^'${1:1:1}'[^-]*:" {
				nv = '$new_value'
				cv = gensub(/.* ([0-9]+).*/, "\\1", 1)
				sub(/[0-9]+/, ("'$sign'") ? cv + nv : nv)
			}

			$1 ~ "^'${1:1:1}'\\w*-'${1:2:1}'\\w*:" {
				if ($1 ~ ".*-padding") {
					w = 2
					fv = '$new_value'
					sv = '${second_arg:=$new_value}'
					av = gensub(".* ([0-9]+).* ([0-9]+).*", "\\1 \\2", 1)
					split(av, v)

					v1 = ("'$sign'") ? v[1] + fv : fv 
					v2 = ("'$second_arg'") ? ("'${second_sign:=$sign}'") ? \
						v[2] + sv : sv : ("'$mode'" ~ "dmenu") ? v[2] : v1

					sub(/([0-9px]+ ?){2}/, v1 "px " v2 "px")
				} else {
					w = (/margin/)
					u = ($1 ~ "width") ? "%" : "px"

					nv = '$new_value'

					cv = gensub(".* ([0-9.]+)(%|px).*", "\\1", 1)
					sub(cv "(%|px)", ("'$sign'") ? cv + nv u : nv u)
				}
			}

			w && FILENAME ~ "icons" && $1 == "window-width:" {
				cv = $NF
				gsub("[^0-9]", "", cv)
				nv = cv + w * '${second_arg:-$new_value}'
				#nv = cv '${second_sign:-$sign}' w * '${second_arg:-$new_value}'
				#system("~/.orw/scripts/notify.sh -t 5 \"" cv " '"${second_sign:-$sign}"' " nv " '"${second_arg:-$new_value}"' \"")
				sub(cv, nv)
			}

			{ print }' $rofi_path/${rofi_conf:-$mode};;
	tm*)
		[[ $1 == tms ]] &&
			pattern=separator || pattern='window.*format'

		awk -i inplace '
			function set_value() {
				cv = length(s)
				uv = "'${new_value:-$2}'"
				nv = sprintf("%*.s", ("'$sign'") ? cv + uv : uv, " ")
			}

			{
				if(/'$pattern'/) {
					if(!s) {
						w = (/format/)
						p = (w) ? ".*W" : ".*\""
						s = gensub(p "(.*)\"$", "\\1", 1)
					}

					set_value()

					if(w) {
						wp = (/current/) ? "W" : "I"
						$0 = gensub("( *)(#[" wp "]|\"$)", nv "\\2", "g")
					} else {
						sub(/".*"/, "\"" nv "\"")
					}
				}
			}
		{ print }' ~/.orw/dotfiles/.config/tmux/tmux.conf

		tmux source-file ~/.orw/dotfiles/.config/tmux/tmux.conf
		exit;;
	tp)
		awk -i inplace '\
			{
				if(/padding/) {
					nv = '$new_value'
					cv = gensub("[^0-9]*([0-9]+).*", "\\1", 1)
					sub(cv, ("'$sign'") ? cv + nv : nv)
				}
				print
		}' ~/.orw/dotfiles/.config/gtk-3.0/gtk.css;;
	tb*)
		ob_reload=true
		[[ $1 == tb ]] && pattern='name.*\*' nr=1 || pattern='font.*ActiveWindow' nr=2

		awk -i inplace '\
			/'$pattern'/ { nr = NR } { \
			if (nr && NR == nr + '$nr') {
				nv = "'${new_value:-$2}'"
				cv = gensub(".*>(.*)<.*", "\\1", 1)
				sub(cv, ('$nr' == 1) ? (nv) ? nv : (cv == "no") ? "yes" : "no" : ("'$sign'") ? cv + nv : nv)
			}
			print
		}' $openbox_conf;;
	d*)
		[[ $mode ]] && dunst_conf="${dunst_conf%/*}/${mode}_dunstrc"

		if [[ $1 =~ df ]]; then
			pattern=frame_width
		else
			[[ $1 =~ h ]] && pattern=horizontal_
			pattern+=padding
		fi

		awk -i inplace '{ \
			if(/^\s*\w*'$pattern'/) {
				nv = '$new_value'
				sub($NF, ("'$sign'") ? $NF + nv : nv)
			}
			print
		}' $dunst_conf

		command=$(ps -C dunst -o args= | awk '{ if($1 == "dunst") $1 = "'$(which dunst)'"; print }')
		killall dunst
		$command &> /dev/null &;;
	l*)
		case $1 in
			lr) pattern=radius;;
			lts) pattern=timesize;;
			lds) pattern=datesize;;
			*) pattern=width
		esac

		awk -i inplace '{ \
			if(/^'$pattern'/) {
				nv = '$new_value'
				cv = gensub(".*=", "", 1)
				sub(cv, ("'$sign'") ? cv + nv : nv)
			}
			print
		}' $lock_conf;;
	*)
		ob_reload=true

		case $1 in
			hw) pattern=handle.width;;
			bw) pattern=^border.width;;
			cp) pattern='client.*padding';;
			ch) pattern='client.padding.height';;
			cw) pattern='client.padding.width';;
			jt) pattern=label.*justify;;
			pw) pattern=^padding.width;;
			ph) pattern=^padding.height;;
			md*) pattern="^menu.overlap.${1: -1}";;
			mbw)
				pattern=^menu.border.width
				gtkrc2=~/.orw/themes/theme/gtk-2.0/gtkrc;;
		esac

		awk -i inplace '{ \
			if("'$pattern'" ~ "menu") {
				if(/^menu.border/) obw = $NF
				if(/^menu.overlap/) {
					if("'$pattern'" ~ "border") $NF = (obw + $NF) - nv
				}
			}

			if(/'$pattern'/) {
				nv = '${new_value:-\"$2\"}'

				if(/overlap/) {
					if("'$sign'") $NF += nv
					else $NF = (/x/) ? -(obw + nv) : nv
				} else {
					$NF = ("'$sign'") ? $NF + nv : nv
					nv = $NF
				}
			} if("'$pattern'" ~ "menu") { 
				if(/^style "menu"/) set = 2
				
				if(/thickness/ && set) {
					$NF = nv
					set--
				}
			}
			print
		}' $theme_conf $gtkrc2
esac

if [[ $ob_reload ]]; then
	 openbox --reconfigure

	if [[ $1 == [bcp][hwp] ]]; then
		sleep 0.1
		read x_border y_border <<< $(~/.orw/scripts/print_borders.sh)
		echo $x_border, $y_border
		awk -i inplace '/^[xy]_border/ { sub($NF, (/^x/) ? '$x_border' : '$y_border') } { print }' $orw_conf
		~/.orw/scripts/signal_windows_event.sh update
	fi
fi
