DISABLE_AUTO_UPDATE="true"
ZSH_DISABLE_COMPFIX="true"
export ZSH="$HOME/src/ohmyzsh" # Production
#export ZSH="$HOME/src/atoponce-ohmyzsh" # Development fork
plugins=(genpass)
source $ZSH/oh-my-zsh.sh
source $HOME/.cargo/env

# Make sure umask is set appropriately, login or not
umask 0002

# Variables for xterm and such
export LC_ALL="en_US.UTF-8"
export TERM="xterm-256color"
export GPG_TTY=$(tty)
HISTFILE=~"/.histfile"
HISTSIZE="10000"
SAVEHIST="10000"
EDITOR="vim"
VISUAL="vim"
PAGER="less"

# modifying the PATH adding the sbin directories
path+=( /sbin /usr/sbin /usr/local/sbin ~/.local/bin )
path=( ${(u)path} )

# various options to set/unset
setopt appendhistory
setopt share_history
setopt prompt_subst

unsetopt autocd beep

autoload -U colors && colors
autoload -Uz compinit && compinit
autoload -U promptinit && promptinit
autoload is-at-least

zmodload zsh/mathfunc
zmodload zsh/datetime
zmodload zsh/system

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
ssh-add -l &> /dev/urandom
if [[ "$?" == 2 ]]; then
    [[ -r ~/.ssh/ssh-agent ]] && eval "$(<~/.ssh/ssh-agent)" > /dev/urandom
    ssh-add -l &> /dev/urandom
    if [[ "$?" == 2 ]]; then
        (umask 066; ssh-agent > ~/.ssh/ssh-agent)
        eval "$(<~/.ssh/ssh-agent)" > /dev/urandom
        ssh-add
    fi
fi

### General purpose aliases
alias ls='ls --color=auto'

### General purpose functions
genpass-csv() {
    # Generates 128-bits base62 "comma-separated" password.
    #
    # > "Add commas to your passwords to mess with the CSV file they will be dumped into after being
    # > breached. Until next time!" ~ Skeletor
    local n
    (( # == 0 )) && n=1 || n=$1 # test if an argument exists, or set to '1'

    if ! [[ "$n" =~ '^[0-9]+$' ]]; then # test if argument is numeric, or return unsuccessfully
        echo "usage: genpass-csv [NUM]"
        return 1
    fi

    repeat $n; do
        tr -cd 0-9A-Za-z < /dev/urandom | head -c 22 | sed -r 's/^(.{11})/\1,/g;s/$/\n/'
    done
}
encrypt() {
    local pubkey="$HOME/.config/age/public.key"

    for f in "$@"; do
        age -e -R "$pubkey" -o "$f".age "$f"
    done
}

decrypt() {
    local privkey="$HOME/.config/age/private.key"

    for f in "$@"; do
        age -d -i "$privkey" -o "$f" "${f:r}"
    done
}

sign() {
    local privkey="$HOME/.config/minisign/private.key"

    for f in "$@"; do
        minisign -S -s "$privkey" -m "$f"
    done
}

verify() {
    local pubkey="$HOME/.config/minisign/public.key"

    for f in "$@"; do
        minisign -V -p "$pubkey" -m "$f"
    done
}

collect-entropy() {
    local print_line() {
        local c="$1"
        local v="$2"

        printf "${c[1]}${v[1]}${c[2]}${v[2]}${c[3]} "
        printf "${c[4]}${v[3]}${c[5]}${v[4]}${c[6]} "
        printf "${c[7]}${v[5]}${c[8]}${v[6]}${c[9]} "
        printf "${c[10]}${v[7]}${c[11]}${v[8]}${c[12]} "
        printf "${c[13]}${v[9]}${c[14]}${v[10]}${c[15]} "
        printf "${c[16]}${v[11]}${c[17]}${v[12]}${c[18]} "
        printf "${c[19]}${v[13]}${c[20]}${v[14]}${c[21]} "
        printf "${c[22]}${v[15]}${c[23]}${v[16]}${c[24]}\n"
    }

    printf "Type, not copy/paste these 32 pseudowords in the event tester window.\n"
    printf "Move your mouse a bit in the event tester window afterward if desired.\n"
    printf "Close the event tester window when finished.\n"
    printf "\n"

    local vowels=$(tr -cd aiou < /dev/urandom | head -c 64)
    local consonants=$(tr -cd bdfghjklmnprstvz < /dev/urandom | head -c 96)

    print_line ${consonants[1,24]} ${vowels[1,16]}
    print_line ${consonants[25,48]} ${vowels[17,32]}
    print_line ${consonants[49,72]} ${vowels[33,48]}
    print_line ${consonants[73,96]} ${vowels[49,64]}

    # Security comes from:
    #   key press precise timestamp
    #   key release precise timestamp
    # collect precise timestamps of keypresses and mouse movements
    entropy=$(strace --timestamps=precision:ns xev 2>&1)
    printf "\n"

    # use b2sum(1) as a fixed-length entropy extractor
    printf %s "${entropy}" | b2sum | awk '{print $1}'
}

alphaimg() {
    convert $1 -alpha on -channel A -evaluate set 99% +channel $1
    cleanimg $1
}

cleanimg() {
    local type=$(identify -format %m)
    exiftool -q -all= -overwrite_original $1

    if [[ "$type" == "JPEG" ]]; then
        jpegoptim -q $1
    elif [[ "$type" == "PNG" ]]; then
        optipng -quiet $1
    fi
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

# 32-bit cryptographically secure RNG
# Assumes ZSH is compiled with 64-bit integers
# See https://gist.github.com/romkatv/a6cede40714ec77d4da73605c5ddb36a as a math function.
srandom() {
    zmodload zsh/system
    local byte
    local -i rnd=0
    repeat 4; do
        sysread -s 1 byte < /dev/urandom || return
        rnd=$(( rnd << 8 | #byte ))
    done
    print -r -- $rnd
}

### Prompt
loc=5
walk=(0 0 0 0 1 0 0 0 0)

precmd() {
    # not necessary, here for readability
    typeset -A compass=(1 "NW" 2 "NE" 3 "SW" 4 "SE")
    # coin weight. not ASCII, but full-width unicode
    typeset -A coins=(
        0 '　'
        1 '%F{021}，%f'
        2 '%F{093}：%f'
        3 '%F{033}－%f'
        4 '%F{051}＝%f'
        5 '%F{047}＋%f'
        6 '%F{190}＊%f'
        7 '%F{220}＃%f'
        8 '%F{208}％%f'
        9 '%F{196}＠%f'
    )

    [[ -w $PWD ]] && cdir=$(print -P '%~') || cdir=$(print -P '%B%F{red}%~%f%b')

    local bishop='🥴'
    row1="$coins[$walk[1]]$coins[$walk[2]]$coins[$walk[3]]"
    row2="$coins[$walk[4]]$coins[$walk[5]]$coins[$walk[6]]"
    row3="$coins[$walk[7]]$coins[$walk[8]]$coins[$walk[9]]"

    [[ $loc -eq 1 ]] && row1="$bishop$coins[$walk[2]]$coins[$walk[3]]"
    [[ $loc -eq 2 ]] && row1="$coins[$walk[1]]$bishop$coins[$walk[3]]"
    [[ $loc -eq 3 ]] && row1="$coins[$walk[1]]$coins[$walk[2]]$bishop"
    [[ $loc -eq 4 ]] && row2="$bishop$coins[$walk[5]]$coins[$walk[6]]"
    [[ $loc -eq 5 ]] && row2="$coins[$walk[4]]$bishop$coins[$walk[6]]"
    [[ $loc -eq 6 ]] && row2="$coins[$walk[4]]$coins[$walk[5]]$bishop"
    [[ $loc -eq 7 ]] && row3="$bishop$coins[$walk[8]]$coins[$walk[9]]"
    [[ $loc -eq 8 ]] && row3="$coins[$walk[7]]$bishop$coins[$walk[9]]"
    [[ $loc -eq 9 ]] && row3="$coins[$walk[7]]$coins[$walk[8]]$bishop"

    # +---+---+---+
    # | 1 | 2 | 3 |    1   2
    # +---+---+---+     \ /
    # | 4 | 5 | 6 |      X
    # +---+---+---+     / \
    # | 7 | 8 | 9 |    3   4
    # +---+---+---+

    local num=$(LC_ALL=C tr -cd 1234 < /dev/urandom | head -c 1)

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
        [[ $walk[$cell] -gt 9 ]] && (( walk[$cell]=9 ))
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
