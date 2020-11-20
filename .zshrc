# Make sure umask is set appropriately, login or not
umask 0002

# Variables for xterm and such
export LC_ALL="en_US.UTF-8"
HISTFILE=~"/.histfile"
HISTSIZE="10000"
SAVEHIST="10000"
EDITOR="vim"
VISUAL="vim"
PAGER="less"

if [[ "$TERM" = "putty" ]]; then
    export LC_ALL=C
fi

# modifying the PATH adding the sbin directories
path+=( /sbin /usr/sbin /usr/local/sbin )
path=( ${(u)path} )

# various options to set/unset
setopt appendhistory
setopt share_history
setopt prompt_subst

unsetopt autocd beep

autoload -U colors
autoload -U promptinit
autoload -Uz compinit
autoload is-at-least

# modules to load
colors
promptinit
compinit

zstyle :compinstall filename '~/.zshrc'

### Keybindings
# vim by default. others added for comfort
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

### SSH agent
#start_ssh_agent() {
#    echo "ssh-agent is not running. Starting..."
#    eval $(ssh-agent | tee /run/systemd/users/$UID/ssh/agent.sh)
#    ssh-add
#}
#
#if [[ -d /run/systemd/users/$UID/ssh ]]; then
#    if [[ -f /run/systemd/users/$UID/ssh/agent.sh ]]; then
#        source /run/systemd/users/$UID/ssh/agent.sh > /dev/random
#        ps $SSH_AGENT_PID > /dev/random
#        if [[ $? != "0" ]]; then start_ssh_agent; fi
#    else
#        start_ssh_agent
#    fi
#else
#    mkdir /run/systemd/users/$UID/ssh
#    start_ssh_agent
#fi

### General purpose aliases
alias ls='ls --color=auto'

### General purpose functions
alphaimg() {
    convert $1 -alpha on -channel A -evaluate set 99% +channel $1
    optipng -q $1
}

expandurl() {
    # Improvement from https://gist.github.com/jlp78/f103beb941842ee1c59fa8b24640684a
    (torsocks wget --spider -O - -S $1 2>&1 |
	awk '/^Location/ {gsub("\\?utm_.*$",""); print $2; exit 0} 
	     /socks5 libc connect: Connection refused/ {exit 1}') ||
    (echo "warning, TOR not enabled"
	wget --spider -O - -S $1 2>&1 |
	awk '/^Location/ {gsub("\\?utm_.*$",""); print $2; exit 0}')
}

shorturl() {
    wget -qO - 'http://ae7.st/s/yourls-api.php?signature=8e4f5d1d8d&action=shorturl&format=simple&url='"$1"
    echo
}

### Password generators
shuff() {
    # Tries to use a CSPRNG for shuffling
    # /dev/urandom and /dev/stdin are not POSIX
    if [ "$(command -v shuf)" ]; then
        shuf -n "$1" --random-source=/dev/urandom
    elif [ "$(command -v shuffle)" ]; then
        # NetBSD uses arc4random_uniform() in src/usr.bin/shuffle/shuffle.c
        shuffle -f /dev/stdin -p "$1"
    else
        awk 'BEGIN{
            "od -tu4 -N4 -A n /dev/urandom" | getline
            srand(0+$0)
        }
        {print rand()"\t"$0}' | sort -n | cut -f 2 | head -n "$1"
    fi
}
gen_monkey_pass() {
    # Generates an unambiguous password with at least 128 bits entropy 
    # Uses Crockford's base32
    # /dev/urandom is not POSIX
    i=0
    [ $(printf "$1" | grep -E '[0-9]+') ] && num="$1" || num="1"
    until [ "$i" -eq "$num" ]; do
        i=$((i+1))
        LC_ALL=C tr -cd '0-9a-hjkmnp-tv-z' < /dev/urandom |\
            dd bs=1 count=26 2> /dev/null 
        echo # add newline
    done | column
}
gen_xkcd_pass() {
    # Generates a passphrase with at least 128 bits entropy
    # /dev/stdin is not POSIX
    i=0
    [ $(printf "$1" | grep -E '[0-9]+') ] && num="$1" || num="1"
    # Solaris, Illumos, FreeBSD, OpenBSD, NetBSD, GNU/Linux, OS X:
    [ $(uname) = "SunOS" ] && file="/usr/dict/words" || file="/usr/share/dict/words"
    dict=$(LC_ALL=C grep -E '^[a-zA-Z]{3,6}$' "$file")
    size=$(printf "$dict" | wc -l | sed -e 's/ //g')
    entropy=$(printf "l(${size})/l(2)\n" | bc -l)
    words=$(printf "(128+${entropy}-1)/${entropy}\n" | bc)
    until [ "$i" -eq "$num" ]; do
        i=$((i+1))
        printf "$dict" | shuff "$words" | paste -s -d '.' /dev/stdin
    done | column
}

### Prompt
loc=5
walk=(0 0 0 0 1 0 0 0 0)
typeset -A compass=(1 "NW" 2 "NE" 3 "SW" 4 "SE") # not necessary, here for readability
typeset -A coins=( # heat map and coin weight
    0 " "
    1 '%B%F{093}.%f%b'
    2 '%B%F{021}:%f%b'
    3 '%B%F{033}-%f%b'
    4 '%B%F{051}=%f%b'
    5 '%B%F{047}+%f%b'
    6 '%B%F{190}*%f%b'
    7 '%B%F{220}#%f%b'
    8 '%B%F{208}&%f%b'
    9 '%B%F{196}@%f%b'
)

precmd() {
    if [[ -w $PWD ]]; then cdir=$(print -P '%~')
    else cdir=$(print -P '%B%F{red}%~%f%b')
    fi

    PROMPT="\
$coins[$walk[1]]$coins[$walk[2]]$coins[$walk[3]] %B%n@%M:$cdir%b
$coins[$walk[4]]$coins[$walk[5]]$coins[$walk[6]] %B%D %T%b
$coins[$walk[7]]$coins[$walk[8]]$coins[$walk[9]] %B%(?..%F{red}%?%f)%(!.%F{red}#%f.%F{green}%%%f)%b "

    local num=$(tr -cd 1234 < /dev/urandom | head -c 1)
    if [[ $loc -eq 1 ]]; then
          if [[ $compass[$num] == "NW" ]]; then loc=1; (( walk[$loc]+=1 ))
        elif [[ $compass[$num] == "NE" ]]; then loc=2; (( walk[$loc]+=1 ))
        elif [[ $compass[$num] == "SW" ]]; then loc=4; (( walk[$loc]+=1 ))
        elif [[ $compass[$num] == "SE" ]]; then loc=5; (( walk[$loc]+=1 ))
        fi
    elif [[ $loc -eq 2 ]]; then
          if [[ $compass[$num] == "NW" ]]; then loc=1; (( walk[$loc]+=1 ))
        elif [[ $compass[$num] == "NE" ]]; then loc=3; (( walk[$loc]+=1 ))
        elif [[ $compass[$num] == "SW" ]]; then loc=4; (( walk[$loc]+=1 ))
        elif [[ $compass[$num] == "SE" ]]; then loc=6; (( walk[$loc]+=1 ))
        fi
    elif [[ $loc -eq 3 ]]; then
          if [[ $compass[$num] == "NW" ]]; then loc=2; (( walk[$loc]+=1 ))
        elif [[ $compass[$num] == "NE" ]]; then loc=3; (( walk[$loc]+=1 ))
        elif [[ $compass[$num] == "SW" ]]; then loc=5; (( walk[$loc]+=1 ))
        elif [[ $compass[$num] == "SE" ]]; then loc=6; (( walk[$loc]+=1 ))
        fi
    elif [[ $loc -eq 4 ]]; then
          if [[ $compass[$num] == "NW" ]]; then loc=1; (( walk[$loc]+=1 ))
        elif [[ $compass[$num] == "NE" ]]; then loc=2; (( walk[$loc]+=1 ))
        elif [[ $compass[$num] == "SW" ]]; then loc=7; (( walk[$loc]+=1 ))
        elif [[ $compass[$num] == "SE" ]]; then loc=8; (( walk[$loc]+=1 ))
        fi
    elif [[ $loc -eq 5 ]]; then
          if [[ $compass[$num] == "NW" ]]; then loc=1; (( walk[$loc]+=1 ))
        elif [[ $compass[$num] == "NE" ]]; then loc=3; (( walk[$loc]+=1 ))
        elif [[ $compass[$num] == "SW" ]]; then loc=7; (( walk[$loc]+=1 ))
        elif [[ $compass[$num] == "SE" ]]; then loc=9; (( walk[$loc]+=1 ))
        fi
    elif [[ $loc -eq 6 ]]; then
          if [[ $compass[$num] == "NW" ]]; then loc=2; (( walk[$loc]+=1 ))
        elif [[ $compass[$num] == "NE" ]]; then loc=3; (( walk[$loc]+=1 ))
        elif [[ $compass[$num] == "SW" ]]; then loc=8; (( walk[$loc]+=1 ))
        elif [[ $compass[$num] == "SE" ]]; then loc=9; (( walk[$loc]+=1 ))
        fi
    elif [[ $loc -eq 7 ]]; then
          if [[ $compass[$num] == "NW" ]]; then loc=4; (( walk[$loc]+=1 ))
        elif [[ $compass[$num] == "NE" ]]; then loc=5; (( walk[$loc]+=1 ))
        elif [[ $compass[$num] == "SW" ]]; then loc=7; (( walk[$loc]+=1 ))
        elif [[ $compass[$num] == "SE" ]]; then loc=8; (( walk[$loc]+=1 ))
        fi
    elif [[ $loc -eq 8 ]]; then
          if [[ $compass[$num] == "NW" ]]; then loc=4; (( walk[$loc]+=1 ))
        elif [[ $compass[$num] == "NE" ]]; then loc=6; (( walk[$loc]+=1 ))
        elif [[ $compass[$num] == "SW" ]]; then loc=7; (( walk[$loc]+=1 ))
        elif [[ $compass[$num] == "SE" ]]; then loc=9; (( walk[$loc]+=1 ))
        fi
    elif [[ $loc -eq 9 ]]; then
          if [[ $compass[$num] == "NW" ]]; then loc=5; (( walk[$loc]+=1 ))
        elif [[ $compass[$num] == "NE" ]]; then loc=6; (( walk[$loc]+=1 ))
        elif [[ $compass[$num] == "SW" ]]; then loc=8; (( walk[$loc]+=1 ))
        elif [[ $compass[$num] == "SE" ]]; then loc=9; (( walk[$loc]+=1 ))
        fi
    fi
    
    # there are only 9 coin weights: .:-=+*#%@
    for cell in {1..9}; do
        if [[ $walk[$cell] -gt 9 ]]; then
            (( walk[$cell]=9 ))
        fi
    done

    # reset when the drunk bishop has visited every cell 9 times
    if [[ $walk[@] == "9 9 9 9 9 9 9 9 9" ]]; then
        walk=(0 0 0 0 1 0 0 0 0)
    fi
}
