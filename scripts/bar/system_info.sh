#!/bin/bash

path=~/.orw/bar

[[ $1 == Weather ]] &&
	module=E || module="${1:0:1}"

pbg="${module}pbg:-\$pbg"
pfg="${module}pfg:-\$pfg"
sbg="${module}sbg:-\${${module}pbg:-\$sbg}"
sfg="${module}sfg:-\${${module}pfg:-\$sfg}"

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
				echo -e "\${$pbg}\$padding\${$pfg}$icon_width$1%{I-}\$padding$2 \$separator";;
			trim) echo -e "\$padding\${$sfg}$icon_width$1%{I-}\$inner\${$pfg}$2\$padding$3 \$separator";;
			*) echo -e "\${$sbg}\$padding\${$sfg}$icon_width$1%{I-}\$inner\${$pbg}\$inner\${$pfg}${@:2}%{F-}%{T1}\${padding}%{B\$bg} \$separator";;
		esac
	else
		[[ $style == hidden ]] && formated="${@:2}" || formated="$(format "${@:2}")"

		if [[ $lines != true ]]; then
			echo -e "${formated% *}%{B\$bg}\$separator"
		else
			set_line
			echo -e "%{U$fc}\${start_line:-$left_frame}${formated% *}\${end_line:-$right_frame}%{B\$bg}\$separator"
		fi
	fi
}

case $1 in
	email*)
		icon= 
		lines=${@: -1}

		old_mail_count=18

		email_auth=~/.orw/scripts/auth/email

		if [[ ! -f $email_auth ]]; then
			waiting_for_auth=$(wmctrl -l | awk '{ waiting += $NF == "email_auth" } END { print waiting }')
			((!waiting_for_auth)) && termite -t email_auth -e ~/.orw/scripts/email_auth.sh &> /dev/null &&
				~/.orw/scripts/barctl.sh -d
		fi

		read username password <<< $(awk '{ print $NF }' $email_auth | xargs)

		read mail_count notification <<< $(curl -u $username:$password --silent "https://mail.google.com/mail/feed/atom" |
			xmllint --format - 2> /dev/null | awk -F '[><]' \
			'/<(fullcount|title|name)/ && ! /Inbox/ { if($2 ~ /count/) c = $3; \
			else if($2 == "title" && $3) t = " - " $3; \
			else { print c, $3 t; exit } }')

		if ((mail_count != old_mail_count)); then
			sed -i "/^\s*old_mail_count=/ s/=.*/=$mail_count/" $0
			((mail_count > old_mail_count)) && ~/.orw/scripts/notify.sh -i ~/.orw/themes/icons/64x64/apps/mail.png \
				-t 10 -p "$notification"
		fi

		[[ $(which mutt 2> /dev/null) ]] && command1='termite -e mutt' ||
			command1="~/.orw/scripts/notify.sh -p 'Mutt is not found..'"
		command2="~/.orw/scripts/show_mail_info.sh $username $password"

		((mail_count)) && format fading "%{A:$command1:}%{A3:$command2:}${!2-MAIL}%{A}%{A}" $mail_count;;
	volume*)
        current_system_volume_mode=duo
        style=$current_system_volume_mode

        eval args=( $(${0%/*}/volume.sh system $2) )

		format "${args[@]}";;
	date*)
		date="$(date +"$(([[ $2 ]] && echo "${2//_/ }" || echo I:M) | sed 's/\w/%&/g')")"

		[[ $date =~ .*\ .*:.* ]] && time="${date##* }" date="${date% *}" || style=mono

		format "$date" $time;;
	Hidden*)
		style=hidden
		lines=${@: -1}

		dropdown() {
			id=$(wmctrl -l | awk '/DROPDOWN/ {print $1}')

			if [[ $id ]]; then
				if [[ $(xwininfo -id $id | awk '/Map/ {print $NF}') =~ Viewable ]]; then
					fg="\${Apfg:-\${$pfg}}"
				else
					fg="\${Asfg:-\${$sfg}}"
				fi

				icon=%{I-}%{I-}
				term=$(format ${!1-TERM} ":~/.orw/scripts/dropdown.sh:")
			fi
		}

	recorder() {
		state=rec
		[[ $state == stop ]] && icon= fg=\${$pfg} || icon= fg=\${$sfg}

		pid=$(ps -ef | awk '/ffmpeg.*(mp4|mkv)/ && !/awk/ {print $2}')

		if [[ $pid ]]; then
			rec_command="~/.orw/scripts/record_screen.sh"
			kill_command="kill $pid"
			rec=$(format ${!1-${state^^}} ":$rec_command:" "2:$kill_command:")
		fi
	}

	if [[ $2 == all ]]; then
		dropdown $3
		recorder $3
	fi

	hidden="\${$sbg}\${inner}$term$separator$rec\$inner \$separator"

	[[ $term || $rec ]] && format fading "$hidden";;
	network)
		icon=

		ssid=$(nmcli dev wifi | awk ' \
			NR == 1 {
					si = index($0, "SSID")
					mi = index($0, "MODE")
				}
			/^*/ { nn = substr($0, si, mi - si)
			print gensub(" {2,}", "", 1, nn) }')

		[[ $ssid ]] && format ${!2-NET} $ssid;;
	Weather*)
		lines=${@: -1}
		info="${2//,/ }"
		(($# == 5)) && city=$4
		[[ $info =~ s ]] && nr=6

		read w $info <<< $(curl -s wttr.in/$city | awk 'NR > 2 && NR < '${nr-5}' \
			{ w = ""; s = (NR == 5) ? " " : ""; for(f = NF - (NR - 3); f <= NF; f++) w = w s $f; print w }' | xargs)

		case $w in
			*[Cc]lear|[Ss]un*) icon=;;
			*[Pp]artly*) icon=;;
			*[Cc]loud*) icon=;;
			*[Ss]now*) icon=;;
			*[Rr]ain*) icon=;;
			*) icon=;;
		esac

		label=${w^^}
		icon="%{I-4}$icon%{I-}"

		[[ $info == s ]] && s="${s#* }"

		for i in $info; do
			weather+="${!i}\${padding}"
		done

		[[ $w ]] && format fading ${!3:-$label} "${weather%\$*}" | sed 's/[^[:print:]]\([^m]*\)m*//g';;
	Cpu)
		usage=$(top -bn 2 | awk '/%Cpu/ {print $2}' | tail -1)

		[[ $@ =~ trim ]] && style=trim

		format "%{A1:~/.orw/scripts/show_top_usage.sh cpu:}${!2-CPU}%{A}" ${usage%.*}%;;
	Ram*)
		icon=%{I-b}%{I-}

		ram=$(free | awk '/^Mem:/ { print int(100 / ($2 / ($3 + $5))) }')

		[[ $@ =~ trim ]] && style=trim

		format "%{A1:~/.orw/scripts/show_top_usage.sh mem:}${!2-RAM}%{A}" ${ram}%;;
	Disk*)
		icon=%{I-n}%{I-}

		[[ $@ =~ trim ]] && style=trim

		while read -r dev usage location; do
			unmount="~/.orw/scripts/mount.sh $dev $dev"
			disk+="$(format "%{A1:thunar $location 2> /dev/null:}%{A2:$unmount:}${!2} ${dev##*/}%{A}%{A}" $usage)"
		done <<< $(df -h | awk '/sd.[0-9]/ { usage = ($5 > 95) ? $4 : $5; print $1, usage, $NF }' | xargs -n 3)

		echo -e "${disk%\*}";;
	Usage*)
		current_usage_mode=extended

		if [[ $current_usage_mode == hidden ]]; then
			icon=%{I-n}%{I-}
			index=2
			usage_mode=extended
			button="\${$pbg}\$padding\${$pfg}${!3-SHOW}\$padding"
		else
			icon=%{I-n}%{I-}
			usage_mode=hidden
			usage="\${$sbg}\$inner"

			for item in ${2//,/ }; do
				case $item in
					c) usage+='$cpu';;
					r) usage+='$ram';;
					d) usage+='$disk';;
				esac
			done

			button="\${$sbg}\$padding\${$sfg}${!3-HIDE}\$padding"
		fi

		echo -e "%{A:sed -i '/current_usage_mode=[a-z]/ s/=.*/=$usage_mode/' $0:}$button%{A}$usage%{B-} \$separator";;
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

		read s $info <<< $(acpi | awk -F '[:, ]' '{'"$sub"' print toupper(substr($4, 1, 3)) '"$fields"'};1')

		case $s in
			#CHA) icon=%{I-}%{I-};;
			CHA) icon=%{I-b}%{I-};;
			FUL) s=FULL icon=%{I-8}%{I-} out=100%;;
			*)
				case ${#p} in
					2) icon=;;
					4) icon=;;
					*)
						case $p in
							[1-3]*) icon=;;
							[4-6]*) icon=;;
							*) icon=;;
						esac
				esac

				label=BAT
				icon=%{I-8}%{T5}$icon%{T-}%{I-};;
		esac

		[[ $s != FULL ]] && for i in $info; do
			out+="${!i}\${padding}"
		done

		format ${!3-${label:-$s}} "${out%\$*}";;
	torrents)
		icon=

		(($(pidof transmission-daemon))) && read c p b <<< $(transmission-remote -l | awk '\
			function make_progressbar(percent) {
				if(percent > 0) return gensub(/ /, "■", "g", sprintf("%*s", percent, " "))
			};
			NR == 1 { ss = index($0, "Status"); ns = index($0, "Name") } \
				{ ts = substr($0, ss, ns - ss); if(ts ~ /^Downloading/) { \
					tp += $2; ap = tp / ++c } } END { s = 5; pd = sprintf("%.0f", ap / s); pr = 100 / s - pd; \
					if(c) print c, ap "%", "${tbfg:-${pbfg:-${'$pfg'}}}" make_progressbar(pd) "${'$sfg'}" make_progressbar(pr) }' 2> /dev/null)

		for torrent_info in ${2//,/ }; do
			torrents+="${!torrent_info}\${padding}"
		done

		((c)) && format fading "%{A:~/.orw/scripts/show_torrents_info.sh:}${!3-TOR}%{A}" "${torrents%\$*}";;
	updates)
		lines=${@: -1}
		icon=%{I-4}%{I-}

		if which pacman &> /dev/null; then
			sudo pacman -Syy &> /dev/null
			updates_count=$(pacman -Qu | wc -l)
		else
			updates_count=$(apt list --upgradable 2> /dev/null | wc -l)
		fi
		
		((updates_count)) && format fading ${!2-UPD} $updates_count;;
	Temp)
		temp=$(awk '{printf("%d°C", $NF / 1000)}' /sys/class/thermal/thermal_zone*/temp)

		case $heat in
			9*) icon="";;
			[8,7]*) icon="";;
			[6,5]*) icon="";;
			[4,3]*) icon="";;
			*) icon="";;
		esac

		format "${!2-TEMP}" "$temp";;
	Logout)
		style=mono
		format "%{A:~/.orw/scripts/bar/shut_down.sh $2 &:}%{A}";;
esac
