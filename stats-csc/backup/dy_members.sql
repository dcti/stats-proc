#!/usr/bin/sqsh -i
#
# $Id: dy_members.sql,v 1.1 2003/09/11 02:05:45 decibel Exp $
#
# Create the team membership tables
#
# Arguments:
#       Project

print "!! Begin ${1}_CACHE_tm_MEMBERS Build"
go

use stats
set rowcount 0
go

print "::  Creating PREBUILD_${1}_tm_MEMBERS table"
go

create table PREBUILD_${1}_tm_MEMBERS
(	id numeric (10,0),
	team int,
	first smalldatetime,
	last smalldatetime,
	blocks numeric (10,0)
)
go

print "::  Filling cache table with data (id,team,first,last,blocks)"
go
select distinct
  id,
  team,
  min(date) as first,
  max(date) as last,
  sum(blocks) as blocks
into #RANKa
from ${1}_master
where team <> 0 and team <> NULL
group by id,team
go

print ":: Linking to participant data in cache_table b (retire_to)"
go

select C.id, C.team, C.first, C.last, C.blocks, S.retire_to
into #RANKb
from #RANKa C, STATS_participant S
where C.id = S.id
go

print "::  Honoring all retire_to requests"
go
update #RANKb
  set id = retire_to
where retire_to <> id and retire_to <> NULL and retire_to <> 0
go

print ":: Populating PREBUILD_${1}_tm_MEMBERS table"
go
insert into PREBUILD_${1}_tm_MEMBERS
  (id,team,first,last,blocks)
select distinct id, team, min(first), max(last), sum(blocks)
from #RANKb
group by id, team
go

create index main on PREBUILD_${1}_tm_MEMBERS(team,blocks)
go

grant select on PREBUILD_${1}_tm_MEMBERS to public
go

drop table ${1}_CACHE_tm_MEMBERS_old
go

sp_rename ${1}_CACHE_tm_MEMBERS, ${1}_CACHE_tm_MEMBERS_old
go

sp_rename PREBUILD_${1}_tm_MEMBERS, ${1}_CACHE_tm_MEMBERS
go

