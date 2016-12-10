# A pumped shell prompt.
# https://github.com/yakovenkomax/pumpt-prompt

##################################
#            Settings
##################################

# is enabled | segment generation function name | foreground color | background color
time_segment_settings=(false time_segment white black)
dir_segment_settings=(true dir_segment black blue)
git_segment_settings=(true git_segment black yellow)
venv_segment_settings=(true venv_segment black magenta)
ssh_segment_settings=(true ssh_segment black white)
screen_segment_settings=(true screen_segment black blue)

# Icons
    # Separator symbols
    SYM_SEPARATOR=""
    SYM_SEPARATOR_THIN=""
    # Separator symbols with reduced height
    # SYM_SEPARATOR=""
    # SYM_SEPARATOR_THIN=""
    # Branch symbol
    SYM_BRANCH=""


# Segments settings array (change segments order here)
settings=(time_segment_settings ssh_segment_settings screen_segment_settings venv_segment_settings dir_segment_settings git_segment_settings)


##################################
#             Colors
##################################

# Colors
colors=("black" "red" "green" "yellow" "blue" "magenta" "cyan" "white" "default" "reset")
# Color codes
fg_colors=("\[\e[0;30m\]" "\[\e[0;31m\]" "\[\e[0;32m\]" "\[\e[0;33m\]" "\[\e[0;34m\]" "\[\e[0;35m\]" "\[\e[0;36m\]" "\[\e[0;37m\]" "\[\e[0;39m\]" "\[\e[0m\]")
bg_colors=("\[\e[40m\]" "\[\e[41m\]" "\[\e[42m\]" "\[\e[43m\]" "\[\e[44m\]" "\[\e[45m\]" "\[\e[46m\]" "\[\e[47m\]" "\[\e[49m\]" "\[\e[0m\]")

# Color -> code translation functions
#   Ex.: fg black
#   Ex.: bg yellow
fg() {
    echo ${fg_colors[$(get_index colors $1)]}
}
bg() {
    echo ${bg_colors[$(get_index colors $1)]}
}


##################################
#            Helpers
##################################

# Get item index from an array helper
#   Ex.: get_index myArray myItemName
get_index() {
    array_name=$1[@]
    array=("${!array_name}")
    value=$2

    for i in ${!array[@]}; do
        if [[ ${array[$i]} = $value ]]; then
            echo "${i}";
        fi
    done
}

# Separator generation function
#   Ex.: separator bg_color [next_bg_color]
separator() {
    if [[ $# -eq 1 ]]; then
        echo $(bg reset)$(fg $1)$SYM_SEPARATOR
    else
        if [[ "$1" == "$2" ]]; then
            echo $(fg "black")$(bg $2)$SYM_SEPARATOR_THIN
        else
            echo $(fg $1)$(bg $2)$SYM_SEPARATOR
        fi
    fi
}


##################################
#          Main function
##################################

generate_prompt() {

    ##################################
    #    Segments generation functions
    ##################################

    # Time segment
    time_segment=""
    time_segment() {
        time_segment=$(date +"%T")
    }

    # Current directory segment
    dir_segment=""
    dir_segment() {
        dir_segment="\w"
    }

    # Git branch segment
    git_segment=""
    git_segment() {
        # Git completion and prompt:
        #   Requires git prompt and completion plugins:
        #   https://github.com/git/git/tree/master/contrib/completion
        source ~/.git-completion.bash
        source ~/.git-prompt.sh

        # Settings
        GIT_PS1_SHOWDIRTYSTATE=1

        GIT_PROMPT=$(__git_ps1 " %s")
        if [[ -n $GIT_PROMPT ]]; then
            git_segment=$SYM_BRANCH$GIT_PROMPT
        fi
    }

    # Python virtual environment segment
    venv_segment=""
    venv_segment() {
        if [[ -n $VIRTUAL_ENV ]]; then
           venv_segment=$(basename $VIRTUAL_ENV)
        fi
    }

    # SSH segment
    ssh_segment=""
    ssh_segment() {
        if [[ "$SSH_CONNECTION" && "$SSH_TTY" == $(tty) ]]; then
            ssh_user=$(id -un)
            ssh_host=$(hostname)
            ssh_segment="${ssh_user}@${ssh_host}"
        fi
    }

    # Screen segment
    screen_segment=""
    screen_segment() {
        if [[ -n $STY ]]; then
            screen_segment=$STY
        fi
    }


    ##################################
    #       Segments filtering
    ##################################

    enabled_segments=""
    for i in ${!settings[@]}; do
        segment=${settings[$i]}
        segment_name=$segment[@]
        segment_settings=("${!segment_name}")

        if [[ ${segment_settings[0]} = true ]]; then
            # Call the segment generation function
            eval ${segment_settings[1]}
            segment_value=${!segment_settings[1]}

            if [[ -n $segment_value ]]; then
                enabled_segments+=${settings[$i]}" "
            fi
        fi
    done
    enabled_segments=($enabled_segments)


    ##################################
    #     Segments concatenation
    ##################################

    PS1=""
    for i in ${!enabled_segments[@]}; do
        segment=${enabled_segments[$i]}
        segment_name=$segment[@]
        segment_settings=("${!segment_name}")
        segment_value=${!segment_settings[1]}
        fg_color=${segment_settings[2]}
        bg_color=${segment_settings[3]}

        # Append segment content to the prompt string
        PS1+=$(fg $fg_color)$(bg $bg_color)" "$segment_value" "

        # Check if the current segment is the last
        if [[ $(($i + 1)) -lt ${#enabled_segments[@]} ]]; then
            next_segment=${enabled_segments[$(($i + 1))]}
            next_segment_name=$next_segment[@]
            next_segment_settings=("${!next_segment_name}")
            next_bg_color=${next_segment_settings[3]}
            # Append a separator
            PS1+=$(separator $bg_color $next_bg_color)
        else
            # Append a separator
            PS1+=$(separator $bg_color)
        fi
    done

    # Check if the prompt string is empty
    if [[ -z "$PS1" ]]; then
        PS1+=$(separator default)
    fi

    # Reset colors and append a space in the end
    PS1+=$(fg reset)" "
}
PROMPT_COMMAND=generate_prompt