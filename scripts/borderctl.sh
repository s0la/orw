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
			rofi_mode=$OPTARG.rasi
			shift 2;;
	esac
done

[[ ! $rofi_mode ]] &&
	rofi_mode=$(awk -F '"' 'END { print $(NF - 1) ".rasi" }' $rofi_path/main.rasi)

if [[ $2 =~ [0-9]+ ]]; then
	sign=${2%%[0-9]*}
	new_value=${2#"$sign"}
fi

case $1 in
	#[xy]*)
	#	awk -i inplace '{
	#		if(/^'${1:0:1}'_offset/) {
	#			nv = '$new_value'
	#			cv = gensub(".* ", "", 1)
	#			sub(cv, ("'$sign'") ? cv '$sign' nv : nv)
	#		}
	#		print
	#	}' ~/.config/orw/config;;

	w*)
		#[[ ${1:1:1} == [xy] ]] && pattern=${1:0:1}_offset || pattern=ratio
		#[[ ${1: -1} == [xy] ]] && pattern=${1: -1}_offset || pattern=ratio

		awk -i inplace '{
			if(/^'${1: -1}'/ && ! set) {
				set = 1
				nv = '$new_value'
				cv = gensub(".* ", "", 1)
				sub(cv, ("'$sign'") ? cv '$sign' nv : nv)
			}

			print
		}' ~/.config/orw/config;;
	r*)
		if [[ $1 == rip ]]; then
			if [[ $3 ]]; then
				second_sign=${3%%[0-9]*}
				second_arg=${3#$second_sign}
			fi

			awk -i inplace '/inputbar|element/ { set = 1 } {
				if(/padding/ && set) {
					set = 0

					if(av) {
						if("'$rofi_mode'" ~ "dmenu") v2 = v1
					} else {
						fv = '$new_value'
						sv = '${second_arg-0}'
						av = gensub(".* ([0-9]+).* ([0-9]+).*", "\\1 \\2", 1)
						split(av, v)

						v1 = ("'$sign'") ? v[1] '$sign' fv : fv 
						v2 = (sv) ? ("'$second_sign'") ? v[2] '$second_sign' sv : sv : \
							("'$rofi_mode'" ~ "dmenu") ? v[2] : v1
					}

					gsub("[0-9]+px [0-9]+", v1 "px " v2)
				}
				print
			}' $rofi_path/$rofi_mode
		else
			case $1 in
				rf) pattern=font;;
				rw) pattern=width;;
				rr)
					set=2
					pattern=radius;;
				rim)
					px=px
					pattern=margin
					[[ $rofi_mode =~ dmenu ]] && pattern+=".* 0 .*";;
				rwp)
					px=px
				 	pattern=padding;;
				r*bw)
					px=px
					pattern="border:.*px"

					[[ $1 == ribw ]] && pattern="${pattern/\./.*0.}" rofi_conf=theme.rasi

					[[ $rofi_mode =~ list ]] && rofi_conf=theme.rasi;;
					#[[ ! $rofi_mode =~ dmenu|icons ]] && rofi_conf=theme.rasi;;
				rln)
					pattern=lines
					rofi_conf=config.rasi;;
				rsp) pattern=spacing;;
			esac

			awk -i inplace '\
				BEGIN { set = '${set:-1}' }
				{
					if(/'"$pattern"'/ && set) {
						px = "'$px'"
						nv = '$new_value'
						cv = gensub(".* ([0-9]*)" px ".*", "\\1", 1)
						sub(cv px, ("'$sign'") ? cv '$sign' nv px : nv px)
						set--
					}
				print
			}' $rofi_path/${rofi_conf:-$rofi_mode}

			#awk -i inplace '\
			#	{ if(/'"$pattern"'/ && ! set) {
			#		px = "'$px'"
			#		nv = '$new_value'
			#		cv = gensub(".* ([0-9]*)" px ".*", "\\1", 1)
			#		sub(cv px, ("'$sign'") ? cv '$sign' nv px : nv px)
			#		set = '${set-1}'
			#	}
			#	print
			#}' $rofi_path/${rofi_conf:-$rofi_mode}
		fi;;
	tp)
		awk -i inplace '\
			{
				if(/padding/) {
					nv = '$new_value'
					cv = gensub("[^0-9]*([0-9]+).*", "\\1", 1)
					sub(cv, ("'$sign'") ? cv '$sign' nv : nv)
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
				sub(cv, ('$nr' == 1) ? (nv) ? nv : (cv == "no") ? "yes" : "no" : ("'$sign'") ? cv '$sign' nv : nv)
			}
			print
		}' $openbox_conf;;
	d*)
		#[[ $1 == dp ]] && pattern=padding || pattern=frame_width
		if [[ $1 =~ df ]]; then
			pattern=frame_width
		else
			[[ $1 =~ h ]] && pattern=horizontal_
			pattern+=padding
		fi

		awk -i inplace '{ \
			if(/^\s*\w*'$pattern'/) {
				nv = '$new_value'
				#$NF = ("'$sign'") ? $NF '$sign' nv : nv
				sub($NF, ("'$sign'") ? $NF '$sign' nv : nv)
			}
			print
		}' $dunst_conf

		killall dunst
		dunst &;;
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
				sub(cv, ("'$sign'") ? cv '$sign' nv : nv)
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
			md) pattern=^menu.overlap.x;;
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
					if("'$sign'") {
						if("'$sign'" == "+") $NF -= nv; else $NF += nv
					} else {
						$NF = -(obw + nv)
					}
				} else {
					$NF = ("'$sign'") ? $NF '$sign' nv : nv
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

[[ $ob_reload ]] && openbox --reconfigure || exit 0
