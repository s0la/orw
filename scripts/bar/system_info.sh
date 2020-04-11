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

	frame="%{B$fc\}$frame_width"
	left_frame="%{+u\}%{+o\}$frame"
	right_frame="$frame%{-o\}%{-u\}"
}

function format() {
	if [[ ! $1 == fading ]]; then
		[[ "$1" == *[![:ascii:]]* && ! "$1" =~ I- ]] && icon_width=%{I-n}

		case $style in
			hidden)
				hidden="\$padding${fg}$icon_width$1%{I-}%{F-}\$padding"

				for (( arg=$#; arg > 1; arg-- )); do
					hidden="%{A${!arg}}$hidden%{A}"
				done

				echo -e $hidden;;
			mono)
				echo -e "\${$pbg}\$padding\${$pfg}$icon_width$mono_fg$1%{I-}\$padding$2 ${separator:-\$separator}";;
			trim) echo -e "\$padding\${$sfg}$icon_width$1%{I-}\$inner\${$pfg}$2\$padding$3 ${separator:-\$separator}";;
			*) echo -e "\${$sbg}\$padding\${$sfg}$icon_width$1%{I-}\$inner\${$pbg}\$inner\${$pfg}${@:2}%{F-}%{T1}\${padding}%{B\$bg} ${separator:-\$separator}";;
		esac
	else
		[[ $style == hidden ]] && formated="${@:2}" || formated="$(format "${@:2}")"

		if [[ $lines != true ]]; then
			echo -e "${formated% *}%{B\$bg}${separator:-\$separator}"
		else
			set_line
			echo -e "%{U$fc}\${start_line:-$left_frame}${formated% *}\${end_line:-$right_frame}%{B\$bg}${separator:-\$separator}"
		fi
	fi
}

case $1 in
	email*)
		#icon= 
		set_icon $1
		separator="$2"
		lines=${@: -1}

		old_mail_count=20

		email_auth=~/.orw/scripts/auth/email

		if [[ ! -f $email_auth ]]; then
			~/.orw/scripts/set_class_geometry.sh -c input -w 300 -h 100
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
			command1="~/.orw/scripts/notify.sh -p 'Mutt is not found..'"
		command2="~/.orw/scripts/show_mail_info.sh $username $password 5"

		((mail_count)) && format fading "%{A:$command1:}%{A3:$command2:}${!3-MAIL}%{A}%{A}" $mail_count;;
	volume*)
		separator="$2"
        current_system_volume_mode=duo
        style=$current_system_volume_mode

        eval args=( $(${0%/*}/volume.sh system $3) )

		format "${args[@]}";;
	date*)
		separator="$2"
		date="$(date +"$(([[ $3 ]] && echo "${3//_/ }" || echo I:M) | sed 's/\w/%&/g')")"

		[[ $date =~ .*\ .*:.* ]] && time="${date##* }" date="${date% *}" || style=mono

		format "$date" $time;;
	Hidden*)
		style=hidden
		separator="$2"
		lines=${@: -1}

		dropdown() {
			id=$(wmctrl -l | awk '/DROPDOWN/ { print $1 }')

			if [[ $id ]]; then
				[[ $(xwininfo -id $id | awk '/Map/ {print $NF}') =~ Viewable ]] && fg='${pfg}' || fg='${sfg}'

				#icon=%{I+3}%{I-}
				set_icon dropdown
				term=$(format ${!1-TERM} ":~/.orw/scripts/dropdown.sh:")
			fi
		}

	recorder() {
		state=rec
		#[[ $state == stop ]] && icon= fg=\${$pfg} || icon=%{I+n}%{I-} fg=\${$sfg}
		if [[ $state == stop ]]; then
			icon=
			fg=\${$pfg}
		else
			set_icon rec
			fg=\${$sfg}
		fi

		pid=$(ps -ef | awk '/ffmpeg.*(mp4|mkv)/ && !/awk/ { print $2 }')

		if [[ $pid ]]; then
			rec_command="~/.orw/scripts/record_screen.sh"
			kill_command="kill $pid"
			rec=$(format ${!1-${state^^}} ":$rec_command:" "2:$kill_command:")
		fi
	}

	if [[ $3 == all ]]; then
		dropdown $4
		recorder $4
	fi

	#hidden="\${$sbg}\${inner}$term$separator$rec\$inner ${separator:-\$separator}"
	hidden="\${$sbg}\${inner}$term$rec\$inner ${separator:-\$separator}"

	[[ $term || $rec ]] && format fading "$hidden";;
	network)
		#icon=
		set_icon $1

		ssid=$(nmcli dev wifi | awk ' \
			NR == 1 {
				si = index($0, " SSID")
				mi = index($0, " MODE")
			}
			/^*/ { nn = substr($0, si, mi - si)
			print gensub(" {2,}", "", 1, nn) }')

		[[ $ssid ]] && format ${!2-NET} $ssid;;
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

		if [[ $4 =~ (no|only) ]]; then
			style=mono

			if [[ $4 == no ]]; then
				mono_fg="\${$pfg}"
			else
				label=$icon
				mono_fg="\${$sfg}"
				unset weather
			fi
		else
			label=${!4:-${w^^}}
		fi

		[[ $w ]] && format fading $label "${weather%\$*}" | sed 's/[^[:print:]]\([^m]*\)m*//g';;
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
			disk+="$(format "%{A1:thunar $location 2> /dev/null:}%{A2:$unmount:}${!2} ${dev##*/}%{A}%{A}" $usage)"
		done <<< $(df -h | awk '/sd.[0-9]/ { usage = ($5 > 95) ? $4 : $5; print $1, usage, $NF }' | xargs -n 3)

		echo -e "${disk%\*}";;
	Usage*)
		separator="$2"
		current_usage_mode=extended

		if [[ $current_usage_mode == hidden ]]; then
			#icon=%{I-n}%{I-}
			set_icon hidden
			index=2
			usage_mode=extended
			button="\${$pbg}\$padding\${$pfg}${!4-SHOW}\$padding"
		else
			#icon=%{I-n}%{I-}
			set_icon shown
			usage_mode=hidden
			usage="\${$sbg}\$inner"

			for item in ${3//,/ }; do
				case $item in
					c) usage+='$cpu';;
					r) usage+='$ram';;
					d) usage+='$disk';;
				esac
			done

			button="\${$sbg}\$padding\${$sfg}${!4-HIDE}\$padding"
		fi

		echo -e "%{A:sed -i '/current_usage_mode=[a-z]/ s/=.*/=$usage_mode/' $0:}$button%{A}$usage%{B-} ${separator:-\$separator}";;
	Battery)
		icon=
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
					2) icon=empty;;
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

		format ${!3-${label:-$s}} "${out%\$*}";;
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

		for torrent_info in ${3//[0-9,]/ }; do
			torrents+="${!torrent_info}\${padding}"
		done

		left_command="transmission-remote -t $ids -$s &> /dev/null"
		right_command="~/.orw/scripts/show_torrents_info.sh"

		((c)) && format fading "%{A:$left_command:}%{A3:$right_command:}${!4-TOR}%{A}%{A}" "${torrents%\$*}";;
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
		
		((updates_count)) && format fading ${!3-UPD} $updates_count;;
	Temp)
		temp=$(awk '{printf("%d°C", $NF / 1000)}' /sys/class/thermal/thermal_zone*/temp)

		case $heat in
			9*) icon=9;;
			[8,7]*) icon=87;;
			[6,5]*) icon=65;;
			[4,3]*) icon=43;;
			*) icon=21;;
		esac

		set_icon $icon
		format "${!2-TEMP}" "$temp";;
	Power)
		style=mono
		set_icon $1
		format "%{A:~/.orw/scripts/bar/power.sh $2 &:}\$inner$icon\$inner%{A}";;
esac
