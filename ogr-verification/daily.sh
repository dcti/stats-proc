#!/bin/sh
# $Id: daily.sh,v 1.16 2003/07/20 23:28:46 nerf Exp $

SYBUSER=$1
SYBPASSWD=$2
PGUSER=$3
PGPASSWD=$4
RUNDATE=$5

sh get_idlookup.sh $SYBUSER $SYBPASSWD &&
psql ogr -a -U $PGUSER -f create_id_lookup.sql &&
rm -f /tmp/id_import.out &&
psql ogr -a -U $PGUSER -f movedata.sql &&
psql ogr -a -U $PGUSER -f summarize.sql &&
psql ogr -a -U $PGUSER -v RUNDATE=\'$RUNDATE\' -f stats.sql &&
(
for project_id in $(psql -q -t ogr -c 'select distinct project_id
from ogr_complete')
do
sudo pcpages_ogr_verify pcpages $project_id 
done
)
