#!/bin/bash
# @Function:
#   Display matrix effect on console.
#   Press any key to exit.
# @Auther
#   Jerry Lee (github.com/oldratlee)
#   wzt (github.com/cloudsec)

set_stty_col_and_row() {
    # get COLUMNS and ROWS by stty size
    local stty_size="$(stty size)"
    local col_num="$(echo $stty_size | awk '{print $2}')"
    local row_num="$(echo $stty_size | awk '{print $1}')"
    COLUMNS=${col_num:-30}
    ROWS=${row_num:-25}

    # use small size because of performance problem
    COLUMNS=30
}
set_stty_col_and_row


#######################################
# util methods
#######################################

function get_random_num_with_bound() {
    local upperbound=${1:-65536}
    local lowerbound=${2:-0}
    local size=$((upperbound - lowerbound))

    local random="$RANDOM"
    # or genernate random number via /dev/random
    # local random=$(echo $(od -An -N4 -l < /dev/random))

    echo $((random % size + lowerbound))
}

# ASCII printable characters
# http://www.dreamdu.com/xhtml/ascii/#printable_characters
readonly printable_characters=(
    \! \" \# \$ % \& \' \( \) \* + , - . /
    0 1 2 3 4 5 6 7 8 9
    \: \; \< = \> \? @
    A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
    [  ] ^ _ \`
    a b c d e f g h i j k l m n o p q r s t u v w x y z
    \{ \| \} \~
)

function get_random_character() {
    local rand_idx=$(($(get_random_num_with_bound ${#printable_characters[@]}) + 1))
    echo "${printable_characters[$rand_idx]}"
}

function set_green_char_console() {
    echo -ne "\033[32m"
}

function reset_green_char_console() {
    echo -ne "\033[0m"
}

# Bash - hide a terminal cursor:
# http://www.unix.com/shell-programming-and-scripting/176837-bash-hide-terminal-cursor.html
function hide_cursor() {
    tput civis -- invisible
}

function show_cursor() {
    tput cnorm -- normal
}

# How to move the cursor around the screen:
# http://tldp.org/HOWTO/Bash-Prompt-HOWTO/x361.html
# use 0-based coordinate (row, col)
function print_at() {
    local row_num="$1"
    local col_num="$2"
    local content="$3"
    echo -ne "\033[$((row_num + 1));$((col_num + 1))H$content"
}


#######################################
# biz methods
#######################################

# Maintain row coordinate of column in function self
function print_character_to_column() {
    local -r col_num="$1"
    local -r var_name_of_row_num_of_column="row_num_of_column_$col_num"
    local -r var_name_of_max_row_of_column="max_row_of_column_$col_num"

    # increase global var(like row_num_of_column_12), and assigin to local var row_num_of_column
    eval "local row_num_of_column=\$(($var_name_of_row_num_of_column++ % ROWS))"

    if [ $row_num_of_column -eq 0 ]; then
        local max_row_num=$(get_random_num_with_bound $((ROWS + 1)) )
        # set global var(like max_row_of_column_12)
        eval "$var_name_of_max_row_of_column=$max_row_num"
    fi
    # assign global var(like max_row_of_column_12) to local var max_row_of_column
    local max_row_of_column=${!var_name_of_max_row_of_column}

    local char
    if [ $row_num_of_column -lt $max_row_of_column ]; then
        char="$(get_random_character)"
        sleep 0.0$(get_random_num_with_bound 1000 500)
    else
        char=" "
        sleep 0.01
    fi

    print_at $row_num_of_column $col_num "$char"
}

function print_matrix() {
    local col_num
    for ((col_num = 0; col_num < COLUMNS; col_num++)); do
        # print each column in a separate subprocess
        while true; do
            print_character_to_column $col_num
        done &
    done
}

kill_all_subprocess() {
    {
        pkill -9 -P $$
        sleep 0.01
    } &> /dev/null
}

function cleanup_when_exit() {
    kill_all_subprocess

    reset_green_char_console
    show_cursor
    clear
}

function main() {
    trap "cleanup_when_exit" EXIT

    clear
    hide_cursor
    set_green_char_console

    print_matrix

    read -n 1 # press any key to exit
}

main
