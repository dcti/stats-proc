#!/bin/sh
# $Id: daily.sh,v 1.17 2003/09/07 05:27:37 nerf Exp $

RUNDATE=$1

rm -f /tmp/id_import.out &&
psql ogr -a -v RUNDATE=\'$RUNDATE\' -f id_lookup.sql &&
psql ogr -a -f movedata.sql &&
psql ogr -a -f summarize.sql &&
psql ogr -a -v RUNDATE=\'$RUNDATE\' -f stats.sql &&
rm -f /tmp/id_import.out &&
(
for project_id in $(psql -q -t ogr -c 'select distinct project_id
from ogr_complete')
do
sudo pcpages_ogr_verify pcpages $project_id 
done
)
