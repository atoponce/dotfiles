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

autoload -U colors && colors
autoload -Uz compinit && compinit
autoload -U promptinit && promptinit
autoload -U regexp-replace
autoload is-at-least

zmodload zsh/mathfunc

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
    (echo "warning, TOR not enabled" wget --spider -O - -S $1 2>&1 |
	awk '/^Location/ {gsub("\\?utm_.*$",""); print $2; exit 0}')
}

shorturl() {
    wget -qO - 'http://ae7.st/s/yourls-api.php?signature=8e4f5d1d8d&action=shorturl&format=simple&url='"$1"
    echo
}

### Password generators
gen-monkey-pass() {
    # Generates an unambiguous password with at least 128 bits entropy 
    # Uses Crockford's base32
    [[ $1 =~ '[0-9]+' ]] && local num=$1 || local num=1
    local pass=$(tr -cd '0-9a-hjkmnp-tv-z' < /dev/urandom | head -c $((26*$num)))
    for i in {1.."$num"}; do
        printf "${pass:$((26*($i-1))):26}\n" # add newline
    done
}
gen-xkcd-pass() {
    # Generates a passphrase with at least 128 bits entropy
    [[ $1 =~ '[0-9]+' ]] && local num=$1 || local num=1
    local dict=$(grep -E '^[a-zA-Z]{3,6}$' /usr/share/dict/words)
    local size=$(printf "$dict" | wc -l | sed -e 's/ //g')
    local entropy=$((log($size)/log(2)))
    local words=$((int(ceil(128/$entropy))))
    for i in {1.."$num"}; do
        printf "$words-"
        printf "$dict" | shuf --random-source=/dev/urandom -n "$words" | paste -sd '-'
    done
}
gen-apple-pass() {
    # Generates a pseudoword with at least 128 bits entropy
    [[ $1 =~ '[0-9]+' ]] && local num=$1 || local num=1
    local c="$(tr -cd bcdfghjkmnpqrstvwxz < /dev/urandom | head -c $((24*$num)))"
    local v="$(tr -cd aeiouy < /dev/urandom | head -c $((12*$num)))"
    local d="$(tr -cd 0-9 < /dev/urandom | head -c $num)"
    local p="$(tr -cd 056bchinotuz < /dev/urandom | head -c $num)"
    typeset -A base36=(0 0 1 1 2 2 3 3 4 4 5 5 6 6 7 7 8 8 9 9 a 10 b 11 c 12 d 13 e 14 f 15 g 16 h 17 i 18
                       j 19 k 20 l 21 m 22 n 23 o 24 p 25 q 26 r 27 s 28 t 29 u 30 v 31 w 32 x 33 y 34 z 35)
    for i in {1.."$num"}; do
        unset pseudo
        for j in {1..12}; do
            # iterate over $c and $v for each $i and each $j
            pseudo="${pseudo}${c:$((-26+24*$i+2*$j)):1}${v:$((-13+12*$i+$j)):1}${c:$((-25+24*$i+2*$j)):1}"
        done
        local digit_pos=$base36[$p[$i]]
        local char_pos=$digit_pos
        while [[ "$digit_pos" -eq "$char_pos" ]]; do
            char_pos=$base36[$(tr -cd 0-9a-z < /dev/urandom | head -c 1)]
        done
        regexp-replace pseudo "^(.{$digit_pos}).(.*)$" '${match[1]}${d[$i]}${match[2]}'
        regexp-replace pseudo "^(.{$char_pos})(.)(.*)$" '${match[1]}${(U)match[2]}${match[3]}'
        regexp-replace pseudo '^(.{6})(.{6})(.{6})(.{6})(.{6})(.{6})$' \
                              '${match[1]}-${match[2]}-${match[3]}-${match[4]}-${match[5]}-${match[6]}'
        printf "${pseudo}\n"
    done
}

### Prompt
loc=5
walk=(0 0 0 0 1 0 0 0 0)

precmd() {
    typeset -A compass=(1 "NW" 2 "NE" 3 "SW" 4 "SE") # not necessary, here for readability
    typeset -A coins=(
        # heat map and coin weight
        # not ASCII, but full-width unicode
        0 "　"
        1 '%B%F{093}，%f%b'
        2 '%B%F{021}：%f%b'
        3 '%B%F{033}－%f%b'
        4 '%B%F{051}＝%f%b'
        5 '%B%F{047}＋%f%b'
        6 '%B%F{190}＊%f%b'
        7 '%B%F{220}＃%f%b'
        8 '%B%F{208}％%f%b'
        9 '%B%F{196}＠%f%b'
    )

    if [[ -w $PWD ]]; then cdir=$(print -P '%~')
    else cdir=$(print -P '%B%F{red}%~%f%b')
    fi

    bishop='🥴'
    row1="$coins[$walk[1]]$coins[$walk[2]]$coins[$walk[3]]"
    row2="$coins[$walk[4]]$coins[$walk[5]]$coins[$walk[6]]"
    row3="$coins[$walk[7]]$coins[$walk[8]]$coins[$walk[9]]"

      if [[ $loc -eq 1 ]]; then row1="$bishop$coins[$walk[2]]$coins[$walk[3]]"
    elif [[ $loc -eq 2 ]]; then row1="$coins[$walk[1]]$bishop$coins[$walk[3]]"
    elif [[ $loc -eq 3 ]]; then row1="$coins[$walk[1]]$coins[$walk[2]]$bishop"
    elif [[ $loc -eq 4 ]]; then row2="$bishop$coins[$walk[5]]$coins[$walk[6]]"
    elif [[ $loc -eq 5 ]]; then row2="$coins[$walk[4]]$bishop$coins[$walk[6]]"
    elif [[ $loc -eq 6 ]]; then row2="$coins[$walk[4]]$coins[$walk[5]]$bishop"
    elif [[ $loc -eq 7 ]]; then row3="$bishop$coins[$walk[8]]$coins[$walk[9]]"
    elif [[ $loc -eq 8 ]]; then row3="$coins[$walk[7]]$bishop$coins[$walk[9]]"
    elif [[ $loc -eq 9 ]]; then row3="$coins[$walk[7]]$coins[$walk[8]]$bishop"
    fi

    # +---+---+---+
    # | 1 | 2 | 3 |  1       2
    # +---+---+---+    \   /
    # | 4 | 5 | 6 |      X
    # +---+---+---+    /   \
    # | 7 | 8 | 9 |  3       4
    # +---+---+---+

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
        loc=5
        walk=(0 0 0 0 1 0 0 0 0)
    fi
}

PROMPT='\
$row1%B%n@%M:$cdir%b
$row2%B%D{%Y-%m-%d} %D{%H:%M:%S.%.}%(?.. %F{red}(%?%)%f)%b
$row3%B%(!.%F{red}#%f.%F{green}%%%f)%b '
