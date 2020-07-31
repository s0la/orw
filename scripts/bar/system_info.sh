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

	#~/.orw/scripts/notify.sh "s: $separator"

	frame="%{B$fc\}$frame_width"
	left_frame="%{+u\}%{+o\}$frame"
	right_frame="$frame%{-o\}%{-u\}"
}

function format() {
	if [[ ! $1 == fading ]]; then
		[[ "$1" == *[![:ascii:]]* && ! "$1" =~ I- ]] && icon_width=%{I-n}

		local padding=${padding:-\$padding}

		case $style in
			hidden)
				hidden="\$padding${fg}$icon_width$1%{I-}%{F-}\$padding"

				for (( arg=$#; arg > 1; arg-- )); do
					hidden="%{A${!arg}}$hidden%{A}"
				done

				echo -e $hidden;;
			mono) echo -e "\${${mono_bg:-$pbg}}$padding\${$pfg}$icon_width$mono_fg$1%{I-}$padding$2 ${separator:-\$separator}";;
			trim) echo -e "$padding\${$sfg}$icon_width$1%{I-}\$inner\${$pfg}$2$padding$3 \$separator";;
			*) echo -e "\${$sbg}$padding\${$sfg}$icon_width$1%{I-}\$inner\${$pbg}\$inner\${$pfg}${@:2}%{F-}%{T1}${padding} %{B\$bg}${separator:-\$separator}";;
		esac
	else
		#~/.orw/scripts/notify.sh "f: $2 a ${@:2}"
		[[ $style == hidden ]] && formated="${@:2}" || formated="$(format "${@:2}")"

		if [[ $lines != true ]]; then
			#~/.orw/scripts/notify.sh "s $separator i $icon"
			#echo -e "${formated% *}%{B\$bg}${separator:-\$separator}"
			#echo -e "${formated% *}%{B\$bg}${separator:-\$separator}"
			echo -e "$formated"
		else
			set_line

			#~/.orw/scripts/notify.sh "s: $module $separator"
			case $separator in
				#e*) echo -e "${separator:1}";;
				[ej]*) echo -e "${formated% *}${separator:1}";;
				s*) echo -e "%{U$fc}\${start_line:-$left_frame}${formated% *}${separator:2}";;
				#e*) echo -e "${formated% *}\${end_line:-$right_frame}%{B\$bg}${separator:1}";;
				*) echo -e "%{U$fc}\${start_line:-$left_frame}${formated% *}\${end_line:-$right_frame}%{B\$bg}${separator:-\$separator}"
			esac

			#echo -e "%{U$fc}\${start_line:-$left_frame}${formated% *}\${end_line:-$right_frame}%{B\$bg}${separator:-\$separator}"
		fi
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

	#if ((count)); then
	if [[ ${count:-$content} ]]; then
		if [[ $icon_type == only ]]; then
			style=mono
			mono_bg="$sbg"
			mono_fg="\${$sfg}"
			#format fading "%{A:$left_command:}%{A3:$right_command:}$icon%{A}%{A}"
			format fading "$left_command$right_command$icon$left_command_end$right_command_end"
		else
			#format fading "%{A:$left_command:}%{A3:$right_command:}${!icon_type-$label}%{A}%{A}" "$content"
			[[ ! $label ]] &&
				format fading "$content" ||
				format fading "$left_command$right_command${!icon_type-$label}$left_command_end$right_command_end" "${content:-$count}"
		fi
	else
		if [[ $separator =~ ^s ]]; then
			set_line
			echo -e "%{U$fc}\${start_line:-$left_frame}"
		fi
		
		[[ $separator =~ ^e ]] && echo -e "${separator:1}"
	fi
}

case $1 in
	email*)
		#icon= 
		set_icon $1
		separator="$2"
		lines=${@: -1}

		old_mail_count=

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

		format_fading MAIL "$mail_count" "${3-none}";;
	volume*)
		separator="$2"
        current_system_volume_mode=duo
        style=$current_system_volume_mode

        eval args=( $(${0%/*}/volume.sh system $3) )

		#~/.orw/scripts/notify.sh "arg1 ${args[1]}"
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
		date="$(date +"$(([[ $4 ]] && echo "${4//_/ }" || echo I:M) | sed 's/\w/%&/g')")"

		[[ $date =~ .*\ .*:.* ]] && time="${date##* }" date="${date% *}" || style=mono

		format "$date" $time;;
	Hidden*)
		style=hidden
		separator="$2"
		lines=${@: -1}

		dropdown() {
			id=$(wmctrl -l | awk '/DROPDOWN/ { print $1 }')

			if [[ $id ]]; then
				[[ $(xwininfo -id $id | awk '/Map/ {print $NF}') =~ Viewable ]] &&
					state=down fg="\${$pfg}" || state=up fg="\${$sfg}"

				#icon=%{I+3}%{I-}
				set_icon dropdown_$state
				term=$(format ${!1-TERM} ":~/.orw/scripts/dropdown.sh:")
			fi
		}

		recorder() {
			state=rec
			#[[ $state == stop ]] && icon= fg=\${$pfg} || icon=%{I+n}%{I-} fg=\${$sfg}
			if [[ $state == stop ]]; then
				set_icon rec
				fg="\${$pfg}"
			else
				set_icon rec
				fg="\${$sfg}"
			fi

			pid=$(ps -ef | awk '/ffmpeg.*(mp4|mkv)/ && !/awk/ { print $2 }')

			if [[ $pid ]]; then
				rec_command="~/.orw/scripts/record_screen.sh"
				kill_command="kill $pid"
				rec=$(format ${!1-${state^^}} ":$rec_command:" "2:$kill_command:")
			fi
		}

		[[ $4 ]] && label=icon

		#~/.orw/scripts/notify.sh "3: $3"

		if [[ $3 == all ]]; then
			dropdown $label
			recorder $label
		fi

		#hidden="\${$sbg}\${inner}$term$separator$rec\$inner ${separator:-\$separator}"
		#hidden="\${$sbg}\${inner}$term$rec\$inner ${separator:-\$separator}"

		[[ $term || $rec ]] && hidden="\${$sbg}\${inner}$term$rec\$inner"
		[[ $hidden ]] && echo "$hidden" > ~/Desktop/hid
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
		set_icon $1

		ssid=$(nmcli dev wifi | awk ' \
			NR == 1 {
				si = index($0, " SSID")
				mi = index($0, " MODE")
			}
			/^*/ { nn = substr($0, si, mi - si)
			print gensub(" {2,}", "", 1, nn) }')

		#if [[ $2 == only ]]; then
		#	style=mono
		#	mono_fg="\${$sfg}"
		#	~/.orw/scripts/notify.sh "i: $icon"
		#	format fading $icon
		#else
		#	[[ $ssid ]] && format ${!2-NET} $ssid
		#fi;;

		format_fading NET "" "${3-none}" "$ssid";;
	Weather*)
		separator="$2"
		lines=${@: -1}
		info="${3//,/ }"

		if (($# > 4)); then
			if [[ $4 =~ ^(icon|only)$ ]]; then
				(($# > 5)) && location=$5
			else
				location=$4
			fi
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

		if [[ $4 =~ ^(no|only)$ ]]; then
			style=mono

			if [[ $4 == no ]]; then
				mono_fg="\${$pfg}"
			else
				label=$icon
				mono_bg="$sbg"
				mono_fg="\${$sfg}"
				unset weather
			fi
		else
			label=${!4:-${w^^}}
		fi

		#format_fading "${w^^}" "" "${4-none}" "$(sed 's/[^[:print:]]\([^m]*\)m*//g' <<< "${weather%\$}")";;
		if [[ $w ]]; then
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
	Ram*)
		#icon=%{I-b}%{I-}
		set_icon $1

		ram=$(free | awk '/^Mem:/ { print int(100 / ($2 / ($3 + $5))) }')

		[[ $@ =~ trim ]] && style=trim

		format "%{A1:~/.orw/scripts/show_top_usage.sh mem:}${!2-RAM}%{A}" ${ram}%;;
	Disk*)
		#icon=%{I-n}%{I-}
		set_icon $1

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
		lines=${@: -1}
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
					ap "%", "${tbefg:-${pbfg:-${'$pfg'}}}" make_progressbar(pd) "${tbfg:-${'$sfg'}}" make_progressbar(pr)
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

		format_fading TORR "$c" "${4-none}" "${torrents%\$*}";;
	updates)
		separator="$2"
		lines=${@: -1}
		#icon=%{I-4}%{I-}
		set_icon $1

		if which pacman &> /dev/null; then
			sudo pacman -Syy &> /dev/null
			updates_count=$(pacman -Qu | wc -l)
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

		format_fading UPD "$updates_count" "${3:-none}";;
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
		set_icon Power

		[[ $6 =~ icon|only ]] && label=$icon
		#~/.orw/scripts/notify.sh "$3 ${!3:-LOG}"
		#~/.orw/scripts/notify.sh "$4 ${!4:-LOG}"
		#~/.orw/scripts/notify.sh "all: $all"

		format "%{A:~/.orw/scripts/bar/power.sh $2 $3 $4 $5 &:}\${inner}${label:-POW}\$inner%{A}";;
esac
