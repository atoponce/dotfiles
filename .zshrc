# Make sure umask is set appropriately, login or not
umask 0002

# Variables for xterm and such
#TERM="xterm-256color"
#export LC_ALL="en_US.UTF-8"
#TERM="xterm"
HISTFILE=~"/.histfile"
HISTSIZE="10000"
SAVEHIST="10000"
EDITOR="vim"
VISUAL="vim"
PAGER="less"
NNTPSERVER="snews.eternal-september.org"

if [ "$TERM" = "putty" ]; then
    export LC_ALL=C
fi

# modifying the PATH adding the sbin directories
path+=( /sbin /usr/sbin /usr/local/sbin )
path=( ${(u)path} )

# various options to set/unset
setopt appendhistory
setopt share_history
unsetopt autocd beep
autoload -U promptinit
autoload -Uz compinit
autoload is-at-least

# modules to load
promptinit
compinit

zstyle :compinstall filename '~/.zshrc'

# keybindings. vim by default. others added for comfort
bindkey -v
bindkey -M viins '\e.' insert-last-word
bindkey -M vicmd '\e.' insert-last-word
bindkey -M viins '^r' history-incremental-search-backward
bindkey -M viins '^f' history-incremental-search-forward

# create a zkbd compatible hash;
# to add other keys to this hash, see: man 5 terminfo
typeset -A key
key[Home]=${terminfo[khome]}
key[End]=${terminfo[kend]}
key[Insert]=${terminfo[kich1]}
key[Delete]=${terminfo[kdch1]}
key[Up]=${terminfo[kcuu1]}
key[Down]=${terminfo[kcud1]}
key[Left]=${terminfo[kcub1]}
key[Right]=${terminfo[kcuf1]}
key[PageUp]=${terminfo[kpp]}
key[PageDown]=${terminfo[knp]}

for k in ${(k)key} ; do
    # $terminfo[] entries are weird in ncurses application mode...
    [[ ${key[$k]} == $'\eO'* ]] && key[$k]=${key[$k]/O/[}
done
unset k

# setup keys accordingly
[[ -n "${key[Home]}"   ]] && bindkey "${key[Home]}" beginning-of-line
[[ -n "${key[End]}"    ]] && bindkey "${key[End]}" end-of-line
[[ -n "${key[Insert]}" ]] && bindkey "${key[Insert]}" overwrite-mode
[[ -n "${key[Delete]}" ]] && bindkey "${key[Delete]}" delete-char
[[ -n "${key[Up]}"     ]] && bindkey "${key[Up]}" up-line-or-history
[[ -n "${key[Down]}"   ]] && bindkey "${key[Down]}" down-line-or-history
[[ -n "${key[Left]}"   ]] && bindkey "${key[Left]}" backward-char
[[ -n "${key[Right]}"  ]] && bindkey "${key[Right]}" forward-char

# work specific aliases
alias git.bo="ssh git.bo"
alias clearstorage0='ssh-keygen -R storage0.cab1 && ssh-keygen -R storage0.cab1.la.bo && ssh-keygen -R 172.10.1.120'
alias asdf="setxkbmap dvorak"
alias aoeu="setxkbmap us"

# general purpose aliases
alias ls='ls --color=auto -F'
alias .='source'
alias achilles='ssh achilles' # rely on ~/.ssh/config for fqdn and options
alias poseidon='ssh poseidon'
alias hera='ssh hera'
alias kratos='ssh kratos'
alias tunnelhome='pkill ssh; ssh -4fgN -D 8081 -L 8080:localhost:3128 -L 33306:localhost:3306 achilles'
alias mounthome='sshfs achilles:/ /home/aaron/pthree'
alias usbmodem="sudo pppd /dev/ttyACM0 call ppp-script-treo"
alias irc="sudo python /usr/local/bin/email-0mq.py& weechat-curses"

# general purpose functions
expandurl() { wget --spider -O - -S $1 2>&1 | awk '/^Location/ {gsub("?utm_.*",""); a=$2} END {print a}' }
longurl() { curl -s "http://api.longurl.org/v2/expand?url=${1}&format=php" | awk -F '"' '{gsub("?utm_.*",""); print $4}'}
shorturl() { wget -qO - 'http://ae7.st/s/yourls-api.php?signature=8e4f5d1d8d&action=shorturl&format=simple&url='"$1"; echo}
shuff(){ 
    if [ $(command -v shuf) ]; then
        shuf -n "$1"
    elif [ $(command -v shuffle) ]; then
        shuffle -f /dev/stdin -p "$1"
    else
        awk 'BEGIN{
            "od -tu4 -N4 -A n /dev/urandom" | getline
            srand(0+$0)
        }
        {print rand()"\t"$0}' | sort -n | cut -f 2 | head -n "$1"
    fi
}
gen_monkey_pass(){
    I=0
    [ $(printf "$1" | grep -E '[0-9]+') ] && NUM="$1" || NUM="1"
    until [ "$I" -eq "$NUM" ]; do
        I=$((I+1))
        LC_CTYPE=C strings /dev/urandom | \
            grep -o '[a-hjkmnp-z2-9-]' | head -n 24 | paste -s -d \\0 /dev/stdin
    done | column
}
gen_xkcd_pass(){
    I=0
    [ $(printf "$1" | grep -E '[0-9]+') ] && NUM="$1" || NUM="1"
    [ $(uname) = "SunOS" ] && FILE="/usr/dict/words" || FILE="/usr/share/dict/words"
    DICT=$(LC_CTYPE=C grep -E '^[a-zA-Z]{3,6}$' "$FILE")
    until [ "$I" -eq "$NUM" ]; do
        I=$((I+1))
        WORDS=$(printf "$DICT" | shuff 6 | paste -s -d ' ' /dev/stdin)
        XKCD=$(printf "$WORDS" | sed 's/ //g')
        printf "$XKCD ($WORDS)" | awk '{x=$1;$1="";printf "%-36s %s\n", x, $0}'
    done | column
}
shell-colors() {
    hexes=($(xrdb -query | sed -n 's/.*color\([0-9]\)/\1/p' | sort -nu | cut -f2))
    names=(black red green yellow blue magenta cyan white)
    
    # add -v argument for verbose output
    if [[ $# -eq 1 && $1 == "-v" ]]; then
        printf "┌────────────────────────────────────────────────────────┐\n"
        printf "│ Preview        Name         Bash      Urxvt      Hex   │\n"
        printf "├────────────────────────────────────────────────────────┤\n"
        for i in {0..7}; do
            #printf "%-35b" "│\e[0;$((30+$i))m ████████   $names[i+1]"
            printf "│\e[0;$((30+$i))m ████████   $names[i+1]\t"
            printf %s "\e[0;$((30+$i))m   "
            printf "\t"
            printf "%-10b" "color$i\t"
            printf "$hexes[i+1]\e[0m │\n"

            #printf "%-35b" "│\e[1;$((30+$i))m ████████   bold $names[i+1]"
            printf "│\e[1;$((30+$i))m ████████   bold $names[i+1]\t"
            printf %s "\e[1;$((30+$i))m   "
            printf "\t"
            printf "%-10b" "color$((i+8))\t"
            printf "$hexes[i+9]\e[0m │\n"
        done
        printf "└────────────────────────────────────────────────────────┘\n"
    else
        printf "\e[1;37m     BLK        RED        GRN        YEL        BLU        MAG        CYN        WHT\n"
        printf "────────────────────────────────────────────────────────────────────────────────────────\e[0m\n"
        for i in {0..7}; do
            printf "\e[$((30+$i))m █ $hexes[i+1] \e[0m"
        done
        printf "\n"
        for i in {8..15}; do
            printf "\e[1;$((22+$i))m █ $hexes[i+1] \e[0m"
        done
        printf "\n"
    fi
}
#source ~/src/scripts/pastebin.sh

if which dpkg &> /dev/null; then
    # apt aliases for Debian-based systems
    # alias pkg-clean="sudo apt-get autoclean && sudo apt-get autoremove && sudo aptitude clean && sudo aptitude remove"
    # alias pkg-filesearch="apt-file search"
    # aleas pkg-p
    alias apt-clean="sudo apt-get autoclean && sudo apt-get autoremove && sudo aptitude clean && sudo aptitude remove"
    if which apt-file > /dev/null; then
        alias apt-filesearch="apt-file search";
    fi
    alias apt-install="sudo aptitude -R install"
    if which deborphan > /dev/null; then
        alias apt-orphand="sudo deborphan | xargs sudo aptitude -y purge";
        #alias apt-clean="apt-clean && apt-orphand"
    fi
    alias apt-reinstall="sudo aptitude -R reinstall"
    alias apt-remove="sudo aptitude remove"
    alias apt-search="aptitude search"
    alias apt-show="aptitude show"
    alias apt-update="sudo aptitude update"
    alias apt-upgrade="sudo aptitude update && sudo aptitude safe-upgrade"
elif which rpm > /dev/null; then
    # yum aliases for Red Hat-based systems
    #alias yum-clean="sudo "
fi

# directory shortcuts
alias home="cd ~/"
alias desktop="cd ~/Desktop"

# archives and compression
extract() {
    if [[ -f $1 ]]; then
        case $1 in
            *.tar.bz2)  tar -xjf $1 ;;
            *.tar.gz)   tar -xzf $1 ;;
            *.tar.lzma) tar --lzma -xf $1 ;;
            *.bz2)      bunzip2 $1 ;;
            *.gz)       gunzip $1 ;;
            *.lzma)     unlzma $1 ;;
            *.rar)      unrar -e $1 ;;
            *.tar)      tar -xf $1 ;;
            *.tbz2)     tar -xjf $1 ;;
            *.tgz)      tar -xzf $1 ;;
            *.zip)      unzip -d ${$1%???} $1 ;;
            *.Z)        gunzip $1 ;;
            *.7z)       7z x $1 ;;
            *)          echo "Unsupported compressed file type." ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

mktar() { tar -cf "${1%%/}.tar" "${1%%/}/"; }
mktgz() { tar -czf "${1%%/}.tar.gz" "${1%%/}/"; }
mktbz() { tar -cjf "${1%%/}.tar.bz2" "${1%%/}/"; }
mktlz() { tar --lzma -cf "${1%%/}.tar.lzma" "${1%%/}/"; }

# We can't forget the prompt!
source ~/.zsh_prompt

#if [ "$PS1" ]; then  
#    mkdir -p -m 0700 /dev/cgroup/cpu/user/$$ > /dev/null 2>&1
#    echo $$ > /dev/cgroup/cpu/user/$$/tasks
#    echo "1" > /dev/cgroup/cpu/user/$$/notify_on_release
#fi

PATH="/home/atoponce/perl5/bin${PATH+:}${PATH}"; export PATH;
PERL5LIB="/home/atoponce/perl5/lib/perl5${PERL5LIB+:}${PERL5LIB}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="/home/atoponce/perl5${PERL_LOCAL_LIB_ROOT+:}${PERL_LOCAL_LIB_ROOT}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"/home/atoponce/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=/home/atoponce/perl5"; export PERL_MM_OPT;
