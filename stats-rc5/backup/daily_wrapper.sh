#!/bin/bash

cd /usr/home/statproc/stats-rc5/

countlogs() {
 numlogs=`ls ~incoming/newlogs-rc5 | wc -l | tr -s " " | cut -d" " -f2`
}

countlogs
if [ 24 -gt $numlogs ]; then
 echo "Only $numlogs log files; sleeping for 45 minutes"
 sleep 2700
fi

countlogs
if [ 24 -gt $numlogs ]; then
 echo "Only $numlogs log files!"|Mail -s "tally aborting rc5 run" dbaker-pager@cuckoo.com nugget-pager@slacker.com
 exit
fi

#echo "Automatically starting stats run!"|Mail -s "tally" dbaker-pager@cuckoo.com
logfile=/tmp/daily-out.RC5.`date +%d%b%Y`
/usr/home/statproc/stats-rc5/daily.pl | tee -a $logfile
chmod a+r $logfile
#echo "Finished stats run!"|Mail -s "tally" dbaker-pager@cuckoo.com
