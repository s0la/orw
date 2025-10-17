#!/bin/bash

print_matrix() {
	for row in $(seq 1 ${1:-9}); do
		echo ${matrix[$row]}
	done
}

get_remaining() {
	remaining=( $(awk '
		NR == FNR {
			v = $0
			x = '$x'; y = '$y'
			sxs = int((x - 1) / 3) * 3 + 1; sxe = sxs + 3
			sys = int((y - 1) / 3) * 3 + 1; sye = sys + 3
		}

		NR > FNR {
			if (FNR >= sys && FNR < sye) {
				for (f=sxs; f<sxe; f++) if ($f) i = i "|" $f
			} else if ($x) i = i "|" $x
		}

		END {
			for (f=1; f<sxs; f++) i = i "|" $f
			gsub(substr(i, 2), "", v)
			print v
		}' <(echo {1..9}) <(print_matrix $y)) )
	((${#remaining[*]})) &&
		value="${remaining[RANDOM % ${#remaining[*]}]}" || value=0
}

generate_matrix() {
	declare -A matrix
	for y in {1..9}; do
		until
			for x in {1..9}; do
				get_remaining
				((value)) &&
					matrix[$y]+="$value " || break
			done

			((value))
		do
			matrix[$y]=""
		done
	done
	print_matrix $y
}

color_matrix() {
	awk '
		BEGIN {
			b = "\033[38;2;66;66;66m"
			d = "\033[0m"
			vs = b "|" d

			c = '$columns'
			hs = sprintf("%*s", c, "-")
			gsub(" ", "-", hs)

			p = '$padding'
			sl = (2 * p + 1) * 3
			es = sprintf("%*s", sl, " ")
			er = vs es vs es vs es vs
		}

		NR == FNR { hf[$1][$2] = $3 }

		NR > FNR {
			if (!((FNR - 1) % 3)) print b hs d
			for (f=1; f<=NF; f++) {
				if (!((f - 1) % 3)) printf vs
				printf "%*s%s%*s", p, " ", ((hf[FNR][f]) ? " " : $f), p, " "
			}
			print vs "\n" er
		} END { print b hs d }' $@
}

while getopts :p:h:d: opt; do
	case $opt in
		p) padding=$OPTARG;;
		h) hidden_fields_count=$OPTARG;;
		d)
			case ${OPTARG,} in
				e*)
					difficulty=easy
					hidden_fields_count=25
					;;
				m*)
					difficulty=medium
					hidden_fields_count=33
					;;
				h*)
					difficulty=hard
					hidden_fields_count=42
					;;
			esac
	esac
done

correct_color=cyan
incorrect_color=red

read {,in}correct <<< $(awk --non-decimal-data -F '"' '
	function hex_to_rgb(h) {
		rgb = ""
		for (i=0; i<3; i++) rgb = rgb ";" sprintf("%d", "0x" substr(h, i * 2 + 2, 2))
		return substr(rgb, 2)
	}

	/bright/ || (b && /^$/) { b = !b }
	b && /'"$correct_color"'/ { c = hex_to_rgb($(NF - 1)) }
	b && /'"$incorrect_color"'/ { ic = hex_to_rgb($(NF - 1)) }
	END { print c, ic }' ~/.config/alacritty/alacritty.toml)

#read {,in}correct <<< $(sed -n 's/^\s*\(gd\|i\)c.*"\(.*\);.*/\2/p' ~/.bashrc | xargs)
#[[ $incorrect ]] || incorrect='255;0;0'
#[[ $correct ]] || correct='0;255;0'

tput sc

while
	tput el1
	tput rc
	echo -n "generating matrix, attempt $((++attempt))"
	exec 3< <(generate_matrix)
	pid=$!
	sleep 2
	generating_pid=$(ps -p $pid -o pid=)
	((generating_pid))
do
	unset matrix
	kill $pid
done

tput el1
echo
#tput rc

IFS=';' read -sdR -p $'\E[6n' current_{row,column}
base_row=$((${current_row#*\[} - 2))

column=1
declare -A matrix
while read row; do
	matrix[$((column++))]="$row"
done <&3
exec 3>&-

((padding)) || padding=$((($(tput cols) - 13) / 9 / 2))
hidden_counts=( $(printf '0%.s ' {1..10}) )
columns=$((13 + 2 * 9 * padding))
rows=$(tput lines)

((hidden_fields_count)) || hidden_fields_count=30

while
	while
		row=$((RANDOM % 9 + 1))
		column=$((RANDOM % 9 + 1))
		field="$row,$column"
		value=$(cut -d ' ' -f $column <<< ${matrix[$row]})
		#echo $row - $column - $value: ${hidden_counts[$value]}
		#[[ "${hidden[*]}" =~ (^| )$field|$field( |$) || ${hidden_counts[$value]} -ge 5 ]]
		#[[ "${hidden[*]}" =~ (^| )$field|$field( |$) || ${hidden_counts[*]} =~ ^0\ (([1-5]\ )*[6-9](\ ?[1-5]\ ?)*){3}$ ]]
		#[[ "${hidden[*]}" =~ (^| )$field|$field( |$) || ${hidden_counts[*]} =~ (.*[6-9].*){3} ]]
		#[[ ${hidden_counts[*]} =~ (.*[6-9].*){3} ]]
		#echo $value: $field - $?: ${BASH_REMATCH[*]}
		((hidden_counts[$value]++))
		#[[ "${hidden[*]}" =~ (^| )$field|$field( |$) || ${hidden_counts[*]} =~ (.*[6-9].*){3} ]]
		[[ "${hidden[*]}" =~ (^| )$field|$field( |$) || ${hidden_counts[*]} =~ (.*[6-9].*){3} ]]
		#[[ "${hidden[*]}" =~ (^| )$field|$field( |$) &&
		#	(${hidden_counts[*]:1} =~ (([1-6]\ ?)*[78](\ ?[1-6]\ ?)*){2} &&
		#	"${BASH_REMATCH[0]}" != "${hidden_counts[*]:1}") ]]
	do
		((hidden_counts[$value]--))
		#continue
	done

	((${#hidden[*]} < hidden_fields_count))
do
	#echo adding $field, ${hidden_counts[$value]}
	#((hidden_counts[$value]++))
	#[[ ${hidden[*]} =~ (^| )$field|$field( |$) ]] && echo $field
	hidden+=( $field )
	#echo ${!hidden_counts[*]}
	#echo ${hidden_counts[*]}
	#sleep 0.1
done

#echo ${hidden[*]}

#echo ${!hidden_counts[*]}
#echo ${#hidden[*]}: ${hidden_counts[*]}
#echo ${#hidden[*]}
#exit

trap "tput cup $((base_row + 24)) 0 && exit" EXIT SIGINT

color_matrix \
	<(
		for value in ${hidden[*]}; do
			[[ "${guessed[*]}" =~ (^| )$value|$value( |$) ]]
			echo ${value/,/ } $?
		done
	) <(print_matrix)

#tput cup $base_row 0
tput rc
echo -n "DIFFICULTY: $difficulty, SCORE: "
tput sc

#tput el
#echo -n "${#hidden[*]}: ${hidden_counts[*]} - DIFFICULTY: $difficulty, SCORE: "
#echo -n "DIFFICULTY: $difficulty, SCORE: "

#tput sc
#tput cup 3 $((padding + 1))

start_time=$(date +'%s')
row=1 column=1

while ((${#guessed[*]} < ${#hidden[*]} && mistakes < 3)); do
	read -rsn 1 key

	case $key in
		l) column=$((column % 9 + 1));;
		h) column=$(((column + 9 - 2) % 9 + 1));;
		j) row=$((row % 9 + 1));;
		k) row=$(((row + 9 - 2) % 9 + 1));;
		*)
			value=$key
			hidden_value=$(cut -d ' ' -f $column <<< "${matrix[$row]}")
			guess=$((hidden_value == value))
			((guess)) &&
				guessed+=( value ) || ((mistakes++))

			((guess)) &&
				color="$correct" || color="$incorrect"
			echo -ne "\033[38;2;${color}m$value\033[0m"

			((score += 10 * ${#guessed[*]}))

			tput rc
			tput el

			echo -n "$score"
			tput cup $y $x
			continue
	esac

	x=$((padding + ((column - 1) * (padding * 2 + 1)) + ((column - 1) / 3) + 1))
	y=$((base_row + row * 2 + (row - 1) / 3))

	tput cup $((y)) $x
done

end_time=$(date +'%s')
tput cup 23 0

((mistakes < 3)) &&
	echo "CONGRADULATION, YOU WON! :)" ||
	echo "YOU LOST - MORE LUCK, NEXT TIME :/"

total_score=$(bc -l <<< "scale=0; ($score * (100 - (($end_time - $start_time) / 60))) / 1")
echo "TOTAL SCORE: $total_score"
tput sc

exit

while
	until
		tput rc
		read -p 'enter row, column and value: ' row column value
		((row && column && value))
	do
		tput cuu1
		tput el1
		tput sc
		echo -ne "\033[38;2;${incorrect}mmissing correct value, try again!\033[0m"
		sleep 1
		tput el1
	done

	x=$((padding + ((column - 1) * (padding * 2 + 1)) + ((column - 1) / 3) + 1))
	y=$((row * 2 + (row - 1) / 3))

	hidden_value=$(cut -d ' ' -f $column <<< "${matrix[$row]}")
	guess=$((hidden_value == value))
	((guess)) &&
		guessed+=( value ) || ((mistakes++))

	tput cup $y $x
	((guess)) &&
		color="$correct" || color="$incorrect"
	echo -ne "\033[38;2;${color}m$value\033[0m"
	tput rc
	tput el

	((${#guessed[*]} < ${#hidden[*]} && mistakes < 3))
do
	continue
done

((mistakes < 3)) &&
	echo "CONGRADULATION, YOU WON! :)" ||
	echo "YOU LOST - MORE LUCK, NEXT TIME :/"
