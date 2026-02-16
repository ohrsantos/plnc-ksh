#!/bin/ksh
################################################################################
PLNKSH_CALC_SCRIPT_NAME="PLNKSH Calc"
################################################################################
PLN_KSH_VERSION=0.3.000
AUTHOR="Orlando Hehl Rebelo dos Santos"
DATE_INI="05-08-2017"
DATE_END="14-09-2019"
DATE_END="21-11-2022"
DATE_END="19-08-2025"
DATE_END="15-10-2025"
################################################################################

OHRS_ETC_DIR="$OHRS_STUFF_PATH/etc"
source $OHRS_ETC_DIR/color-constants.sh
source $OHRS_STUFF_PATH/share/plnc-ksh/kbdlib.sh

################################################################################
usage(){
    print $PLNKSH_CALC_SCRIPT_NAME
    print "Usage: plncalc.ksh [-p precision] [-v] [-t]"
    print "  -k   Precision"
    print "  -C   Columns"
    print "  -s   Clear screen"
    print "  -t   Enable tests"
    print "  -v   Print version and exit"
    print "  -h   Print help and exit"
}

################################################################################
# HISTÓRICO
################################################################################
typeset -a hist_type
typeset -a hist_op
typeset -a hist_value
hist_idx=0

function hist_add_push {
    hist_type[$hist_idx]="PUSH"
    hist_value[$hist_idx]="$1"
    ((hist_idx++))
}

function hist_add_binary {
    hist_type[$hist_idx]="BINARY"
    hist_op[$hist_idx]="$1"
    hist_value[$hist_idx]=$2
    ((hist_idx++))
}

################################################################################
PRECISION=7
reg_idx=0
typeset -a regs
typeset -F10 input_f
input=""
CLRSCR=FALSE
ENABLE_TEST=FALSE

################################################################################
function auto_enter_if_needed {
    if [[ -n $input ]]; then
        regs[$reg_idx]=$input_f
        hist_add_push "$input"
        input=""
        ((reg_idx++))
    fi
}

################################################################################
function print_history {

    printf "\n"

    for ((i=0; i < hist_idx; i++)); do

        case "${hist_type[$i]}" in

            "PUSH")
                printf "${FG237}%*s${C_RST}\n" \
                    $COLUMNS "${hist_value[$i]}"
                ;;

            "BINARY")
                formatted=$(printf "%.${PRECISION}f" "${hist_value[$i]}")
                printf "${FG237}%*s %*s${C_RST}\n" \
                    $((COLUMNS/2)) "${hist_op[$i]}" \
                    $((COLUMNS - COLUMNS/2 - 1)) "$formatted"
                ;;
        esac
    done
}

################################################################################
function print_regs {

    if [[ $CLRSCR == "TRUE" ]]; then
        tput clear
    fi

    print_history

    for (( i = 0; i <= $COLUMNS; i++ )); do printf "-"; done
    printf "\n\n"

    if [[ -n ${regs[0]} ]]; then

        regs_length=0
        for index in "${!regs[@]}"; do
            if [[ -n ${regs[index]} ]]; then
                ((regs_length++))
            fi
        done

        columns_available=$((COLUMNS - 4))

        for index in "${!regs[@]}"; do
            if [[ -n ${regs[index]} ]]; then
                printf "%2d: %*.${PRECISION}f\n" \
                    $regs_length \
                    $columns_available \
                    ${regs[$index]}
                ((regs_length--))
            fi
        done
    else
        echo "(EMPTY STACK)"
    fi

    for ((i=0; i < COLUMNS; i++)); do printf "="; done
    printf "\n>"
}

################################################################################
function set_precision {
    if [[ -n ${1} ]]; then
        PRECISION=${1}
        input=""
    else
        PRECISION=${regs[reg_idx - 1]}
        drop_regs
    fi
    PRECISION=$((abs(PRECISION)))
}

################################################################################
function enter {

    if [[ -n $input ]]; then
        regs[$reg_idx]=$input_f
        hist_add_push "$input"
        input=""
    else
        regs[$reg_idx]=${regs[reg_idx - 1]}
    fi

    ((reg_idx++))
    print_regs
}

################################################################################
# BINÁRIAS
################################################################################
function add {
    auto_enter_if_needed
    if(( reg_idx < 2 )); then return; fi
    result=$((regs[reg_idx - 2] + regs[reg_idx - 1]))
    hist_add_binary "+" "$result"
    regs[reg_idx - 2]=$result
    regs[reg_idx - 1]=""
    ((reg_idx--))
    print_regs
}

function sub {
    auto_enter_if_needed
    if(( reg_idx < 2 )); then return; fi
    result=$((regs[reg_idx - 2] - regs[reg_idx - 1]))
    hist_add_binary "-" "$result"
    regs[reg_idx - 2]=$result
    regs[reg_idx - 1]=""
    ((reg_idx--))
    print_regs
}

function mul {
    auto_enter_if_needed
    if(( reg_idx < 2 )); then return; fi
    result=$((regs[reg_idx - 2] * regs[reg_idx - 1]))
    hist_add_binary "*" "$result"
    regs[reg_idx - 2]=$result
    regs[reg_idx - 1]=""
    ((reg_idx--))
    print_regs
}

function div {
    auto_enter_if_needed
    if(( reg_idx < 2 )); then return; fi
    if (( regs[reg_idx - 1] == 0 )); then
        print "Division by zero"
        return
    fi
    result=$((regs[reg_idx - 2] * 1.0 / regs[reg_idx - 1]))
    hist_add_binary "/" "$result"
    regs[reg_idx - 2]=$result
    regs[reg_idx - 1]=""
    ((reg_idx--))
    print_regs
}

################################################################################
# POWER
################################################################################
function power {
    auto_enter_if_needed
    if(( reg_idx < 2 )); then return; fi
    result=$((regs[reg_idx - 2] ** regs[reg_idx - 1]))
    hist_add_binary "Power" "$result"
    regs[reg_idx - 2]=$result
    regs[reg_idx - 1]=""
    ((reg_idx--))
    print_regs
}

function inv_power {
    auto_enter_if_needed
    if(( reg_idx < 2 )); then return; fi
    result=$((regs[reg_idx - 2] ** (1.0/regs[reg_idx - 1])))
    hist_add_binary "Inv Power" "$result"
    regs[reg_idx - 2]=$result
    regs[reg_idx - 1]=""
    ((reg_idx--))
    print_regs
}

################################################################################
# UNÁRIAS HP STYLE
################################################################################
function square_root {
    if [[ -n $input ]]; then
        result=$((sqrt(input_f)))
        input=$(printf "%.${PRECISION}f" "$result")
        input_f=$result
        printf "\r%${COLUMNS}s" "$input"
    else
        if(( reg_idx < 1 )); then return; fi
        result=$((sqrt(${regs[reg_idx-1]})))
        regs[reg_idx-1]=$result
        hist_add_binary "Square Root" "$result"
        print_regs
    fi
}

function inverse {
    if [[ -n $input ]]; then
        result=$((1.0/input_f))
        input=$(printf "%.${PRECISION}f" "$result")
        input_f=$result
        printf "\r%${COLUMNS}s" "$input"
    else
        if(( reg_idx < 1 )); then return; fi
        result=$((1.0/${regs[reg_idx-1]}))
        regs[reg_idx-1]=$result
        hist_add_binary "Inverse" "$result"
        print_regs
    fi
}

function abs {
    if [[ -n $input ]]; then
        result=$((abs(input_f)))
        input=$(printf "%.${PRECISION}f" "$result")
        input_f=$result
        printf "\r%${COLUMNS}s" "$input"
    else
        regs[reg_idx-1]=$((abs(${regs[reg_idx-1]})))
        hist_add_binary "Abs" "${regs[reg_idx-1]}"
        print_regs
    fi
}

function round {
    if [[ -n $input ]]; then
        result=$((round(input_f)))
        input=$(printf "%.${PRECISION}f" "$result")
        input_f=$result
        printf "\r%${COLUMNS}s" "$input"
    else
        regs[reg_idx-1]=$((round(${regs[reg_idx-1]})))
        hist_add_binary "Round" "${regs[reg_idx-1]}"
        print_regs
    fi
}

function trunc {
    if [[ -n $input ]]; then
        result=$((trunc(input_f)))
        input=$(printf "%.${PRECISION}f" "$result")
        input_f=$result
        printf "\r%${COLUMNS}s" "$input"
    else
        regs[reg_idx-1]=$((trunc(${regs[reg_idx-1]})))
        hist_add_binary "Trunc" "${regs[reg_idx-1]}"
        print_regs
    fi
}

function float_p_reminder {
    if [[ -n $input ]]; then
        result=$((fmod(input_f)))
        input=$(printf "%.${PRECISION}f" "$result")
        input_f=$result
        printf "\r%${COLUMNS}s" "$input"
    else
        regs[reg_idx-1]=$((fmod(${regs[reg_idx-1]})))
        hist_add_binary "Reminder" "${regs[reg_idx-1]}"
        print_regs
    fi
}

function minus {
    if [[ -n $input ]]; then
        result=$((input_f*(-1)))
        input=$(printf "%.${PRECISION}f" "$result")
        input_f=$result
        printf "\r%${COLUMNS}s" "$input"
    else
        regs[reg_idx-1]=$((regs[reg_idx-1]*(-1)))
        hist_add_binary "Minus" "${regs[reg_idx-1]}"
        print_regs
    fi
}

################################################################################
# RESTANTE ORIGINAL INALTERADO
################################################################################
function to_inch { regs[reg_idx-1]=$((${regs[reg_idx-1]} / 25.4)); print_regs; }
function to_meter { regs[reg_idx-1]=$((${regs[reg_idx-1]} * 25.4)); print_regs; }

function double_zeros { load_reg "00"; }
function triple_zeros { load_reg "000"; }
function recall_reg { load_reg ${regs[reg_idx - ${1}]}; }
function input_pi { load_reg "3.1415926535"; }

function drop_regs {
    if(( reg_idx > 0 )); then
        regs[reg_idx - 1]=""
        ((reg_idx--))
        print_regs
    fi
}

function swap {
    aux=${regs[reg_idx - 2]}
    regs[reg_idx - 2]=${regs[reg_idx - 1]}
    regs[reg_idx - 1]=$aux
    print_regs
}

function clear {
    printf "\r%${COLUMNS}s" ' '
    input=""
}

function load_reg {
    if [[ $1 == "BS" ]]; then
        input="${input%?}"
    else
        input="${input}${1}"
    fi
    input_f=$input
    printf "\r%${COLUMNS}s" "$input"
}

################################################################################
function dispatch_key {
    key="$1"
    case "$key" in
           "CTRL_B")       print -n "CTRL_B";;
           "CTRL_C")       printf "\nbye!\n"; exit 0;;
           "CTRL_P")       input_pi;;
           "CTRL_R")       inverse;;
               "CR")       enter;;
            "FN_01")       print_help;;
            "FN_02")       print_regs;;
            "FN_05")       swap;;
            "FN_06")       echo F6;;
            "FN_07")       echo F7;;
            "FN_08")       echo F8;;
            "FN_09")       echo F9;;
            "FN_10")       echo F10;;
            "FN_11")       echo F11;;
            "FN_12")       echo F12;;
            "CURS_RIGHT")  double_zeros;;
            "CURS_DOWN")   minus;;
            "CURS_UP")     swap;;
            "CURS_LEFT")   drop_regs;;
            "PG_UP")       square_root;;
            "PG_DOWN")     triple_zeros;;
            "HOME")        recall_reg $input;;
            "INS")         echo INS;;
            "DEL")         clear;;
            "BS")          load_reg "$key";;
                *)      case $key in
                            '~') round;;
                            ',') double_zeros;;
                            '+') add;;
                            '-') sub;;
                            '*') mul;;
                            '/') div;;
                            'T') trunc;;
                            'a') abs;;
                            'd') drop_regs;;
                            'f') float_p_reminder;;
                            'H') print_help;;
                            'k') set_precision $input; print_regs;;
                            'I') to_inch;;
                            'M') to_meter;;
                            'm') minus;;
                            'p') power;;
                            'P') inv_power;;
                            'R') inverse;;
                            'r') square_root;;
                            'S') swap;;
                            'q') exit;;
                             [0-9.])load_reg "$key";;
                        esac
    esac
}

################################################################################
while getopts "k:C:tsvh" arg
do
    case $arg in
        k) set_precision $OPTARG ;;
        C) COLUMNS=$OPTARG ;;
        s) CLRSCR=TRUE ;;
        v) print "${PLNKSH_CALC_SCRIPT_NAME} ${PLN_KSH_VERSION}"; exit 0 ;;
        t) ENABLE_TEST=TRUE; exec > /dev/null ;;
        h|*) usage; exit 1 ;;
    esac
done

shift $(($OPTIND - 1))

print "${PLNKSH_CALC_SCRIPT_NAME} ${PLN_KSH_VERSION}"
print_regs

while true; do
    dispatch_key "$(NewGetKey)"
done

