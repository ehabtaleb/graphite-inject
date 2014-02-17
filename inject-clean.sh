#!/bin/sh

# inject-clean.sh - A shell script to inject stat in graphite
# Author - Ehab TALEB
# Tested under centos 6/Linux using Bash shell version 
# -----------------------------------------------------------------------------

#2013-11-19 14:12:44.397+0100|loggername|www.domain.com|instance61|WWW-correlation-id|http-ip-51503-10|v1|2598|524|2074|com.service.FinalizationService.pay|subsys:2074|N

#exit with first non 0 result
#set -e

#Global Variables
# where i installed Graphite
PORT="2003"
SERVER="127.0.0.1"

EXACT_MIN="0"
LOCAL_SCRIPT_DIR=`cd $(dirname $0); pwd`
#where i copy log to be analyzed and charted
DATA_FILES=$LOCAL_SCRIPT_DIR/data

#user variable mostly variable used because the way we stock log
#these variables are only used to copy your slice of log in a local dir DATA_FILES 
#ssh User-pass to connect and copy the VM log
SSHPASSWORD=
SSHUSER=

#this is a namespace to tag your stats in graphite could be any thing
NAMESPACE=

ERR_FILEPATTERN=
FILEPATTERN=
#name of datacenters if you want to chart each datacenter on it's own
DCENTER1=
DCENTER2=
#your application name 
APP=
#root dir for log
DDIR=

usage(){
    echo "this script gets a 10 minutes worth of log and inject them in graphite"
    echo "Usage: sh $0 16 [0] this will analyse between 16:00 and 16:10 not included"
    echo "Usage: sh $0 16  this will analyse between 16:00 and 17:00 not included"
}

#######################################################################
#remove old log files 
#######################################################################
cleanUp(){
    echo "cleanning old files in $DATA_FILES"
    find $DATA_FILES -type f -print0 | xargs -0 rm -f
}

#######################################################################
# copy new load of log files to be analyzed
#######################################################################
getNewLoad(){
    for t in $MINUTES
    do 
	#echo "t="$t;
	echo "getting new files from remote  $DDIR/LIL/$APP/$HOUR-$t$EXACT_MIN/$FILEPATTERN"
	sshpass -p $SSHPASSWORD scp $SSHUSER:$DDIR/LIL/$APP/$HOUR-$t$EXACT_MIN/$FILEPATTERN ./data/"${DCENTER1}"/
	echo "getting new files from remote  $DDIR/PRA/$APP/$HOUR-$t$EXACT_MIN/$FILEPATTERN"
	sshpass -p $SSHPASSWORD scp $SSHUSER:$DDIR/PRA/$APP/$HOUR-$t$EXACT_MIN/$FILEPATTERN ./data/"${DCENTER2}"/
    done
}
###################################################################
# extract service response time and netcat to graphite
# normaly some thing like that
# com.service.IQuotationService.getOutwardProposalsByDay-lil 983 1392388973 
##################################################################

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

     find $DATA_FILES -name $ERR_FILEPATTERN$ff -exec grep "$APP_" {} \; | awk -F'|' '{ print "'$package'"$13$14,'"$timestamp"';}' | sort | uniq -c | sort -nr
     find $DATA_FILES -name $ERR_FILEPATTERN$ff -exec grep "$APP_" {} \; | awk -F'|' '{ print "'$package'"$13$14,'"$timestamp"';}' | sort | uniq -c | sort -nr | awk ' {print $2,$1,$3;}' | nc ${SERVER} ${PORT};
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