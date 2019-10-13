#!/bin/bash

function set() {
	eval $1='${2:-${!1}}'
	escaped=$(echo "${!1}" | sed 's/[\/\&]/\\&/g')
	sed -i "s/\(^$1=\).*/\1\"$escaped\"/" $0
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
	notify "${source_dir:-$archive}"
	filename="$current/$arg"
	cd ${source_dir:-$archive}

	notify "creating file\n<b>$filename</b>"

	shopt -s extglob
	case ${filename##*.} in
		*[bgx]z*) eval tar zcf "$filename" ${content:-"${archive##*/}"};;
		zip) eval zip -rqq9 "$filename" ${content:-"${archive##*/}"};;
		rar) eval rar a "$filename"  "${content:-${archive##*/}}"-inul;;
	esac

	un_set archive
}

function list_archive() {
	format=${current##*.}
	case $format in
		*[bgx]z*) tar tf "$current";;
		zip) column=4 flag=-l;;
		rar) column=5 flag=l;;
	esac

	[[ $format =~ zip|rar ]] && un$format $flag $password "$current" | awk '/[0-9]{4}-[0-9]{2}-[0-9]{2}/ \
		{ file=""; for(c='$column'; c<NF; c++) file=file$c" "; print file$c}'
}

function extract_archive() {
	format=${archive##*.}
	destination="$current"
	[[ $arg ]] && destination+="/$arg"

	if [[ $archive_single ]]; then
		case $format in
			*[bgx]z*)
				path_levels=${archive_single//[^\/]/}
				level_count=${#path_levels}

				[[ $archive_single =~ /$ ]] && ((level_count--))
				strip="--strip=$level_count";;
			zip) [[ $archive_single =~ /$ ]] || flag=j;;
			rar) [[ $(unrar l "$archive" | sed -n "/\s${archive_single//\//\\\/}$/ s/.*\.\([AD]\)\..*/\1/p") == D ]] && flag=x || flag=e
		esac
	fi

	notify "extracting file\n<b>${archive%/*}/${archive_single:-${archive##*/}}\n  $destination</b>"

	case $format in
		*[bgx]z*) tar xfC "$archive" "$destination" "$archive_single" $strip;;
		zip) unzip -qq$flag $password "$archive" "$archive_single*" -d "$destination";;
		rar) unrar ${flag:-x} $password "$archive" "${archive_single:-*}" "$destination" -inul;;
	esac

	un_set archive archive_single password
}

function add_music() {
	music_directory="$(sed -n 's/^music_directory.*\"\(.*\)\"/\1/p' .mpd/mpd.conf)"
	[[ ${music_directory: -1} == '/' ]] && music_directory=${music_directory%/*}

	mpc add "${current#$music_directory/}"

	notify "adding to playlist\n<b>$current</b>"
}

function notify() {
	~/.orw/scripts/notify.sh -p "$1"
}

[[ ! ${@%% *} =~ [[:alpha:]] && ${@#${@%% *}} ]] && file="${@#* }" || read option arg <<< "$@"

all=""
copy="/home/lubuntu/Downloads/xhe5twznc0u21.jpg"
sort=""
reverse=""
options=""
current="/home/sola"

archive="/home/sola/Documents/z.zip"
password=""
archive_single=""

echo -e 

if [[ -z $@ ]]; then
	set current "$HOME"
elif [[ $file ]]; then
	set current "$current/$file"
fi

if [[ ${option% *} ]]; then
	case "$option" in
		 )
			if [[ $options ]]; then
				[[ $options == options ]] && un_set options || set options options
			elif [[ "$archive" && -f "$current" && "$archive" == "$current" ]]; then
				un_set archive password
			else
				back
			fi;;
		sort)
			set options sub_options
			echo -e 'by_date\nby_size\nby_type\nreverse\nalphabetically';;
		remove)
			set options sub_options
			echo -e 'yes\nno';;
		hidden) [[ $hidden ]] && un_set hidden || set hidden '-a';;
		password) [[ ${current##*.} == zip ]] && set password "-P ${@#* }" || set password "-p${@#* }";;
		list_archive)
			set archive "$current"
			list_archive
			list=true;;
		slide_images)
			killall rofi
			feh "$current";;
		edit_text)
			killall rofi
			termite -e "nvim '$current'" &;;
		 ) set options options;;
		 )
			if [[ ! $file ]]; then
				killall rofi
				thunar "$current"
			fi;;
		xdg-open)
			killall rofi
			[[ $(file --mime-type -b "$current") =~ "image" ]] && ~/.orw/scripts/open_multiple_images.sh "$current" ||
				xdg-open "$current"

			un_set options;;
		view_all_images)
			killall rofi
			sxiv -t "$current"/*

			un_set options;;
		*)
			back=true
			[[ $options ]] && un_set options

			case $option in
				all) [[ $all ]] && un_set all || set all '-a';;
				yes) rm -rf "$current" && back;;
				no) ;;
				copy) set copy "$current";;
				paste)
					destination="$current"
					[[ $arg ]] && destination+="/$arg"

					cp -r "$copy" "$destination"
					notify "pasting\n<b>$copy\n  $destination</b>";;
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
				extract_archive) [[ -d "$current" && $archive ]] && $option || set archive "$current";;
				*to_archive)
					if [[ -d "$current" && $archive ]]; then
						[[ $option =~ directory ]] && source_dir="${archive%/*}" || content='{.,}[[:alnum:]]*'
						create_archive
					else
						set archive "$current"
					fi;;
				create_directory)
					set current "$current/$arg"
					mkdir "$current";;
				add_to_playlist) add_music;;
				set_as_wallpaper_directory) ~/.orw/scripts/wallctl.sh -d "$current";;
				set_as_wallpaper) ~/.orw/scripts/wallctl.sh -s "$current";;
				*) set archive_single "$@";;
			esac
	esac
fi

if [[ $options == options ]]; then
	options=( 'all' 'sort' 'copy' )

	[[ $copy ]] && options+=( 'paste' )

	options+=( 'remove' 'add_content_to_archive' 'add_directory_to_archive' )

	[[ "$archive" ]] && options+=( 'extract_archive' )
	[[ "$current" =~ Music ]] && options+=( 'add_to_playlist' )
	[[ $(ls "$current"/*.{jp*g,png} 2> /dev/null) ]] && options+=( )

	options+=( 'create_directory' 'set_as_wallpaper_directory' 'view_all_images' )

	print_options
fi

if [[ -f "$current" ]]; then
	if [[ $back == true ]]; then
		back
	else
		if [[ ! $list && ! $option == remove ]]; then
			mime=$(file --mime-type -b "$current")
			file_options=( 'copy' 'remove' 'xdg-open' )

			case $mime in
				*zip*|*rar) file_options+=( 'password' 'list_archive' 'extract_archive' );;
				*image*) file_options+=( 'set_as_wallpaper' );;
				*audio*) file_options+=( 'add_to_playlist' );;
				*text*) file_options+=( 'edit_text' );;
			esac

			for option in ${file_options[*]}; do
				echo -e "$option"
			done
		fi
	fi
fi

if [[ -d "$current" && ! $options ]]; then
	echo -e 
	echo -e 
	while read -r file; do
		if [[ $file ]]; then
			if [[ -d "$current/$file" ]]; then
				icon=
			else
				icon=
				icon=
			fi
			echo -e "$icon $file"
		fi
	done <<< "$(ls $sort $reverse $all --group-directories-first "$current" | grep -v '\.$')"
fi
