#!/bin/bash
###############################################################################
# A small script to query ephemd for asteroid positions.
# For the usage run the script with the --help option.
# https://github.com/rszakats/horizons_query
# R. Szakáts, Konkoly Observatory, 2024
###############################################################################
## Parameters

red="\033[1;31m\e[5m"
green="\033[1;32m"
yellow="\e[33m"
normal="\033[0m"
bold='\033[1m'
baseurl="https://ssd-api.jpl.nasa.gov/sb_ident.api?" # format=text
tmpdir="/tmp/${USER}"
externals="awk grep curl wget wc ephemd-query.sh"
defout="horizons_result.csv"
csvformat="YES"
infile1="input.dat"

mkdir -p ${tmpdir}

## Functions

# Help function
help () {
    echo "help"
}

# Checks the availability of the used commands
check_command () {
   args=($@)
   command -v "${args[0]}" >/dev/null 2>&1 || { echo -e >&2 "${red}Error! The script requires ${bold}${green}"${args[0]}"${normal}${red} but it's not installed. Aborting.${normal}"; exit 1; }
}

for  ext in ${externals};do
    check_command ${ext}
done

# Getting command line arguments
while [[ $# -gt 0 ]] && [[ "$1" == "--"* ]] ;
do
    opt="$1";
    shift;              #expose next argument
    case "$opt" in
        "--" ) break 2;;
        # script specific arguments
        "--wdir="* )
           wdir="${opt#*=}";;
        "--infile"* )
           infile="${opt#*=}";;
        "--outfile"* )
           outfile="${opt#*=}";;
        "--size"* )
           size="${opt#*=}";;
        # help
        "--help" )
           help; exit 1;;
        *) echo >&2 "Invalid option: $* Use --help"; exit 1;;
   esac
done

if [ -z "${wdir}" ]; then
   wdir=$(pwd)  # or change this to your desired default directory
   if [ "${verbose}" == "True" ]; then
      echo "Working directory was not specified. Setting to default."
      echo "New working directory: ${wdir}"
   fi
fi
size=0.23 # deg
outfile="fov_result.dat"
# James Webb 500@-170

cd ${wdir} || exit 1
result=$(while read -r line
    do
        if [ ! -z "$(echo $line | grep -v Date)" ];then
            # echo $line
            TLIST=$(echo $line | cut -d " " -f 1)
            ra=$(echo $line |awk '{print $2}')
            dec=$(echo $line |awk '{print $3}')
            ephemd-query.sh -b jwst -c ${ra},${dec} -r ${size} -t ${TLIST} |\
             awk '{print $1,$2,$3,$4,$5,"\n"}'
            # sleep 1
        else
            echo -e "ID JD RA DEC Vmag\n"
        fi
    done < "${infile1}" )
printf "${result}"  | column -t -s' ' > ${outfile}
cat ${outfile}
echo -e "\nAll done!"
#| column -t -s' '