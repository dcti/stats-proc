#!/bin/sh
# $Id: daily.sh,v 1.11 2003/02/16 19:22:14 nerf Exp $

USER = $1
PASSWD = $2

sh get_idlookup.sh $USER $PASSWD &&
psql ogr -a -U $USER -f create_id_lookup.sql &&
rm -f /tmp/id_lookup.out &&
psql ogr -a -U $USER -f movedata.sql &&
psql ogr -a -U $USER -f summarize.sql &&
