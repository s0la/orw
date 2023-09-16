#!/bin/bash

shopt -s extglob

directory=${0%/*}
orw=~/.orw

function files() {
	echo 'copying files..'

	[[ -d $orw  ]] || mkdir $orw
	find $directory -maxdepth 1 -type d ! -name "*${directory##*/}" -exec cp -r {} $orw \;
}

get_app() {
	echo "installing $3.."

	(
		git clone https://github.com/$2/$3 ~/Downloads/$3
		(( $? > 0 )) && return 1

		cd ~/Downloads/$3
		rm -rf .git

		for arg in "${@:4}"; do
			eval $arg
		done

		if [[ $1 == install ]]; then
			make && sudo make install
			(( $? > 0 )) && return 1
		fi

		cd && rm -rf ~/Downloads/$3
	) &> $output
}

install_picom() {
	echo 'installing picom..'

	(
		wget https://www.archlinux.org/packages/community/x86_64/libev/download -O ~/Downloads/libev.tar.zst
		sudo tar xfC $HOME/Downloads/libev.tar.zst /
		rm ~/Downloads/libev.tar.zst

		git clone https://github.com/pijulius/picom ~/Downloads/picom
		cd ~/Downloads/picom
		git submodule update --init --recursive

		meson --buildtype=release . build
		ninja -C build
		sudo ninja -C build install

		cd && rm -rf ~/Downloads/picom
	) &> $output || handle_failure 'Failed to install picom'
}

install_termite() {
	echo 'installing termite..'

	sudo apt-get install -y \
		git \
		g++ \
		libgtk-3-dev \
		gtk-doc-tools \
		gnutls-bin \
		valac \
		intltool \
		libpcre2-dev \
		libglib3.0-cil-dev \
		libgnutls28-dev \
		libgirepository1.0-dev \
		libxml2-utils \
		gperf &> $output

	(git clone https://github.com/thestinger/vte-ng.git ~/Downloads/vte
	git clone --recursive https://github.com/thestinger/termite.git ~/Downloads/termite

	echo export LIBRARY_PATH="/usr/include/gtk-3.0:$LIBRARY_PATH"

	sed -i '/^\s*public.*audible/i\\tpublic int dummy;' ~/Downloads/vte/bindings/vala/app.vala

	cd ~/Downloads/vte && ./autogen.sh && make && sudo make install
	cd ~/Downloads/termite && make && sudo make install

	rm -rf ~/Downloads/{vte,termite}

	sudo ldconfig
	sudo mkdir -p /lib/terminfo/x
	sudo ln -s /usr/local/share/terminfo/x/xterm-termite /lib/terminfo/x/xterm-termite
	sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/local/bin/termite 60) &> $output
}

handle_failure() {
	echo "${1:-Failed to install dependencies, please check your internet connection and available disk space, and try again.}"
	exit
}

function deps() {
	echo 'installing dependencies..'

	failure_message="Failed to install dependencies, try installing them manually and run './setup.sh apps orw fonts man'"
	common_deps=(
		git
		openbox
		cmake
		wget
		bc
		alacritty
		neovim
		vifm
		tmux
		rofi
		xclip
		xdo
		xdotool
		wmctrl
		dunst
		slop
		feh
		hsetroot
		sxiv
		mp{d,c}
		ncmpcpp
		w3m
		ffmpeg
		acpi
		jq
		fzf
		ripgrep
		newsboat
	)

	if [[ $(which apt 2> /dev/null) ]]; then
		sudo apt update &> $output
		sudo apt install -y ${common_deps[*]} build-essential ninja-build automake autoconf pkg-config python3-pip xinit gettext \
			libnotify-dev libreadline-dev libcurl4-gnutls-dev libxft-dev libx11-xcb-dev libxcb-randr0-dev libxcb-xinerama0-dev \
			libtool{,-bin} libfftw3-dev libasound2-dev libncursesw5-dev libpulse-dev \
			libxml2-utils curl thunar gawk &> $output ||
			handle_failure "$failure_message"

		#termite installation
		install_termite

		#dunst dependencies
		sudo apt install -y libdbus-1-dev libx11-dev libxinerama-dev libxrandr-dev libxss-dev libglib2.0-dev libpango1.0-dev libgtk-3-dev libxdg-basedir-dev

		#cleaning
		echo 'cleaning..'
		sudo apt clean
	elif [[ $(which pacman 2> /dev/null) ]]; then
		generate_mirrors() {
			sudo sed -i '/Serbia/,/^$/ { /^#\w/ s/#// }' /etc/pacman.d/mirrorlist

			(sudo pacman-key --init
			sudo pacman-key --populate archlinux) &> $output || 
				handle_failure "Failed to generate mirrors."
		}

		confirm() {
			for answer in "$@"; do
				echo $answer
			done
		}

		#generate_mirrors

		sudo pacman --noconfirm -Syy archlinux-keyring &> $output
		for dep in lxappearance-{obconf-,}gtk3 thunar; do
			which $dep &> /dev/null && sudo pacman --noconfirm -R $dep &> $output
		done

		confirm '' 'y' 'y' | sudo pacman -S ${common_deps[*]} base-devel llvm-libs ninja python-pip bash-completion \
			alsa-lib alsa-plugins alsa-utils pipewire{,-pulse} xorg-xrandr xorg-xwininfo xorg-xset xorg-xsetroot iniparser \
			gtk-engine-murrine unzip dunst mpfr openssl wpa_supplicant meson uthash \
			libconfig libev xcb-util-{image,renderutil} libxml2 glibc icu &> $output ||
			handle_failure "$failure_message"

		echo 'cleaning..'
		confirm 'y' 'y' | sudo pacman -Scc &> $output || handle_failure 'Pacman error.'

		( if [[ ! -f /lib/libreadline.so.8 ]]; then
			wget https://www.archlinux.org/packages/core/x86_64/readline/download -O ~/Downloads/readline.tar.xz
			sudo tar xfC $HOME/Downloads/readline.tar.xz /
		fi ) &> $output || handle_failure
	else
		echo "Sorry, couldn't install dependencies for your distro :/"
		echo "Try installing them manually, then run './setup.sh apps orw fonts man'"
		exit
	fi
}

function apps() {
	##compton with kawase blur
	#get_app install tryone144 compton "sed -i '/^ifneq/! { /MANPAGES/d }' Makefile"

	python_dir=$(ls -d /usr/lib/python*)
	[[ -f $python_dir/EXTERNALLY-MANAGED ]] &&
		sudo mv $python_dir/EXTERNALLY-MANAGED $python_dir/EXTERNALLY-MANAGED.bak

	#pynput
	python -m pip install pynput &> /dev/null

	#picom with kawase blur
	install_picom

	#neovim python3 installation
	sudo ln -s /usr/lib/libffi.so.6 /usr/lib/libffi.so.7
	sudo pip3 install neovim &> $output || handle_failure "Failed to install neovim python3."

	#ueberzug installation
	#sudo pip3 install ueberzug &> $output || handle_failure "Failed to install ueberzug."

	#cava installation
	get_app install karlstav cava ./autogen.sh ./configure || handle_failure "Failed to install cava."

	#lemonbar installation
	get_app install krypt-n bar ~/.orw/scripts/add_borders_to_bar_source.sh || handle_failure "Failed to install bar."

	#dunst installation
	#get_app install dunst-project dunst "make dunstify" "sudo cp dunstify /usr/local/bin"

	##fff installation
	#get_app install dylanaraps fff || handle_failure "Failed to install fff."

	#colorpicker installation
	get_app install ym1234 colorpicker || handle_failure "Failed to install colorpicker."

	#i3lock-color installation
	get_app install PandorasFox i3lock-color "autoreconf --force --install" \
		"rm -rf build/" "mkdir -p build" "cd build/" "../configure --prefix=/usr --sysconfdir=/etc --disable-sanitizers"

	#fseed installation
	#get_app git clone git://git.codemadness.org/sfeed
	get_app install dxwc sfeed

	#git clone git://git.codemadness.org/sfeed ~/Downloads/sfeed
	#cd ~/Downloads/sfeed
	#make && sudo make install
	#cd && rm -rf ~/Downloads/sfeed
}

function backup() {
	cd $1
	echo "backing up files in ${1/$HOME/\~}"

	for file in $(find ~/.orw/dotfiles/${1#$HOME/} -maxdepth 1 ! -regex ".*\(dotfiles/\|config\|services\)"); do
		file_name=${file##*/}

		if [[ -e $file_name ]]; then
			tar uhf .backup_by_orw.tar.gz $file_name
			rm -rf $file_name
		fi

		ln -s $file $file_name
	done
}

function orw() {
	echo 'setting up orw..'

	[[ -d ~/.fonts ]] || mkdir ~/.fonts
	[[ -d ~/.icons ]] || mkdir ~/.icons
	[[ -d ~/.themes ]] || mkdir ~/.themes

	ln -s $orw/.fonts/* ~/.fonts
	ln -s $orw/themes/icons ~/.icons/orw
	ln -s $orw/themes/theme ~/.themes/orw

	echo 'linking config files..'

	backup ~/
	backup ~/.config

	services_dir=/etc/systemd/user
	[[ ! -d $services_dir ]] && sudo mkdir $services_dir
	sudo ln -s $orw/dotfiles/services/* $services_dir

	#installing neovim pugins
	plugins=(
		junegunn/fzf.vim
		voldikss/vim-floaterm
		neovim/nvim-lspconfig
		hrsh7th/{nvim-cmp,cmp-nvim-lsp}
	)

	plugin_dir=$orw/dotfiles/.config/nvim/pack/plugins/start

	for plugin in ${plugins[*]}; do
		plugin_name=${plugin##*[/-]}
		git clone https://github.com/$plugin \
			$plugin_dir/${plugin_name%.*} &> $output ||
			handle_failure "failed to install neovim plugin: ${plugin_name%.*}"
	done

	nvim -c UpdateRemotePlugins +qall! &> /dev/null

	ex_user=$(sed -n 's/user.*"\(.*\)"/\1/p' ~/.config/mpd/mpd.conf)
	sed -i "s/$ex_user/$(whoami)/" $orw/{scripts/{bar/generate_bar,wallctl,ncmpcpp*}.sh,dotfiles/{.config/{mpd/mpd.conf,ncmpcpp/config*},services/change_wallpaper.service}}

	[[ ! -f ~/.config/orw/config ]] && $orw/scripts/generate_orw_config.sh

	openbox --reconfigure
}

function fonts() {
	echo 'setting fonts..'
	fc-cache -f
}

function man() {
	echo 'adding mans..'
	sudo ln -s $orw/.man/* /usr/share/man/man1/
}

arguments="$@"
[[ $arguments =~ -v ]] &&
	output=/dev/stdout arguments="${arguments/-v/}" || output=/dev/null

while read -r function; do
	${function##* }
done <<< $([[ $arguments ]] && echo "$arguments" | xargs -n1 || awk -F '[( ]' '/^fun/ {print $2}' $0)

((! $?)) && echo 'Installation completed succesfully, please re-login and enjoy! :)'
