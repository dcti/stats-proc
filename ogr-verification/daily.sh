#!/bin/sh
# $Id: daily.sh,v 1.21 2004/05/25 15:03:01 nerf Exp $

RUNDATE=$1
PCPAGES=/home/statproc/stats-proc/misc/pcpages_ogr_verify

rm -f /tmp/id_import.out &&
psql ogr -a -v RUNDATE=\'$RUNDATE\' -f daily_update.sql 
RETURNSTATUS=$?
rm -f /tmp/id_import.out
(
    if [ -f $PCPAGES ]; then
        PROJECT_IDS=$(psql -q -t ogr -c \
            'select distinct project_id from ogr_complete')
        sudo $PCPAGES pcpages $PROJECT_IDS
    fi
)

echo $RUNDATE `date` >> ./log/runtime

return $RETURNSTATUS
