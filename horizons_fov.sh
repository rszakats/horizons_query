#!/bin/bash
###############################################################################
# A small script to query JPL/Horizons FOV service trough the API.
# https://ssd-api.jpl.nasa.gov/doc/sb_ident.html
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
externals="awk grep curl wget wc"
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

get_vectors() {
    args=($@)
    base="https://ssd.jpl.nasa.gov/api/horizons.api?format=text&OBJ_DATA='YES'&MAKE_EPHEM='YES'&EPHEM_TYPE='VECTOR'&TLIST_TYPE='JD'&CSV_FORMAT='YES'&VEC_TABLE='2'"
    COMMAND='-170'
    CENTER='500@10'
    TLIST="${args[0]}"
    #echo "${base}&CENTER='${CENTER}'&TLIST='${TLIST}'&COMMAND='${COMMAND}'"
    query=$(echo "${base}&CENTER='${CENTER}'&TLIST='${TLIST}'&COMMAND='${COMMAND}'&REF_PLANE='F'&OUT_UNITS='AU-D'") # &VEC_CORR='LT'
    #echo ${query}
    wget -q "$query" -O ${tmpdir}/${outfile}
    grep SOE -A 2 ${tmpdir}/${outfile} | grep -v SOE|\
     awk -F ',' 'NR==1{print $3,",",$4,",",$5,",",$6,",",$7,",",$8}' |\
     sed -e s_\ __g -e s_E+_E\%2B_g -e s_E-_E\%2D_g
    

}

convert_ra_deg_to_HMS (){
    args=($@)
    prefix=""
    ra=${args[0]}
    # echo "ra:" ${ra}
    if [ 1 -eq "$(echo "${ra} < 0.0" | bc)" ]; then
        prefix="M"
        ra=$(bc -l <<< "${args[0]}*-1")
    fi
    ra_h=$(bc -l <<< "scale=0;${ra}/15")
    ra_m=$(bc -l <<< "((${args[0]}/15)-${ra_h})*60")
    ra_m0=$(bc -l <<< "scale=0;${ra_m}/1")
    ra_s=$(bc -l <<< "scale=0;(${ra_m}-${ra_m0})*60/1")
    echo ${prefix}${ra_h}-${ra_m0}-${ra_s}
}

convert_dec_deg_to_HMS (){
    args=($@)
    prefix=""
    dec=${args[0]}
    # echo "ra:" ${ra}
    if [ 1 -eq "$(echo "${dec} < 0.0" | bc)" ]; then
        prefix="M"
        dec=$(bc -l <<< "${dec}*-1")
    fi
    dec_h=$(bc -l <<< "scale=0;${dec}/1")
    dec_m=$(bc -l <<< "(${dec}-${dec_h})*60")
    dec_m0=$(bc -l <<< "scale=0;${dec_m}/1")
    dec_s=$(bc -l <<< "scale=0;(${dec_m}-${dec_m0})*60/1")
    echo ${prefix}${dec_h}-${dec_m0}-${dec_s}
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
size=0.08 #$(bc -l <<< "113/60/60") # deg
outfile="fov_result.csv"
# James Webb 500@-170

cd ${wdir} || exit 1
while read -r line
    do
        if [ ! -z "$(echo $line | grep -v Date)" ];then
            echo $line
            fovracenter=$(echo $line |awk '{print $2}')
            fovracenter=$(convert_ra_deg_to_HMS ${fovracenter})
            fovdeccenter=$(echo $line |awk '{print $3}')
            fovdeccenter=$(convert_dec_deg_to_HMS ${fovdeccenter})
            fovrahwidth=${size}
            fovdechwidth=${size}
            TLIST=$(echo $line | cut -d " " -f 1)
            get_vectors ${TLIST}
            vectors=$(get_vectors ${TLIST})
            url=${baseurl}
            url=${url}"xobs-hel=${vectors}&obs-time=${TLIST}"
            url=${url}"&fov-ra-center=${fovracenter}&fov-dec-center=${fovdeccenter}"
            url=${url}"&fov-ra-hwidth=${fovrahwidth}&fov-dec-hwidth=${fovdechwidth}"
            # url=${url}"&two-pass=true&suppress-first-pass=true"
            echo ${url}
            
            sleep 1
        fi
    done < "${infile1}" 
