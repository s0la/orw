#!/bin/bash

config=~/.config/orw/config
notify=~/.orw/scripts/notify.sh
services=~/.orw/dotfiles/services
all_colors=~/.config/orw/colorschemes/colors

function set_notification_icon() {
	icon="<span font='Roboto Mono 15'>$notification_icon    </span>"
}

function replace() {
	sed -i "s#^$1.*#$1 ${!1}#" $config

	if [[ $1 == directory ]]; then
		$notify -p "$icon directory <b>$directory</b>\nhas been successfully set as default directory."
		exit
	fi
}

function set_aspect() {
	if [[ -f "$1" ]]; then
		read aspect xinerama <<< $(file -b "$1" | awk -F '[x,]' '{ o = "'${orientation:0:1}'"; \
			field = ("'${1##*.}'" == "png") ? 2 : NF - 2; ww = $field; wh = $(field + 1); \
			if ((o == "h" && ww > 2.5 * wh) || (o == "v" && wh > ww)) print "--bg-scale --no-xinerama"; else print "--bg-fill" }')
	fi
}

function assign_value() {
	[[ ! $2 == -[[:alpha:]] ]] && eval "$1=$2"
}

function get_directory_path() {
	[[ ! $1 =~ ^/ ]] && current_directory="$(pwd)/"
	echo "$current_directory${1}"
}

function read_wallpapers() {
	eval wallpapers=( $(sed -n "s/desktop_$current_desktop //p" $config) )
}

function write_wallpapers() {
	[[ -f "${directories[$2 - 1]:-$directory}/$1" || $1 =~ ^# ]] &&
		awk -i inplace 'BEGIN {
				wi = '$2'
				dc = '$display_count'
				w = " \"'"$1"'\""
			}

			{
				if(/^desktop_'${all_desktops:-$current_desktop}'/) {
					$0 = (wi > dc) ? $0 w : gensub(" [^\"]*(\"[^\"]*\")*", w, wi)
				}
				print
			}' $config
}

set_order() {
	[[ $unsplash ]] && type=image || type=wallpaper

	case ${image_order:=${order:=n}} in
		p*) index="(((${type}_count + current_${type}_index - ${order_count-1})) % ${type}_count)";;
		n*) index="(current_${type}_index + ${order_count-1})";;
		*) index="RANDOM";;
	esac
}

set_search_parameter() {
	[[ $1 =~ ^u ]] && search_parameter=user || search_parameter=collection
	[[ $2 ]] && eval "$search_parameter=$2"
}

set_query_parameters() {
	query="&query=${1// /-}"
	search_term="search/"
	results=".results | "
}

set_color_name() {
	local color_name

	read save_color color_name <<< $(awk '\
		$1 ~ "sc_" { lsc = $1 } \
		$2 == "'$color'" { cn = $1 } \
		END { print cn == "", cn ? cn : "sc_" gensub("sc_", "", 1, lsc) + 1 }' $all_colors)

	if ((save_color)); then
		echo "$color_name $color" >> $all_colors
		~/.orw/scripts/update_colors.sh
	fi
}

set_color() {
	~/.orw/scripts/rice_and_shine.sh -R all -C $color $color_save_name -m bar -p Afc &
}

change_color() {
	clear
	read -rsn 1 -p "Image color/custom color? [I/c]"$'\n' color_type

	if [[ $color_type == c ]]; then
		kill_preview
		echo "Pick a color: "
		color=$(~/.orw/scripts/pick_color.sh)
		echo -ne '\n'
	fi

	echo -e 'Offset/name/apply color? [o/n/A]'

	while
		read -rsn 1 -p $'\n* ' color_action

		case $color_action in
			o)
				read -p 'Offset: ' offset

				local original_color=$color
				color=$(~/.orw/scripts/colorctl.sh -o $offset -ph "$color")

				echo "Color $original_color offseted by ${offset#[+-]}%, now $color.";;
			n)
				local color_name
				read -p 'Name: ' color_name
				local color_save_name="-s $color_name"

				echo "Color $color saved as $color_name";;
		esac

		[[ $color_action =~ [on] ]]
	do
		continue
	done

	[[ ! $color_name ]] && set_color_name
	set_color
}

check_preview() {
	preview_pid=$(wmctrl -lp | awk '$NF == "image_preview" { print $3 }')
}

add_tags() {
	unset tags
	local all_tags_count=${#all_tags[*]}

	echo -e "Tags:\n"
	echo "0) done"

	for tag_index in $(seq $all_tags_count); do
		echo "$tag_index) ${all_tags[tag_index - 1]}"
		((tag_index == 9)) && break
	done

	until
		read -rsn 1 tag_index
		((!tag_index))
	do
		[[ $tags ]] && tags+=, && echo -n ', ' ||
			echo -ne '\nGenerating query from '

		tag="${all_tags[tag_index - 1]}"
		tags+="${tag// /-}"

		echo -n $tag
	done
}

kill_preview() {
	if ((preview_pid)); then
		kill $preview_pid
		unset preview_pid
		rm $thumb
	fi
}

fetch_preview() {
	if ((!preview_pid)); then
		thumb=/tmp/thumb.jpg
		curl -s "$thumb_url" --output $thumb

		color=$(convert $thumb -resize 1x1 txt:- | awk 'END { print $3 }')
		convert $thumb -gravity south -background $color -splice 0x15 $thumb

		read x y <<< $(~/.orw/scripts/windowctl.sh -p | awk '{ print $3 + ($5 - '${thumb_width-300}'), $4 + ($2 - $1) }')
		~/.orw/scripts/set_class_geometry.sh -c image_preview -x $x -y $y
		feh --title image_preview $thumb &

		preview_pid=$!
	fi
}

try_wall() {
	[[ ! $directory_path ]] && directory_path=$(sed -n "s/\(.*[Ww]all[^/]*\).*/\1\/$1/p" <<< $directory)
	[[ ! -d "$directory_path" ]] && mkdir "$directory_path"
	wallpaper_path="$directory_path/${wallpaper,,}"

	read -rsn 1 -p $"Apply/offset color$color_types? [a/o/N]"$'\n' apply_color

	if [[ $apply_color == o ]]; then
		read -p "Offset: " offset
		color=$(~/.orw/scripts/colorctl.sh -o $offset -ph "$color")
	fi

	if [[ ! -f $wallpaper_path ]]; then
		echo Downloading..
		curl --progress-bar -L "${path-https://unsplash.com/photos/$id/download}" --output "$wallpaper_path"
	fi

	if [[ $apply_color =~ [ao] ]]; then
		set_color_name
		set_color
	fi

	set_aspect "$wallpaper_path"
	feh $aspect $xinerama "$wallpaper_path"

	read -srn1 -p "Keep wallpaper? [Y/n]"$'\n' keep_wall
	[[ $keep_wall == n ]] && rm "$wallpaper_path"
}

current_desktop=$(xdotool get_desktop)

read directory recursion <<< $(awk '/^directory|recursion/ {print $2}' $config | xargs)
read orientation display_count <<< $(awk -F '[_ ]' '/^orientation/ {o = $NF}; /^display_[0-9] / {dc = $2}; END {print o, dc}' $config)

[[ "$@" =~ -U ]] && unsplash=true

while getopts :i:m:w:sd:D:rR:o:acAI:O:P:p:t:q:UW flag; do
	case $flag in
		i) index=$((OPTARG - 1));;
		m)
			read_wallpapers
			display_number=$OPTARG;;
		w) current_desktop=$OPTARG;;
		s)
			add_wallpaper() {
				[[ $(get_directory_path ${arg%/*}) =~ $directory ]] && local path_level=$recursion

				for level in $(seq 1 $path_level); do
					local wallpaper_section_expression+='/*'
				done

				wallpaper_index=$((${display_number:-1} + $1 - 1))

				if (($1 <= arg_count)); then
					[[ $arg =~ / ]] && local directory_section="${arg%$wallpaper_section_expression}/"
					wallpaper_directory=$(get_directory_path $directory_section)
					wallpaper=${arg#$directory_section}

					directories[wallpaper_index]="$wallpaper_directory"
					wallpapers[wallpaper_index]="$wallpaper"
				fi

				directories[wallpaper_index]="$wallpaper_directory"

				[[ ${wallpaper_directory:-$directory} =~ ^$directory || $wallpaper =~ ^# ]] &&
					write_wallpapers "$wallpaper" $((${display_number:-1} + $1))
			}

			initial_index=$OPTIND

			for arg_index in $(seq $initial_index $#); do
				[[ ${!arg_index} =~ ^- ]] && break
				((arg_count++))
			done

			((arg_count--))

			if ((display_number == 0 && arg_count == 0)); then
				arg=${!initial_index}

				for display in $(seq 0 $((display_count - 1))); do
					add_wallpaper $display
				done
			else
				for wall in $(seq 0 $arg_count); do
					arg_index=$((initial_index + wall))
					arg="${!arg_index}"
					add_wallpaper $wall
				done
			fi

			shift $arg_count;;
		d)
			directory="$OPTARG"
			[[ ${directory: -1} == '/' ]] && directory=${directory%/*}
			directory=$(get_directory_path $directory)

			replace directory;;
		D)
			directory="${directory%/*}/$OPTARG"
			replace directory;;
		r)
			read_wallpapers

			if [[ $all_desktops ]]; then
				for wallpaper_index in ${!wallpapers[*]}; do
					write_wallpapers "${wallpapers[wallpaper_index]}" $((wallpaper_index + 1))
				done
			fi;;
		R)
			recursion=$OPTARG
			replace recursion;;
		a) all_desktops=*;;
		A)
			service=true

			assign_value state ${!OPTIND} && shift
			current_state=$(systemctl --user status change_wallpaper.timer | awk '/Active/ {print $2}')

			if [[ ${current_state:-$state} == 'inactive' ]]; then
				new_state='start'
				boot='enable'
			else
				new_state='stop'
				boot='disable'
			fi;;
		I)
			service=true
			service_property=interval

			interval=$OPTARG
			assign_value unit ${!OPTIND} && shift

			sed -i "/OnUnitActiveSec/ s/[0-9]\+.*/$interval${unit:-min}/" ~/.orw/dotfiles/services/change_wallpaper.timer;;
		O)
			service=true
			service_property=order

			order=$OPTARG

			#sudo sed -i "s/\(ExecStart.* \).*\"/\1$mode\"/" ~/.orw/dotfiles/services/change_wallpaper.service;;
			sed -i "/Exec/ s/-o \w*/-o $order/" ~/.orw/dotfiles/services/change_wallpaper.service;;
		o)
			order=$OPTARG
			[[ ${!OPTIND} =~ [0-9]+ ]] && order_count=${!OPTIND} && shift
			set_order;;
		c) colors=true;;
		p) page=$OPTARG;;
		P) per_page=$OPTARG;;
		t) thumb_width=$OPTARG;;
		q) set_query_parameters "$OPTARG";;
		O) image_orientation="&orientation=$OPTARG";;
		W)
			base_url='https://wallhaven.cc/api/v1'

			parse_url() {
				eval $(awk '
					function parse_url(var, term) {
						if ($0 ~ term) {
							st = term ? term : var
							ts = term ? "\\1\\2" : "\\2"

							value = gensub(".*([&?]" st "=)([^&]*).*", ts, 1)
							printf "%s=\"%s\" ", var, value
						}
					}
				{
					parse_url("page")
					parse_url("categories")
					parse_url("query", "q")
					parse_url("sorting", "sorting")
					parse_url("top_range", "topRange")
				}' <<< "$url")
			}

			get_results_info() {
				parse_url

				if [[ $query ]]; then
					case ${query#*=} in
						@*) local n_user=" ${query#*@}'s";;
						like*) local n_related=" related";;
						*) local n_tagged_as=", tagged as ${tag_name:-${tags//,/, }}";;
					esac
				else
					local wallhaven="Wallhaven "
				fi

				if [[ $sorting ]]; then
					case ${sorting#*=} in
						relevance) local n_sorting=" most relevant";;
						favorites) local n_sorting=" favorite";;
						toplist)
							local n_sorting=" top listed"

							if [[ $top_range ]]; then
								local top_range=${top_range#*=}
								local range=${top_range:0: -1}
								local period=${top_range: -1}

								case $period in
									M) local n_period=month;;
									y) local n_period=year;;
									w) local n_period=week;;
									d) local n_period=day;;
								esac

								((range > 1)) && n_period+=s || unset range
								local n_top_range=" in last $range $n_period"
							fi;;
						views) local n_sorting=" most viewed";;
						date_added) local n_sorting=" latest";;
						*) local n_sorting=" random";;
					esac
				fi

				results_info="$n_user$n_sorting$n_related ${wallhaven}wallpapers$n_top_range$n_tagged_as.."
				[[ $results_info =~ ^  ]] && results_info=${results_info#* }
			}

			back_to_photo() {
				if ((${#url_history[*]})); then
					unset query sorting top_range 
					read original_photo_id url <<< "${url_history[-1]}"
					unset url_history[-1]

					get_images $url

					current_image_index=0
					until [[ ${images[current_image_index]%% *} == $original_photo_id || $current_image_index -eq $image_count ]]; do
						((current_image_index++))
					done
				else
					echo "No photo to go back to!"
					sleep 3
				fi
			}

			get_images() {
				kill_preview

				[[ $1 ]] && url=$1 ||
					url="$base_url/search?page=${page:=1}&categories=${categories-100}$query$sorting$top_range$atleast$resolutions$order"

				clear
				get_results_info
				echo -e "Loading $results_info"

				local elements='.id + " " + .thumbs.small + " " + .path + " " +'
				elements+='.resolution + " " + (.file_size / 1048576 | tostring)'

				read total_pages last_page_total_results urls <<< $(curl -s "$url" | \
					jq "(.meta | .last_page, .total), (.data[] | $elements)" | xargs -d '\n')

				eval images=( $urls )
				image_count=${#images[*]}
			}

			set_top_range() {
				read -p 'Enter range: ' range
				read -rsn 1 -p 'Select period (day/week/month/year): [d/w/m/y] ' period

				[[ $period == m ]] && period=M
				top_range="&topRange=$range$period"
			}

			set_sorting() {
				current_image_index=0 page=1

				case ${1-d} in
					t)
						read -rsn 1 -p $'Set top range? [Y/n]\n' set_top_range
						[[ $set_top_range != n ]] && set_top_range

						sorting='&sorting=toplist';;
					T) set_top_range;;
					d) sorting='&sorting=date_added';;
					f) sorting='&sorting=favorites';;
					r) sorting='&sorting=relevance';;
					R) sorting='&sorting=random';;
					v) sorting='&sorting=views';;
				esac

				get_images
			}

			get_images

			until
				image_index=$((current_image_index % image_count))

				case $direction in
					n)
						if ((current_image_index && !image_index)); then
							((page == total_pages)) && page=1 || ((page++))
							get_images

							current_image_index=0
						fi;;
					p)
						if ((image_index == image_count - 1)); then
							((page == 1)) && page=$total_pages || ((page--))
							get_images

							image_index=$((image_count - 1))
							current_image_index=$image_index
						fi;;
				esac

				read id thumb_url path resolution size <<< ${images[image_index]}

				fetch_preview

				((${#url_history[*]})) && back='/back' b='/b' || unset back b

				((page == total_pages)) && page_results=$last_page_total_results || page_results=24

				clear
				echo "You're currently searching through $results_info"
				echo -e "Page $page of $total_pages, wallpaper $((image_index + 1)) of $image_count..\n"

				echo "* Try wallpaper ($resolution, ${size:0:3} MB): [t]"
				echo "* Next/previous$back: [n/p$b]"
				echo "* Query/more like this/uploader's photos: [q/m/u]"
				echo "* Categories/sorting/order/page/index: [c/s/o/P/i]"
				echo "* Atleast/resolutions: [a/r]"
				echo "* Tags/color: [T/C]"
				echo "* Exit: [e]"

				read -rsn 1 -p $'\n' choice

				[[ $choice =~ ^[mTuq] ]] && url_history+=( "$id $url" )

				case ${choice:-t} in
					n)
						direction=n
						((current_image_index++))
						
						kill_preview;;
					p)
						direction=p
						current_image_index=$((image_count + image_index - 1 % image_count))
						
						kill_preview;;
					b) back_to_photo;;
					q)
						current_image_index=0 page=1
						
						read -p "Enter tags: " tags
						query="&q=${tags// /-}"

						get_images;;
					m)
						current_image_index=0 page=1
						query="&q=like:$id"
						get_images;;
					u)
						user=$(curl -s "$base_url/w/$id" | jq -r '.data | .uploader.username')
						query="&q=@$user"
						set_sorting;;
					c)
						read -p 'Enter categories (as sequence of 1 and 0, in following order: general, anime, people): ' categories_seq
						categories="&categories=${categories_seq-111}"
						get_images;;
					s)
						[[ $sort =~ [tT] ]] && top_range_prompt='/top range' trp='/T' || unset top_range_prompt trp
						sort_prompt="Select sorting (date_added/relevance/random/views/favorites/top list$top_range_prompt): "
						sort_prompt+="[d/r/R/v/f/t$trp]"

						read -rsn 1 -p "$sort_prompt"$'\n' sort
						set_sorting $sort;;
					T)
						unset all_tags
						eval all_tags=( $(curl -s "$base_url/w/$id" | jq ".data.tags[].name") )

						if ((${#all_tags[*]})); then
							add_tags
						else
							echo "No tags for this wallpaper!"
							sleep 2
						fi

						if ((${#tags})); then
							query="&q=$tags"
							set_sorting
						fi;;
					i)
						read -p 'Enter index: ' index

						if [[ $index =~ ^[+-] ]]; then
							((${#index} == 1)) && index+=1
							current_image_index=$((image_count + image_index $index % image_count))
						else
							 current_image_index=$index
						 fi
						 
						kill_preview;;
					o)
						current_image_index=0 page=1

						read -rsn 1 $'Select order (ascending/descending): [a/d]\n' order
						[[ $order == a ]] && order='&order=asc' || order='&order=desc'

						get_images;;
					a)
						read -rsn 1 -p 'Select minimum resolution allowed (my screen resolution/custom): [M/c]' atleast
						[[ $atleast == c ]] && read -p 'Enter minimum resolution allowed: ' minimum_resolution ||
							minimum_resolution=$(awk '$1 == "primary" { p = $NF } p && $1 == p { print $2 "x" $3 }' ~/.config/orw/config)

						atleast="&atleast=$minimum_resolution"

						get_images;;
					r)
						read -p 'Enter exact resolution[s]: ' exact_resolutions
						resolutions="&resolutions=$exact_resolutions"
						get_images;;
					P)
						read -p 'Enter page: ' page_number

						if [[ $page_number =~ ^[+-] ]]; then
							((${#page_number} == 1)) && page_number+=1
							(( page ${page_number:0:1}= ${page_number:1} ))
						else
							 page=$page_number
						 fi

						get_images
						
						current_image_index=0;;
					C) change_color;;
					e)
						kill_preview
						exit 0;;
					t)
						wallpaper="${path##*/}"
						try_wall wallhaven
				esac

				[[ $choice == e ]]
			do
				continue
			done;;
		U)
			base_url='https://api.unsplash.com'
			client_id='?client_id=33e9e4c0f8d42b5542446f1c8c291480cb91231dbadc5ce285f285bf76975752'

			format_output() {
				#The ONLY way of fetching all urls that doesn't make feh throw error!!! 
				awk '{ l = NR % '$1';
						if(!l) {
							sq = ""
							eq = "\""
						} else if(l == 1) {
							sq = "\""
							eq = ""
						} else sq = eq = ""
						gsub(/^"|"$/, "")
						printf("%s%s%s ", sq, $0, eq) }'
			}

			get_results_info() {
				if [[ ! $image_type ]]; then
					if [[ $search_parameter ]]; then
						search_parameter_name=${search_parameter}_name
						image_type="${!search_parameter_name}"

						[[ $search_parameter == collection ]] && image_type+=" collection"
						image_type+="'s $search_order images"
					elif [[ $tags ]]; then
						image_type="$search_order images tagged as ${tags//,/, }"
					fi
				fi

				results_info="${image_type-Unsplash images}"
			}

			get_images() {
				kill_preview

				if [[ $@ ]]; then
					url="$1"
					local message="Returning to image"
				else
					url="$base_url/$search_term${user}${collection}photos$photo_id$related/$client_id"
					url+="$query$image_orientation&order_by=${search_order:=latest}&page=${page:=1}&per_page=${per_page-100}"
					get_results_info
				fi

				clear
				echo ${message-Loading $results_info}..

				local elements='.id + " " + (.width|tostring) + " " + (.height|tostring) + " " + .color + " " +'
				elements+='.urls.thumb + " " + .links.download_location + " " + .user.username + " " + .user.name'
				eval images=( $(curl -s "$url" | jq "$results .[] | $elements") )
				image_count=${#images[*]}
			}

			search() {
				kill_preview

				unset search_term query

				if [[ ! $1 ]]; then
					local results='.results'
					search_url="$base_url/search/${search_parameter}s/$client_id&query=${!search_parameter}&per_page=100" 
				else
					local results='.related_collections.results'
					search_url="$base_url/photos/$related_id/$client_id&per_page=10000"
				fi

				[[ $search_parameter == user ]] &&
					elements='.username + " " + (.total_photos|tostring) + " " + .name' ||
					elements='(.id|tostring) + " " + (.total_photos|tostring) + " " + .title'

				eval search_results=( $(curl -s "$search_url" | jq "$results | .[] | $elements") )
				search_result_count=${#search_results[*]}

				if ((search_result_count > 1)); then
					local results_per_page=10
					local search_page search_result_index result_index selected_result

					until
						clear
						echo -e "Select $search_parameter:\n\nPage $((search_page + 1))\n"

						search_result_index=$((search_page * results_per_page))

						((search_result_index + results_per_page > search_result_count)) &&
							page_results=$((search_result_count % results_per_page)) || page_results=$results_per_page

						for result_index in $(seq ${search_result_index-0} $((search_result_index + page_results - 1))); do
							read result_id result_photos result_title <<< "${search_results[result_index]}"
							echo "$((result_index % results_per_page))) $result_title ($result_photos photos)"
						done

						[[ ! $1 ]] && echo 'p) page'
						((result_index > results_per_page)) && echo 'b) back'
						((result_index < search_result_count - 1)) && echo 'n) next'

						read -rsn 1 -p $'#?\n' selected_result

						case $selected_result in
							p)
								read -p "Enter page number: " search_page
								((search_page--));;
							b) ((search_page--));;
							n) ((search_page++));;
						esac

						[[ $selected_result == [[:digit:]] ]]
					do
						continue
					done
				fi

				index=0 page=1

				eval previous_$search_parameter=${!search_parameter}
				eval ${search_parameter}_name=\"${search_results[search_result_index + selected_result]#* * }\"
				eval $search_parameter="${search_parameter}s/${search_results[search_result_index + selected_result]%% *}/"
			}

			back_to_photo() {
				unset collection user search_parameter $search_parameter ${search_parameter}_name query related image_type
				if ((${#url_history[*]})); then
					read index original_photo_id page url search_parameter \
						search_parameter_value previous_search_parameter_value <<< "0 ${url_history[-1]}"

					if [[ $search_parameter ]]; then
						unset related_results
						eval ${search_parameter}_name=\"$search_parameter_value\"
						eval previous_${search_parameter}=$previous_search_parameter_value
					fi

					if [[ $url =~ query|related ]]; then
						if [[ $url =~ query ]]; then
							tags=$(sed 's/.*query=\(.*\)\&\(orientation\|order\).*/\1/' <<< $url)
							set_query_parameters $tags
						elif [[ $url =~ related ]]; then
							photo_id=$original_photo_id
							results=".results | "
							related="/related"
						fi
					else
						unset results
					fi

					get_results_info
					get_images $url

					until [[ ${images[index]%% *} == $original_photo_id || $index -eq $image_count ]]; do
						((index++))
					done

					((index %= image_count))
					unset url_history[-1]
				else
					echo "No photo to go back to!"
					sleep 3
				fi
			}

			[[ $search_parameter ]] && search

			get_images
			set_order

			while
				if ((image_count)); then
					index_in_range=$((current_image_index % image_count))

					if [[ ! $url =~ /related/ ]]; then
						case $image_order in
							n*) ((current_image_index && !index_in_range)) && ((page++)) && get_images;;
							p*) ((index_in_range == image_count - 1 && page > 1)) && ((page--)) && get_images;;
						esac
					fi
				else
					echo "No images were found, returning back!"
					sleep 2

					((${#url_history[*]})) && back_to_photo > /dev/null

					image_order=$current_image_order
					current_image_index=$index
					set_order
				fi

				read id width height alt_color thumb_url download_location username name <<< ${images[index_in_range]}

				thumb_url="${thumb_url//w=*[0-9]&/w=${thumb_width:=200}&/}"
				wallpaper="${name//[ \/]/_}_${id}_unsplash.jpg"

				fetch_preview

				((${#url_history[*]})) && back='/back to photo' back_option='/b' || unset back{,_option} 

				clear
				echo "You are currently browsing through $results_info.."
				echo -e "Page $page, image $((index_in_range + 1)) of $image_count..\n"

				echo io $image_order

				echo "* Try image (${width}x${height})? [t]"
				echo "* Go to home page$back/next? [h${back:0:2}/n]"
				echo "* More photos from $name/related (photos/collections)? [m/r/R]"
				echo "* Change search parameter (user/collection)/${search_parameter:-user}_id/query? [s/i/q]"
				echo "* Order/image order/page/results per page)? [O/o/p/P]"
				echo "* Tags/color? [T/C]"
				echo "* Exit? [e]"

				read -srn 1 -p $'\n' choice

				if [[ $choice =~ [rRm] ]]; then
					if [[ $search_parameter ]]; then
						previous_search_parameter=previous_${search_parameter}
						url_search_parameter="$search_parameter ${!search_parameter_name} ${!previous_search_parameter}"
					fi

					url_history+=( "$id $page $url $url_search_parameter" )
				fi

				case ${choice:=t} in
					h)
						unset results search_term user collection query photo_id related
						image_type="home page images"

						index=0 page=1

						get_images;;
					b) back_to_photo;;
					[rR])
						related_id=$id

						if [[ $choice == r ]]; then
							unset search_term user collection query image_type

							image_type="related images"
							results=".results | "
							related="/related"
							photo_id="/$id"

							index=0 page=1
						else
							unset user results photo_id related image_type

							search_parameter=collection
							related_results=related

							search $related_results
						fi

						get_images

						unset photo_id related;;
					m)
						eval unset results search_term user collection query photo_id related image_type

						search_parameter=user
						user="users/$username/"
						user_name="$name"

						index=0 page=1

						get_images;;
					C) change_color;;
					T)
						unset search_parameter user collection photo_id related image_type all_tags
						eval all_tags=( $(curl -s "$base_url/photos/$id/$client_id" | jq '.tags[].title') )

						if ((${#all_tags[*]})); then
							add_tags 9
						else
							echo "No tags for this photo!"
							sleep 2
						fi

						if ((${#tags[*]})); then
							index=0 page=1

							set_query_parameters $tags
							get_images
						fi;;
					q)
						unset search_parameter user collection photo_id related tags image_type
						read -p "Enter tags: " tags
						set_query_parameters "$tags"

						page=1 index=0

						get_images;;
					[suc])
						unset results related_results related_id image_type

						if [[ $choice == s ]]; then
							cspo=${search_parameter:0:1}
							[[ ${cspo:=u} == u ]] && ospo=c || ospo=u

							read -rsn1 -p "Select search_parameter (user/collection): [${cspo~}/$ospo] "$'\n' choice
							unset user collection query photo_id related
							set_search_parameter ${choice:=$cspo}
						fi

						read -p "Enter ${search_parameter} name: " $search_parameter

						search
						get_images;;
					i)
						unset user collection image_type

						previous_search_parameter=previous_${search_parameter}
						eval $search_parameter=${!previous_search_parameter}

						search $related_results
						get_images;;
					[pP])
						if [[ $choice == p ]]; then
							read -p "Enter page number: " page_number

							if [[ $page_number =~ ^[+-] ]]; then
								((${#page_number} == 1)) && page_number+=1
								(( page ${page_number:0:1}= ${page_number:1} ))
							else
								page=$page_number
							fi

							index=0
						else
							read -p "Enter number of results per page: " per_page
						fi

						get_images;;
					O)
						unset image_type
						read -rsn 1 -p "Select order (popular/latest/oldest): [p/L/o] " search_order

						case $search_order in
							p) search_order=popular;;
							l) search_order=latest;;
							o) search_order=oldest;;
						esac

						index=0 page=1

						get_images;;
					o)
						current_image_order=$image_order

						read -rsn 1 -p $'Select image order (next/previous/random/index): [N/p/r/i]\n' image_order

						if [[ $image_order == i ]]; then
							read -p 'Enter index: ' custom_index

							if [[ $custom_index =~ ^[+-] ]]; then
								((${#custom_index} == 1)) && custom_index+=1
								current_image_index=$(((image_count + index_in_range $custom_index) % image_count))
							else
								current_image_index=$((custom_index - 1))
							fi

							index=$current_image_index
							restore_image_order=true
						else
							set_order
						fi
						
						kill_preview;;
					e)
						kill_preview
						exit 0;;
					d)
						unsplash_directory=${directory%/*}/unsplash
						wallpaper_path="$unsplash_directory/$wallpaper"

						[[ ! -d "$unsplash_directory" ]] && mkdir "$unsplash_directory"

						read -srn1 -p "Would you like to set it as wallpaper? [Y/n]"$'\n' set_as_wall
						[[ $set_as_wall != n ]] && read -rsn 1 -p $'Would you like to apply image color? [y/N]\n' apply_color
						[[ $apply_color == y ]] && save_color

						wget -q "$download_location"
						wget -q --show-progress -O "$wallpaper_path" "https://unsplash.com/photos/$id/download"

						if [[ $set_as_wall != n ]]; then
							set_aspect "$wallpaper_path"

							[[ $apply_color ]] && set_color

							feh $aspect $xinerama "$wallpaper_path"
						fi;;
					t) try_wall unsplash;;
					n) kill_preview;;
				esac

				if [[ ! $choice =~ [tCP] ]]; then
					current_image_index="$(($index))"

					if [[ $index =~ ^[[:digit:]]+ ]]; then
						[[ $restore_image_order ]] && image_order=$current_image_order
						unset current_image_order restore_image_order

						set_order
					fi
				fi

				[[ $choice != e ]]
			do
				continue
			done;;
		?) echo "$OPTARG is not supported, please try again.";;
	esac
done

if [[ ! $wallpapers ]]; then
	if [[ $service ]]; then
		if [[ $new_state ]]; then
			(systemctl --user $boot change_wallpaper.timer
			systemctl --user $new_state change_wallpaper.timer) &> /dev/null

			[[ $new_state == start ]] && notification_icon= || notification_icon=
			set_notification_icon

			$notify -p "$icon Wallpaper auto-changer has been ${new_state}ed."
		else
			systemctl --user daemon-reload
			systemctl --user restart change_wallpaper.timer

			notification_icon=
			set_notification_icon

			$notify -p "$icon Wallpaper auto-changer $service_property has been set to ${order:-$interval ${unit:-min}}."
		fi

		exit
	fi

	[[ ! ${directory} ]] && echo 'Please set default directory by providing it to -d flag.' && exit

	current_wallpaper="$(awk -F '"' '\
		/^primary/ { p = gensub("[^0-9]*", "", 1) } \
		/^desktop_'${current_desktop}'/ { print $(p * 2) }' $config)"

	while read -r wallpaper; do
		[[ "$wallpaper" == "$current_wallpaper" ]] && current_wallpaper_index=${#all_wallpapers[*]}
		all_wallpapers+=("$wallpaper")
	done <<< $(find $directory/ -maxdepth $recursion -type f -iregex ".*\(jpe?g\|png\)" | awk -F '/' \
		'{ w = ""; r = '$((recursion - 1))'; for(f = NF - r; f <= NF; f++) w = w "/" $f; print substr(w, 2) }' | sort)

	wallpaper_count=${#all_wallpapers[*]}

	if [[ ! $index ]]; then
		[[ $colors ]] && index=$current_wallpaper_index || set_order
	fi

	for display in $(seq $display_count); do
		wallpaper_index="$((${index:-$wall_index} % wallpaper_count))"
		wallpaper="${all_wallpapers[$wallpaper_index]}"

		write_wallpapers "$wallpaper" ${display_number:-$display}

		wallpapers+=( "$wallpaper" )
	done
fi

for wallpaper_index in "${!wallpapers[@]}"; do
	wallpaper="${wallpapers[wallpaper_index]}"

	if [[ ${wallpaper//\"/} =~ ^# ]]; then
		((wallpaper_index == (${#wallpapers[@]} - 1))) && hsetroot -solid "$wallpaper" && exit
	else
		wallpaper_path="${directories[wallpaper_index]:-$directory}/$wallpaper"
		set_aspect "${wallpaper_path//\"/}"

		wallpapers_to_set+="$aspect $xinerama \"$wallpaper_path\" "
	fi
done

if [[ $colors ]]; then
	primary_display=$(awk -F '_' '/^primary / {print $NF - 1}' $config)

	wallpaper="${wallpapers[primary_display]//\"/}"
	wallpaper_name="${wallpaper##*/}"
	wallpaper_name="${wallpaper_name%\.*}"
	colorscheme="wall_${wallpaper_name// /_}"

	[[ -f "${config%/*}/colorschemes/$colorscheme.ocs" ]] && ~/.orw/scripts/rice_and_shine.sh -C $colorscheme &
fi

eval "feh $wallpapers_to_set"
