Green="\033[0;32m"
LightGreen="\033[1;32m"
Yellow="\033[0;33m"
LightYellow="\033[1;33m"
Red="\033[0;31m"
LightRed="\033[1;31m"
Magenta="\033[0;95m"
LightMagenta="\033[1;95m"
Blue="\033[0;94m"
LightBlue="\033[1;94m"

Screen="\033[38;5;198m"
UserName="\033[0;32m"
WorkDir="\033[0;33m"
HostnameFiglet="\033[38;5;166m"
Normal="\033[0m"

Git="\033[0;95m"
GitMaster="\033[0;93m"
GitSubmodule="\033[0;94m"
GitStagedChanges="\033[0;32m"
GitUnstagedChanges="\033[0;91m"


smiley() {
    ret_val=$1
    if [ "$ret_val" = 0 ]; then
        echo -e "\[$LightGreen\]:)\[$Normal\]"
    elif [ "$ret_val" -lt 5 ]; then
        printf "\[$LightRed\]:%${ret_val}s\[$Normal\]" |tr " " "("
    else
        echo -e "\[$LightRed\]¯\_(⊙︿⊙)_/¯ ($ret_val)\[$Normal\]"
    fi
}


git_prompt(){
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ $? -ne 0 ]; then
        return
    fi

    git_info=$(git rev-parse --abbrev-ref @{u} --git-dir 2>/dev/null)
    IFS=$'\n' read -rd '' -a git_info_array <<< "$git_info"
    upstream="${git_info_array[0]}"
    submodule=$(echo "${git_info_array[1]}" | sed -nre 's/^.+\.git\/modules\/([^/]+)$/\1/p')

    staged=$(git diff --cached --numstat | wc -l)
    unstaged=$(git diff --numstat | wc -l)

    extra=""

    if [ "$staged" -gt 0 -a "$unstaged" -gt 0 ]; then
        extra=" \[$GitStagedChanges\][${staged}\[$Git\]/\[$GitUnstagedChanges\]${unstaged}]\[$Git\]$extra"
    else
        if [ "$staged" -gt 0 ]; then
             extra=" \[$GitStagedChanges\][${staged}]\[$Git\]$extra"
        fi
        if [ "$unstaged" -gt 0 ]; then
             extra="\[$GitUnstagedChanges\][${unstaged}]\[$Git\]$extra"
        fi
    fi

    if [ ! -z "$upstream" ]; then

        behind_ahead=$(git rev-list --left-right --count $branch...$upstream)
        behind=$(echo "$behind_ahead" | sed -re 's/.+\s([0-9]+)$/\1/')
        ahead=$(echo "$behind_ahead" | sed -re 's/^([0-9]+)\s.+/\1/')

        if [ "$behind" -eq 0 -a "$ahead" -eq 0 ]; then
            ba="="
        else
            ba=""
            if [ "$behind" -ne 0 ]; then
                ba+="\[$Yellow\]−$behind\[$Git\]"
            fi
            if [ "$ahead" -ne 0 ]; then
                ba+="\[$Green\]+$ahead\[$Git\]"
            fi
        fi

        extra=" $ba $upstream"
    fi

    # within submodule

    if [ "$branch" == "master" ]; then
        branchColor="$GitMaster"
    else
        branchColor="$Git"
    fi

    if [ ! -z "$submodule" ]; then
        echo " \[$Git\](\[$GitSubmodule\]$submodule:\[$Git\] \[$branchColor\]$branch\[$Git\]$extra)\[$Normal\]"
    else
        echo " \[$Git\](\[$branchColor\]$branch\[$Git\]$extra)\[$Normal\]"
    fi
}


set_bash_prompt() {
    local smiley=$(smiley $?)
    local git=$(git_prompt)
    local title=$(dirs -0)
    echo -ne "\033]0;$title\007"

    if [[ "$TERM" = screen* ]]; then
        local screen="\[$Screen\]$STY$TMUX "
    else
        local screen=""
    fi

    PS1="\$()\n\[$UserName\]\u@\h $screen\[$WorkDir\]\w\[$Normal\]$git\n$smiley \[$Normal\]"
}

PROMPT_COMMAND=set_bash_prompt

#export PS0="[\u@\h \W]\$ "

colortest(){
    printf "          "
    for b in 0 1 2 3 4 5 6 7; do printf "  4${b}m "; done
    echo
    for f in "" 30 31 32 33 34 35 36 37; do
        for s in "" "1;"; do
            printf "%4sm" "${s}${f}"
            printf " \033[%sm%s\033[0m" "$s$f" "gYw "
            for b in 0 1 2 3 4 5 6 7; do
                printf " \033[4%s;%sm%s\033[0m" "$b" "$s$f" " gYw "
            done
            echo
         done
    done
}

colortest256(){
    for fgbg in 38 48 ; do #Foreground/Background
        for color in {0..256} ; do #Colors
            #Display the color
            echo -en "\e[${fgbg};5;${color}m ${color}\t\e[0m"
            #Display 10 colors per lines
            if [ $((($color + 1) % 10)) == 0 ] ; then
                echo #New line
            fi
        done
        echo #New line
    done
}
