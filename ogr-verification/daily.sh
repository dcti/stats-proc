#!/bin/sh
# $Id: daily.sh,v 1.5 2002/12/22 21:29:30 joel Exp $

# addlog.sql drops and creates the logdata table each day, and fills it with filtered(filter.pl) data.
# id_lookup.sql creates a table containing an id and an email for each participant.
# movedata.sql moves the valid data from logdata to the table called nodes and creates indecies on nodes.
# donestubs.sql creates the donestubs table, does not put any data in it.
# query3.sql is the big query, fills donestubs with data.

psql -d ogrstats -f addlog24.sql
psql -d ogrstats -f id_lookup.sql
psql -d ogrstats -f movedata.sql
#psql -d ogrstats -f donestubs.sql
psql -d ogrstats -f query3.sql

#psql -d ogrstats25 -f addlog25.sql
#psql -d ogrstats25 -f id_lookup.sql
#psql -d ogrstats25 -f movedata.sql
#psql -d ogrstats25 -f donestubs.sql
#psql -d ogrstats25 -f query3.sql
