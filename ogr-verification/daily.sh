#!/bin/sh
# $Id: daily.sh,v 1.18 2003/09/12 20:34:25 nerf Exp $

RUNDATE=$1

rm -f /tmp/id_import.out &&
psql ogr -a -v RUNDATE=\'$RUNDATE\' -f daily_update.sql &&
psql ogr -a -v RUNDATE=\'$RUNDATE\' -f stats.sql &&
rm -f /tmp/id_import.out &&
#(
#for project_id in $(psql -q -t ogr -c 'select distinct project_id
#from ogr_complete')
#do
#sudo pcpages_ogr_verify pcpages $project_id 
#done
#)
