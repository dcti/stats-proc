/* TM_YRANK */

print "!! Begin CACHE_tm_YRANK Build"
go

use stats
set rowcount 0
go

while exists (select * from sysobjects where id = object_id('CACHE_tm_YRANK_old'))
	drop table CACHE_tm_YRANK_old
go

while exists (select * from sysobjects where id = object_id('CACHE_tm_YRANK'))
	EXEC sp_rename 'CACHE_tm_YRANK', 'CACHE_tm_YRANK_old'
go

print "::  Creating CACHE_tm_YRANK table"
go
create table CACHE_tm_YRANK 
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
from RC5_64_master

select distinct
 team,
 min(date) as First,
 max(date) as Last,
 Sum(blocks) as Blocks
into #TYRANKa
from RC5_64_master
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

print "::  Populating CACHE_tm_YRANK live table"
go
insert into CACHE_tm_YRANK 
  (team,name,first,last,blocks,days_working,rank,change,listmode)
select distinct team, max(name),min(first),max(last),sum(blocks),1 as days_working,min(rank),min(change),max(listmode)
from #TYRANKb
where listmode < 10 or listmode = NULL
group by team
order by blocks desc
go

print "::  Setting # of Current members"
go

update CACHE_tm_YRANK
set CurrentMembers = T.CurrentMembers
from CACHE_tm_YRANK C, CACHE_tm_RANK T
where T.team = C.team
go

print "::  Setting # of total members"
go

update CACHE_tm_YRANK
set TotalMembers = T.TotalMembers
from CACHE_tm_YRANK C, CACHE_tm_RANK T
where T.team = C.team
go

print "::  Setting # of Active members"
go

update CACHE_tm_YRANK
set ActiveMembers = T.ActiveMembers
from CACHE_tm_YRANK C, CACHE_tm_RANK T
where T.team = C.team
go

print "::  Updating rank values to idx values (ranking step 1)"
go
update CACHE_tm_YRANK
  set rank = idx,
      overall_rate = convert(numeric(14,4),Blocks*268435.456/DateDiff(ss,First,DateAdd(dd,1,Last)))
go

print "::  Indexing on blocks for ranking acceleration"
go
create index tempindex on CACHE_tm_YRANK(blocks)
go

print "::  Correcting rank for tied teams"
go
update CACHE_tm_YRANK
set rank = (select min(btb.rank) from CACHE_tm_YRANK btb where btb.blocks = CACHE_tm_YRANK.blocks)
where (select count(btb.blocks) from CACHE_tm_YRANK btb where btb.blocks = CACHE_tm_YRANK.blocks) > 1
go

drop index CACHE_tm_YRANK.tempindex

print "::  Creating team indexes"
go
create unique index team on CACHE_tm_YRANK(team)
go

print "::  Calculating offset from previous ranking"
go
update CACHE_tm_YRANK
set Change = (select CACHE_tm_YRANK_old.rank from CACHE_tm_YRANK_old
              where CACHE_tm_YRANK_old.team = CACHE_tm_YRANK.team)-CACHE_tm_YRANK.rank
go

print ":: Creating clustered index"
go
create clustered index rank on CACHE_tm_YRANK(rank) with fillfactor = 100
go
print "::Updating statistics"
go
update statistics CACHE_tm_YRANK
go
grant select on CACHE_tm_YRANK  to public
go

