#!/bin/sh
# $Id: daily.sh,v 1.10 2003/01/19 07:51:57 nerf Exp $

# get_idlookup.sh exports the id, email, and retire_to info for each person
# create_id_lookup.sql creates a table containing an id and an email for
#   each participant.
# movedata.sql moves the valid data from logdata to the table called nodes
#   and creates indecies on nodes.
# query3.sql is the big query, fills donestubs with data.
# process_donestubs.sql verifys that each "done stub has been done by at
#   least one recent client

sh get_idlookup.sh
psql ogr -f create_id_lookup.sql
psql ogr -f movedata.sql
psql ogr -f query3.sql
psql ogr -f process_donestubs.sql
