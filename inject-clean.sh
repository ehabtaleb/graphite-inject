#!/bin/sh

# inject-clean.sh - A shell script to inject stat in graphite
# Author - Ehab TALEB
# Tested under centos 6/Linux using Bash shell version 
# -----------------------------------------------------------------------------

#2013-11-19 14:12:44.397+0100|loggernamesla|www.domain.com|instance61|WWW-correlation-id|http-ip-51503-10|v1|2598|524|2074|com.service.FinalizationService.pay|subsys:2074|N

#exit with first non 0 result
#set -e

#Global Variables
PORT="2003"
SERVER="127.0.0.1"
EXACT_MIN="0"
LOCAL_SCRIPT_DIR=`cd $(dirname $0); pwd`
DATA_FILES=$LOCAL_SCRIPT_DIR/data

#env variable
SSHPASSWORD=
SSHUSER=
NAMESPACE=
ERR_FILEPATTERN=
FILEPATTERN=
DCENTER1=
DCENTER2=
APP=
DDIR=

usage(){
    echo "this script gets a 10 minutes worth of log and inject them in graphite"
    echo "Usage: sh $0 16 [1] this will analyse between 16:00 and 16:10"
    echo "Usage: sh $0 16  this will analyse between 16:00 and 17:00"
}

#######################################################################
#remove old files 
#######################################################################
cleanUp(){
    echo "cleanning old files in $DATA_FILES"
    find $DATA_FILES -type f -print0 | xargs -0 rm -f
}

#######################################################################
#
#######################################################################
getNewLoad(){
    for t in $MINUTES
    do 
	#echo "t="$t;
	echo "getting new files from remote  $DDIR/LIL/SBE/$HOUR-$t$EXACT_MIN/$FILEPATTERN"
	sshpass -p $SSHPASSWORD scp $SSHUSER:$DDIR/LIL/SBE/$HOUR-$t$EXACT_MIN/$FILEPATTERN ./data/"${DCENTER1}"/
	echo "getting new files from remote  $DDIR/PRA/SBE/$HOUR-$t$EXACT_MIN/$FILEPATTERN"
	sshpass -p $SSHPASSWORD scp $SSHUSER:$DDIR/PRA/SBE/$HOUR-$t$EXACT_MIN/$FILEPATTERN ./data/"${DCENTER2}"/
    done
}

injectResponseTime(){
    local -r dataCenter="-"$1
    local -r service=$2

    echo "inject ResponseTime $dataCenter data from "`pwd`
 
    find $DATA_FILES"/$1" -name $FILEPATTERN -exec grep $service {} \; | awk -F'|' -v class=$dataCenter 'BEGIN{cmd="date +%s -d "}{cmdOnRow=cmd " \""$1"\""; cmdOnRow | getline D; close(cmdOnRow); print $11class,$8,D;}' | nc ${SERVER} ${PORT};
}


#######################################################################
# Processes a volume for a service.
# $1 - is the name of the service ex confirm
########################################################################
injectVolume(){
    local -r service=$1
    local -r class=$NAMESPACE".volume."$service

    echo "injecting $class data from "`pwd`
#    find $DATA_FILES -name $FILEPATTERN -exec grep $service {} \; | awk -F'|' -v pat=$class 'BEGIN{cmd="date +%s -d "}{cmdOnRow=cmd " \""$1"\""; cmdOnRow | getline D; close(cmdOnRow); print pat,D;}' | sort | uniq -c  | awk '{print $2,$1,$3}'

find $DATA_FILES -name $FILEPATTERN -exec grep $service {} \; | awk -F'|' -v pat=$class 'BEGIN{cmd="date +%s -d "}{cmdOnRow=cmd " \""$1"\""; cmdOnRow | getline D; close(cmdOnRow); print pat,D;}' | uniq -c | awk '{print $2,$1,$3}' | nc ${SERVER} ${PORT};
}

servicesResponseTime(){
#inject new data
    declare -r -a service_array=( IQuotationService confirm  makeReservation loadTravel modifyPassengerData getExchangeOutwardProposalByDay)
    for service in "${service_array[@]}"
    do
	#echo "inject ResponseTime $service"
	injectResponseTime "${DCENTER1}" "$service"
	injectResponseTime "${DCENTER2}" "$service"
    done
}

servicesVolume(){
    declare -r -a service_array=( IQuotationService confirm  makeReservation loadTravel modifyPassengerData )
    for service in "${service_array[@]}"
    do
	#echo "inject volume $service"
	injectVolume "$service"
    done
}



servicesError(){

local -r package=$NAMESPACE".error."

 for ti in $MINUTES
    do 
     tt=`date +'%Y-%m-%d'`" $1:$ti$EXACT_MIN"
     echo $tt
     timestamp=`date +%s -d "$tt"`
     echo `date +%s -d "$tt"`
     
     ff=`date +'%Y%m%d'`"-$1$ti*"

     find $DATA_FILES -name $ERR_FILEPATTERN$ff -exec grep "SBE_" {} \; | awk -F'|' '{ print "'$package'"$13$14,'"$timestamp"';}' | sort | uniq -c | sort -nr
     find $DATA_FILES -name $ERR_FILEPATTERN$ff -exec grep "SBE_" {} \; | awk -F'|' '{ print "'$package'"$13$14,'"$timestamp"';}' | sort | uniq -c | sort -nr | awk ' {print $2,$1,$3;}' | nc ${SERVER} ${PORT};
 done
}



# ===================================================================
# MAIN BLOCK
# ===================================================================

if [[ -z "$1" ]]; then
    usage;
    exit 1;
fi

HOUR=$1
MINUTES=$2;

if [[ -z "$2" ]]; then
    MINUTES="0 1 2 3 4 5";
fi

shift 2;
#echo "$MINUTES";

cleanUp;
getNewLoad "$HOUR" $MINUTES
servicesResponseTime
servicesVolume
servicesError "$HOUR" $MINUTES