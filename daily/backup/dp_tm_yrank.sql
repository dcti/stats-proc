#!/usr/bin/sqsh -i
#
# $Id: dp_tm_yrank.sql,v 1.1 2000/02/09 16:13:58 nugget Exp $
#
# Ranks the teams (yesterday)
#
# Arguments:
#       Project

/* TM_YRANK */

print "!! Begin ${1}_CACHE_tm_YRANK Build"
go

use stats
set rowcount 0
go

while exists (select * from sysobjects where id = object_id(\\'${1}_CACHE_tm_YRANK_old\\'))
	drop table ${1}_CACHE_tm_YRANK_old
go

while exists (select * from sysobjects where id = object_id(\\'${1}_CACHE_tm_YRANK\\'))
	EXEC sp_rename \\'${1}_CACHE_tm_YRANK\\', \\'${1}_CACHE_tm_YRANK_old\\'
go

print "::  Creating ${1}_CACHE_tm_YRANK table"
go
create table ${1}_CACHE_tm_YRANK 
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

declare @mdv smalldatetime
select @mdv = max(date)
from ${1}_master

select distinct
 team,
 min(date) as First,
 max(date) as Last,
 Sum(blocks) as Blocks
into #TYRANKa
from ${1}_master
where datediff(dd,date,@mdv)=0
group by team
go

print "::  Linking to team data into cache table b (name,days_working,listmode)"
go

select C.team, S.name, C.first, C.last, C.blocks,
  0 as rank, 0 as change,
  S.listmode 
into #TYRANKb
from #TYRANKa C, STATS_team S
where C.team = S.team
go 

print "::  Populating ${1}_CACHE_tm_YRANK live table"
go
insert into ${1}_CACHE_tm_YRANK 
  (team,name,first,last,blocks,days_working,rank,change,listmode)
select distinct team, max(name),min(first),max(last),sum(blocks),1 as days_working,min(rank),min(change),max(listmode)
from #TYRANKb
where listmode < 10 or listmode = NULL
group by team
order by blocks desc
go

print "::  Setting # of Current members"
go

update ${1}_CACHE_tm_YRANK
set CurrentMembers = T.CurrentMembers
from ${1}_CACHE_tm_YRANK C, ${1}_CACHE_tm_RANK T
where T.team = C.team
go

print "::  Setting # of total members"
go

update ${1}_CACHE_tm_YRANK
set TotalMembers = T.TotalMembers
from ${1}_CACHE_tm_YRANK C, ${1}_CACHE_tm_RANK T
where T.team = C.team
go

print "::  Setting # of Active members"
go

update ${1}_CACHE_tm_YRANK
set ActiveMembers = T.ActiveMembers
from ${1}_CACHE_tm_YRANK C, ${1}_CACHE_tm_RANK T
where T.team = C.team
go

print "::  Updating rank values to idx values (ranking step 1)"
go
update ${1}_CACHE_tm_YRANK
  set rank = idx,
      overall_rate = convert(numeric(14,4),Blocks*268435.456/DateDiff(ss,First,DateAdd(dd,1,Last)))
go

print "::  Indexing on blocks for ranking acceleration"
go
create index tempindex on ${1}_CACHE_tm_YRANK(blocks)
go

print "::  Correcting rank for tied teams"
go
update ${1}_CACHE_tm_YRANK
set rank = (select min(btb.rank) from ${1}_CACHE_tm_YRANK btb where btb.blocks = ${1}_CACHE_tm_YRANK.blocks)
where (select count(btb.blocks) from ${1}_CACHE_tm_YRANK btb where btb.blocks = ${1}_CACHE_tm_YRANK.blocks) > 1
go

drop index ${1}_CACHE_tm_YRANK.tempindex

print "::  Creating team indexes"
go
create index team on ${1}_CACHE_tm_YRANK(team)
go

print "::  Calculating offset from previous ranking"
go
update ${1}_CACHE_tm_YRANK
set Change = (select ${1}_CACHE_tm_YRANK_old.rank from ${1}_CACHE_tm_YRANK_old
              where ${1}_CACHE_tm_YRANK_old.team = ${1}_CACHE_tm_YRANK.team)-${1}_CACHE_tm_YRANK.rank
go

grant select on ${1}_CACHE_tm_YRANK  to public
go

