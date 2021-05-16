#!/bin/bash

function set() {
	eval $1='${2:-${!1}}'
	escaped=$(sed 's/[\/\&]/\\&/g' <<< "${!1}")
	sed -i "s/\(^$1=\).*/\1\"$escaped\"/" $0
}

set_multiple_files() {
	if [[ ${multiple_files:-$archive_multiple} ]]; then
		[[ $option == extract_archive ]] && local var=archive_multiple || var=multiple_files
		[[ "${!var}" =~ | ]] && files="'$1'{'${!var//|/\',\'}'}" || files="'$1''${!var}'"

		[[ ! $option =~ yes|playlist ]] && end='\n\n'

		multiple_files_notification="$start\n${!var//|/\\n}$end"

		un_set $var
	fi
}

function un_set() {
	for var in "$@"; do
		unset $var
		set $var
	done
}

function back() {
	current="${current%/*}"
	set current "${current:-/}"
}

function print_options() {
	for option in ${!options[*]}; do
		echo -e "${options[option]}"
	done
}

function create_archive() {
	filename="$current/$arg"
	cd ${source_dir:-$archive}

	set_multiple_files

	notify "Adding\n<b>${multiple_files_notification:-${archive##*/}}</b>  to  <b>${filename##*/}</b>"

	shopt -s extglob
	case ${filename##*.} in
		*[bgx]z*) coproc (eval tar zcf "$filename" "${regex:-${files:-${content:-"${archive##*/}"}}}" &);;
		zip) coproc (eval zip -rqq9 "$filename" "${regex:-${files:-${content:-"${archive##*/}"}}}" &);;
		rar) coproc (eval rar a "$filename"  "${regex:-${files:-${content:-${archive##*/}}}}"-inul &);;
	esac

	un_set regex

	pid=$((COPROC_PID + 1))
	coproc (execute_on_finish "notify 'Operation finished.'" &)

	echo -e  

	un_set archive
}

function list_archive() {
	format=${current##*.}

	case $format in
		*[bgx]z*) tar tf "$current" | awk '{ if("'$selection'") s = (/^('"$(sed 's/[][\(\)\/]/\\&/g' <<< "$multiple_files")"')$/) ? " " : " "
			print s $0 }';;
		zip) nr=2 flag=-l;;
		rar) nr=7 flag=l;;
	esac

	[[ $format =~ zip|rar ]] && un$format $flag $password "$current" | awk 'NR == '$nr' { i = index($0, "Name") } \
		/[0-9]{4}-[0-9]{2}-[0-9]{2}/ {
			f = substr($0, i) 
			if("'$selection'") s = (f ~ /^('"$(sed 's/[][\(\)\/]/\\&/g' <<< "$multiple_files")"')$/) ? " " : " "
			print s f
		}'
}

function extract_archive() {
	format=${archive##*.}
	destination="$current"
	[[ $arg ]] && destination+="/$arg"

	if [[ ${regex:-$archive_single} ]]; then
		case $format in
			*[bgx]z*)
				[[ $regex ]] && var=regex || var=archive_single
				path_levels=${!var//[^\/]/}
				level_count=${#path_levels}

				[[ $archive_single =~ /$ ]] && ((level_count--))
				strip="--strip=$level_count";;
			zip) [[ $archive_single =~ /$ ]] || flag=j;;
			rar) [[ $(unrar l "$archive" | sed -n "/\s${archive_single//\//\\\/}$/ s/.*\.\([AD]\)\..*/\1/p") == D ]] && flag=x || flag=e
		esac
	fi

	notify "Extracting\n<b>${archive%/*}/${archive_single:-${archive##*/}}</b>  to  <b>$destination</b>"

	[[ $archive_multiple ]] && archive_multiple="$(sed 's/\(^\||\)[^|]*\/|/\1/g' <<< $archive_multiple)"
	set_multiple_files

	case $format in
		*[bgx]z*) coproc (eval tar xfC "$archive" "$destination" "${regex:-${files:-$archive_single}}" $strip &);;
		zip) coproc (eval unzip -qq$flag $password \"$archive\" "${regex:-${files:-$archive_single\"*\"}}" -d \"$destination\" &);;
		rar) coproc (eval unrar ${flag:-x} $password \"$archive\" \"${regex:-${files:-${archive_single:-*}}}\" \"$destination\" -inul &);;
	esac

	un_set regex

	pid=$((COPROC_PID + 1))
	coproc (execute_on_finish "notify 'Operation finished.'" &)

	echo -e  

	un_set archive archive_single password
}

check_git_files() {
	aggregate_files() {
		local field=$1
		awk -F '['\''/]' '{ if(o !~ "\\|"$'$1'"($|\\|)") o = o "|" $'$1' } END { print substr(o, 2) }'
	}

	git="$current"
	sub_dir=$(git rev-parse --show-prefix)
	sub_depth=$(wc -L <<< ${sub_dir//[^\/]/})

	staged=$(git diff --cached --name-only . | aggregate_files $((1 + sub_depth)))
	unstaged=$(git add . -n | aggregate_files $((2 + sub_depth)))

	set staged
	set unstaged
}

function add_music() {
	[[ ${current#$music_directory} ]] && music_files_directory="${current#$music_directory/}/"
	set_multiple_files "$music_files_directory"

	notify "Adding to playlist\n<b>${multiple_files_notification:-${current##*/}}</b>"

	eval mpc add "${files:-'${current#$music_directory/}'}" &
}

function notify() {
	~/.orw/scripts/notify.sh -p "$1"
}

execute_on_finish() {
	while kill -0 $pid 2> /dev/null; do
		sleep 1
	done && eval "$@"
}

[[ ${@%% *} == *[![:ascii:]]* && ${@#${@%% *}} ]] && file="${@#* }" || read option arg <<< "$@"

all=""
move=""
copy=""
sort=""
reverse=""
options=""
current=""
torrent=""
selection=""
multiple_files=""
music_directory="/home/sola/Music"
regex=""

git=""
staged=""
unstaged=""

list=""
archive=""
password=""
archive_single=""
archive_multiple=""

bookmarks=${0%/*}/bookmarks

[[ $options ]] && back_icon= || back_icon=
back_icon=
echo -e $back_icon

#~/.orw/scripts/notify.sh "o: $back_icon $options"

if [[ -z $@ ]]; then
	set current "$HOME"
elif [[ $file ]]; then
	toggle_file() {
		if [[ "${!1}" =~ \|"$file"$ ]]; then local toggle_file="|$file"
		elif [[ "${!1}" == "$file" ]]; then local toggle_file="$file"
		else local toggle_file="$file|"; fi

		eval "$1=\${$1//"$toggle_file"}"
		set $1
	}

	if [[ $git ]]; then
		cd "$current"

		if [[ "$unstaged" =~ (^|\|)"$file"(\||$) ]]; then
			toggle_file unstaged

			((${#staged})) && staged+="|$file" || staged="$file"
			set staged

			git add -A "$file"
		else
			toggle_file staged

			((${#unstaged})) && unstaged+="|$file" || unstaged="$file"
			set unstaged

			commit_count=$(git rev-list --all --count)
			((commit_count)) && command='restore --staged' || command='rm --cached'

			git $command "$file" --quiet
		fi
	else
		if [[ $selection ]]; then
			[[ ${file: -1} == / ]] &&
				file=$(list_archive | awk '/ '${file//\//\\/}'/ { sub("^[^ ]* ", "|"); f = f $0 } END { print substr(f, 2) }')

			if [[ "$multiple_files" =~ "$file" ]]; then
				toggle_file multiple_files
			else
				((${#multiple_files})) && multiple_files+="|$file" || multiple_files="$file"
			fi

			set multiple_files
		else
			set current "$current/$file"
		fi
	fi
fi

if [[ ${option% *} ]]; then
	[[ $selection && $option =~ ^[a-z] && ! $option =~ selection|_all$ ]] && un_set selection

	case "$option" in
		$back_icon)
			if [[ $options ]]; then
				[[ $options =~ ^options|bookmarks || $list ]] && un_set options || set options options
			elif [[ "$archive" && -f "$current" && "$archive" == "$current" ]]; then
				if [[ $list ]]; then
					un_set list

					if [[ $multiple_files ]]; then
						set archive_multiple "$multiple_files"
						un_set selection multiple_files
					fi
				else
					un_set list archive password
				fi
			else
				back
			fi;;
		sort)
			set options sub_options
			echo -e 'by_date\nby_size\nby_type\nreverse\nalphabetically';;
		git)
			set options sub_options
			echo -e 'show\nhide';;
		remove)
			set options sub_options
			echo -e 'yes\nno';;
		selection)
			set options sub_options
			echo -e 'enable\ndisable\nselect_all\ndiscard_all';;
		hidden) [[ $hidden ]] && un_set hidden || set hidden '-a';;
		password) [[ ${current##*.} == zip ]] && set password "-P ${@#* }" || set password "-p${@#* }";;
		list_archive)
			set list true
			set archive "$current"

			echo 'selection'
			echo '━━━━━━━━━'
			list_archive;;
		slide_images)
			killall rofi
			feh "$current";;
		mount)
			lsblk -lpo +model | awk '{
				if($1 ~ /sd.$/ && $7) {
					m=""
					for(f = 7; f <= NF; f++) m = m $f " "
					}
				if($6 == "part" && $4 ~ /[0-9]G/ && $7 !~ /^\//) printf("%-45s %-20s %s\n", m, $4, $1)}'

			exit;;
		edit_text)
			killall rofi
			set_multiple_files "$current/"
			termite -e "bash -c \"nvim -p ${files:-${regex:-'$current'}}\"" &
			un_set regex;;
		open_in_terminal)
			killall rofi
			termite -e "bash -c \"cd '$current'\";bash"
			exit;;
		) set options options;;
		 );;
		 );;
		 );;
		 )
			awk '{ print $1 }' $bookmarks
			set options bookmarks;;
		 )
			killall rofi

			if [[ ! $file ]]; then
				set_multiple_files "$current/"

				if [[ $files ]]; then
					thunar &
					sleep 0.1

					for directory in $(eval echo $files); do
						((tab)) && xdotool key ctrl+t
						xdotool key ctrl+l
						xdotool type -delay 0 "$directory"
						xdotool key Return

						((tab++))
					done
				else
					#thunar "$current"
					~/.orw/scripts/vifm.sh -i "$current"
				fi
			fi;;
		xdg-open)
			killall rofi
			[[ $(file --mime-type -b "$current") =~ "image" ]] && ~/.orw/scripts/open_multiple_images.sh "$current" ||
				xdg-open "$current"

			un_set options;;
		view_all_images)
			killall rofi

			set_multiple_files "$current/"

			~/.orw/scripts/sxiv_wrapper.sh "${files:-${regex:-'$current'/*}}"

			un_set options regex
			exit;;
		*)
			back=true
			[[ $options =~ options ]] && un_set options

			case $option in
				show)
					cd "$current"
					check_git_files
					set git;;
				hide)
					set current "$git"
					un_set git un{staged,};;
				commit)
					cd $git
					git commit -m "${arg//\"/}" --quiet 
					check_git_files;;
				all) [[ $all ]] && un_set all || set all '-a';;
				yes)
					set_multiple_files "$current/"

					notify "Removing\n<b>${multiple_files_notification:-${current##*/}}</b>"

					if [[ $regex || $files ]]; then
						unset back
					else
						[[ -d $current ]] && current_directory=${current%/*}
					fi

					eval rm -rf "${files:-${regex:-'$current'}}" &
					un_set regex

					[[ $current_directory ]] && set current $current_directory;;
				no) ;;
				move) set move "$current";;
				copy) set copy "$current";;
				paste)
					destination="$current"
					[[ $arg ]] && destination+="/$arg"

					file="${move:-$copy}"

					set_multiple_files "$file/"

					if [[ $move ]]; then
						operation=Move
						command='mv'
						un_set move
					else
						operation=Copy
						command='cp -r'
					fi

					coproc (eval $command "${files:-${regex:-'$file'}}" "'$destination'" &)
					un_set regex
					pid=$((COPROC_PID + 1))
					coproc (execute_on_finish "notify 'Operation finished.'" &)

					echo -e  ;;
				add_to_bookmarks) echo "${arg:-${current##*/}} $current" >> $bookmarks;;
				by_*|reverse|alpha*)
					case ${option#*_} in
						size) sort='-S';;
						date) sort='-t';;
						type) sort='-X';;
						reverse) [[ $reverse ]] && un_set reverse || set reverse '-r';;
						*) sort='';;
					esac

					set sort "$sort"
					set options options;;
				select_all)
					unset selection

					[[ $list ]] && command='list_archive' || command='ls -1 "$current"'

					set multiple_files "$(eval $command | tr '\n' '|' | head -c -1)"
					set selection "enabled";;
				discard_all) un_set multiple_files;;
				enable) set selection "enabled";;
				disable)
					un_set selection multiple_files archive_multiple

					if [[ $list ]]; then
						echo 'selection'
						echo '━━━━━━━━━'
						list_archive

						unset back
					fi;;
				*torrent*)
					[[ -d $current ]] && torrent_directory="$current" || set torrent "$current"
					[[ $option =~ ^(add_torrent|select_torrent_content)$ ]] && torrent_state="--start-paused"

					if [[ ! $option =~ destination ]]; then
						pidof transmission-daemon &> /dev/null || coproc (transmission-daemon &)

						command="transmission-remote -a ${regex:-\"$torrent\"} "
						command+="-w '${torrent_directory-$HOME/Downloads/}' $torrent_state &> /dev/null"
						coproc (execute_on_finish "sleep 0.5 && $command" &)

						notify "Adding torrent\n${torrent:-$current}"

						un_set regex torrent
					fi

					if [[ $option == select_torrent_content ]]; then
						killall rofi

						command="~/.orw/scripts/rofi_scripts/select_torrent_content_with_size.sh set_torrent_id"
						command+="&& ~/.orw/scripts/rofi_scripts/torrents_group.sh select_torrent_content"
						coproc (execute_on_finish "sleep 0.5 && $command" &)
						exit
					fi;;
				extract_archive) [[ -d "$current" && $archive ]] && $option || set archive "$current";;
				*to_archive)
					if [[ -d "$current" && $archive ]]; then
						[[ $option =~ directory ]] && source_dir="${archive%/*}" || content='{.,}[[:alnum:]]*'
						create_archive
					else
						[[ -d $current ]] && archive="$current" || archive="${current%/*}"
						set archive
					fi;;
				create_directory)
					set current "$current/$arg"
					mkdir "$current";;
				add_to_playlist) add_music;;
				*_wallpaper_directory)
					[[ ! $option =~ ^set ]] &&
						flag=M modify=${option%%_*}

					#if [[ $option =~ ^set ]]; then
					#	flag=d
					#else
					#	flag=M
					#	modify=${option%%_*}
					#fi

					set_multiple_files "$current/"
					[[ $files ]] && files="${files//\'/}"

					~/.orw/scripts/wallctl.sh -${flag:-d} $modify "${files:-$current}";;
				set_as_wallpaper)
					set_multiple_files "$current/"
					eval ~/.orw/scripts/wallctl.sh -s "${files:-'$current'}";;
				*)
					if [[ $options == bookmarks ]]; then
						current=$(awk '/^'$option' / { print gensub("^\\w* ", "", 1) }' $bookmarks)

						un_set options
						set current
					else
						if [[ "${@##* }" =~ ^/dev/sd.[0-9] ]]; then
							~/.orw/scripts/mount.sh "${@##* }" "${@%% *}" "$current"
						elif [[ $archive ]]; then
							[[ $(list_archive | grep "^$@$") ]] &&
								set archive_single "$@" || set regex "--wildcards $@"
							un_set list
						else
							set regex "'$current'/$@"
							set options options
							unset back
						fi
					fi
			esac
	esac
fi

if [[ $list && $selection && ! $options ]]; then
	echo 'selection'
	echo '━━━━━━━━━'
	list_archive
fi

if [[ $options == options ]]; then
	options=( 'all' 'sort' 'copy' 'move' )

	[[ $move || $copy ]] && options+=( 'paste' )

	options+=( 'remove' 'mount' 'selection' 'add_to_bookmarks' 'add_content_to_archive' 'add_directory_to_archive' )

	[[ "$archive" || "$archive_multiple" ]] && options+=( 'extract_archive' )
	[[ "$torrent" ]] && options+=( 'add_torrent' 'start_torrent' 'select_torrent_content' )

	[[ $multiple_files ]] && options+=( 'set_as_wallpaper' 'edit_text' )
	[[ ! $music_directory ]] && set music_directory "$(sed -n 's/^music_directory.*\"\(.*\)\/\?\"/\1/p' ~/.mpd/mpd.conf)"
	[[ "$current" =~ "$music_directory" ]] && options+=( 'add_to_playlist' )
	options+=( 'set_as_wallpaper_directory' 'add_wallpaper_directory' 'remove_wallpaper_directory' 'view_all_images' 'open_in_terminal' )

	options+=( 'create_directory' )

	cd "$current"
	repo=$(git status -sb | wc -l)
	[[ $git ]] && options+=( 'commit' )
	[[ $git ]] || ((repo)) && options+=( 'git' )
fi

if [[ ! -d "$current" && ! $selection && ! $git ]]; then
	if [[ $back == true ]]; then
		back
	else
		if [[ ! $list && ! $option == remove && ! $git ]]; then
			options+=( 'move' 'copy' 'remove' 'xdg-open' )
			mime=$(file --mime-type -b "$current")

			case $mime in
				*torrent)
					options+=( 'add_torrent' 'start_torrent' 'select_torrent_destination' 'select_torrent_content' );;
				*tar|*[bgx]z|*zip*|*rar) options+=( 'password' 'list_archive' 'extract_archive' );;
				*image*) options+=( 'set_as_wallpaper' );;
				*audio*) options+=( 'add_to_playlist' );;
				*text*) options+=( 'edit_text' );;
			esac
		fi
	fi
fi

if ((${#options[*]} > 1)); then
	print_options | awk '!options[$0]++'
else
	[[ ! -f "$current" && ! -d "$current" ]] && back
fi

if [[ -d "$current" && ! $options ]]; then
	echo -e 
	echo -e 
	echo -e 

	if [[ $git ]]; then
		print_git_files() {
			[[ $1 =~ ^un ]] && local icon= || local icon=

			for file in ${!1//|/ }; do
				[[ $1 == staged && "$unstaged" =~ (^|\|)"$file"(\||$) ]] || echo $icon $file
			done
		}

		print_git_files staged
		print_git_files unstaged
	else
		while read -r s file; do
			if [[ $file ]]; then
				if [[ $selection ]]; then
					((s)) && icon= || icon=
				else
					if [[ -d "$current/$file" ]]; then
						icon=
					else
						#icon=
						icon=
					fi
				fi

				echo -e "$icon $file"
			fi
		done <<< "$(ls $sort $reverse $all --group-directories-first "$current" | awk '!/\.$/ \
			{ print (length("'$selection'") && /^('"$(sed 's/[][\(\)\/]/\\&/g' <<< "$multiple_files")"')$/), $0 }')"
	fi
fi
