#!/bin/ksh
#        1         2         3         4         5         6         7         8         9
#234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
# Import lib
. $OHRS_STUFF_PATH/plnc-ksh/kbdlib.sh

################################################################################
SCRIPT_NAME="PLNKSH Calc"
################################################################################
PLN_KSH_VERSION=0.997a
AUTHOR="Orlando Hehl Rebelo dos Santos"
DATE_INI="05-08-2017"
DATE_END="06-04-2019"
################################################################################

#clear
BOLD_GREEN="\033[1;49;92m"
NO_COLOUR="\033[0m"
BOLD_RED="\033[1;49;91m"

function print_regs {
   if [[ $CLRSCR == "TRUE" ]]; then
       tput clear
   fi

   printf  "\r                        \n"

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
                  printf "%2d:%${columns_available}.${PRECISION}f\n" $regs_length ${regs[$index]}
               ((regs_length--))
           fi
       done
    else
          echo "(EMPTY STACK)"
    fi

   for ((i=0; i < COLUMNS; i++)); do
      printf "-"
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

usage(){
        print $SCRIPT_NAME
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

print "${SCRIPT_NAME} ${PLN_KSH_VERSION}"

function clear {
   printf  "\r                               \r"
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
    #echo 'load_reg()'
    #echo $input
   input="${input}${1}"
    #echo $input
   input_f=$input
   printf "\r%${COLUMNS}s" ${input}
}


function enter {

   if [[ -n $input ]]; then
      regs[$reg_idx]=$input_f
      input=""
   else
      regs[$reg_idx]=${regs[reg_idx - 1]}
   fi
   ((reg_idx++))

   printf  "\r                               "
   print_regs
}

function add {
   if(( $reg_idx < 1)); then return;fi

   if [[ -n $input ]]; then
      regs[reg_idx - 1]=$((input_f + regs[reg_idx - 1]))
      regs[reg_idx]=""
      input=""
   else
      regs[reg_idx - 2]=$((regs[reg_idx - 2] + regs[reg_idx - 1]))
      ((reg_idx--))
      regs[reg_idx]=""
   fi

   print_regs
}

function sub {
   if(( $reg_idx < 1)); then print "Error!"; return;fi

   if [[ -n $input ]]; then
      regs[reg_idx - 1]=$((regs[reg_idx - 1] - input_f))
      regs[reg_idx]=""
      input=""
   else
      regs[reg_idx - 2]=$((regs[reg_idx - 2] - regs[reg_idx - 1]))
      ((reg_idx--))
      regs[reg_idx]=""
   fi

   print_regs
}

function mul {
   if(( $reg_idx < 1)); then print "Error!"; return;fi

   if [[ -n $input ]]; then
      regs[reg_idx - 1]=$((regs[reg_idx - 1] * input_f))
      regs[reg_idx]=""
      input=""
   else
      regs[reg_idx - 2]=$((regs[reg_idx - 2] * regs[reg_idx - 1]))
      ((reg_idx--))
      regs[reg_idx]=""
   fi

   print_regs
}

function div {
   if(( $reg_idx < 1)); then print "Error!"; return;fi

   if [[ -n $input ]]; then
      regs[reg_idx - 1]=$((regs[reg_idx - 1] / input_f))
      regs[reg_idx]=""
      input=""
   else
      regs[reg_idx - 2]=$((regs[reg_idx - 2] * 1.0 / regs[reg_idx - 1]))
      ((reg_idx--))
      regs[reg_idx]=""
   fi

   print_regs
}

function swap {
   aux=${regs[reg_idx - 2]}
   regs[reg_idx - 2]=${regs[reg_idx - 1]}
   regs[reg_idx - 1]=$aux

   print_regs
}

function sqrt {
   if [[ -n $input ]]; then
      input_f=$((sqrt(input_f)))
      input=""
      load_reg "$input_f"
      return
   else
      regs[reg_idx - 1]=$((sqrt(${regs[reg_idx - 1]})))
      regs[reg_idx]=""
   fi

   print_regs
}

function power {
   if [[ -n $input ]]; then
      input_f=$((regs[reg_idx - 1] ** input_f))
      input=""
      load_reg "$input_f"
      return
   else
      regs[reg_idx - 1]=$((regs[reg_idx - 2] ** regs[reg_idx - 1]))
      regs[reg_idx]=""
   fi

   print_regs
}

function inv_power {
   if [[ -n $input ]]; then
      input_f=$((regs[reg_idx - 1] ** (1 / input_f)))
      input=""
      load_reg "$input_f"
      return
   else
      regs[reg_idx - 1]=$((regs[reg_idx - 2] ** regs[reg_idx - 1]))
      regs[reg_idx]=""
   fi

   print_regs
}

function to_inch {
   if [[ -n $input ]]; then
      regs[$reg_idx]=$((input_f / 25.4))
      input=""
      ((reg_idx++))
   else
      regs[reg_idx - 1]=$((${regs[reg_idx - 1]} / 25.4 ))
      regs[reg_idx]=""
   fi

   print_regs
}

function to_meter {
   if [[ -n $input ]]; then
      regs[$reg_idx]=$((input_f * 25.4))
      input=""
      ((reg_idx++))
   else
      regs[reg_idx - 1]=$((${regs[reg_idx - 1]} * 25.4 ))
      regs[reg_idx]=""
   fi

   print_regs
}

function abs {
   if [[ -n $input ]]; then
      regs[$reg_idx]=$((abs(input_f)))
      input=""
      ((reg_idx++))
   else
      regs[reg_idx - 1]=$((abs(${regs[reg_idx - 1]})))
      regs[reg_idx]=""
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
COMMAND[0]="Exitr|CTRL+C or q"
COMMAND[1]="Print|Stack CTRL+P"
COMMAND[2]="Recall|Register R#, F2"
COMMAND[4]="Swap|F5"
COMMAND[5]="Round|~"
COMMAND[6]="00|,"
COMMAND[7]="000|F10"
COMMAND[8]="Clear|BACK SPACE"
COMMAND[9]="Clear|BACK SPACE"
COMMAND[10]="Minus|-"
COMMAND[11]="Pi|p"
COMMAND[12]="Precision|INPUT-REG k"
COMMAND[13]="Precision|R1 k"

for i in "${!COMMAND[@]}"; do
   echo "${COMMAND[i]}"
done

   printf  "\nPress any key to continue...                  \n\n"
   read -n1
   print_regs

}

function dispatch_key {
    case "$Key" in
           "CTRL_B")       print -n "CTRL_B";;
           "CTRL_C")       printf "\nbye!\n"; exit 0;;
           "CTRL_P")       print_regs;;
               "CR")       enter;;
            "FN_01")       print_help;;
            "FN_02")       recall_reg $input;;
            "FN_05")       swap;;
            "FN_06")       echo F6;;
            "FN_07")       echo F7;;
            "FN_08")       echo F8;;
            "FN_09")       echo F9;;
            "FN_10")       triple_zeros;;
            "FN_11")       echo F11;;
            "FN_12")       echo F12;;
            "CURS_RIGHT")  double_zeros;;
            "CURS_DOWN")   minus;;
            "CURS_UP")     swap;;
            "CURS_LEFT")   drop_regs;;
            "PG_UP")       sqrt;;
            "PG_DOWN")     triple_zeros;;
            "INS")         echo INS;;
            "DEL")         clear;;
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
                            #'P') input_pi;;
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
