#!/bin/sh
# $Id: daily.sh,v 1.12 2003/02/23 00:44:55 nerf Exp $

SQLUSER=$1
SQLPASSWD=$2

sh get_idlookup.sh $SQLUSER $SQLPASSWD &&
psql ogr -a -U $SQLUSER -f create_id_lookup.sql &&
rm -f /tmp/id_import.out
psql ogr -a -U $SQLUSER -f movedata.sql &&
psql ogr -a -U $SQLUSER -f summarize.sql &&
