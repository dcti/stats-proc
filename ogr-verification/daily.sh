#!/bin/sh
# $Id: daily.sh,v 1.15 2003/06/09 14:16:30 nerf Exp $

SYBUSER=$1
SYBPASSWD=$2
PGUSER=$3
PGPASSWD=$4
RUNDATE=$5

rm -f /tmp/id_import.out

psql stats -a -c "\\copy STATS_participant to '/tmp/id_import.out'" &&
psql ogr -a -f create_id_lookup.sql &&
psql ogr -a -f movedata.sql &&
psql ogr -a -f summarize.sql &&
psql ogr -a -v RUNDATE=\'$RUNDATE\' -f stats.sql

rm -f /tmp/id_import.out
