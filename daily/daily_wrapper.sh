#!/bin/bash
exit 1
cd /usr/home/statproc/stats-csc/

countlogs() {
 numlogs=`ls ~incoming/newlogs-csc | wc -l | tr -s " " | cut -d" " -f2`
}

countlogs
if [ 24 -gt $numlogs ]; then
 echo "Only $numlogs log files; sleeping for 45 minutes"
 sleep 2700
fi

countlogs
if [ 24 -gt $numlogs ]; then
 echo "Only $numlogs log files!"|Mail -s "tally aborting csc run" dbaker-pager@cuckoo.com nugget-pager@slacker.com
 exit
fi

#echo "Automatically starting stats run!"|Mail -s "tally" dbaker-pager@cuckoo.com
logfile=/tmp/daily-out.CSC.`date +%d%b%Y`
/usr/home/statproc/stats-csc/daily.pl | tee -a $logfile
chmod a+r $logfile
#echo "Finished stats run!"|Mail -s "tally" dbaker-pager@cuckoo.com
