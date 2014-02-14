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

2013-11-19 14:12:44.397+0100|loggernamesla|www.domain.com|instance61|WWW-correlation-id|http-ip-51503-10|v1|2598|524|2074|com.service.FinalizationService.pay|subsys:2074|N





