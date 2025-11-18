CASE_SENSITIVE="true"
DISABLE_AUTO_UPDATE="true"
ZSH_DISABLE_COMPFIX="true"
DISABLE_MAGIC_FUNCTIONS="true"
#export ZSH="$HOME/src/ohmyzsh" # Production
#export ZSH="$HOME/src/atoponce-ohmyzsh" # Development fork
#plugins=(genpass)
#source $ZSH/oh-my-zsh.sh
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
srandom() {
    # 32-bit cryptographically secure RNG
    # Assumes ZSH is compiled with 64-bit integers
    # See https://gist.github.com/romkatv/a6cede40714ec77d4da73605c5ddb36a as a math function.
    local bytes
    sysread -s 4 bytes < /dev/urandom || return
    local b1=$bytes[1] b2=$bytes[2] b3=$bytes[3] b4=$bytes[4]
    print -r -- $((#b1 << 24 | #b2 << 16 | #b3 << 8 | #b4))
}

csprng() {
    # Generates a cryptographically secure uniform random value between [0..$1)
    local bound=${1:?"Must provide an upper bound"}
    local min=$((2 ** 32 % bound))
    local n=$(srandom)

    # Uniform modulo with rejection
    while [[ $n -lt $min ]]; do
        n=$(srandom)
    done

    print -r -- "$((n % bound))"
}

trng() {
    # Generates 256 bits of true randomness based on the stress of the system.
    # Modeled after coin flips pitting a slow clock (RTC) against a fast clock (CPU).
    local flips=()

    while (( ${#flips[@]} < 256 )); do
        local coin=0
        local stop=$((EPOCHREALTIME+0.001)) # 1ms into the future

        while (( $EPOCHREALTIME < $stop )); do
            ((coin^=1)) # flip coin as fast as possible
        done

        flips+=($coin)
    done

    local h=($(print -r -- ${(j[])flips} | b2sum -l 256)) # whiten the data
    print -r -- "$h[1]"
}

genpass-apple() {
    # Usage: genpass-apple [NUM]
    #
    # Generate a password made of 6 pseudowords of 6 characters each with the security margin of at
    # least 128 bits.
    #
    # Example password: xudmec-4ambyj-tavric-mumpub-mydVop-bypjyp
    #
    # If given a numerical argument, generate that many passwords.
    #
    # Initially developed by me for ohmyzsh.

    emulate -L zsh -o no_unset -o warn_create_global -o warn_nested_var

    if [[ ARGC -gt 1 || ${1-1} != ${~:-<1-$((16#7FFFFFFF))>} ]]; then
      print -ru2 -- "usage: $0 [NUM]"
      return 1
    fi

    zmodload zsh/system zsh/mathfunc || return

    {
      local -r vowels=aeiouy
      local -r consonants=bcdfghjklmnpqrstvwxz
      local -r digits=0123456789

      # Sets REPLY to a uniformly distributed random number in [1, $1].
      # Requires: $1 <= 256.
      function -$0-rand() {
        local c
        while true; do
          sysread -s1 c || return
          # Avoid bias towards smaller numbers.
          (( #c < 256 / $1 * $1 )) && break
        done
        typeset -g REPLY=$((#c % $1 + 1))
      }

      local REPLY chars

      repeat ${1-1}; do
        # Generate 6 pseudowords of the form cvccvc where c and v
        # denote random consonants and vowels respectively.
        local words=()
        repeat 6; do
          words+=('')
          repeat 2; do
            for chars in $consonants $vowels $consonants; do
              -$0-rand $#chars || return
              words[-1]+=$chars[REPLY]
            done
          done
        done

        local pwd=${(j:-:)words}

        # Replace either the first or the last character in one of
        # the words with a random digit.
        -$0-rand $#digits || return
        local digit=$digits[REPLY]
        -$0-rand $((2 * $#words)) || return
        pwd[REPLY/2*7+2*(REPLY%2)-1]=$digit

        # Convert one lower-case character to upper case.
        while true; do
          -$0-rand $#pwd || return
          [[ $vowels$consonants == *$pwd[REPLY]* ]] && break
        done
        # NOTE: We aren't using ${(U)c} here because its results are
        # locale-dependent. For example, when upper-casing 'i' in Turkish
        # locale we would get 'İ', a.k.a. latin capital letter i with dot
        # above. We could set LC_CTYPE=C locally but then we would run afoul
        # of this zsh bug: https://www.zsh.org/mla/workers/2020/msg00588.html.
        local c=$pwd[REPLY]
        printf -v c '%o' $((#c - 32))
        printf "%s\\$c%s\\n" "$pwd[1,REPLY-1]" "$pwd[REPLY+1,-1]" || return
      done
    } always {
      unfunction -m -- "-${(b)0}-*"
    } </dev/urandom
}

genpass-csv() {
    # Usage: genpass-apple [NUM]
    #
    # Generate a password made of two 11-character alphanumeric strings, quotedo, and comma
    # separated with a security margin of at least 128 bits.
    #
    # > "Add commas to your passwords to mess with the CSV file they will be dumped into after being
    # > breached. Until next time!" ~ Skeletor
    #
    # Example password: "9Q8v6p3aCUm","qXYtKI8oKtc"
    #
    # If given a numerical argument, generate that many passwords.
    #
    # Initially developed by me for ohmyzsh.

    emulate -L zsh -o no_unset -o warn_create_global -o warn_nested_var

    # Test if argument is numeric, or return unsuccessfully
    if [[ ARGC -gt 1 || ${1-1} != ${~:-<1-$((16#7FFFFFFF))>} ]]; then
        print -ru2 -- "usage: $0 [NUM]"
        return 1
    fi

    zmodload zsh/system zsh/mathfunc || return

    {
        local c
        local chars="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/" # Base 64
        local length=$(( ceil(128/log2($#chars)) ))

        repeat ${1-1}; do
            local pw=""
            repeat $length; do
                sysread -s1 c || return
                pw+=$chars[#c%$#chars+1] # Uniform as $#chars divides 256 evenly.
            done
            print -r -- "\"$pw[1,$#pw/2]\",\"$pw[$#pw/2+1,$#pw]\""
        done

    } < /dev/urandom
}

genpass-monkey() {
    # Usage: genpass-monkey [NUM]
    #
    # Generate a password made of 26 alphanumeric characters with the security margin of at least
    # 128 bits.
    #
    # Example password: nz5ej2kypkvcw0rn5cvhs6qxtm
    #
    # If given a numerical argument, generate that many passwords.
    #
    # Initially developed by me for ohmyzsh.

    emulate -L zsh -o no_unset -o warn_create_global -o warn_nested_var

    if [[ ARGC -gt 1 || ${1-1} != ${~:-<1-$((16#7FFFFFFF))>} ]]; then
      print -ru2 -- "usage: $0 [NUM]"
      return 1
    fi

    zmodload zsh/system || return

    {
      local -r chars=abcdefghjkmnpqrstvwxyz0123456789
      local c
      repeat ${1-1}; do
        repeat 26; do
          sysread -s1 c || return
          # There is uniform because $#chars divides 256.
          print -rn -- $chars[#c%$#chars+1]
        done
        print
      done
    } </dev/urandom
}

genpass-whitespace() {
    # Usage: genpass-whitespace [NUM]
    #
    # Generate a password made of 32 non-control, non-graphical, horizontal spaces/blanks with a
    # security margin of at least 128 bits.
    #
    # Both nonzero- and zero-width characters are used. Two characters are technically vertical
    # characters, but aren't interpreted as such in the shell. They are "\u2028" and "\u2029". You
    # might need a font with good Unicode support to prevent some of these characters creating tofu.
    #
    # The password is wrapped in braille pattern blanks for correctly handling zero-width characters
    # at the edges, to prevent whitespace stripping by the auth form, and to guarantee a copy-able
    # width should only zero-width characters be generated.
    #
    # Example password: ● "⠀　    ‍ ​   ‍ 　   ͏͏ᅟ  ⠀ ⁠‌⠀"
    #
    # If given a numerical argument, generate that many passwords.
    #
    # Initially developed by me for ohmyzsh.

    emulate -L zsh -o no_unset -o warn_create_global -o warn_nested_var

    # Test if argument is numeric, or return unsuccessfully
    if [[ ARGC -gt 1 || ${1-1} != ${~:-<1-$((16#7FFFFFFF))>} ]]; then
        print -ru2 -- "usage: $0 [NUM]"
        return 1
    fi

    zmodload zsh/system zsh/mathfunc || return

    tabs -1 # set tab width to 1 space

    {
        local c
        local chars=(
            $'\u0009' $'\u0020' $'\u00A0' $'\u00AD' $'\u034F' $'\u115F' $'\u1160' $'\u180E'
            $'\u2000' $'\u2001' $'\u2002' $'\u2003' $'\u2004' $'\u2005' $'\u2006' $'\u2007'
            $'\u2008' $'\u2009' $'\u200A' $'\u200B' $'\u200C' $'\u200D' $'\u2028' $'\u2029'
            $'\u202F' $'\u205F' $'\u2060' $'\u2800' $'\u3000' $'\u3164' $'\uFEFF' $'\uFFA0'
        )
        local length=$(( ceil(128/log2($#chars)) ))

        repeat ${1-1}; do
            local warn=false
            local pass=""

            pass+=$'"\u2800'

            repeat $length; do
                sysread -s1 c || return
                local x=$chars[#c%$#chars+1]

                [[ $x == ($'\u2028'|$'\u2029') ]] && warn=true

                pass+="$x"
            done

            pass+=$'\u2800"'

            [[ $warn == true ]] \
                && print -rP '%F{yellow}●%F{reset} $pass' \
                || print -rP '%F{green}●%F{reset} $pass'
        done
    } < /dev/urandom


    tabs -8 # restore tab width
}

genpass-xkcd() {
    # Usage: genpass-xkcd [NUM]
    #
    # Generate a password made of words from /usr/share/dict/words with the security margin of at
    # least 128 bits.
    #
    # Example password: 9-mien-flood-Patti-buxom-dozes-ickier-pay-ailed-Foster
    #
    # If given a numerical argument, generate that many passwords.
    #
    # The name of this utility is a reference to https://xkcd.com/936/.
    #
    # Initially developed by me for ohmyzsh.

    emulate -L zsh -o no_unset -o warn_create_global -o warn_nested_var -o extended_glob

    if [[ ARGC -gt 1 || ${1-1} != ${~:-<1-$((16#7FFFFFFF))>} ]]; then
      print -ru2 -- "usage: $0 [NUM]"
      return 1
    fi

    zmodload zsh/system zsh/mathfunc || return

    local -r dict=/usr/share/dict/words

    if [[ ! -e $dict ]]; then
      print -ru2 -- "$0: file not found: $dict"
      return 1
    fi

    # Read all dictionary words and leave only those made of 1-6 characters.
    local -a words
    words=(${(M)${(f)"$(<$dict)"}:#[a-zA-Z](#c1,6)}) || return

    if (( $#words < 2 )); then
      print -ru2 -- "$0: not enough suitable words in $dict"
      return 1
    fi

    if (( $#words > 16#7FFFFFFF )); then
      print -ru2 -- "$0: too many words in $dict"
      return 1
    fi

    # Figure out how many words we need for 128 bits of security margin.
    # Each word adds log2($#words) bits.
    local -i n=$((ceil(128. / (log($#words) / log(2)))))

    {
      local c
      repeat ${1-1}; do
        print -rn -- $n
        repeat $n; do
          while true; do
            # Generate a random number in [0, 2**31).
            local -i rnd=0
            repeat 4; do
              sysread -s1 c || return
              (( rnd = (~(1 << 23) & rnd) << 8 | #c ))
            done
            # Avoid bias towards words in the beginning of the list.
            (( rnd < 16#7FFFFFFF / $#words * $#words )) || continue
            print -rn -- -$words[rnd%$#words+1]
            break
          done
        done
        print
      done
    } </dev/urandom
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
    # 256-bit keyboard entropy collector
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

    # use b3sum(1) as a fixed-length entropy extractor
    printf %s "${entropy}" | b3sum -l 64 | awk '{print $1}'
}

alphaimg() {
    convert $1 -alpha on -channel A -evaluate set 99% +channel $1
    cleanimg $1
}

cleanimg() {
    local type=$(identify -format %m)
    exiftool -q -all= -overwrite_original $1 2> /dev/random

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
