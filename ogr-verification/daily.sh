#!/bin/sh
# $Id: daily.sh,v 1.9 2003/01/08 02:30:36 joel Exp $

# addlog.sql drops and creates the logdata table each day, and fills it with filtered(filter.pl) data.
# id_lookup.sql creates a table containing an id and an email for each participant.
# movedata.sql moves the valid data from logdata to the table called nodes and creates indecies on nodes.
# donestubs.sql creates the donestubs table, does not put any data in it.
# query3.sql is the big query, fills donestubs with data.

psql -d ogrstats -f addlog25.sql -vinfile=\'/home/postgres/ogr25.filtered\'
psql -d ogrstats -f addlog24.sql -vinfile=\'/home/postgres/ogr24.filtered\'
#sqsh create_id_lookup.sql
#psql -d ogrstats -f create_cheaters.sql 
#psql -d ogrstats -f create_cheaters.sql 
psql -d ogrstats -f movedata.sql 
psql -d ogrstats -f movedata.sql 
psql -d ogrstats -f query3.sql 
psql -d ogrstats -f query3.sql 
#psql -d ogrstats -f diff_counts.sql 
#psql -d ogrstats -f diff_counts.sql 
