#!/bin/bash
# @Auther
#   wzt (github.com/cloudsec)

MAX_COL_NUM=160
MAX_ROW_NUM=40

START_ROW=1
START_COL=1

function get_random_char() {
    local tmp=`od -An -N1 -i /dev/urandom`
    local matrix_char=$((tmp%126))

    if [ $matrix_char -le 31 ]; then
        matrix_char=$((matrix_char+31))
    fi

    return $matrix_char
}

function matrix_thread() {
    local col_num row_num
    local max_row_num matrix_char

    col_num=$1
    max_row_num=`od -An -N1 -i /dev/urandom`
    max_row_num=$(($max_row_num%MAX_ROW_NUM))
    for ((row_num = $START_ROW; row_num <= $max_row_num; row_num++))
    do
        get_random_char
        matrix_char=$?
        matrix_char=`echo $matrix_char | awk '{printf "%c", $0}'`
        (
            echo -ne "\033[${row_num};${col_num}H\033[32m$matrix_char\033[?25l"
            sleep 0.02
        ) &
    done

    wait
}

function matrix_start() {
    local col_num row_num

    for ((col_num = $START_COL; col_num <= $MAX_COL_NUM; col_num++)); do
        matrix_thread $col_num
    done
}

function matrix_init() {
    echo -ne "\033[2J"
}

function main() {
    matrix_init
    while true; do
        matrix_start
    done
}

main
