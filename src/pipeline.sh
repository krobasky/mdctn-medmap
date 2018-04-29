#!/usr/bin/bash
# Name: pipeline.sh
#
# Runs a pipeline to interpret the medication codes in the CONCEPT_DIMENSION export from i2b2
#
# Dependencies:
#   ${ROOT}/src/get-meds.awk
#   ${ROOT}/src/mapGenCUIDoseCombo.pl
# 
version=1.0 
sccver='$Id:$'

display_usage() {
    display_version
    echo -e "
Usage:  $(basename $0) [-t <med-targets>] [-c <med-codes>] [-h]
  -t med-targets	Tab-delimited, manually curated list of interesting drugs, paired to their most generic RxCUI [$dMedTargets]
  -c med-codes		i2B2 export from NCTraC [$dMedCodes]
  -p problem-codes	codes that have identified problems and don't appear in i2B2 observation data for analysis [$dProblemCodes]
  -o output		where to put the file (tsv mapping, 
                  	cols:MDCTN, general-RxCUIs, general-names,subRxCUIs, subNames []
  -d 			Debug mode
  -h 			This message
"
}
display_help() {
    display_usage
    echo -e "
Make <problem-codes> file by inspecting the NAME_CD field in the i2b2 <med-codes> export. Here are some pointers:

 1. use python's nltk + manual inspection to find all unit types and synonyms (also look at 'forms'). 
       See nlp.py, parse.pl as simple examples to help
 2. use parse.pl to reduce the redundent MDCTN codes and ensure doses are parsing correctly
 3. identify codes that have conflicting units and add to the <problems-codes>
 4. inspect the observations to see what, if any, ipmact there will be from omitting those codes.
"
}
display_version() {
    echo -e "
$(basename $0) Version $version $sccver
Copyright 2018 University of North Carolina Board of Trustees
All Rights Reserved

License: GNU GPL 2
$(basename $0) comes with ABSOLUTELY NO WARRANTY; 
This is free software, and you are welcome to redistribute it under certain conditions.
Author: Kimberly Robasky, krobasky@renci.org
Created On: 2018
"
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="${DIR}/.."

# define default variables so they are still available
# if usage is called after the options have been set
dMedTargets=${ROOT}/config/map.medTarget-RxCUI
dProblemCodes=${ROOT}/config/problem-codes.txt
dMedCodes=${ROOT}/../rwe/CONCEPT_DIMENSION.csv
dOutputFile="map.MDCTN-genRxCUIs-genNames-subRxCUIs-subNames"
dDebug=0

medTargets=$dMedTargets
problemCodes=$dProblemCodes
medCodes=$dMedCodes
outputFile=$dOutputFile
debug=$dDebug
while getopts ":hdt:c:p:o:" opt; do
    case ${opt} in
	h )
	    display_help
	    exit 0
	    ;;
	d )
	    debug=1;
	    ;;
	t )
	    medTargets=$OPTARG
	    ;;
	c )
	    medCodes=$OPTARG
	    ;;
	p )
	    problemCodes=$OPTARG
	    ;;
	o )
	    outputFile=$OPTARG
	    ;;
	: )
	    echo "ERROR: Invalid argument $OPTARG" 1>&2
	    display_usage
	    exit 1
	    ;;
	\? )
	    echo "ERROR: Invalid Option -$OPTARG" 1>&2
	    display_usage
	    exit 1
	    ;;
    esac
done
shift $((OPTIND -1))

if [ $# -ne 0 ]; then
    echo "ERROR: Invalid arguments (\"$1\"...), should only have switches" 1>&2
    display_usage
fi

medsTmpfile=$(mktemp /tmp/$(basename $0).RxCUI-MDCTN-name.$USER.$HOSTNAME.XXXXXX)
medsFilteredTmpFile=$(mktemp /tmp/$(basename $0).label-RxCUI-MDCTN-name.$USER.$HOSTNAME.XXXXXX)

if [ $debug -eq 1 ]; then 
    echo "---DEBUG MODE---"
    medsTmpfile="medsTmpfile"
    medsFilteredTmpFile="medsFilteredTmpFile"
    set -x
fi

display_version
echo "["`date +"%Y-%m-%d %H:%M:%S"`"]""BEGIN"

echo "["`date +"%Y-%m-%d %H:%M:%S"`"]""[step 1 of 3] Get the RxCUI, MDCTN codes and descriptions ('name')"
# grep MDCTN ${medCodes} |awk -f ${ROOT}/src/get-meds.awk|sed 's/"//g'|sed 's/RX://'  > $medsTmpfile
# This is the longest step
# xxx replace inline perl with a C program to filter, started it here: filterProblemCodes.c
grep MDCTN ${medCodes} |awk -f ${ROOT}/src/get-meds.awk|sed 's/"//g'|sed 's/RX://'| \
    perl -ane 'if(`if ! fgrep -xqw "$F[1]" '$problemCodes'; then echo -n 1; else echo -n 0; fi`){print "$_";}'\
 > $medsTmpfile

echo "["`date +"%Y-%m-%d %H:%M:%S"`"]""[step 2 of 3] Pull out the target drugs of interest"
for i in `awk -F'\t' '{print $1}' ${medTargets}` ; do  
  grep -iw $i $medsTmpfile | awk -F'\t' '{print "'$i'\t"$0}' ; 
done > $medsFilteredTmpFile

echo "["`date +"%Y-%m-%d %H:%M:%S"`"]""[step 3 of 3] Sort by MDCTN code so that like codes are together"
# Combine duplicate MDCTNs with rxCUI lists on one line; separate general CUIs from dosages:
#   sort by MDCTN to put duplicate MDCTNs together
#   then sort by target; use -f to properly sort MDCTN:250 and MDCTN:2504
cat $medsFilteredTmpFile | awk -F'\t' '{print $3"\t"$2"\t"$1"\t"$4}' | sort -uf \
 |  ${ROOT}/src/mapGenCUIDoseCombo.pl -t ${medTargets} | sort \
 |  awk -F'\t' '{print $2"\t"$3"\t"$5"\t"$4"\t"$6}' \
  > $outputFile

# map MDCTN to drug/dosage
# xxx move this into arguments
mapFile=map.mdctn-dose-units-drug
mapErrs=errs
awk -F'\t' '{print $1"\t"$3"\t"$4"\t"$5}' $outputFile |${ROOT}/src/parse.pl > $mapFile  2> $mapErrs;
# xxx inspect mapErrs

echo "["`date +"%Y-%m-%d %H:%M:%S"`"]""...created $outputFile, $mapFile, $mapErrs"
if [$debug -eq 1]; then 
    echo "  [debug] also created: "
    echo "  [debug]   $medsTmpfile"
    echo "  [debug]   $medsFilteredTmpFile"
fi


echo "["`date +"%Y-%m-%d %H:%M:%S"`"]""COMPLETE."
