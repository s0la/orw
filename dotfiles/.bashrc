# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

color_content() {
	echo "\[\033[${1}8;2;${2%;}m\]"
}

format_module() {
	local OPTIND B b f c

	while getopts :b:f:c:B flag; do
		case $flag in
			B) local bold='\[\033[1m\]' unbold='\[\033[0m\]';;
			b)
				if [[ $mode == rice ]]; then
					if [[ $edge_mode == flat ]]; then
						if [[ $module == r ]]; then
							local edge_symbol="$(fading_blocks end)"
							local edge="$default$(color_content 3 $last_bg)$edge_symbol"
							((content_length += 3))
						elif [[ $right_align ]] && ((left_part_length == ${#all_modules})); then
							local edge_symbol="$(fading_blocks start)"
							local edge="$(color_content 3 $OPTARG)$edge_symbol"
							((content_length += 3))
						fi
					else
						if [[ $reverse ]]; then
							local content="${@: -1}"
							[[ ${content// /} && ! $last_module ]] &&
								local edge="$(color_content 3 $OPTARG)$edge_symbol"
						else
							[[ $last_bg && $last_bg != default ]] &&
								local edge="$(color_content 3 $last_bg)$edge_symbol"
						fi
					fi
				fi

				[[ $OPTARG == default ]] && local mbg=$default || local mbg="$(color_content 4 $OPTARG)"
				last_bg=$OPTARG;;
			f)
				[[ $OPTARG == default ]] && local fg=$fg || local fg=$OPTARG
				mfg="$(color_content 3 $fg)";;
			c)
				local content="$OPTARG"
				(( content_length += ${#content} ))
				[[ $content && $mode == rice && $edge_mode != flat &&
					${FUNCNAME[-2]} == color_modules ]] && (( content_length++ ))
		esac
	done

	if [[ $add_separator && $edge_mode != flat ]]; then
		[[ ${content// /} || $reverse ]] && local separator_fg="$(color_content 3 $term_bg)$edge_symbol"
		[[ $content || $reverse ]] && (( content_length++ ))
	fi

	[[ $reverse ]] &&
		all_modules+="$separator_fg$edge$mbg$mfg$bold$content$unbold" ||
		all_modules+="$mbg$separator_fg$edge$mfg$bold$content$unbold"
}

get_branch_info() {
	read branch icon clean changes <<< $(git status -sb 2> /dev/null | \
		awk -F '[,.\\[\\]]' '\
			NR == 1 {
				b = gensub(/[^ ]* ([^ ]*)(\\.\\.\\.)?.*/, "\\1", 1)
				sub("\\.\\.\\..*", "", b)
				r = NF

				f_start = (/\.\.\./) ? 5 : 4

				if(r > f_start) for(f = 5; f < NF; f++) {
					i = ($f ~ /^ ?a/) ? "  " : "  "
					s = s gensub(/ ?.* /, i, 1, $f)
				}

				s = "s=\"" ((s) ? s : 0) "\""; i = ""
			}

			NR > 1 {
				if(/^\s*M/) m++
				else if(/^\s*D/) d++
				else if(/^A/) a++
				else if(/^\?/) u++
				if(!/^\?/ && index($0, $1) == 1) i++
			}

			END {
				gm = "'$1'"
				#if(gm ~ "m" && m) c = c " m=\"  "m"\""
				#if(gm ~ "m" && m) c = c " m=\"  "m"\""
				if(gm ~ "m" && m) c = c " m=\"  "m"\""
				if(gm ~ "i" && i) c = c " i=\"  "i"\""
				if(gm ~ "d" && d) c = c " d=\"  "d"\""
				if(gm ~ "a" && a) c = c " a=\"  "a"\""
				if(gm ~ "u" && u) c = c " u=\"  "u"\""
				#if(gm ~ "u" && u) c = c " u=\"  "u"\""

				if(b) print b, (r > 1) ? "╋" : "┣", (NR == 1), s, c }')

			eval "$changes"

	if [[ $1 ]]; then
		for branch_module in ${1//,/ }; do
			branch_module_content=${!branch_module}
			[[ $branch_module == s && ${branch_module_content##* } -eq 0 ]] && continue
			[[ $branch_module_content ]] && sorted_branch_modules+=" $branch_module_content"
		done
	fi

	if [[ $branch ]]; then
		((clean)) && gc=$gcc || gc=$gdc

		if [[ $mode == simple ]]; then
			[[ $start_bracket ]] && format_module -f $fg -Bc "("
			format_module -f $gc -c "$branch$sorted_branch_modules"
			[[ $start_bracket ]] && format_module -f $fg -Bc ")"
			(( content_length += 2 ))
		else
			format_module -b $gc -f $fg -c " $icon $branch$sorted_branch_modules "
		fi
	fi
}

get_virtual_env() {
	if [[ $VIRTUAL_ENV ]]; then
		if [[ $mode == simple ]]; then
			[[ $start_bracket ]] && all_modules+=$start_bracket
			format_module -f $vc -c "${VIRTUAL_ENV##*/}"
			all_modules+="$end_bracket"
			(( content_length += 2 ))
		else
			format_module -b $vc -c "   ${VIRTUAL_ENV##*/} "
		fi
	fi
}

get_basic_info() {
	[[ $mode == simple ]] &&
		local info_flag=f || local info_flag=b space=' '

	for info in ${1//,/ }; do
		case $info in
			u) info_content="$(whoami)";;
			h) info_content="$(hostname)";;
			*)
				bold_info=B
				info_content="${info//_/ }"
				;;
		esac

		format_module -$info_flag $ic -${bold_info}c "$space$info_content$space"
		unset bold_info
	done
}

set_edge() {
	[[ $edge_mode != flat ]] && case $edge_mode in
		flat_fade)
			[[ $reverse ]] && local position=end || local position=start
			edge_symbol=$(fading_blocks $position);;
		sharp) [[ $reverse ]] && edge_symbol='' || edge_symbol='';;
		round) [[ $reverse ]] && edge_symbol='' || edge_symbol='';;
	esac
}

color_modules() {
	default='\[\033[0m\]'

	for module in ${modules//,/ }; do
		case $module in
			v) get_virtual_env;;
			i*) get_basic_info "$info_module";;
			g*) get_branch_info "$git_module";;
			r)
				format_module -b default -c ""

				[[ $mode == simple ]] &&
					format_module -f $fg -Bc " ]"

				reverse=true
				right_align=true
				left_part_length=${#all_modules}

				[[ $mode == simple ]] &&
					(( content_length += 2 )) || set_edge
				left_content_length=$content_length
				;;
			[Ww])
				[[ $mode == simple ]] &&
					local bg=default working_dir_bg=$default ||
					local working_dir_bg="$(color_content 4 $bg)" dir_side_sep='\ '

				if [[ $module == W ]]; then
					IFS='/' read -a path_sections <<< "${PWD/$HOME/${dir_side_sep}\~}"

					for path_index in ${!path_sections[*]}; do
						((path_index)) && format_module -b $bg -f $fg -Bc " › "
						format_module -b $bg -f $fg -c "${path_sections[path_index]}"
					done
				else
					format_module -b $bg -f $fg -c "${PWD##*/}"
				fi

				[[ $mode == rice ]] &&
					all_modules+=' ' && ((content_length++))
				[[ $mode == rice ]] && format_module -f $bg;;
			s*)
				if [[ $mode == rice ]]; then
					add_separator=true

					[[ $term_bg ]] ||
						term_bg=$(awk -F '[()]' '/^background/ {
									gsub(",", ";")
									print gensub("(.*;).*", "\\1", 1, $(NF - 1))
								}' ~/.config/termite/config)

					((${#module} > 1)) && separator_length=${module:1} || separator_length=1
					[[ $edge_mode != flat ]] && (( separator_length-- ))
					((separator_length)) && separator="$(printf '%*.s' $separator_length ' ')"

					format_module -b default -c "$separator"
					before_separator_content_length=$content_length
				fi
		esac

		[[ $module == ${modules##*,} ]] && last_module=true
		[[ ! $module =~ ^s || $reverse ]] && unset add_separator separator_length
	done

	all_modules+="$default"

	if [[ $right_align ]]; then
		left=${all_modules:0:left_part_length}
		right=${all_modules:left_part_length}

		separator_length=$((COLUMNS - content_length))

		#if [[ $modules == *d* ]]; then
		if [[ $modules == *r* ]]; then
			[[ $mode == rice ]] && local side_separators=3
			dashed_symbol='•'
			dashed_symbol=''
			dashed_symbol='━'
			[[ $modules == *d* ]] &&
				symbol='━' || symbol=' '
			half_length=$((separator_length / 2 - 0))
			separator_content=$(printf "$symbol%.0s" \
				$(eval echo {0..$((separator_length - side_separators))}))
			separator_content=" $separator_content"
			[[ $mode == rice ]] &&
				((content_length > left_content_length)) && separator_content+=' '
		fi

		separator="$default$(color_content 3 $dc)$separator_content"

		if [[ $mode == simple && ! $separator_content ]]; then
			local save_cursor='\e[s'
			local restore_cursor='\e[u'
		fi

		all_modules="$left$save_cursor$default$separator$right$restore_cursor"
	fi
}

fading_blocks() {
	[[ $1 == end ]] &&
		sequence='{3..1}' || sequence='{1..3}'

	for i in $(eval echo $sequence); do
		echo -en "\u259$i"
	done
}

generate_ps1() {
	local exit_code=$?

	bg="default"
	fg="67;70;82;"
	sc="67;70;82;"
	dc="67;70;82;"
	ic="93;150;175;"
	sec="76;112;123;"
	gcc="76;112;123;"
	gdc="186;96;138;"
	vc="109;80;125;"

	clean='\[\033[0m\]'

	((exit_code)) && sc=$sec || sc=$sc

	pid=$$

    if [[ $(ps -ef | awk '/tmux.*ncmpcpp_with_cover_art/ && !/awk/ && $2 + 1 == '$pid' {print "cover"}') ]]; then
		echo ''
	else
		mode=simple
		edge_mode=flat

		set_edge

		info_module="u,┃"
		[[ $mode == simple ]] &&
			info_module='u,|' || info_module="u"
		git_module="s,m,i,a,d,u"

		modules="i,W,g,v"

		full_length=$(tput cols)
		half_length=$(echo $full_length / 2 - 2 | bc)

		if [[ $mode == simple ]]; then
			start_bracket="$(color_content 3 $fg)("
			end_bracket="$(color_content 3 $fg))"

			format_module -f $fg -b default -Bc "[ "
			color_modules

			((content_length > 55)) &&
				prompt_start='┌─' prompt_end='└─╼'

			if [[ $prompt_start ]]; then
				start="$(color_content 3 $sc)$prompt_start"
				all_modules="$start$all_modules"
			fi

			[[ $reverse ]] || format_module -f $fg -Bc " ]"

			if [[ $prompt_end ]]; then
				all_modules+='\n'
				format_module -f $sc -Bc "$prompt_end"
			else
				format_module -f $sc -Bc '›'
			fi
		else
			if [[ $edge_mode == sharp ]]; then
				symbol_start='╭── '
				symbol_end='╰────›'
				symbol_start='┌── '
				symbol_end='└────›'
				symbol_start='┌─╼ '
				symbol_end='└────╼'
			else
				symbol_start='┌─╼ '
				symbol_end='└────╼'
			fi

			format_module -f $sc -c "$symbol_start"
			format_module -f $bg
			color_modules
			format_module -b '' -c '\n'
			format_module -f $sc -c "$symbol_end"
		fi

		all_modules="$dashed$all_modules"
		all_modules+=$default

		echo -e "$all_modules "
	fi
}

redraw_prompt() {
	echo -ne '\033[s\033[1F\033[0K\033[u'
}

regenerate_ps1() {
	source ~/.bashrc
	clear
}

trap regenerate_ps1 USR1

[[ $blank ]] &&
	PROMPT_COMMAND='PS1=""' ||
	PROMPT_COMMAND='PS1="$(generate_ps1)"'

ras() {
	~/.orw/scripts/rice_and_shine.sh $@

	if [[ $@ =~ (bash|-R all) && ! $@ =~ "-r no" ]]; then
		source ~/.bashrc
	fi
}

toggle() {
	~/.orw/scripts/toggle.sh $@

	if [[ $1 == bash ]]; then
		source ~/.bashrc
	fi
}

set_status_modules() {
	~/.orw/scripts/set_status_modules.sh $@

	if [[ $1 == bash ]]; then
		source ~/.bashrc
	fi
}

remove_id() {
	sed 's/^[0-9]*\s*//'
}

show_tty_clock() {
	local color=$(sed -n 's/visualizer_color.*,//p' ~/.config/ncmpcpp/config)
	tty-clock -cBDC $((color - 1))
}

#fff colors
export FFF_LS_COLORS=0
export FFF_COL1=3
export FFF_COL2=2
export FFF_COL3=2
export FFF_COL4=9

export EDITOR='nvim'
export TERM=xterm-256color
export PATH="$PATH:/sbin:/usr/local/go/bin:~/.local/bin:~/.orw/scripts"
export XDG_CONFIG_HOME="$HOME/.config"
export GTK2_RC_FILES="$HOME/.config/gtk-2.0/gtkrc-2.0"

#aliases
alias srec="~/.orw/scripts/record_screen.sh -d display_1"
alias rec="~/.orw/scripts/record_screen.sh"
alias kbar="killall {bar,main}.sh lemonbar"
alias mute="amixer -q -D pul set Master toggle"
alias vol="amixer -q set Master"
alias la='ls -lah'
alias ld='ls -lhd'
alias lt='ls -lht'
alias ll='ls -lh'

#script aliases
scripts=~/.orw/scripts

#ctls
alias barctl="$scripts/barctl.sh"
alias borderctl="$scripts/borderctl.sh"
alias windowctl="$scripts/windowctl.sh"

#colors
alias rbar="$scripts/rice_and_shine.sh -m bar"
alias rbash="$scripts/rice_and_shine.sh -m bash"
alias rrofi="$scripts/rice_and_shine.sh -m rofi"
alias rob="$scripts/rice_and_shine.sh -m ob"
alias rterm="$scripts/rice_and_shine.sh -m term"
alias rdunst="$scripts/rice_and_shine.sh -m dunst"
alias rncmpcpp="$scripts/rice_and_shine.sh -m ncmpcpp"

#borders
alias bw="$scripts/borderctl.sh bw"
alias jt="$scripts/borderctl.sh jt"
alias tb="$scripts/borderctl.sh tb"
alias tbh="$scripts/borderctl.sh tbh"

#ncmpcpp
alias ncmpcpp="$scripts/ncmpcpp.sh"

#rice mode
alias toggle_rice="source $scripts/toggle.sh"
alias toggle_bash="source $scripts/toggle.sh bash"
alias toggle_tmux="$scripts/toggle.sh tmux"

#source bashrc
alias sb="source ~/.bashrc"
alias blk="~/.orw/scripts/blocks1"
alias stc="show_tty_clock"

#tmux
alias tmux="tmux -f ~/.config/tmux/tmux.conf"
alias nf="clear && neofetch"

#startx
if [[ `tty` == '/dev/tty1' ]]; then
	pidof openbox || startx ~/.orw/dotfiles/.config/X11/xinitrc
fi

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
. "$HOME/.cargo/env"

#neovim
alias nvim='/opt/nvim-linux64/bin/nvim'

#[ -f ~/.fzf.bash ] && source ~/.fzf.bash
