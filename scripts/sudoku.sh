#!/bin/bash

get_ignored() {
	print_matrix | awk '
		BEGIN {
			x = '$x'
			a = "'"${indices[*]}"'"
		} { i = i "|" $x - 1 }

		END {
			for (r=1; r<x; r++) i = i "|" $r - 1
			gsub(substr(i, 2), "", a)
			print a
		}'
}

print_matrix() {
	for row in $(seq 1 ${1:-9}); do
		echo ${matrix[$row]}
	done
}

get_remaining() {
	local ignore=$(print_matrix $y | awk '
		BEGIN {
			x = '$x'
			y = '$y'
			sxs = int((x - 1) / 3) * 3 + 1; sxe = sxs + 3
			sys = int((y - 1) / 3) * 3 + 1; sye = sys + 3
		}

		{
			if (NR >= sys && NR < sye) {
				for (f=sxs; f<sxe; f++) if ($f) i = i "|" $f
			} else if ($x) i = i "|" $x
		}

		END {
			for (f=1; f<sxs; f++) i = i "|" $f
			print (i) ? substr(i, 2) : 0
		}')
	remaining=( $(sed "s/${ignore//\|/\\|}//g" <<< $(echo {1..9})) )
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
	print_matrix
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
				printf "%*s%s%*s", p, " ", (($f in hf[FNR]) ? " " : $f), p, " "
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
				e*) hidden_fields_count=20;;
				m*) hidden_fields_count=35;;
				h*) hidden_fields_count=45;;
			esac
	esac
done

((padding)) || padding=$((($(tput cols) - 13) / 9 / 2))
columns=$((13 + 2 * 9 * padding))
rows=$(tput lines)

((hidden_fields_count)) || hidden_fields_count=30

while
	while
		row=$((RANDOM % 9 + 1))
		column=$((RANDOM % 9 + 1))
		value="$row,$column"
		[[ "${hidden[*]}" =~ (^| )$value|$value( |$) ]]
	do
		continue
	done

	((${#hidden[*]} < hidden_fields_count))
do
	hidden+=( $value )
done

read {,in}correct <<< $(sed -n 's/^\s*\(gd\|i\)c.*"\(.*\);.*/\2/p' ~/.bashrc | xargs)

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
done

tput el1
tput rc

column=1
declare -A matrix
while read row; do
	matrix[$((column++))]="$row"
done <&3
exec 3>&-

color_matrix \
	<(
		for value in ${hidden[*]}; do
			[[ "${guessed[*]}" =~ (^| )$value|$value( |$) ]]
			echo ${value/,/ } $?
		done
	) <(print_matrix)

tput sc
tput cup 0 0
tput el
tput rc

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
