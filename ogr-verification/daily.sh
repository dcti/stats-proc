#!/bin/sh
# $Id: daily.sh,v 1.8 2003/01/01 17:01:05 joel Exp $

# addlog.sql drops and creates the logdata table each day, and fills it with filtered(filter.pl) data.
# id_lookup.sql creates a table containing an id and an email for each participant.
# movedata.sql moves the valid data from logdata to the table called nodes and creates indecies on nodes.
# donestubs.sql creates the donestubs table, does not put any data in it.
# query3.sql is the big query, fills donestubs with data.

psql -d ogrstats -f addlog.sql -vprojnum=25 -vinfile=\'/home/postgres/ogr25.filtered\'
psql -d ogrstats -f addlog.sql -vprojnum=24 -vinfile=\'/home/postgres/ogr24.filtered\'
#sqsh create_id_lookup.sql
#psql -d ogrstats -f create_cheaters.sql -vprojnum:24
#psql -d ogrstats -f create_cheaters.sql -vprojnum:25
psql -d ogrstats -f movedata.sql -vprojnum=25
psql -d ogrstats -f movedata.sql -vprojnum=24
psql -d ogrstats -f query3.sql -vprojnum=25
psql -d ogrstats -f query3.sql -vprojnum=24
#psql -d ogrstats -f diff_counts.sql -vprojnum=25
#psql -d ogrstats -f diff_counts.sql -vprojnum=24
