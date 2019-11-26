#!/bin/bash

shopt -s extglob

directory=${0%/*}
destination=~/.orw

function files() {
	echo 'copying files..'

	[[ -d $destination  ]] || mkdir $destination
	find $directory -maxdepth 1 -type d ! -name "*${directory##*/}" -exec cp -r {} $destination \;
}

get_app() {
	echo "installing $3.."

	(git clone https://github.com/$2/$3 ~/Downloads/$3
	(( $? > 0 )) && return 1

	cd ~/Downloads/$3
	rm -rf .git

	for command in $(seq 4 $#); do
		eval "\$$command"
	done

	if [[ $1 == install ]]; then
		make && sudo make install
		(( $? > 0 )) && return 1
	fi

	cd && rm -rf ~/Downloads/$3) &> /dev/null
}

handle_failure() {
	echo "${1:-Failed to install dependencies, please check your internet connection and available disk space, and try again.}"
	exit
}

function deps() {
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
			gperf &> /dev/null

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
		sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/local/bin/termite 60) &> /dev/null
	}

	echo 'installing dependencies..'

	common_apps=( cmake git neovim tmux rofi xclip xdo xdotool wmctrl feh hsetroot sxiv mp{d,c} ncmpcpp w3m ffmpeg acpi )

	if [[ $(which apt 2> /dev/null) ]]; then
		sudo apt update &> /dev/null
		sudo apt install -y ${common_apps[*]} build-essential ninja-build automake autoconf pkg-config python3-pip xinit gettext \
			libnotify-dev libreadline-dev libcurl4-gnutls-dev libxft-dev libx11-xcb-dev libxcb-randr0-dev libxcb-xinerama0-dev \
			libtool{,-bin} libfftw3-dev libasound2-dev libncursesw5-dev libpulse-dev \
			libxml2-utils curl thunar gawk &> /dev/null ||
			handle_failure

		#termite installation
		install_termite

		#dunst dependencies
		sudo apt install -y libdbus-1-dev libx11-dev libxinerama-dev libxrandr-dev libxss-dev libglib2.0-dev libpango1.0-dev libgtk-3-dev libxdg-basedir-dev
		
		#Thunar 1.6
		wget http://ftp.br.debian.org/debian/pool/main/t/thunar/thunar_1.6.11-1_amd64.deb -O ~/Downloads/thunar.deb
		sudo dpkg -i ~/Downloads/thunar.deb
		rm ~/Downloads/thunar.deb
		
		#cleaning
		echo 'cleaning..'
		sudo apt clean
	elif [[ $(which pacman 2> /dev/null) ]]; then
		generate_mirrors() {
			sudo sed -i '/Serbia/,/^$/ { /^#\w/ s/#// }' /etc/pacman.d/mirrorlist

			(sudo pacman-key --init
			sudo pacman-key --populate archlinux) &> /dev/null || 
				handle_failure "Failed to generate mirrors."
		}

		confirm() {
			for answer in "$@"; do
				echo $answer
			done
		}

		#generate_mirrors

		sudo pacman --noconfirm -Syy archlinux-keyring &> /dev/null
		sudo pacman --noconfirm -R lxappearance-obconf-gtk3 lxappearance-gtk3 thunar &> /dev/null

		confirm '' 'y' 'y' | sudo pacman -S ${common_apps[*]} base-devel llvm-libs ninja python-pip bash-completion \
			alsa-lib alsa-plugins alsa-utils pulseaudio xorg-xrandr xorg-xwininfo xorg-xset xorg-xsetroot \
			gtk-engine-murrine unzip termite dunst icu glibc libxml2 mpfr openssl wpa_supplicant &> /dev/null ||
			handle_failure

		#Thunar 1.6
		(wget https://aur.archlinux.org/cgit/aur.git/snapshot/thunar-gtk2.tar.gz -O ~/Downloads/thunar.tar.xz
		tar xfC ~/Downloads/thunar.tar.xz ~/Downloads
		cd ~/Downloads/thunar-gtk2
		makepkg --noconfirm -sci) &> /dev/null || handle_failure 'Failed to install Thunar.'
		rm -rf ~/Downloads/thunar-gtk2

		echo 'cleaning..'
		confirm 'y' 'y' | sudo pacman -Scc &> /dev/null || handle_failure 'Pacman error.'

		( if [[ ! -f /lib/libreadline.so.8 ]]; then
			wget https://www.archlinux.org/packages/core/x86_64/readline/download -O ~/Downloads/readline.tar.xz
			sudo tar xfC $HOME/Downloads/readline.tar.xz /
		fi ) &> /dev/null || handle_failure
	else
		echo "Sorry, couldn't install dependencies for your distro :/"
		echo "Try installing them manually, then run './setup.sh apps orw fonts man'"
		exit
	fi
}

function apps() {
	#compton with kawase blur
	get_app install tryone144 compton "sed -i '/^ifneq/! { /MANPAGES/d }' Makefile"

	#pip neovim installation
	sudo pip3 install neovim &> /dev/null || handle_failure "Failed to install pip neovim."

	#cava installation
	get_app install karlstav cava ./autogen.sh ./configure || handle_failure "Failed to install cava."

	#lemonbar installation
	get_app install krypt-n bar ~/.orw/scripts/add_borders_to_bar_source.sh || handle_failure "Failed to install bar."

	#dunst installation
	get_app install dunst-project dunst "make dunstify" "sudo cp dunstify /usr/local/bin"

	#fff installation
	get_app install dylanaraps fff || handle_failure "Failed to install fff."

	#colorpicker installation
	get_app install ym1234 colorpicker || handle_failure "Failed to install colorpicker."

	#i3lock-color installation
	get_app install PandorasFox i3lock-color "autoreconf --force --install" \
		"rm -rf build/" "mkdir -p build" "cd build/" "../configure --prefix=/usr --sysconfdir=/etc --disable-sanitizers"
}

function backup() {
	cd ~/$1
	echo "backing up files in ~/$1"

	for dir in $(find ~/.orw/dotfiles/$1 -maxdepth 1 ! -regex ".*\(dotfiles/\|config\|services\)"); do
		existing=${dir##*/}

		if [[ -e $existing ]]; then
			tar uf .backup_by_orw.tar.gz $existing
			rm -rf $existing
		fi

		ln -s $dir $existing
	done
}

function firefox() {
	if [[ -d ~/.mozilla ]]; then
		default_dir=$(ls -d ~/.mozilla/firefox/*default*)

		mkdir $default_dir/chrome
		ln -s ~/.orw/themes/firefox/userChrome.css $default_dir/chrome/
	fi
}

function orw() {
	echo 'setting up orw..'

	[[ -d ~/.fonts ]] || mkdir ~/.fonts
	[[ -d ~/.icons ]] || mkdir ~/.icons
	[[ -d ~/.themes ]] || mkdir ~/.themes

	firefox

	ln -s $destination/.fonts/* ~/.fonts
	ln -s $destination/themes/icons ~/.icons/orw
	ln -s $destination/themes/theme ~/.themes/orw

	echo 'linking config files..'

	backup
	backup .config

	services_dir=/etc/systemd/user
	[[ ! -d $services_dir ]] && sudo mkdir $services_dir
	sudo ln -s $destination/dotfiles/services/* $services_dir

	#deoplete - neovim completion plugin
	get_app download Shougo deoplete.nvim 'cp -r {autoload,*plugin} ~/.config/nvim' ||
		handle_failure 'Failed to install deoplete.'
	nvim -c UpdateRemotePlugins +qall! &> /dev/null

	ex_user=$(sed -n 's/user.*"\(.*\)"/\1/p' ~/.mpd/mpd.conf)
	sed -i "s/$ex_user/$(whoami)/" $destination/{scripts/{bar/generate_bar,wallctl,ncmpcpp*}.sh,dotfiles/{.mpd/mpd.conf,.ncmpcpp/config*,services/change_wallpaper.service}}

	[[ ! -f ~/.config/orw/config ]] && $destination/scripts/generate_orw_config.sh

	openbox --reconfigure
}

function fonts() {
	echo 'setting fonts..'
	fc-cache -f
}

function man() {
	echo 'adding mans..'
	sudo ln -s $destination/.man/* /usr/share/man/man1/
}

while read -r function; do
	${function##* }
done <<< $([[ $@ ]] && echo $@ | xargs -n1 || awk -F '[( ]' '/^fun/ {print $2}' $0)

((! $?)) && echo 'Installation completed succesfully, please re-login and enjoy! :)'
