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
externals="awk grep curl wget wc"
defout="horizons_result.csv"
csvformat="YES"

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
aargtable=($argtable)

# Functions

help () {
    echo -e "${bold}Example usage:${normal}"

}

check_command () {
    args=($@)
    command -v "${args[0]}" >/dev/null 2>&1 || { echo -e >&2 "${red}The script requires ${bold}${green}"${args[0]}"${normal}${red} but it's not installed.  Aborting.${normal}"; exit 1; }
}

process_input_csv () {
   args=($@)
   infile="${args[0]}"
   header=($(awk -F ',' '!/^#/ && NR==1 {print $0}' ${wdir}/${infile} | sed s/,/\ /g))
   ncol=${#header[@]}
   lc=0
   while read line
   do
      echo "Processing line : $line"
      # line=($(echo ${line} | sed s/,/\ /g))
      u=""
      for (( C=0; C<=${ncol}-1; C+=1 )); do
         l=$(echo $line | awk -v C=${C} -F ',' '{print $(C+1)}')
         name=($(echo -e "${argtable}" | grep -w ${header[$C]}))
         name=${name[1]}
         if [ ! -z "${!header[$C]}" ];then
            echo -e ${red}"Warning! Duplicate! Deleting value${normal} ${bold}"${!header[$C]}" ${normal}for${bold} ${name}"${normal}
            unset "${header[$C]}"
         fi
         u=${u}"&${name}=${l}"
      done
      # echo "url: "${u}
      len=$(echo ${#aargtable[@]}-1 | bc)
      url=""
      for (( C=0; C<=${len}; C+=2 )); do
         a=$(echo ${aargtable[$C]})
         if [ ! -z "${!a}" ];then
               name=($(echo -e "${argtable}" | grep -w ${a}))
               name=${name[1]}
               url=${url}"&"$(echo $name"="${!a})
         fi
      done
      query=$(echo ${baseurl}${url}${u} | sed s/\;/\%3B/g)
      # echo $query 
      wget -q "$query" -O ${tmpdir}/${outfile}
      HGA=($(get_HGA ${tmpdir}/${outfile}))
      header0=$(grep -B 2 SOE  ${tmpdir}/${outfile} | head -n 1 |\
            awk '{print "target, H, G, albedo, ",$0}')
      if [ ${lc} == 0 ];then
         echo ${header0} > ${wdir}/${outfile}
      fi
      target=$(get_target ${tmpdir}/${outfile})
      s1=$(grep SOE -n ${tmpdir}/${outfile}| awk -F ':' '{print $1}')
      s2=$(grep EOE -n ${tmpdir}/${outfile}| awk -F ':' '{print $1}')
      if [ -z "${s1}" ] || [ -z "${s2}" ]; then
         echo -e ${red}"Warning! No data found!"${normal}
         echo -e ${bold}"Please check"${normal}${green} ${tmpdir}/${outfile}${normal} "for errors!" ; exit 1
      fi
      echo "$(head -n $(echo ${s2}-1 | bc) ${tmpdir}/${outfile} | tail -n $(echo ${s2}-${s1}-1 | bc) |\
            awk -v target="${target}" -v H=${HGA[0]} -v G=${HGA[1]} -v albedo=${HGA[2]} '{print target,",",H,","G,",",albedo",",$0}')" >> ${wdir}/${outfile}
      ((lc+=1))
   done < <(awk -F ',' '!/^#/ && NR!=1 {print $0}' ${wdir}/${infile})

}

process_query () {
   url=""
   len=$(echo ${#aargtable[@]}-1 | bc)

   for (( C=0; C<=${len}; C+=2 )); do
      a=$(echo ${aargtable[$C]})
      if [ ! -z "${!a}" ];then
            name=($(echo -e "${argtable}" | grep -w ${a}))
            name=${name[1]}
            url=${url}"&"$(echo $name"="${!a})
      fi
   done
   query=$(echo ${baseurl}${url} | sed s/\;/\%3B/g)
   # echo $query 
   wget -q "$query" -O ${tmpdir}/${outfile}
   HGA=($(get_HGA ${tmpdir}/${outfile}))
   header=$(grep -B 2 SOE  ${tmpdir}/${outfile} | head -n 1 |\
         awk '{print "target, H, G, albedo, ",$0}')
   target=$(get_target ${tmpdir}/${outfile})
   s1=$(grep SOE -n ${tmpdir}/${outfile}| awk -F ':' '{print $1}')
   s2=$(grep EOE -n ${tmpdir}/${outfile}| awk -F ':' '{print $1}')
   if [ -z "${s1}" ] || [ -z "${s2}" ]; then
      echo -e ${red}"Warning! No data found!"${normal}
      echo -e ${bold}"Please check"${normal}${green} ${tmpdir}/${outfile}${normal} "for errors!" ; exit 1
   fi
   echo ${header} > ${wdir}/${outfile}
   echo $(head -n $(echo ${s2}-1 | bc) ${tmpdir}/${outfile} | tail -n $(echo ${s2}-${s1}-1 | bc) |\
            awk -v target="${target}" -v H=${HGA[0]} -v G=${HGA[1]} -v albedo=${HGA[2]} '{print target,",",H,","G,",",albedo",",$0}' >> ${wdir}/${outfile})
}

get_target () {
   args=($@)
   infile="${args[0]}"
   target=$(grep "Target body name" ${infile} | sed s/"Target body name:"//g)
   target=${target%"{"*}
   echo ${target} | awk '{$1=$1;print}'
}

use_fileapi () {
   args=($@)
   infile="${args[0]}"
   check=$(grep "!\$\$SOF" ${infile}|  wc -l | awk '{print $1}')
   if [ "${check}" == 0 ]; then
      echo -e ${red}"Warning! Wrong input file format! Exiting."${normal}; exit 1
   fi
   curl -s -F format=text -F input=@${infile} https://ssd.jpl.nasa.gov/api/horizons_file.api >  ${tmpdir}/results.txt
   size=$(wc -c ${tmpdir}/results.txt | awk '{print $1}')
   if [ "${size}" == 0 ];then
      echo -e ${red}"Warning!" Returned file size is zero! Check your settings! Exiting.${normal} ; exit 1
   fi
   HGA=($(get_HGA ${tmpdir}/results.txt))
   header=$(grep -B 2 SOE  ${tmpdir}/results.txt | head -n 1 |\
            awk '{print "target, H, G, albedo, ",$0}')
   target=$(get_target ${tmpdir}/results.txt)
   isoutfile=$(find ${wdir} -maxdepth 1 -type f -name "${outfile}*"  | wc -l)
   if [[ "${isoutfile}" > 0 ]];then
      mv ${wdir}${outfile} ${wdir}${outfile}.${isoutfile}
   fi
   echo ${header} > ${wdir}${outfile}
   sed -n '/SOE/,/EOE/{/SOE/b;/EOE/b;p}' ${tmpdir}/results.txt |\
   awk -v target="${target}" -v H="${HGA[0]}" -v G="${HGA[1]}" -v albedo="${HGA[2]}" '{print target", ",H", ",G", ",albedo", ",$0}' >> ${wdir}${outfile}
}

get_HGA () {
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


# Main script

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

csvformat='YES' # hardwired for now; TODO: allow JSON format

if [ -z "${wdir}" ]; then
   wdir=$(pwd)  # or change this to your desired default directory
   if [ "${verbose}" == "True" ]; then
      echo "Working directory was not specified. Setting to default."
      echo "New working directory: ${wdir}"
   fi
fi

if [ -z "${format}" ]; then
    format="text"
fi

if [ -z "${outfile}" ]; then
   if [ "${verbose}" == "True" ]; then
      echo "Output file was not specified. Setting to default."
      echo "New output file: ${defout}"
   fi
   outfile=${defout}  # Change this to your desired default filename
fi

if [[ "${usefileapi}" == "True" ]];then
   if [[ ! -z "${ephemtype}" ]];then
      echo -e ${red}"Warning!${normal} Using --usefileapi and --ephemtype at the same time is not allowed!"
      echo "Use --help" ; exit 1
   fi
   if [ -z "${infile}" ]; then
      echo "No input file specified! Use --help"; exit 1
   fi
   use_fileapi ${wdir}/${infile}
else

   if [ -z "${command}" ]; then
      echo -e ${red}"Please specify a target body!"${normal}
      echo "For details see: https://ssd-api.jpl.nasa.gov/doc/horizons.html#command"
      echo "Use --help"; exit 1
   fi

   if [ -z "${ephemtype}" ]; then
      echo -e ${red}"Please specify a type of ephemeris to generate!"${normal}
      echo "See here: https://ssd-api.jpl.nasa.gov/doc/horizons.html#ephem_type"
      echo "Use --help" ; exit 1
   fi

   if [[ "${ephemtype}" == "observer" ]] || [[ "${ephemtype}" == "vectors" ]] || [[ "${ephemtype}" == "elements" ]]; then
      if [ ! -z "${infile}" ];then
         process_input_csv ${infile}
      else
         process_query
      fi
   fi
fi
echo -e "${green}All done!${normal}"