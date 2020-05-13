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

color_module() {
	echo "\[\033[${1}8;2;${2}2m\]"
}

format_module() {
	local OPTIND b f c

	while getopts :b:f:c: flag; do
		case $flag in
			b)
				#if [[ $reverse ]]; then
				#	[[ $mode == rice && $edge_mode != flat && $last_bg && $last_bg != default ]] &&
				#		local edge="$(color_module 3 $last_bg)$edge_symbol"
				#fi




				if [[ $mode == rice && $edge_mode != flat ]]; then
					if [[ $reverse ]]; then
						[[ ! $last_module ]] && local edge="$(color_module 3 $OPTARG)$edge_symbol"
					else
						[[ $last_bg && $last_bg != default ]] &&
							local edge="$(color_module 3 $last_bg)$edge_symbol"
					fi
				fi

				#[[ ! ($reverse && $last_bg == default) ]] && local
				#[[ $mode == rice && $edge_mode != flat && $last_bg && $last_bg != default ]] &&
				#	local edge="$(color_module 3 $last_bg)$edge_symbol"



				#[[ $OPTARG == default ]] && local mbg=$default || local mbg="$(color_module 4 $OPTARG)"
				[[ $OPTARG == default ]] && local mbg=$default || local mbg="$(color_module 4 $OPTARG)"
				last_bg=$OPTARG;;
			f)
				[[ $OPTARG == default ]] && local fg=$fg || local fg=$OPTARG
				mfg="$(color_module 3 $fg)";;
			c)
				local content="$OPTARG"
				(( content_length += ${#content} ))
				[[ $content =~ [[:alnum:]] && $edge_mode != flat ]] && (( content_length++ ))
				#(( content_length += ${#content} ));;
		esac
	done

	[[ $reverse ]] && all_modules+="$edge$mbg$mfg$content" || all_modules+="$mbg$edge$mfg$content"
	#all_modules+="$mbg$edge$mfg$content"
}

get_branch_info() {
	read branch icon clean s <<< $(git status -sb 2> /dev/null | \
		awk -F '[,.\\[\\]]' 'NR == 1 { b = gensub(/.* /, "", 1, $1); \
		r = NF; if(r > 4) for(f = 5; f < NF; f++) \
		{ i = ($f ~ /^ ?a/) ? "  " : "  "; \
			s = s gensub(/ ?.* /, i, 1, $f) } } \
			END { if(b) print b, (r > 1) ? "╋" : "┣", (NR == 1), s }')

	eval $(git status --porcelain 2> /dev/null | \
		awk '{ if(/^\s*M/) m++; else if(/^\s*D/) d++; else if(/^A/) a++; else if(/^\?/) u++ } \
		END { i = "'$1'"; \
		if(i ~ "m" && m) o = "m=\"  "m"\""; \
			if (i ~ "d" && d) o = o" d=\"  "d"\""; \
				if(i ~ "a" && a) o = o" a=\"  "a"\""; \
					if(i ~ "u" && u) o = o" u=\"  "u"\""; \
						print o }')

	if [[ $1 ]]; then
		for branch_module in ${1//,/ }; do
			branch_module_content=${!branch_module}
			[[ $branch_module_content ]] && sorted_branch_modules+=" $branch_module_content"
		done
	fi

	if [[ $branch ]]; then
		((clean)) && gc=$gcc || gc=$gdc

		if [[ $mode == simple ]]; then
			[[ $start_bracket ]] && all_modules+=$start_bracket
			format_module -f $gc -c "$branch$sorted_branch_modules$end_bracket"
		else
			format_module -b $gc -f $bg -c " $icon $branch$sorted_branch_modules "
		fi
	fi
}

get_virtual_env() {
	if [[ $VIRTUAL_ENV ]]; then
		if [[ $mode == simple ]]; then
			[[ $start_bracket ]] && all_modules+=$start_bracket
			format_module -f $vc -c "${VIRTUAL_ENV##*/}$end_bracket"
		else
			format_module -b $vc -c "   ${VIRTUAL_ENV##*/}"
		fi
	fi
}

get_basic_info() {
	for info in ${1//,/ }; do
		#((${#info} == 1)) && infos+="\\$info" || info="${info:1: -1}" infos+="${info//_/ }"
		case $info in
			u) infos+="$(whoami)";;
			h) infos+="$(hostname)";;
			*) infos+="${info//_/ }";;
		esac
	done

	if [[ $mode == simple ]]; then
		format_module -f $ic -c "$infos"
	else
		format_module -b $ic -c " $infos "
	fi
}

set_edge() {
	[[ $edge_mode != flat ]] && case $edge_mode in
		fade) [[ $reverse ]] && edge_symbol='' || edge_symbol='';;
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
				if [[ $mode == rice ]]; then
					format_module -b default -c ""

					reverse=true
					right_align=true
					left_part_length=${#all_modules}
					left_content_length=$content_length

					set_edge
				fi;;
			w)
				format_module -b $bg -f $fg -c "$working_directory"
				[[ $mode == rice ]] && format_module -f $bg;;
			s*)
				if [[ $mode == rice ]]; then
					#((${#module} > 1)) && separator="$(printf '%*.s' ${module:1} ' ')"
					((${#module} > 1)) && separator_length=${module:1}
					separator="$(printf '%*.s' ${separator_length-1} ' ')"
					format_module -b default -c "${separator- }"

					(( content_length += ${separator_length-1} ))
					before_separator_content_length=$content_length

					#for reverse edge on next module
					reverse=true
					set_edge

					#format_module -b default -c "${separator- }"
					#all_modules+="$default${separator_length:- }"
					#(( content_length += ${separator_length-1} ))
				fi
		esac

		[[ $module == ${modules##*,} ]] && last_module=true

		#if [[ $edge_mode != flat && ${modules%,$module*} =~ ,s$ ]]; then
		if [[ $edge_mode != flat && $before_separator_content_length && $content_length -gt $before_separator_content_length ]]; then
			unset reverse before_separator_content_length
			set_edge
		fi
	done

	all_modules+="$default"

	if [[ $right_align ]]; then
		left=${all_modules:0:left_part_length}
		right=${all_modules:left_part_length}
		#[[ $edge_mode != flat ]] && edge_length=${modules//+([sr,])}
		separator_length="$(printf "%*s" $((COLUMNS - content_length - 1)) ' ')"
		all_modules="$left$default$separator_length$right"
	fi
}

generate_ps1() {
	local exit_code=$?

	bg="default"
	fg="65;66;68;"
	sc="65;66;68;"
	ic="107;160;164;"
	sec="129;98;92;"
	gcc="135;147;148;"
	gdc="113;94;66;"
	vc="135;147;156;"

	clean="\[$(tput sgr0)\]"
	#separator="$clean $clean"

	((exit_code)) && sc=$sec || sc=$sc

	pid=$$

    if [[ $(ps -ef | awk '/tmux.*ncmpcpp_with_cover_art/ && !/awk/ && $2 + 1 == '$pid' {print "cover"}') ]]; then
		echo ''
	else
		mode=simple
		edge_mode=flat

		set_edge

		#modules
		info_module="h"
		git_module="s,m,a,d,u"

		#modules="i:u_'on'_h,w,g:s_m_a_d_u,v"
		#modules="i,w,v,r,g"
		modules="w,v,g"

		if [[ $mode == simple ]]; then
			start_bracket="$(color_module 3 $fg)("
			end_bracket="$(color_module 3 $fg))"

			working_directory=' \W'

			format_module -f $fg -b $bg
			color_modules
			format_module -f $sc -c ' '
		else
			if [[ $edge_mode == sharp ]]; then
				symbol_start='╭── '
				symbol_end='╰────'
			else
				symbol_start='┌─╼ '
				symbol_end='└────╼'
			fi

			working_directory=" $(pwd | sed "s/${HOME//\//\\\/}//; s/\//  /g") "
			working_directory=" $(pwd | sed "s/${HOME//\//\\\/}/ /; s/\//  /g") "
			working_directory=" $(pwd | sed "s/${HOME//\//\\\/}/ /; s/\//    /g") "
			working_directory=" $(pwd | sed "s/${HOME//\//\\\/}/ /; s/\//    /g") "
			working_directory=" $(pwd | sed "s/${HOME//\//\\\/}/ /; s/\//    /g") "
			working_directory=" $(pwd | sed "s/${HOME//\//\\\/}/ /; s/\//    /g") "

			format_module -f $sc -c "$symbol_start"
			format_module -f $bg
			color_modules
			format_module -b '' -c '\n'
			format_module -f $sc -c "$symbol_end"
		fi

		all_modules+=$default

		echo -e "$all_modules "
	fi
}

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

#fff colors
export FFF_LS_COLORS=0
export FFF_COL1=3
export FFF_COL2=2
export FFF_COL3=2
export FFF_COL4=9

export EDITOR='nvim'
export TERM=xterm-256color
export PATH="$PATH:/sbin:~/.orw/scripts"
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

#tiling
alias hat="$scripts/half_and_tile.sh"

#source bashrc
alias sb="source ~/.bashrc"

#tmux
alias tmux="tmux -f ~/.config/tmux/tmux.conf"
