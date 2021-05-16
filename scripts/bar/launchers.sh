#!/bin/bash

padding=$2
separator="$3"
lines=${@: -1}
offset=$padding

launchers_directory=~/.config/orw/bar/launchers
launchers_file=$launchers_directory/$1

current_desktop=$(xdotool get_desktop)
current_id=$(printf "0x%.8x" $(xdotool getactivewindow 2> /dev/null))

[[ ! -d $launchers_directory ]] && mkdir $launchers_directory
[[ ! -f $launchers_file ]] && cp ~/.orw/scripts/bar/launchers $launchers_file

mouse_action() {
	local name="$1" action="$2"
	#~/.orw/scripts/notify.sh "n: $name"

	#~/.orw/scripts/notify.sh "a: $action"

	read count position ids <<< $(wmctrl -l | awk '\
		BEGIN { c = 0 }
		$NF != "input" && /'"$name"'[0-9]+?/ {
			if($1 == "'$current_id'") p = c
			ids = ids " " $1
			c++
		} END { print c, p, ids }')

	if ((count)); then
		ids=( $ids )

		if [[ $action == left ]]; then
			[[ ${ids[position]} == $current_id ]] &&
				#~/.orw/scripts/notify.sh "n: $name"
				command="xdotool getactivewindow windowminimize" ||
				command="wmctrl -a $name"
		elif [[ $action == middle ]]; then
			command="wmctrl -ic ${ids[position]}"
		else
			if ((count > 1)); then
				if [[ $action =~ up|down ]]; then
					[[ $action == down ]] &&
						index=$(((position + 1) % count)) ||
						index=$(((position + count - 1) % count))
					command="wmctrl -ia ${ids[index]}"
				fi
			fi
		fi
	fi

	#~/.orw/scripts/notify.sh "com: $3"
	eval "${command:-$3}"
	#echo "${command:-$3}" >> ~/Desktop/ls
	exit

					#local next_index=$(((position + 1) % count))
					#local previous_index=$(((position + count - 1) % count))

					#local down="wmctrl -ia ${ids[next_index]}"
					#local up="wmctrl -ia ${ids[previous_index]}"
	#			fi
	#		else
	#			local current=s
	#		fi
	#	fi
	#fi

}

if [[ $1 == mouse_action ]]; then
	#$@
	#all="$@"
	#~/.orw/scripts/notify.sh "c: $4"
	mouse_action "${@:2}"
	#eval "$all"
	exit
	#eval mouse_action "$@"
else
	if (($# > 4)); then
		for argument in ${4//,/ }; do
			if [[ $argument == a ]]; then
				active=true
			else
				value=${argument:1}
				property=${argument:0:1}

				[[ $5 == true ]] && separator_color='%{B${Lfc:-$fc}}'
				#~/.orw/scripts/notify.sh "sc: $5"

				if [[ $property == s ]]; then
					#~/.orw/scripts/notify.sh "sc: $value"
					#launcher_separator="${separator_color:-\$bsbg}%{O$value}"

					#launcher_separator="${separator_color:-\$Lsc}%{O$value}"
					#[[ $value == s ]] && separator_value=\$separator || separator_value="%{O$value}"
					#((value)) && separator_value="%{O$value}" || separator_value=\$separator
					((value)) && separator_value="%{O$value}" ||
						separator_value="%{O\${separator##*O}"
					launcher_separator="${separator_color:-%{B\$Lsc:-\$bg}}$separator_value"

					#~/.orw/scripts/notify.sh "sc: $launcher_separator"
				elif [[ $property == p ]]; then
					module_padding=true
				else
					if [[ $value =~ [0-9] ]]; then
						offset="%{O$value}"
					else
						[[ $value == p ]] && offset=$padding || offset='${inner}'
					fi
				fi
			fi
		done
	fi
fi

function set_line() {
	fc="\${Lfc:-\$fc}"
	frame_width="%{O\${Lfw:-\${frame_width-0}}\}"

	if [[ $lines == [ou] ]]; then
		left_frame="%{+$lines}" right_frame="%{-$lines}"
	else
		frame="%{B$fc\}$frame_width"
		left_frame="%{+u\}%{+o\}$frame"
		remove_frame="%{-o\}%{-u\}"
		right_frame="$frame$remove_frame"
	fi
}

[[ $lines != false ]] && set_line

make_launcher() {
	local count position ids commands closing

	#read count position ids <<< $(wmctrl -l | awk '\
	#	BEGIN { c = 0 }
	#	$NF != "input" && /'"$name"'[0-9]+?/ {
	#		if($1 == "'$current_id'") p = c
	#		ids = ids " " $1
	#		c++
	#	} END { print c, p, ids }')

	#if [[ $name =~ ^bar ]]; then
	#	current=$(ps aux | awk '{ b = (/-n '${name#*_}'$/); if(b) exit } END { print b ? "p" : "s" }')
	#else
	#	if [[ $up && $down ]]; then
	#		local current=s
	#	else
	#		if ((count)); then
	#			ids=( $ids )
	#			local current=p

	#			[[ ${ids[position]} == $current_id ]] &&
	#				local toggle="xdotool getactivewindow windowminimize" ||
	#				local focus="wmctrl -a $name"

	#			if ((count > 1)); then
	#				local next_index=$(((position + 1) % count))
	#				local previous_index=$(((position + count - 1) % count))

	#				local down="wmctrl -ia ${ids[next_index]}"
	#				local up="wmctrl -ia ${ids[previous_index]}"
	#			fi
	#		else
	#			local current=s
	#		fi
	#	fi
	#fi

	error='\&\> \/dev\/null \&'
	[[ $right ]] || right="$left $error"
	left="$0 mouse_action \'$name\' left \'$left $error\'"
	[[ $middle ]] || middle="$0 mouse_action \'$name\' middle"
	[[ $up ]] || up="$0 mouse_action \'$name\' up"
	[[ $down ]] || down="$0 mouse_action \'$name\' down"

	#left="${toggle:-${focus:-$left $error}}"
	#[[ $right ]] || right="$left $error"
	#[[ $middle ]] || middle="wmctrl -ic ${ids[position]}"

	[[ $left ]] && commands+="%{A1:$left:}" && closing+="%{A}"
	[[ $middle ]] && commands+="%{A2:$middle:}" && closing+="%{A}"
	[[ $right ]] && commands+="%{A3:$right:}" && closing+="%{A}"
	[[ $up ]] && commands+="%{A4:$up:}" && closing+="%{A}"
	[[ $down ]] && commands+="%{A5:$down:}" && closing+="%{A}"
	#[[ $up ]] && commands+="%{A4:$up:}" && closing+="%{A}"
	#[[ $down ]] && commands+="%{A5:$down:}" && closing+="%{A}"

	if [[ $active ]]; then
		[[ ! $name =~ bar ]] &&
			current_name="$name[0-9]+?" current_command="wmctrl -l" ||
			current_name="${name#*_}" current_command="ps -C lemonbar -o args="

		current=$(eval "$current_command" | awk '{
				r = $NF ~ "'"$current_name"'"
				if(r) exit
			} END { print r ? "p" : "s" }')

			#current=$(wmctrl -l | awk '{ r = $NF ~ "'"$name"'[0-9]+"; if(r) exit } END { print r ? 
			#current=$(ps -C lemonbar -o args= | awk '{ r = $NF ~= "'${name#*_}'"; if(r) exit } END { print r ? "s" : "p" }')
	else
		current=s
	fi

	bg="\${L${current}bg:-\${Lsbg:-\$${current}bg}}"
	fg="\${L${current}fg:-\${Lsfg:-\$${current}fg}}"

	#commands="%{A:if ! wmctrl -a "$name"; then $left; fi:A}"
	launcher="$commands$bg$fg$offset$icon$offset$closing"
	#echo "$commands" >> ~/Desktop/ls

	#if [[ $lines == single ]]; then
	#	if [[ $current == p ]]; then
	#		[[ ! $separator =~ ^[s%] ]] && launcher="\$start_line$launcher\$end_line" ||
	#			launcher="%{U$fc}\${start_line:-$left_frame}$launcher\${end_line:-$right_frame}"
	#	else
	#		launcher="%{-o}%{-u}$launcher"
	#	fi
	#fi

	#if [[ $lines == single ]]; then
	if [[ $lines == single && $current == p ]]; then
		#~/.orw/scripts/notify.sh "s: $separator"
		#[[ $separator =~ ^% && $current == p ]] &&
			launcher="%{U$fc}\${start_line:-$left_frame}$launcher\${end_line:-$right_frame}"
	fi

	unset right middle up down
}

while read launcher_properties; do
		eval ${launcher_properties//\&/\\&}
		make_launcher
		launchers+="$launcher$launcher_separator"
done <<< $(awk '{ if(/^$/) {
						if(l) al[++i] = l; l = ""
					} else { if(!/^#/) l = l " " $0 }
					} END { for(li in al) print al[li]; print l }' $launchers_file)

#echo "$launchers" > ~/Desktop/ls

#[[ $launcher_separator ]] && ~/.orw/scripts/notify.sh "le: ${launchers##*%}"
[[ $launcher_separator ]] && launchers="${launchers%\%*}\${Lsbg:-\$sbg}"
[[ $module_padding ]] && launchers="\${Lsbg:-\$sbg}$padding$launchers$padding"
#[[ $separator =~ ^% ]] && launchers="$remove_frame$launchers"
	#~/.orw/scripts/notify.sh "s: $separator"

#if [[ $launchers && $lines == true ]]; then
#if [[ $lines != false ]]; then
#[[ $lines == single && $separator =~ ^% ]] && ~/.orw/scripts/notify.sh here
if [[ $lines == false || ($lines == single && $separator =~ ^% ) ]]; then
	#~/.orw/scripts/notify.sh here
	launchers+="%{B\$bg}$separator"
else
	#~/.orw/scripts/notify.sh "s: $separator"
	case $separator in
		[ej]*)
			[[ $separator =~ j ]] &&
				launchers+='$start_line'
			launchers+="${separator:1}";;
		s*) launchers="%{U$fc}\${start_line:-$left_frame}$launchers\$start_line${separator:2}\$start_line";;
		#e*) launchers+="\${end_line:-$right_frame}%{B\$bg}${separator:1}";;
		#e*) launchers+="${separator:1}";;
		#*) [[ $lines == true ]] &&
		*) [[ $lines == a ]] &&
			launchers="%{U$fc}\${start_line:-$left_frame}$launchers\${end_line:-$right_frame}%{B\$bg}$separator";;
			#launchers="%{U$fc}\${start_line:-$left_frame}$launchers\${end_line:-$right_frame}%{B\$bg}$separator" || launchers+="%{B\$bg}$separator";;
	esac
fi

#	esac
#
#	#launchers="%{U$fc}\${start_line:-$left_frame}$launchers\${end_line:-$right_frame}"
#else
#	#~/.orw/scripts/notify.sh here
#	launchers+="%{B\$bg}$separator"
#fi

#~/.orw/scripts/notify.sh "s: $1 $separator"

#[[ $launchers ]] && echo -e "$launchers%{B\$bg}$separator"
echo -e "$launchers"
