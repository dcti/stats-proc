#!/bin/sh
# $Id: daily.sh,v 1.14 2003/04/25 21:10:57 nerf Exp $

SYBUSER=$1
SYBPASSWD=$2
PGUSER=$3
PGPASSWD=$4
RUNDATE=$5

sh get_idlookup.sh $SYBUSER $SYBPASSWD &&
psql ogr -a -U $PGUSER -f create_id_lookup.sql &&
rm -f /tmp/id_import.out
psql ogr -a -U $PGUSER -f movedata.sql &&
psql ogr -a -U $PGUSER -f summarize.sql &&
psql ogr -a -U $PGUSER -v RUNDATE=\'$RUNDATE\' -f stats.sql
