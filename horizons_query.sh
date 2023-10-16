#!/bin/bash
###############################################################################
# A small script to query different JPL/Horizons services trough the web or
# file API.
# For the usage run the script with the --help option.
# https://github.com/rszakats/horizons_query
# R. Szakáts, Konkoly Observatory, 2023
###############################################################################
# Parameters
# oldvars=$(compgen -v | cat)
red="\033[1;31m\e[5m"
green="\033[1;32m"
normal="\033[0m"
bold='\033[1m'
baseurl="https://ssd.jpl.nasa.gov/api/horizons.api?OBJ_DATA='YES'&MAKE_EPHEM='YES'" # format=text
tmpdir="/tmp/${USER}"
mkdir -p ${tmpdir}
externals="awk grep curl wget"

argtable="
format format
command COMMAND
ephemtype EPHEM_TYPE
center CENTER
refplane REF_PLANE
coordtype COORD_TYPE
sitecoord SITE_COORD
starttime START_TIME
stoptime STOP_TIME
stepsize STEP_SIZE
tlist TLIST
tlisttype TLIST_TYPE
quantities QUANTITIES
refsystem REF_SYSTEM
outunits OUT_UNITS
vectable VEC_TABLE
veccorr VEC_CORR
calformat CAL_FORMAT
caltype CAL_TYPE
angformat ANG_FORMAT
apparent APPARENT
timedigits TIME_DIGITS
timezone TIME_ZONE
rangeunits RANGE_UNITS
suppressrangerate SUPPRESS_RANGE_RATE
elevcut ELEV_CUT
skipdaylt SKIP_DAYLT
solarelong SOLAR_ELONG
airmass AIRMASS
lhacutoff LHA_CUTOFF
angratecutoff ANG_RATE_CUTOFF
extraprec EXTRA_PREC
csvformat CSV_FORMAT
veclabels VEC_LABELS
vecdeltat VEC_DELTA_T
elmlabels ELM_LABELS
tptype TP_TYPE
rtsonly R_T_S_ONLY
catabletype CA_TABLE_TYPE
tca3sglimit TCA3SG_LIMIT
calimsb CALIM_SB
calimpl CALIM_PL
"
# e=($(echo -e "${argtable}" | grep starttime))
# echo ${e[1]}
# Functions

function help {
    echo -e "${bold}Example usage:${normal}"

}
export -f help

function check_command {
    args=($@)
    command -v "${args[0]}" >/dev/null 2>&1 || { echo -e >&2 "${red}The script requires ${bold}${green}"${args[0]}"${normal}${red} but it's not installed.  Aborting.${normal}"; exit 1; }
}
export -f check_command

function get_HGA {
    args=($@)
    infile="${args[0]}"
    # echo $infile
    H=$(grep " H=" ${infile} | awk 'NR==1{print $2}')
    G=$(grep " G=" ${infile} | awk 'NR==1{print $4}')
    A=$(grep " ALBEDO=" ${infile} | awk 'NR==1{print $2}')
    iscomet=$(grep Comet ${infile})
    if [[ "$iscomet" > 0 ]];then
        H=$(grep " M1=" ${infile} | awk 'NR==1{print $2}')
    fi
    if [ -z "$H" ]; then
        H="n.a."
    fi
    if [ -z "$G" ]; then
        G="n.a."
    fi
    if [ -z "$A" ]; then
        A="n.a."
    fi

    if [[ "$H" != "n.a" ]]; then
        H=$(echo $H | awk '{printf "%1.3f", $1 }')
    fi
    if [[ "$G" != "n.a." ]]; then
        G=$(echo $G | awk '{printf "%1.3f", $1 }')
    fi
    if [[ -z "$A" ]]; then
        A=$(echo $A | awk '{printf "%1.3f", $1 }')
    fi
    echo $H $G $A 
}
export -f get_HGA

# Main script

echo "Running with arguments:" "$@"

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
        "--usefileapi"* )
           usefileapi="True";;
        "--verbose"* )
           verbose="True";;
        # arguments for common parameters
        "--format"* )
           format="${opt#*=}";;
        "--command"* )
           command="${opt#*=}";;
        "--ephemtype"* )
           ephemtype="${opt#*=}";;
        # arguments for ephemeris-specific parameters   
        "--center"* )
           center="${opt#*=}";;
        "--refplane"* )
           reflplane="${opt#*=}";;
        "--coordtype"* )
           coordtype="${opt#*=}";;
        "--sitecoord"* )
           sitecoord="${opt#*=}";;
        "--starttime"* )
           starttime="${opt#*=}";;
        "--stoptime"* )
           stoptime="${opt#*=}";;
        "--stepsize"* )
           stepsize="${opt#*=}";;
        "--tlist"* )
           tlist="${opt#*=}";;
        "--tlisttype"* )
           tlisttype="${opt#*=}";;
        "--quantities"* )
           quantities="${opt#*=}";;
        "--refsystem"* )
           refsystem="${opt#*=}";;
        "--outunits"* )
           outunits="${opt#*=}";;
        "--vectable"* )
           vectable="${opt#*=}";;
        "--veccorr"* )
           veccorr="${opt#*=}";;
        "--calformat"* )
           calformat="${opt#*=}";;
        "--caltype"* )
           caltype="${opt#*=}";;
        "--angformat"* )
           angformat="${opt#*=}";;
        "--apparent"* )
           apparent="${opt#*=}";;
        "--timedigits"* )
           timedigits="${opt#*=}";;
        "--timezone"* )
           timezone="${opt#*=}";;
        "--rangeunits"* )
           rangeunits="${opt#*=}";;
        "--suppressrangerate"* )
           suppressrangerate="${opt#*=}";;
        "--elevcut"* )
           elevcut="${opt#*=}";;
        "--skipdaylt"* )
           skipdaylt="${opt#*=}";;
        "--solarelong"* )
           solarelong="${opt#*=}";;
        "--airmass"* )
           airmass="${opt#*=}";;
        "--lhacutoff"* )
           lhacutoff="${opt#*=}";;
        "--angratecutoff"* )
           angratecutoff="${opt#*=}";;
        "--extraprec"* )
           extraprec="${opt#*=}";;
        "--csvformat"* )
           csvformat="${opt#*=}";;
        "--veclabels"* )
           veclabels="${opt#*=}";;
        "--vecdeltat"* )
           vecdeltat="${opt#*=}";;
        "--elmlabels"* )
           elmlabels="${opt#*=}";;
        "--tptype"* )
           tptype="${opt#*=}";;
        "--rtsonly"* )
           rtsonly="${opt#*=}";;
        # arguments for SPK File Parameters
        # "--starttime"* )
        #    starttime="${opt#*=}";;
        # "--stoptime"* )
        #    stoptime="${opt#*=}";;
        # arguments for Close-Approach Table Parameters
        "--catabletype"* )
           catabletype="${opt#*=}";;
        "--tca3sglimit"* )
           tca3sglimit="${opt#*=}";;
        "--calimsb"* )
           calimsb="${opt#*=}";;
        "--calimpl"* )
           calimpl="${opt#*=}";;
        # help
        "--help" )
           help; exit 1;;
        *) echo >&2 "Invalid option: $* Use --help"; exit 1;;
   esac
done

for  ext in ${externals};do
    check_command ${ext}
done
if [ -z "${wdir}" ]; then
    wdir=$(pwd)  # or change this to your desired default directory
fi

# if [ -z "${infile}" ]; then
#     echo "No input file specified! Use --help"; exit 1
# fi

if [ -z "${format}" ]; then
    format="text"
fi

if [[ "${usefileapi}" != "True" ]] && [ -z "${command}" ]; then
    echo -e ${red}"Please specify a target body!"${normal}
    echo "For details see: https://ssd-api.jpl.nasa.gov/doc/horizons.html#command"
    echo "Use --help"; exit 1
fi

if [[ "${usefileapi}" != "True" ]] && [ -z "${ephemtype}" ]; then
    echo -e ${red}"Please specify a type of ephemeris to generate!"${normal}
    echo "See here: https://ssd-api.jpl.nasa.gov/doc/horizons.html#ephem_type" ; exit 1
fi

if [ -z "${outfile}" ]; then
    outfile='horizons_result.csv'  # Change this to your desired default filename
fi


if [[ "${usefileapi}" != "True" ]] && ([[ "${ephemtype}" == "observer" ]] || [[ "${ephemtype}" == "vectors" ]] || [[ "${ephemtype}" == "elements" ]]); then
    url=""
    aargtable=($argtable)
    len=$(echo ${#aargtable[@]}-1 | bc)

    for (( C=0; C<=${len}; C+=2 )); do
        a=$(echo ${aargtable[$C]})
        if [ ! -z "${!a}" ];then
            name=($(echo -e "${argtable}" | grep -w ${a}))
            # echo ${name[@]}
            name=${name[1]}
            url=${url}"&"$(echo $name"="${!a})
        fi
    done

    query=$(echo ${baseurl}${url} | sed s/\;/\%3B/g)
    echo $query 
    wget -q "$query" -O ${tmpdir}${outfile}
fi

if [[ "${usefileapi}" == "True" ]];then
    curl -s -F format=text -F input=@${infile} https://ssd.jpl.nasa.gov/api/horizons_file.api >  ${tmpdir}/results.txt
    HGA=($(get_HGA /tmp/${USER}/results.txt))
    header=$(grep -B 2 SOE  /tmp/${USER}/results.txt | head -n 1 |\
                awk '{print "target, H, G, albedo, ",$0}')
    target=$(grep "Target body name" /tmp/${USER}/results.txt | sed s/"Target body name:"//g)
    target=${target%"{"*}
    target=$(echo ${target} | awk '{$1=$1;print}')
    isoutfile=$(find ${wdir} -maxdepth 1 -type f -name "${outfile}*"  | wc -l)
    if [[ "${isoutfile}" > 0 ]];then
        mv ${wdir}${outfile} ${wdir}${outfile}.${isoutfile}
    fi
    echo ${header} > ${wdir}${outfile}
    sed -n '/SOE/,/EOE/{/SOE/b;/EOE/b;p}' /tmp/${USER}/results.txt |\
    awk -v target="${target}" -v H="${HGA[0]}" -v G="${HGA[1]}" -v albedo="${HGA[2]}" '{print target", ",H", ",G", ",albedo", ",$0}' >> ${wdir}${outfile}
fi
echo -e "${green}All done!${normal}"