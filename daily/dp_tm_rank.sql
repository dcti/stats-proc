#!/usr/bin/sqsh -i
#
# $Id: dp_tm_rank.sql,v 1.1 2000/02/09 16:13:57 nugget Exp $
#
# Ranks the teams (overall)
#
# Arguments:
#       Project

/* TM_RANK */

print "!! Begin ${1}_CACHE_tm_RANK Build"
go

use stats
set rowcount 0
go

while exists (select * from sysobjects where id = object_id(\\'${1}_CACHE_tm_RANK_old\\'))
	drop table ${1}_CACHE_tm_RANK_old
go

while exists (select * from sysobjects where id = object_id(\\'${1}_CACHE_tm_RANK\\'))
	EXEC sp_rename \\'${1}_CACHE_tm_RANK\\', \\'${1}_CACHE_tm_RANK_old\\'
go

print "::  Creating ${1}_CACHE_tm_RANK table"
go
create table ${1}_CACHE_tm_RANK 
(       Idx numeric (10,0) IDENTITY NOT NULL,
        Team numeric (10,0) NULL ,
	Name varchar (64) NULL ,
	First smalldatetime NULL ,
	Last smalldatetime NULL ,
	Blocks numeric (10,0) NULL ,
	Days_Working int NULL ,
	Overall_Rate numeric (14,4) NULL ,
	Rank int NULL,
	Change int NULL,
        ListMode int NULL,
	CurrentMembers int NULL,
        ActiveMembers int NULL,
	TotalMembers int NULL
)
go

print "::  Filling cache table a with data (team,first,last,blocks)"
go
select distinct
 team,
 min(date) as First,
 max(date) as Last,
 Sum(blocks) as Blocks
into #TRANKa
from ${1}_master
group by team
go

print "::  Linking to team data into cache table b (name,days_working,listmode)"
go
declare @gdv smalldatetime
declare @gdva smalldatetime
select @gdv = getdate()
select @gdva = DateAdd(hh,8,@gdv)

select C.team, S.name, C.first, C.last, C.blocks,
  datediff(dd,C.first,@gdv)+1 as Days_working,
  0 as rank, 0 as change,
  S.listmode 
into #TRANKb
from #TRANKa C, STATS_team S
where C.team = S.team
go 

print "::  Populating ${1}_CACHE_tm_RANK live table"
go
insert into ${1}_CACHE_tm_RANK 
  (team,name,first,last,blocks,days_working,rank,change,listmode)
select distinct team, max(name),min(first),max(last),sum(blocks),max(days_working),min(rank),min(change),max(listmode)
from #TRANKb
where listmode < 10 or listmode = NULL
group by team
order by blocks desc
go

print "::  Setting # of Current members"
go

select distinct team, count(*) as members 
into #curmema
from STATS_participant
where retire_to = 0 or retire_to = NULL
group by team
go

create index team on #curmema(team)
go

update ${1}_CACHE_tm_RANK
set CurrentMembers = T.members
from ${1}_CACHE_tm_RANK C, #curmema T
where T.team = C.team
go

print "::  Setting # of total members"
go

select distinct team, count(*) as members
into #curmemb
from ${1}_master
group by team
go

create index team on #curmemb(team)
go

update ${1}_CACHE_tm_RANK
set TotalMembers = T.members
from ${1}_CACHE_tm_RANK C, #curmemb T
where T.team = C.team
go

print "::  Setting # of Active members"
go

declare @mdv smalldatetime
select @mdv = max(date)
from ${1}_master

select distinct team, count(*) as members
into #curmemc
from ${1}_master
where datediff(dd,date,@mdv)<7
group by team
go

create index team on #curmemc(team)
go

update ${1}_CACHE_tm_RANK
set ActiveMembers = T.members
from ${1}_CACHE_tm_RANK C, #curmemc T
where T.team = C.team
go



print "::  Updating rank values to idx values (ranking step 1)"
go
update ${1}_CACHE_tm_RANK
  set rank = idx,
      overall_rate = convert(numeric(14,4),Blocks*268435.456/DateDiff(ss,First,DateAdd(dd,1,Last)))
go

print "::  Indexing on blocks for ranking acceleration"
go
create index tempindex on ${1}_CACHE_tm_RANK(blocks)
go

print "::  Correcting rank for tied teams"
go
update ${1}_CACHE_tm_RANK
set rank = (select min(btb.rank) from ${1}_CACHE_tm_RANK btb where btb.blocks = ${1}_CACHE_tm_RANK.blocks)
where (select count(btb.blocks) from ${1}_CACHE_tm_RANK btb where btb.blocks = ${1}_CACHE_tm_RANK.blocks) > 1
go

drop index ${1}_CACHE_tm_RANK.tempindex

print "::  Creating team indexes"
go
create index team on ${1}_CACHE_tm_RANK(team)
go

print "::  Calculating offset from previous ranking"
go
update ${1}_CACHE_tm_RANK
set Change = (select ${1}_CACHE_tm_RANK_old.rank from ${1}_CACHE_tm_RANK_old
              where ${1}_CACHE_tm_RANK_old.team = ${1}_CACHE_tm_RANK.team)-${1}_CACHE_tm_RANK.rank
go

grant select on ${1}_CACHE_tm_RANK  to public
go

