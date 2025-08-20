#!/bin/ksh
################################################################################
PLNKSH_CALC_SCRIPT_NAME="PLNKSH Calc"
################################################################################
PLN_KSH_VERSION=0.2.007
AUTHOR="Orlando Hehl Rebelo dos Santos"
DATE_INI="05-08-2017"
DATE_END="14-09-2019"
DATE_END="21-11-2022"
DATE_END="19-08-2025"
################################################################################
OHRS_LIB_DIR="$OHRS_STUFF_PATH/lib/sh"
OHRS_ETC_DIR="$OHRS_STUFF_PATH/etc"
source $OHRS_ETC_DIR/color-constants.sh
#source $OHRS_LIB_DIR/kbdlib.sh
source $OHRS_STUFF_PATH/share/plnc-ksh/kbdlib.sh

#clear
#BOLD_GREEN="\033[1;49;92m"
#NO_COLOUR="\033[0m"
#RED="\033[1;49;91m"

function print_regs {

   if [[ $CLRSCR == "TRUE" ]]; then
       tput clear
   fi


   printf  "\r                        \n\n\n"

   for h in "${history[@]}"; do
        printf "${FG237}%${COLUMNS}s${C_RST}\n" "$h"
   done
   for (( i = 0; i <= $COLUMNS; i++ )); do  printf "${FG237}-${C_RST}"; done
   printf "\n\n"

   if [[ -n ${regs[0]} ]]; then

       regs_length=0
       #This loop is used to count the vector elements not null as
       #unused elements are not freed up in memory, by the shell 
       for index in "${!regs[@]}"; do
           if [[ -n ${regs[index]} ]]; then
              ((regs_length++))
           fi
       done

       columns_available=$((COLUMNS - 3))
       for index in "${!regs[@]}"; do
           if [[ -n ${regs[index]} ]]; then
               if [[ ${regs[index]} -ge 0 ]]; then
                   printf "$D_WHITE%2d:$C_RST%${columns_available}.${PRECISION}f\n" $regs_length ${regs[$index]}
               else
                   printf "$D_WHITE%2d:$D_RED%${columns_available}.${PRECISION}f$C_RST\n" $regs_length ${regs[$index]}
              fi
              ((regs_length--))
           fi
       done
    else
          echo "(EMPTY STACK)"
    fi

   for ((i=0; i < COLUMNS; i++)); do
      printf "="
   done
   printf "\n>"
}

function set_precision {

   if [[ -n ${1} ]]; then
      PRECISION=${1}
      input=""
   else
      PRECISION=${regs[reg_idx - 1]}
      drop_regs
   fi

   #Unlike trunc(), abs() must be used because of printf() formating option and returnig error.
   PRECISION=$((abs(PRECISION)))
}

set_precision 2
reg_idx=0
typeset -F10 input_f
typeset -a history
hist_index=1
float_point=false

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

while getopts "k:C:tsvh" arg
do
        case $arg in
            k)
                set_precision $OPTARG
                ;;
            C)
                #COLUMNS=26
                COLUMNS=$OPTARG
                ;;
            s)
                CLRSCR=TRUE
                ;;
            v)
                print "${SCRIPT_NAME} ${PLN_KSH_VERSION}"
                exit 0
                ;;
            t)
                ENABLE_TEST=TRUE
                exec > /dev/null
                ;;
            h|*)
                usage
                exit 1
                ;;
        esac
done

shift $(($OPTIND - 1))

print "${PLNKSH_CALC_SCRIPT_NAME} ${PLN_KSH_VERSION}"

function clear {
   printf "\r%${COLUMNS}s" ' '
   input=""
}


set -A regs


function drop_regs {
   if(( $reg_idx > 0)); then
      regs[reg_idx - 1]=""
      ((reg_idx--))
      print_regs
   fi
}

function load_reg {
   if [[ $1 != "BS" ]]; then
        if [[ $1 == "." ]]; then
            if [[ -z $input ]]; then
                input="0."
                float_point=true
            else
                if [[ $float_point != true ]]; then
                    input="${input}${1}"
                    float_point=true
                fi
            fi
        else
            input="${input}${1}"
        fi
   else
       input="${input%?}"
   fi
       input_f=$input
   printf "\r${FG255}%${COLUMNS}s${C_RST}" ${input}
}


function enter {

   float_point=false
   if [[ -n $input ]]; then
      regs[$reg_idx]=$input_f
      if [[ $history_skip == 'true'  ]]; then
          history_skip='false'
      else
          history[$hist_index]=$input; ((hist_index++))
      fi
      input=""
   else
      regs[$reg_idx]=${regs[reg_idx - 1]}
   fi
   ((reg_idx++))

   printf  "\r                               "
   print_regs
}

function add {
   float_point=false
   if(( $reg_idx < 1)); then return;fi


   if [[ -n $input ]]; then
      regs[reg_idx - 1]=$((input_f + regs[reg_idx - 1]))
      regs[reg_idx]=""
      history[$hist_index]=$input; ((hist_index++))
      input=""
   else
      regs[reg_idx - 2]=$((regs[reg_idx - 2] + regs[reg_idx - 1]))
      ((reg_idx--))
      regs[reg_idx]=""
   fi

   history[$hist_index]='+'; ((hist_index++))
   history[$hist_index]="${regs[0]}"; ((hist_index++))
   print_regs
}

function sub {
   float_point=false
   if(( $reg_idx < 1)); then print "Error!"; return;fi

   if [[ -n $input ]]; then
      regs[reg_idx - 1]=$((regs[reg_idx - 1] - input_f))
      regs[reg_idx]=""
      history[$hist_index]=$input; ((hist_index++))
      input=""
   else
      regs[reg_idx - 2]=$((regs[reg_idx - 2] - regs[reg_idx - 1]))
      ((reg_idx--))
      regs[reg_idx]=""
   fi

   history[$hist_index]='-'; ((hist_index++))
   history[$hist_index]="${regs[0]}"; ((hist_index++))
   print_regs
}

function mul {
   float_point=false
   if(( $reg_idx < 1)); then print "Error!"; return;fi

   if [[ -n $input ]]; then
      regs[reg_idx - 1]=$((regs[reg_idx - 1] * input_f))
      regs[reg_idx]=""
      history[$hist_index]=$input; ((hist_index++))
      input=""
   else
      regs[reg_idx - 2]=$((regs[reg_idx - 2] * regs[reg_idx - 1]))
      ((reg_idx--))
      regs[reg_idx]=""
   fi

   history[$hist_index]='*'; ((hist_index++))
   history[$hist_index]="${regs[0]}"; ((hist_index++))
   print_regs
}

function div {
   float_point=false
   if(( $reg_idx < 1)); then print "Error!"; return;fi

   if [[ -n $input ]]; then
      regs[reg_idx - 1]=$((regs[reg_idx - 1] / input_f))
      regs[reg_idx]=""
      history[$hist_index]=$input; ((hist_index++))
      input=""
   else
      regs[reg_idx - 2]=$((regs[reg_idx - 2] * 1.0 / regs[reg_idx - 1]))
      ((reg_idx--))
      regs[reg_idx]=""
   fi

   history[$hist_index]='/'; ((hist_index++))
   history[$hist_index]="${regs[0]}"; ((hist_index++))
   print_regs
}

function swap {
   aux=${regs[reg_idx - 2]}
   regs[reg_idx - 2]=${regs[reg_idx - 1]}
   regs[reg_idx - 1]=$aux

   history[$hist_index]='swap'; ((hist_index++))
   history[$hist_index]="${regs[0]}"; ((hist_index++))
   print_regs
}

function sqrt {
   float_point=false
   if [[ -n $input ]]; then
      input_f=$((sqrt(input_f)))
     # if(( $reg_idx < 0)); then
     #     #regs[reg_idx - 1]=$input_f
     #     regs[reg_idx]=""
     # fi
     history[$hist_index]=$input; ((hist_index++)); history_skip='true'
     history[$hist_index]='sqrt'; ((hist_index++))
     history[$hist_index]=$input_f; ((hist_index++))
      input=""
      load_reg "$input_f"
   else
      regs[reg_idx - 1]=$((sqrt(${regs[reg_idx - 1]})))
      regs[reg_idx]=""
      history[$hist_index]='sqrt'; ((hist_index++))
      history[$hist_index]=${regs[reg_idx - 1]}; ((hist_index++))
   fi

   print_regs
}

function power {
   float_point=false
   if [[ -n $input ]]; then
      regs[$reg_idx]=$((regs[reg_idx - 1] ** input_f))
      history[$hist_index]=$input; ((hist_index++))
      input=""
      history[$hist_index]='power'; ((hist_index++))
      history[$hist_index]=${regs[$reg_idx]}; ((hist_index++))
      ((reg_idx++))
   else
      regs[reg_idx - 1]=$((regs[reg_idx - 2] ** regs[reg_idx - 1]))
      regs[reg_idx]=""
      history[$hist_index]='power'; ((hist_index++))
      history[$hist_index]=${regs[reg_idx - 1]}; ((hist_index++))
   fi

   print_regs
}

function inv_power {
   float_point=false
   if [[ -n $input ]]; then
      regs[$reg_idx]=$((regs[reg_idx - 1] ** (1 / input_f)))
      history[$hist_index]=$input; ((hist_index++))
      input=""
      history[$hist_index]='inv power'; ((hist_index++))
      history[$hist_index]=${regs[$reg_idx]}; ((hist_index++))
      ((reg_idx++))
   else
      regs[reg_idx - 1]=$((regs[reg_idx - 2] ** regs[reg_idx - 1]))
      regs[reg_idx]=""
      history[$hist_index]='inv power'; ((hist_index++))
      history[$hist_index]=${regs[reg_idx - 1]}; ((hist_index++))
   fi

   print_regs
}

function to_inch {
   float_point=false
   if [[ -n $input ]]; then
      regs[$reg_idx]=$((input_f / 25.4))
      history[$hist_index]=$input; ((hist_index++)); history_skip='true'
      history[$hist_index]=${regs[$reg_idx]}; ((hist_index++))
      input=""
      ((reg_idx++))
   else
      regs[reg_idx - 1]=$((${regs[reg_idx - 1]} / 25.4 ))
      regs[reg_idx]=""
      history[$hist_index]='to inch'; ((hist_index++))
      history[$hist_index]=${regs[reg_idx - 1]}; ((hist_index++))
   fi

   print_regs
}

function to_meter {
   float_point=false
   if [[ -n $input ]]; then
      regs[$reg_idx]=$((input_f * 25.4))
      history[$hist_index]=$input; ((hist_index++)); history_skip='true'
      history[$hist_index]='to milimiter'; ((hist_index++))
      history[$hist_index]=${regs[$reg_idx]}; ((hist_index++))
      input=""
      ((reg_idx++))
   else
      regs[reg_idx - 1]=$((${regs[reg_idx - 1]} * 25.4 ))
      regs[reg_idx]=""
      history[$hist_index]='to milimiter'; ((hist_index++))
      history[$hist_index]=${regs[reg_idx - 1]}; ((hist_index++))
   fi

   print_regs
}

function abs {
   float_point=false
   if [[ -n $input ]]; then
      regs[$reg_idx]=$((abs(input_f)))
      history[$hist_index]=$input; ((hist_index++)); history_skip='true'
      history[$hist_index]='abs'; ((hist_index++))
      history[$hist_index]=$input_f; ((hist_index++))
      input=""
      ((reg_idx++))
   else
      regs[reg_idx - 1]=$((abs(${regs[reg_idx - 1]})))
      regs[reg_idx]=""
      history[$hist_index]='abs'; ((hist_index++))
      history[$hist_index]=${regs[reg_idx - 1]}; ((hist_index++))
   fi

   print_regs
}

function minus {
   if [[ -n $input ]]; then
      input_f=$((input_f * (-1)))
      printf "\r%.${PRECISION}f                        " $input_f
   else
      regs[reg_idx - 1]=$((${regs[reg_idx - 1]} * (-1)))
      regs[reg_idx]=""
      history[$hist_index]='minus'; ((hist_index++))
      history[$hist_index]="${regs[0]}"; ((hist_index++))
      print_regs
   fi
}

function round {
   if [[ -n $input ]]; then
      input_f=$((round(input_f)))
      printf "\r%.${PRECISION}f                        " $input_f
   else
      regs[reg_idx - 1]=$((round(${regs[reg_idx - 1]})))
      regs[reg_idx]=""
      history[$hist_index]='round'; ((hist_index++))
      history[$hist_index]="${regs[0]}"; ((hist_index++))
      print_regs
   fi
}

function trunc {
   if [[ -n $input ]]; then
      input_f=$((trunc(input_f)))
      printf "\r%.${PRECISION}f                        " $input_f
   else
      regs[reg_idx - 1]=$((trunc(${regs[reg_idx - 1]})))
      regs[reg_idx]=""
      history[$hist_index]='trunc'; ((hist_index++))
      history[$hist_index]="${regs[0]}"; ((hist_index++))
      print_regs
   fi
}

function float_p_reminder {
   if [[ -n $input ]]; then
      input_f=$((fmod(input_f)))
      printf "\r%.${PRECISION}f                        " $input_f
   else
      regs[reg_idx - 1]=$((fmod(${regs[reg_idx - 1]})))
      regs[reg_idx]=""
      history[$hist_index]='reminder'; ((hist_index++))
      history[$hist_index]="${regs[0]}"; ((hist_index++))
      print_regs
   fi
}
 
function double_zeros {
   load_reg "00"
}

function triple_zeros {
   load_reg "000"
}

function recall_reg {

   if [[ -n ${1} ]]; then
      printf  "\r"
      input=""
      load_reg ${regs[reg_idx - ${1}]}
   fi
}

function input_pi {
   if [[ -z $input ]]; then
       load_reg "3.1415926535"
   fi
}

# ***  WIP ***
function print_help {
COMMAND[00]="Exit            : CTRL+C or q"
COMMAND[01]="Print           : Stack F2"
COMMAND[02]="Recall          : Register R#, R"
COMMAND[04]="Swap            : Up Arrow, F5"
COMMAND[05]="Round           : ~"
COMMAND[06]="00              : Right Arrow"
COMMAND[07]="000             : F10, Pg Down"
COMMAND[08]="Clear Register  : Del"
COMMAND[09]="Drop Register   : Left Arrow"
COMMAND[10]="Minus           : Down Arrow, m"
COMMAND[11]="Pi              : CTRL+P"
COMMAND[12]="Precision       : INPUT-REG k"
COMMAND[13]="Precision       : R1 k"
COMMAND[14]="To Inch         : I"
COMMAND[15]="To Meter        : M"
COMMAND[16]="Square          : r"
COMMAND[17]="Power           : p"
COMMAND[18]="Power Inv       : P"
COMMAND[19]="Abs             : a"

#COMMAND[00]="Exit            ....................   CTRL+C or q"
#COMMAND[01]="Print           ....................   Stack CTRL+P"
#COMMAND[02]="Recall          ....................   Register R#, F2"
#COMMAND[04]="Swap            ....................   Up Arrow, F5"
#COMMAND[05]="Round           ....................   ~"
#COMMAND[06]="00              ....................   Right Arrow"
#COMMAND[07]="000             ....................   F10, Pg Down"
#COMMAND[08]="Clear Register  ....................   Del"
#COMMAND[09]="Drop Register   ....................   Left Arrow"
#COMMAND[10]="Minus           ....................   Down Arrow, m"
#COMMAND[11]="Pi              ....................   p"
#COMMAND[12]="Precision       ....................   INPUT-REG k"
#COMMAND[13]="Precision       ....................   R1 k"
#COMMAND[14]="To Inch         ....................   I"
#COMMAND[15]="To Meter        ....................   M"
#COMMAND[16]="Square          ....................   r"
#COMMAND[17]="Power           ....................   p"
#COMMAND[18]="Power Inv       ....................   P"
#COMMAND[19]="Abs             ....................   a"

#for i in "${!COMMAND[@]}"; do
#   echo "${COMMAND[i]}"
#done

for command in "${COMMAND[@]}"; do
   echo "${command}"
done

   printf  "\nPress any key to continue...                  \n\n"
   read -n1
   print_regs

}

function dispatch_key {
    case "$Key" in
           "CTRL_B")       print -n "CTRL_B";;
           "CTRL_C")       printf "\nbye!\n"; exit 0;;
           "CTRL_P")       input_pi;;
               "CR")       enter;;
            "FN_01")       print_help;;
            "FN_02")       print_regs;;
            "FN_05")       echo swap;;
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
            "PG_UP")       sqrt;;
            "PG_DOWN")     triple_zeros;;
            "HOME")       recall_reg $input;;
            "INS")         echo INS;;
            "DEL")         clear;;
            "BS")         load_reg "$Key";;
                *)      case $Key in
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
                            'k') set_precision $input
                                 print_regs
                                 ;;
                            'I') to_inch;;
                            'M') to_meter;;
                            'm') minus;;
                            'p') power;;
                            'P') inv_power;;
                            'R') recall_reg $input;;
                            'r') sqrt;;
                            'S') swap;;
                            'q') exit;;
                             [0-9.])load_reg "$Key";;
                        esac
    esac
}


#Test Units -
if [[ $ENABLE_TEST == "TRUE" ]]; then
    (>&2 echo -n "Multiplication : ")
    for Key in 1 '.' 5 0 'CR' 3 '*'; do
       dispatch_key
    done
    if [[ $((abs(4.500000 - ${regs[0]}))) -le  0.0000001 ]]; then
       (>&2 printf "${BOLD_GREEN}PASS!!!${NO_COLOUR}\n")
    else
       (>&2 printf "${BOLD_RED}FAILED!!!${NO_COLOUR}\n")
       exit 255
    fi


    #unset regs
    (>&2 echo -n "Division       : ")
    for Key in 2 '.' 7 0 'CR' 2 '/'; do
       dispatch_key
    #(>&2 echo -n "${regs[0]}")
    done
    #(>&2 echo -n "${regs[0]}")
    if [[ $((abs(1.350000 - ${regs[0]}))) -le  0.0000001 ]]; then
       (>&2 printf "${BOLD_GREEN}PASS!!!${NO_COLOUR}\n")
    else
       (>&2 printf "${BOLD_RED}FAILED!!!${NO_COLOUR}\n")
       exit 255
    fi

    exit 0
fi

while true; do
    Key=$(NewGetKey)
    dispatch_key
done
