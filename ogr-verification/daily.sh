#!/bin/sh
# $Id: daily.sh,v 1.19 2003/09/28 16:52:29 nerf Exp $

RUNDATE=$1

rm -f /tmp/id_import.out &&
psql ogr -a -v RUNDATE=\'$RUNDATE\' -f daily_update.sql &&
rm -f /tmp/id_import.out &&
(
    if [ -f /usr/local/bin/pcpages_ogr_verify ]; then
        for project_id in $(psql -q -t ogr -c
            'select distinct project_id from ogr_complete')
        do
            sudo pcpages_ogr_verify pcpages $project_id 
        done
    fi
)
