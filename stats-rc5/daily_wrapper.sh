#!/bin/bash
#
# $Id: daily_wrapper.sh,v 1.1 1999/07/27 20:49:03 nugget Exp $
#


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
 echo "Only $numlogs log files!"|Mail -s "tally" dbaker-pager@cuckoo.com
 exit
fi

echo "Automatically starting stats run!"|Mail -s "tally" dbaker-pager@cuckoo.com
/usr/home/statproc/stats-rc5/daily.pl > /tmp/daily-out.`date +%d%b%Y`
echo "Finished stats run!"|Mail -s "tally" dbaker-pager@cuckoo.com
