#!/bin/sh

cd /usr/home/statproc/stats-rc5/

countlogs() {
 numlogs=`ls ~incoming/newlogs-rc5 | wc -l | tr -s " " | cut -d" " -f2`
}

countlogs
if [ 24 -gt $numlogs ]; then
 echo "Only $numlogs log files; sleeping for 5 minutes"
 sleep 300
fi

countlogs
if [ 24 -gt $numlogs ]; then
 echo "Only $numlogs log files; sleeping for 30 minutes"
 sleep 1800
fi

countlogs
if [ 24 -gt $numlogs ]; then
 echo "Only $numlogs log files; sleeping for 15 minutes"
 sleep 900
fi

countlogs
if [ 24 -gt $numlogs ]; then
 echo "Only $numlogs log files!"|Mail -s "blower aborting rc5 run" statsmon@distributed.net
 exit 1
fi

if [ -e /home/statproc/log/ogr.lck -o -e /home/statproc/log/rc5.lck ]; then
 echo "/home/statproc/log/ogr.lck exists; sleeping 5 minutes"
 sleep 300
fi

if [ -e /home/statproc/log/ogr.lck -o -e /home/statproc/log/rc5.lck ]; then
 echo "/home/statproc/log/ogr.lck exists; sleeping 5 minutes"
 sleep 300
fi

if [ -e /home/statproc/log/ogr.lck -o -e /home/statproc/log/rc5.lck ]; then
 echo "/home/statproc/log/ogr.lck exists; sleeping 10 minutes"
 sleep 600
fi

if [ -e /home/statproc/log/ogr.lck -o -e /home/statproc/log/rc5.lck ]; then
 echo "/home/statproc/log/ogr.lck exists; sleeping 10 minutes"
 sleep 600
fi

if [ -e /home/statproc/log/ogr.lck -o -e /home/statproc/log/rc5.lck ]; then
 echo "/home/statproc/log/ogr.lck exists; sleeping 30 minutes"
 sleep 1800
fi

if [ -e /home/statproc/log/ogr.lck -o -e /home/statproc/log/rc5.lck ]; then
 echo "/home/statproc/log/ogr.lck exists; sleeping 60 minutes"
 sleep 3600
fi

if [ -e /home/statproc/log/ogr.lck -o -e /home/statproc/log/rc5.lck ]; then
 echo "/home/statproc/log/ogr.lck exists!"|Mail -s "blower aborting rc5 run" statsmon@distributed.net
 exit 1
fi

#echo "Automatically starting stats run!"|Mail -s "blower" dbaker-pager@cuckoo.com
logfile=/tmp/daily-out.RC5.`date +%d%b%Y`
umask 022
/usr/home/statproc/stats-rc5/daily.pl 2>&1 | tee -a $logfile
chmod a+r $logfile
#echo "Finished stats run!"|Mail -s "blower" dbaker-pager@cuckoo.com
