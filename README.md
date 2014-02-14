graphite-inject
===============

inject application log data in graphite

1- clean old log files
2- copy new load of application log 
3- inject webservice Response Time
4- inject webservice volume 
5- inject webservices number of errors by 10 mins


lunching the inject script
=========================

usage(){

    echo "this script gets a 10 minutes worth of log and inject them in graphite"
    echo "Usage: sh inject.sh 16 1 #this will analyse and inject between 16:00 and 16:10"
    echo "Usage: sh inject.sh 16   #this will analyse and inject between 16:00 and 17:00"

}

log format
=====================

time stamp|loggername|www.domain.com|instance61|WWW-correlation-id|http-ip|API_version|response_time |internal time|subsys time|com.service.FinalizationService.pay|subsys:2074|error[Y/N]|error detail

2013-11-19 14:12:44.397+0100|loggername|www.domain.com|instance61|WWW-correlation-id|http-ip|v1|2598|524|2074|com.service.FinalizationService.pay|subsys:2074|N




