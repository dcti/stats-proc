#!/usr/bin/sqsh -i
#
# $Id: dp_newjoin.sql,v 1.1 2003/09/11 02:05:45 decibel Exp $
#
# Does team joins for past blocks
#
# Arguments:
#       Project

update ${1}_master set team = (select team from STATS_participant where STATS_participant.id = ${1}_master.id)
where (team = 0) and 
      (select team from STATS_participant where STATS_participant.id = ${1}_master.id) <> 0 
go

