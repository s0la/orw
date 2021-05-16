#!/bin/bash

all="$@"
path=~/.orw/bar

[[ $1 == Weather ]] &&
	module=E || module="${1:0:1}"

pbg="${module}pbg:-\$pbg"
pfg="${module}pfg:-\$pfg"
sbg="${module}sbg:-\${${module}pbg:-\$sbg}"
sfg="${module}sfg:-\${${module}pfg:-\$sfg}"

function set_icon() {
	[[ "$all" =~ icon|only ]] && icon="$(sed -n "s/${1}_icon=//p" ${0%/*}/icons)"
}

function set_line() {
	fc="\${${module}fc:-\$fc}"
	frame_width="%{O\${${module}fw:-\${frame_width-0}}\}"

	#[[ $lines == [ou] ]] && local start_line_position="%{+$lines}" end_line_position="%{-$lines}"

	#~/.orw/scripts/notify.sh "s: $separator"

	if [[ $lines == [ou] ]]; then
		left_frame="%{+$lines\}" right_frame="%{-$lines\}"
	else
		frame="%{B$fc\}$frame_width"
		left_frame="%{+u\}%{+o\}$frame"
		right_frame="$frame%{-o\}%{-u\}"
	fi

	#left_frame="${start_line_position:-%{+u\}%{+o\}}$frame"
	#right_frame="$frame${end_line_position:-%{-o\}%{-u\}}"
}

function format() {
	if [[ ! $1 == fading ]]; then
		[[ "$1" == *[![:ascii:]]* && ! "$1" =~ I- ]] && icon_width=%{I-n}

		local all_args="$@"
		local padding=${padding:-\$padding}

		case $style in
			hidden)
				hidden="\$inner${fg}$icon_width$1%{I-}%{F-}\$inner"

				for (( arg=$#; arg > 1; arg-- )); do
					hidden="%{A${!arg}}$hidden%{A}"
				done

				echo -e $hidden;;
			#mono) echo -e "\${${mono_bg:-$pbg}}$padding\${$pfg}$icon_width$mono_fg$1%{I-}$padding$2 ${separator:-\$separator}";;
			#mono) echo -e "\${${mono_bg:-$pbg}}$padding\${${mono_fg:-$pfg}}$icon_width$1%{I-}$padding$2 ${separator:-\$separator}";;
			mono) echo -e "\${${mono_bg:-$pbg}}$padding${mono_fg:-\${$pfg\}}$icon_width%{T5}$1%{T1}%{I-}$padding$2 ${separator:-\$separator}";;
			trim) echo -e "$padding\${$sfg}$icon_width$1%{I-}\$inner\${$pfg}$2$padding$3 \$separator";;
			*) echo -e "\${$sbg}$padding\${$sfg}$icon_width%{T5}$1%{T1}%{I-}\$inner\${$pbg}\$inner\${$pfg}%{T5}${@:2}%{F-}%{T1}${padding} %{B\$bg}${separator:-\$separator}";;
		esac
	else
		#~/.orw/scripts/notify.sh "f: $2 a ${@:2}"
		#[[ $module == H ]] && ~/.orw/scripts/notify.sh "${count:-$content}"
		#[[ $module == N ]] && ~/.orw/scripts/notify.sh "ARGS ${@:2}"
		[[ $style == hidden ]] && formated="${@:2}" || formated="$(format "${@:2}")"

		#if [[ $lines != true ]]; then
		#	#~/.orw/scripts/notify.sh "s $separator i $icon"
		#	#echo -e "${formated% *}%{B\$bg}${separator:-\$separator}"
		#	#echo -e "${formated% *}%{B\$bg}${separator:-\$separator}"
		#	#echo -e "${formated% *}%{B\$bg}${separator:-\$separator}"
		#	#~/.orw/scripts/notify.sh "$module $separator"
		#	echo -e "$formated"
		#else

		#~/.orw/scripts/notify.sh "l: $lines"
		#~/.orw/scripts/notify.sh "$module: $lines"

		#if [[ $lines == false ]]; then
		if [[ $lines != false ]]; then
		#	echo -e "${formated% *}$separator"
		#	#echo -e "${formated% *} %{B\$bg}$separator"
		#else
		#if [[ $lines != true ]]; then

			#[[ $lines == true ]] && set_line ||
			#	start_line=+$lines end_line=-$lines

			#set_line
			#lines=u
			set_line

			#~/.orw/scripts/notify.sh -t 22 "$module - l: $left_frame, r: $right_frame"

			#if [[ $lines == true ]]; then
			#	set_line
			#	left_frame="%{+u}" right_frame="%{-u}"
			#	start_line="%{+u}" end_line="%{-u}"
			#else
			#	#fc="%{U\${${module}fc:-\$fc}}"
			#	left_frame="%{+u}" right_frame="%{-u}"
			#	#~/.orw/scripts/notify.sh -t 22 "l: $left_frame, r: $right_frame"
			#fi

			case $separator in
				[ej]*) separator=${separator:1};;
				*)
					if [[ $separator =~ ^s ]]; then
						separator=${separator:2}
					else
						separator=${separator:-\$separator}
						#local end="%{U$fc}\${end_line:-$right_frame}"
						local end="%{U$fc}$right_frame"
					fi

					#local start="%{U$fc}\${start_line:-$left_frame}"
					local start="%{U$fc}$left_frame"
			esac
				#e*) echo -e "${formated% *}\${end_line:-$right_frame}%{B\$bg}${separator:1}";;
				#~/.orw/scripts/notify.sh "$module: l $start, r $end"
		fi

			#~/.orw/scripts/notify.sh "s: $module $separator"
		#[[ $module == N ]] && ~/.orw/scripts/notify.sh -t 22 "sep: $separator, s: $start, e: $end"
		#[[ $module == N ]] && ~/.orw/scripts/notify.sh -t 22 "f: ${formated% *}$end"
		#[[ $module == N ]] && echo "f: ${formated% *}$end" >> ~/Desktop/net_log
		#[[ $module == N ]] && echo "f: $start$format$end$separator" >> ~/Desktop/net_log

		#[[ $module == N ]] && echo "a: $start$formated$end$separator" >> ~/Desktop/net_log
		#[[ $module == N ]] && echo "f: $start${formated% *}$end$separator" >> ~/Desktop/net_log

			#latest changes
			#case $separator in
			#	#e*) echo -e "${separator:1}";;
			#	[ej]*) echo -e "${formated% *}${separator:1}";;
			#	s*) echo -e "%{U$fc}\${start_line:-$left_frame}${formated% *}${separator:2}";;
			#	#e*) echo -e "${formated% *}\${end_line:-$right_frame}%{B\$bg}${separator:1}";;
			#	*) echo -e "%{U$fc}\${start_line:-$left_frame}${formated% *}\${end_line:-$right_frame}%{B\$bg}${separator:-\$separator}"
			#esac

		#[[ $module == N ]] && ~/.orw/scripts/notify.sh -t 22 "f: $start${formated% *}$end$separator"
		#[[ $module == E ]] && ~/.orw/scripts/notify.sh -t 22 "f: $start${formated% *}$end$separator"
		#[[ $module == E ]] && echo -e "f: $start${formated% *}$end$separator" >> ~/Desktop/weather_log

		#[[ $module == N ]] && ~/.orw/scripts/notify.sh "f: $start${formated%: *}$end$separator"
		#echo -e "$start${formated% *}$end$separator"
		#~/.orw/scripts/notify.sh -t 22 "format $module: $start${formated% *}$end$separator"
		#[[ $module == R ]] && ~/.orw/scripts/notify.sh "sep: $separator"
		echo -e "$start${formated% *}$end$separator"

			#echo -e "%{U$fc}\${start_line:-$left_frame}${formated% *}\${end_line:-$right_frame}%{B\$bg}${separator:-\$separator}"
		#fi
	fi
}

format_fading() {
	local label=$1
	local count=$2
	local icon_type=${3:-none}
	local content="$4"

	#[[ $1 == UPD ]] && ~/.orw/scripts/notify.sh "c: $3 ${content:-$count}"

	[[ $left_command ]] && local left_command="%{A1:$left_command:}" left_command_end="%{A}"
	[[ $right_command ]] && local right_command="%{A3:$right_command:}" right_command_end="%{A}"

	#[[ $module == N ]] && ~/.orw/scripts/notify.sh "c: $content"
	#if ((count)); then
	if [[ ${count:-$content} ]]; then
		if [[ $icon_type == only ]]; then
			style=mono
			mono_bg="$sbg"
			mono_fg="\${$sfg}"
			#format fading "%{A:$left_command:}%{A3:$right_command:}$icon%{A}%{A}"
			#[[ $module == N ]] && ~/.orw/scripts/notify.sh "$left_command$right_command$icon$left_command_end$right_command_end"
			format fading "$left_command$right_command$icon$left_command_end$right_command_end"
		else
			#format fading "%{A:$left_command:}%{A3:$right_command:}${!icon_type-$label}%{A}%{A}" "$content"
			[[ ! $label ]] &&
				format fading "$content" ||
				format fading "$left_command$right_command${!icon_type:-$label}$left_command_end$right_command_end" "${content:-$count}"

			#[[ $module == N ]] && #~/.orw/scripts/notify.sh "it: $icon_type 3, ${!icon_type}"
			#	~/.orw/scripts/notify.sh "$left_command$right_command${!icon_type:-$label}$left_command_end$right_command_end ${content:-$count}"
		fi
	else
		if [[ $separator =~ ^s ]]; then
			set_line
			echo -e "%{U$fc}$left_frame"
			#echo -e "%{U$fc}\${start_line:-$left_frame}"
		fi
		
		[[ $separator =~ ^e ]] && echo -e "${separator:1}"
	fi
}

case $1 in
	email*)
		#icon= 
		set_icon $1
		separator="$2"
		#lines=${@: -1}
		lines=$3

		old_mail_count=55

		email_auth=~/.orw/scripts/auth/email

		if [[ ! -f $email_auth ]]; then
			~/.orw/scripts/set_geometry.sh -c input -w 300 -h 100
			waiting_for_auth=$(wmctrl -l | awk '{ waiting += $NF == "email_auth" } END { print waiting }')
			((!waiting_for_auth)) && termite -t email_input -e ~/.orw/scripts/email_auth.sh &> /dev/null &&
				~/.orw/scripts/barctl.sh
		fi

		read username password <<< $(awk '{ print $NF }' $email_auth | xargs)

		read mail_count notification <<< $(curl -u $username:$password --silent "https://mail.google.com/mail/feed/atom" |
			xmllint --format - 2> /dev/null | awk -F '[><]' \
			'/<(fullcount|title|name)/ && ! /Inbox/ { if($2 ~ /count/) c = $3; \
			else if($2 == "title" && $3) t = $3; \
			else { print c, "<b>" $3 "</b>\\\\n" t; exit } }')

		if ((mail_count != old_mail_count)); then
			#notification_icon="<span font='Roboto 15'>$icon</span>"
			#((mail_count > old_mail_count)) && ~/.orw/scripts/notify.sh -i ~/.orw/themes/icons/64x64/apps/mail.png \
			sed -i "/^\s*old_mail_count=/ s/=.*/=$mail_count/" $0
			((mail_count > old_mail_count)) &&
				~/.orw/scripts/notify.sh -t 10 -p "new mail:\n\n$notification"
		fi

		[[ $(which mutt 2> /dev/null) ]] && command1='termite -e mutt' ||
			left_command="~/.orw/scripts/notify.sh -p 'Mutt is not found..'"
		right_command="~/.orw/scripts/show_mail_info.sh $username $password 5"

		#if ((mail_count)); then
		#	if [[ $3 == only ]]; then
		#		#~/.orw/scripts/notify.sh "i: $icon"
		#		style=mono
		#		mono_fg="\${$sfg}"
		#		format fading "%{A:$left_command:}%{A3:$right_command:}$icon%{A}%{A}"
		#	else
		#		format fading "%{A:$left_command:}%{A3:$right_command:}${!3-MAIL}%{A}%{A}" $mail_count
		#	fi
		#else
		#	[[ $separator =~ ^e ]] && echo -e "${separator:1}"
		#fi;;

		format_fading MAIL "$mail_count" "${4-none}";;
	volume*)
		separator="$2"
        current_system_volume_mode=duo
        style=$current_system_volume_mode

        eval args=( $(${0%/*}/volume.sh system $3) )

		#~/.orw/scripts/notify.sh "arg1 ${args[1]}"
		#~/.orw/scripts/notify.sh "3: $3"
		if [[ $3 == only ]]; then
			style=mono
			mono_bg="$sbg"
			mono_fg="\${$sfg}"
			format "${args[0]}"
		else
			format "${args[@]}"
		fi;;
	date*)
		padding=$2
		separator="$3"
		format=$(sed 's/_/ /g; s/\w/%&/g' <<< ${5:-I:M})
		date="$(date +"$format")"
		#date="$(date +"$(([[ $5 ]] && echo "${5//_/ }" || echo I:M) | sed 's/\w/%&/g')")"

		[[ $date =~ .*\ .*:.* ]] && time="${date##* }" date="${date% *}" || style=mono

		#if [[ ${@: -1} == icon ]]; then
		if [[ $4 == icon ]]; then
			get_num_icon() {
				local var=${!1}

				for char_index in $(seq ${#var}); do
					char=${var:char_index - 1:1}

					if [[ $char == [0-9] ]]; then
						case $char in
							0) num_icon=zero;;
							1) num_icon=one;;
							2) num_icon=two;;
							3) num_icon=three;;
							4) num_icon=four;;
							5) num_icon=five;;
							6) num_icon=six;;
							7) num_icon=seven;;
							8) num_icon=eight;;
							9) num_icon=nine;;
						esac

						set_icon num_$num_icon
						eval "${1}_icon+=$icon"
					else
						eval "${1}_icon+=$char"
					fi
				done
			}

			mono_bg="$sbg"
			mono_fg="\${$sfg}"
			get_num_icon date
			[[ $time ]] && get_num_icon time
		fi

		format "${date_icon:-$date}" ${time_icon:-$time};;
	Hidden*)
		style=hidden
		separator="$2"
		#lines=${@: -1}
		lines=$4

		dropdown() {
			id=$(wmctrl -l | awk '/DROPDOWN/ { print $1 }')

			if [[ $id ]]; then
				[[ $(xwininfo -id $id | awk '/Map/ {print $NF}') =~ Viewable ]] &&
					state=down fg="\${$pfg}" || state=up fg="\${$sfg}"
				#fg="\${$pfg}"
				#fg="\${$sfg}"

				#fg="\${$sfg}"
				#sec=$(date +'%S')
				#red=$(awk '$1 == "red" { print $NF }' ~/.config/orw/colorschemes/colors)
				#((sec % 2 == 0)) && fg="%{F\${Hpfg:-$red}}"

				#icon=%{I+3}%{I-}
				#set_icon dropdown_$state
				set_icon dropdown
				term=$(format ${!1-TERM} ":~/.orw/scripts/dropdown.sh:")
				#echo "term: $term" >> ~/Desktop/term_out
				#~/.orw/scripts/notify.sh "term: $term"
			fi
		}

		recorder() {
			state=rec
			#[[ $state == stop ]] && icon= fg=\${$pfg} || icon=%{I+n}%{I-} fg=\${$sfg}
			#if [[ $state == stop ]]; then
			#	set_icon rec
			#	fg="\${$pfg}"
			#else
			#	set_icon rec
			#	fg="\${$sfg}"
			#fi

			#set_icon rec
			set_icon rec_new

			fg="\${$pfg}"
			fg="\${$sfg}"

			#if [[ $state == rec ]]; then
			#	sec=$(date +'10#%S')
			#	red=$(awk '$1 == "red" { print $NF }' ~/.config/orw/colorschemes/colors)
			#	((sec % 2 == 0)) && fg="%{F\${Hpfg:-$red}}"
			#fi

			#pid=$(ps -ef | awk '/ffmpeg.*(mp4|mkv)/ && !/awk/ { print $2 }')
			pid=$(ps -C ffmpeg -o pid=)

			#if [[ $pid ]]; then
			if ((pid)); then
				#~/.orw/scripts/notify.sh "p: $pid"
				#kill_command="kill $pid && sed -i '/state=\w*$/ s/\w*$//' $0"

				sec=$(date +'10#%S')
				red='#785a5a'
				#red=$(awk '$1 == "red" { print $NF }' ~/.config/orw/colorschemes/colors)
				#((sec % 2 == 0)) && fg="%{F\${Hpfg:-$red}}"
				((sec % 2 == 0)) && fg="\${Hpfg:-\${$pfg}}"

				#kill_command="kill $pid"
				#rec_command="~/.orw/scripts/record_screen.sh"
				##rec=$(format ${!1-${state^^}} ":$rec_command:" "2:$kill_command:")
				#rec=$(format ${!1-${state^^}} ":$kill_command:")
				rec=$(format ${!1-${state^^}} ":kill $pid:")
			fi
		}

		tiling() {
			#pids=( $(pidof -x tile_windows.sh) )

			#if ((${#pids[*]})); then
			if pidof -x tile_windows.sh &> /dev/null; then
				#mode=$(awk '$1 == "mode" { print $NF }' ~/.config/orw/config)

				#id=$(printf '0x%.8x' $(xdotool getactivewindow))
				##orientation=$(wmctrl -lG | awk '$1 == "'$id'" { print ($5 > $6) ? "h" : "v" }')
				#orientation=$(wmctrl -lG | awk '$1 == "'$id'" { print ($5 > $6) ? "" : "" }')

				#read prev next mode icon <<< $(awk '$1 == "mode" { m = $NF }
				#		END {
				#			if(m == "tiling") { n = 0; i = "" }
				#			#else if(m == "auto") { n = 1; i = ("'$orientation'" == "h") ? "" : "" }
				#			else if(m == "auto") { n = 1; i = "'$orientation'" }
				#			else { n = 2; i = "" }
				#			print ((3 + n - 1) % 3), ((3 + n + 1) % 3), m, i
				#		}' ~/.config/orw/config)

				read prev_index next_index mode direction <<< $(awk \
					'$1 == "mode" { 
						m = $NF

						if(m == "tiling") n = 0
						else if(m == "auto") n = 1
						else n = 2

						pi = ((3 + n - 1) % 3)
						ni = ((3 + n + 1) % 3)
					}
					$1 == "direction" { d = $NF }
					$1 == "reverse" { if($NF == "true") r = "_" $1 }
					$1 == "full" {
						#if($NF == "true") f = "_" $1

						print pi, ni, m, d f r
					}' ~/.config/orw/config)

				#case $mode in
				#	tiling) next_mode=auto;;
				#	auto) next_mode=stack;;
				#	*) next_mode=tiling;;
				#esac

				if [[ $mode == auto && ! $direction =~ full ]]; then
					id=$(printf '0x%.8x' $(xdotool getactivewindow))
					direction=$(wmctrl -lG | awk '$1 == "'$id'" { print ($5 > $6) ? "h" : "v" }')
				fi

				#id=$(printf '0x%.8x' $(xdotool getactivewindow))
				#orientation=$(wmctrl -lG | awk '$1 == "'$id'" { print ($5 > $6) ? "h" : "v" }')

				#fg="\${$sfg}"
				#~/.orw/scripts/notify.sh "dir: $direction"
				set_icon tile_${direction}_full
				#set_icon tile_${direction}
				#icon="%{T4}$icon%{T-}"

				#set_icon tiling_${mode}_${orientation:-h}

				modes=( tiling auto stack )

				#~/.orw/scripts/notify.sh "n: $next ${modes[next]}, p: $prev ${modes[prev]}"

				toggle="~/.orw/scripts/toggle.sh wm"
				next="$toggle ${modes[prev_index]}"
				prev="$toggle ${modes[next_index]}"
				#tiling=$(format ${!1:-${mode^^}} ":$toggle $next_mode:" "2:$toggle floating:")
				tiling=$(format ${!1:-${mode^^}} ":$toggle floating:" "4:$next:" "5:$prev:")
				#~/.orw/scripts/notify.sh "$tiling"
			fi
		}

		screenkey() {
			pid=$(ps -C screenkey -o pid=)

			if ((pid)); then
				fg="\${$sfg}"
				set_icon screenkey
				screenkey=$(format ${!1:-SKEY} ":kill $pid:")
			fi
		}

		[[ $5 ]] && label=icon
		fg="\${$pfg}"
		fg="\${$sfg}"
		#~/.orw/scripts/notify.sh "3: $3"

		#if [[ $3 == all ]]; then
		#~/.orw/scripts/notify.sh "args: $3"
		for app in ${3//,/ }; do
			case $app in
				t) tiling $label;;
				d) dropdown $label;;
				r) recorder $label;;
				s) screenkey $label;;
			esac
		done

		#hidden="\${$sbg}\${inner}$term$separator$rec\$inner ${separator:-\$separator}"
		#hidden="\${$sbg}\${inner}$term$rec\$inner ${separator:-\$separator}"

		[[ $term || $rec || $tiling || $screenkey ]] &&
			hidden="\${$sbg}\${padding}$tiling$term$screenkey$rec\$padding ${separator:-\$separator}"
		format_fading "" "" "none" "$hidden";;

#	if [[ $term || $rec ]]; then
#		hidden="\${$sbg}\${inner}$term$rec\$inner"
#		format fading "$hidden"
#	else
#		[[ $separator =~ ^e ]] && echo -e "${separator:1}"
#
#		if [[ $separator =~ ^s ]]; then
#			set_line
#			echo -e "%{U$fc}\${start_line:-$left_frame}"
#		fi
#	fi;;
	Network)
		#icon=
		padding=$2
		#lines=${@: -1}
		lines=$3

		#type=$(ip a | awk '/^[0-9]/ && $2 ~ "^enp" { eth = 1 } END { print (eth) ? "eth" : "wifi" }')
		#set_icon $1_$type

		network_type='e'
		#interface=$(ip -o link show | awk -F '[: ]' '/state UP/ { print $3 }')
		interface=$(ip -o link show | awk -F '[: ]' '/state UP/ { print substr($3, 0, 1) }')

		#[[ $network_type != ${interface:0:1} ]] && sed -i "/^\s*network_type/ s/'.*'/'${interface:0:1}'/" $0
		#set_icon $1_${interface:0:3}

		#~/.orw/scripts/notify.sh "3: $3, 4: $4"

		#if [[ $type == eth ]]; then
		if [[ $interface == e ]]; then
			style=mono
			mono_bg="$sbg"
			#mono_fg="\${$sfg}"
			mono_fg="$pfg"
			#~/.orw/scripts/notify.sh "mg: $mono_bg"

			#[[ $3 ]] && #icon_type=only && mono_fg="$sfg"
			#	set_icon $1_eth && icon_type=only && mono_fg="$sfg"

			[[ $4 ]] && icon_type=only mono_fg="$sfg" && set_icon $1_eth

			#~/.orw/scripts/notify.sh "it: $icon_type, $icon, ${!4}"

			#format_fading ${icon:-ETH} "" "${icon_type:-none}"
			#~/.orw/scripts/notify.sh "i: $icon, $3"
			format_fading "" "" "$icon_type" "${!4:-ETH}"
		else
			#~/.orw/scripts/notify.sh "i: ^$interface^"

			#ssid=$(nmcli dev wifi | awk ' \
			read signal ssid <<< $(nmcli dev wifi | awk ' \
				NR == 1 {
					mi = index($0, " MODE")
					si = index($0, " SIGNAL")
					ssidi = index($0, " SSID")
				}
				/^*/ {
					s = substr($0, si, 3)
					ssid = substr($0, ssidi, mi - ssidi)
					print s, gensub("^\\s*", "", 1, ssid)
				}')
				#print gensub(" {2,}", "", 1, nn) }')

			case $signal in
				100) strength=full;;
				[7-9]*) strength=high;;
				[4-6]*) strength=mid;;
				*) strength=low;;
			esac

			set_icon $1_wifi_$strength
			#set_icon $1_${interface}_$strength
			#format ${!3} "$ssid"
			format_fading NET "" "${4:-none}" "$ssid"
			#format_fading NET "" "${3:-none}" "${ssid// /_}"
			#format ${!3} "$ssid"
		fi

		if [[ $network_type != ${interface:0:1} ]]; then
			#[[ $interface ]] && network_icon=${icon//[[:ascii:]]/} || network_icon=  diss=diss
			#~/.orw/scripts/notify.sh -s osd -i ${icon//[[:ascii:]]/} "connected"
			if [[ $interface ]]; then
				network_icon=${icon//[[:ascii:]]/}
			else
				[[ $network_type == w ]] && network_icon= || network_icon=
				diss=diss
			fi

			~/.orw/scripts/notify.sh -s osd -i $network_icon "${diss}connected"
			sed -i "/^\s*network_type/ s/'.*'/'${interface:0:1}'/" $0
		fi;;
		#format_fading NET "" "${icon_type:-${3:-none}}" "$ssid";;

		#if [[ $2 == only ]]; then
		#	style=mono
		#	mono_fg="\${$sfg}"
		#	~/.orw/scripts/notify.sh "i: $icon"
		#	format fading $icon
		#else
		#	[[ $ssid ]] && format ${!2-NET} $ssid
		#fi;;

		#format_fading NET "" "${3-none}" "$ssid";;
	Weather*)
		separator="$2"
		#lines=${@: -1}
		lines=$4
		info="${3//,/ }"

		#if (($# > 4)); then
		#	if [[ $5 =~ ^(icon|only)$ ]]; then
		#		(($# > 5)) && location=$5
		#	else
		#		location=$4
		#	fi
		#fi

		if [[ $@ =~ (icon|only)$ ]]; then
			(($# == 6)) && location=$5
		else
			location=$5
		fi

		[[ $info =~ s ]] && nr=6

		read w $info <<< $(curl -s wttr.in/$location | awk 'NR > 2 && NR < '${nr-5}' \
			{ w = ""; s = (NR == 5) ? " " : ""; for(f = NF - (NR - 3); f <= NF; f++) w = w s $f; print w }' | xargs)

		case $w in
			*[Cc]lear|[Ss]un*) icon=sun;;
			*[Pp]artly*) icon=partly;;
			*[Cc]loud*) icon=cloud;;
			*[Ss]now*) icon=snow;;
			*[Rr]ain*) icon=rain;;
		esac

		set_icon $icon

		[[ $info == s ]] && s="${s#* }"

		for i in $info; do
			weather+="${!i}\${padding}"
		done

		if [[ $6 =~ ^(no|only)$ ]]; then
			style=mono

			if [[ $6 == no ]]; then
				#mono_fg="\${$pfg}"
				mono_fg="$pfg"
			else
				label=$icon
				mono_bg="$sbg"
				#mono_fg="\${$sfg}"
				mono_fg="$sfg"
				unset weather
			fi
		else
			label=${!6:-${w^^}}
		fi

		#format_fading "${w^^}" "" "${4-none}" "$(sed 's/[^[:print:]]\([^m]*\)m*//g' <<< "${weather%\$}")";;
		if [[ $w ]]; then
		#~/.orw/scripts/notify.sh "l $label, w $w"
			#~/.orw/scripts/notify.sh "$label, ${weather%\$*}"

			#format fading $label "${weather%\$*}" | sed 's/[^[:print:]]\([^m]*\)m*//g'
			format fading $label "${weather%\$*}" | sed 's/[^[:print:]]\([^m]*\)m*//g'
		else
			if [[ $separator =~ ^s ]]; then
				set_line
				echo -e "%{U$fc}\${start_line:-$left_frame}"
			fi

			[[ $separator =~ ^e ]] && echo -e "${separator:1}"
		fi;;
	Cpu)
		#icon=
		set_icon $1
		usage=$(top -bn 2 | awk '/%Cpu/ {print $2}' | tail -1)

		[[ $@ =~ trim ]] && style=trim

		format "%{A1:~/.orw/scripts/show_top_usage.sh cpu:}${!2-CPU}%{A}" ${usage%.*}%;;
	Mem*)
		#icon=%{I-b}%{I-}
		set_icon $1

		ram=$(free | awk '/^Mem:/ { print int(100 / ($2 / ($3 + $5))) }')

		[[ $@ =~ trim ]] && style=trim

		format "%{A1:~/.orw/scripts/show_top_usage.sh mem:}${!2-RAM}%{A}" ${ram}%;;
	Disk*)
		#icon=%{I-n}%{I-}
		set_icon $1

		#[[ $@ =~ trim ]] && style=trim

		[[ $@ =~ trim ]] && style=trim

		while read -r dev usage location; do
			unmount="~/.orw/scripts/mount.sh $dev $dev"
			vifm_command="~/.orw/scripts/vifm.sh -i $location"
			disk+="$(format "%{A1:$vifm_command:}%{A2:$unmount:}${!2} ${dev##*/}%{A}%{A}" $usage)"
		done <<< $(df -h | \
			awk '/^\/dev/ {
				p = gensub(/.*\/([^-]*-)?(.*) (.*)%/, "\\2  \\3", 1, $1 " " $5 )
				split(p, pa)
				print pa[1], (pa[2] > 95) ? $4 : $5, $NF
			}' | xargs -n 3)
		#done <<< $(df -h | awk '/sd.[0-9]/ { usage = ($5 > 95) ? $4 : $5; print $1, usage, $NF }' | xargs -n 3)

		echo -e "${disk%\*}";;
	Usage*)
		padding=$2
		current_usage_mode=hidden

		if [[ $current_usage_mode == hidden ]]; then
			#icon=%{I-n}%{I-}
			set_icon hide
			index=2
			usage_mode=extended
			separator=' $separator'
			button="\${$pbg}$padding\${$pfg}${!4-SHOW}$padding"
		else
			#icon=%{I-n}%{I-}
			set_icon show
			usage_mode=hidden
			usage="\${$sbg}\$inner"

			for item in ${3//,/ }; do
				case $item in
					c) usage+='$cpu';;
					r) usage+='$ram';;
					d) usage+='$disk';;
				esac
			done

			button="\${$sbg}$padding\${$sfg}${!4-HIDE}$padding"
		fi

		#~/.orw/scripts/notify.sh "$all"

		full_usage="%{A:sed -i '/current_usage_mode=[a-z]/ s/=.*/=$usage_mode/' $0:}$button%{A}$usage%{B-}$separator"

		#case $separator in
		#	#e*) echo -e "${separator:1}";;
		#	[ej]*) echo -e "${full_usage% *}${separator:1}";;
		#	s*) echo -e "%{U$fc}\${start_line:-$left_frame}${full_usage% *}${separator:2}";;
		#	#e*) echo -e "${formated% *}\${end_line:-$right_frame}%{B\$bg}${separator:1}";;
		#	*) echo -e "%{U$fc}\${start_line:-$left_frame}${full_usage% *}\${end_line:-$right_frame}%{B\$bg}${separator:-\$separator}"
		#esac;;

		#echo -e "%{A:sed -i '/current_usage_mode=[a-z]/ s/=.*/=$usage_mode/' $0:}$button%{A}$usage%{B-} ${separator:-\$separator}";;
		echo -e "%{A:sed -i '/current_usage_mode=[a-z]/ s/=.*/=$usage_mode/' $0:}$button%{A}$usage%{B-}$separator";;
	Battery)
		icon=
		icon=%{I-b}%{I-}
		icon=%{I-b}%{I-}

		info="${2//,/ }"

		for i in $info; do
			case $i in
				p) fields+=', $6';;
				t) fields+=', $8 ":" $9' sub='sub(/^0/, "", $8);';;
			esac
		done

		read s $info <<< $(acpi | awk -F '[:, ]' '{'"$sub"' print toupper(substr($4, 1, 3)) '"$fields"'}')

		case $s in
			CHA) icon=charging;;
			FUL) s=FULL label=BATT icon=charging_full out=100%;;
			*)
				case ${#p} in
					2)
						icon=empty
						sfg="Bafg:-\${afg:-\${$sfg}}";;
					4) icon=full;;
					*)
						case $p in
							[1-3]*) icon=13;;
							[4-6]*) icon=46;;
							*) icon=79;;
						esac
				esac

				label=BAT
		esac

		set_icon Battery_$icon

		[[ $s != FULL ]] && for i in $info; do
			out+="${!i}\${padding}"
		done

		if [[ $3 == only ]]; then
			style=mono
			mono_bg="$sbg"
			mono_fg="\${$sfg}"
			format $icon
		else
			format ${!3-${label:-$s}} "${out%\$*}"
		fi;;
	torrents)
		separator="$2"
		#lines=${@: -1}
		lines=$4
		#icon=%{I+n}%{I-}
		#icon=%{I+n}%{I-}
		set_icon $1

		step=${3//[^0-9]/}

		(($(pidof transmission-daemon))) && read ids s c p b <<< $(transmission-remote -l | awk '\
			function make_progressbar(percent) {
				if(percent > 0) return gensub(/ /, "■", "g", sprintf("%*s", percent, " "))
			}

			NR == 1 {
				ns = index($0, "Name")
				ss = index($0, "Status")
			} {
				if($2 ~ "^[0-9]{1,2}%") {
					tp += $2
					ap = tp / ++c

					i = i "," $1
					ts = substr($0, ss)
					ns = (ts ~ "^Stopped") ? "s" : "S"
				}
			} END {
				s = '${step:-5}'
				pd = sprintf("%.0f", ap / s); pr = 100 / s - pd
				if(c) print substr(i, 2), ns, c,
					ap "%", "${tbefg:-${pbefg:-${'$pfg'}}}" make_progressbar(pd) "${tbfg:-${'$sfg'}}" make_progressbar(pr)
			}' 2> /dev/null)

		((c)) &&
			for torrent_info in ${3//[0-9,]/ }; do
				torrents+="${!torrent_info}\${padding}"
			done

		left_command="transmission-remote -t $ids -$s &> /dev/null"
		right_command="~/.orw/scripts/show_torrents_info.sh"

		#if ((c)); then
		#	if [[ $4 == only ]]; then
		#		style=mono
		#		mono_fg="\${$sfg}"
		#		format fading "%{A:$left_command:}%{A3:$right_command:}$icon%{A}%{A}"
		#	else
		#		format fading "%{A:$left_command:}%{A3:$right_command:}${!4-TORR}%{A}%{A}" "${torrents%\$*}"
		#	fi
		#else
		#	[[ $separator =~ ^e ]] && echo -e "${separator:1}"
		#fi;;

		format_fading TORR "$c" "${5-none}" "${torrents%\$*}";;
	updates)
		separator="$2"
		#lines=${@: -1}
		lines=$3
		#icon=%{I-4}%{I-}
		set_icon $1

		if which pacman &> /dev/null; then
			sudo pacman -Syy &> /dev/null
			#updates_count=$(pacman -Qu | wc -l)
			updates_count=$(pacman -Qu | awk 'END { if(NR) print NR }')
		else
			updates_count=$(apt list --upgradable 2> /dev/null | wc -l)
		fi

		#if ((updates_count)); then
		#	if [[ $3 == only ]]; then
		#		style=mono
		#		mono_fg="\${$sfg}"
		#		format fading $icon
		#	else
		#		format fading ${!3-UPD} $updates_count
		#	fi
		#else
		#	[[ $separator =~ ^e ]] && echo -e "${separator:1}"
		#fi;;

		format_fading UPD "$updates_count" "${4:-none}";;
	Rss)
		separator="$2"
		lines=$3

		last_feed_count=6
		#feed_count=$(newsboat -x reload print-unread | cut -d ' ' -f 1)
		pid=$(pidof newsboat)
		((pid)) &&
			feed_count=$last_feed_count ||
			feed_count=$(newsboat -x reload print-unread | awk '$1 { print $1 }')
		#feed_count=3

		#~/.orw/scripts/notify.sh "rss: $feed_count"

		set_icon $1
		left_command='termite -t newsboat -e newsboat &> /dev/null &'
		format_fading RSS "$feed_count" "${4:-none}"

		if ((feed_count != last_feed_count)); then
			feed_icon=${icon//[[:ascii:]]/}
			((feed_count)) && ~/.orw/scripts/notify.sh -r 501 -s osd -i $feed_icon "New feeds: $feed_count"
			sed -i "/^\s*last_feed_count/ s/[0-9]\+/${feed_count:-0}/" $0
		fi;;

		#if ((feed_count)); then
		#	set_icon $1
		#	format_fading RSS "$count" "${4-none}"

		#	~/.orw/scripts/notify.sh "fc: $feed_count"

		#	if ((feed_count != last_feed_count)); then
		#		rss_icon=${icon//[[:ascii:]]/}
		#		~/.orw/scripts/notify.sh -s osd -i $rss_icon "New feeds: <b>$feed_count</b>"
		#		sed -i "/^\s*last_feed_count/ s/[0-9]\+/$feed_count/" $0
		#	fi
		#fi;;
	Temp)
		#temp=$(awk '{ printf("%d°C", $NF / 1000) }' /sys/class/thermal/thermal_zone*/temp)
		temp=$(awk '{ tt += $NF / 1000; tc++ } END { print $NF / 1000 "°C" }' /sys/class/thermal/thermal_zone*/temp)

		case $temp in
			9*)
				icon=9
				sfg="Tafg:-\${afg:-\${$sfg}}";;
			[8,7]*) icon=87
				sfg="Tafg:-\${afg:-\${$sfg}}";;
			[6,5]*) icon=65;;
			[4,3]*) icon=43;;
			*) icon=21;;
		esac

		set_icon Temp_$icon

		if [[ $2 == only ]]; then
			style=mono
			mono_bg="$sbg"
			mono_fg="\${$sfg}"
			format $icon
		else
			format "${!2-TEMP}" "$temp"
		fi;;
	Power)
		style=mono
		#padding="$2"
		#separator="$3"
		#[[ $5 == icon ]] && set_icon Power
		set_icon power_power_off

		[[ $6 =~ icon|only ]] && label=$icon
		#~/.orw/scripts/notify.sh "$3 ${!3:-LOG}"
		#~/.orw/scripts/notify.sh "$4 ${!4:-LOG}"
		#~/.orw/scripts/notify.sh "all: $all"

		format "%{A:~/.orw/scripts/bar/power.sh $2 $3 $4 $5 &:}\${inner}${label:-POW}\$inner%{A}";;
esac
