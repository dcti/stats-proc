#!/usr/bin/sqsh -i
#
# $Id: dy_appendday.sql,v 1.3 2000/02/21 03:47:06 bwilson Exp $
#
# Appends the data from the daytables into the main tables
#
# Arguments:
#       Project

print "!! Appending day's activity to master tables"
go

print "::  Appending into _master"
go
declare @proj_id tinyint
select @proj_id = PROJECT_ID
	from Projects
	where PROJECT = \\'${1}\\'

insert into ${1}_master (date, PROJECT_ID, id, team, blocks)
select
  d.timestamp as date,
  @proj_id,
  p.id,
  p.team,
  sum(d.size) as blocks
from ${1}_daytable_master d, STATS_participant p
where p.email = d.email
group by timestamp, id, team
go

print ":: Appending into _platform"
go
declare @proj_id tinyint
select @proj_id = PROJECT_ID
	from Projects
	where PROJECT = \\'${1}\\'

insert into ${1}_platform (date, PROJECT_ID, cpu, os, ver, blocks)
select
  timestamp as date,
  @proj_id,
  cpu,
  os,
  ver,
  sum(size) as blocks
from ${1}_daytable_platform
group by timestamp, cpu, os, ver
go

