#graphite-inject

inject application log data in graphite


1- remove old log files                                                                                               

cleanUp(){

    echo "cleanning old files in $DATA_FILES"
    find $DATA_FILES -type f -print0 | xargs -0 rm -f
}


2- copy new load of application log 

3- Extract service response time and netcat to graphite                                                                                                                              
 normaly some thing like that                                                                                                           com.service.IQuotationService.getOutwardProposalsByDay-lil 983 1392388973                                                                                                         

injectResponseTime(){

    local -r dataCenter="-"$1
    local -r service=$2

    echo "inject ResponseTime $dataCenter data from "`pwd`

    find $DATA_FILES"/$1" -name $FILEPATTERN -exec grep $service {} \; | awk -F'|' -v class=$dataCenter 'BEGIN{cmd="date +%s -d "}{cmdOnRow=cmd " \""$1"\""; cmdOnRow | getline D; close(cmdOnRow); print $11class,$8,D;}' | nc ${SERVER} ${PORT};

}


4- inject webservice volume 

5- inject webservices number of errors by 10 mins


lunching the inject script
=========================

usage(){

    echo "this script gets a 10 minutes worth of log and inject them in graphite"
    echo "Usage: sh $0 16 [0] this will analyse between 16:00 and 16:10 not included"
    echo "Usage: sh $0 16  this will analyse between 16:00 and 17:00 not included"
}


log format
=====================

time stamp|loggername|www.domain.com|instance61|WWW-correlation-id|http-ip|API_version|response_time |internal time|subsys time|com.service.FinalizationService.pay|subsys:2074|error[Y/N]|error detail

2013-11-19 14:12:44.397+0100|loggername|www.domain.com|instance61|WWW-correlation-id|http-ip|v1|2598|524|2074|com.service.FinalizationService.pay|subsys:2074|N




