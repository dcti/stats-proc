#!/usr/bin/perl
# $Id: daily.pl,v 1.2 2002/12/20 23:55:45 nerf Exp $

# addlog.sql drops and creates the logdata table each day, and fills it with filtered(filter.pl) data.
# id_lookup1.sql creates a table containing an id and an email for each participant.
# movedata.sql moves the valid data from logdata to the table called nodes and creates indecies on nodes.
# donenodes.sql creates the donenodes table, does not put any data in it.
# query2.sql is the big query, fills donenodes with data.

@scripts = qw( addlog.sql, id_lookup1.sql, movedata.sql, donenodes.sql, query2.sql );

foreach(@scripts) {
system(psql -d ogrstats -f $_);
}
