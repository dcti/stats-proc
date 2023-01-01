#!/bin/sh 
#
# $Id: send_email.sh,v 1.1 2005/04/27 23:51:04 decibel Exp $

TMPFILE=$TEMP/send_email.wget
if [ "$1" = "-q" ]; then
    quiet=y
else
    quiet=n
fi

for ID in `psql -tqc "SELECT id FROM stats_participant WHERE password=''" stats | tr -d ' ' | egrep -v '^$'`
do
    [ $quiet = n ] && echo -n "Processing $ID "

    wget -q -O $TMPFILE https://stats.distributed.net/participant/ppass.php?id=$ID
    RESULT=`grep "<\!-- Error:" $TMPFILE`
    if [ "$RESULT" = "" ]; then
        [ $quiet = n ] && echo " OK"
    else
        echo "FAILED: $RESULT";
    fi
done

rm $TMPFILE
exit 0
