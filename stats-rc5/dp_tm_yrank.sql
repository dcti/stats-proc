/* TM_YRANK */

print "!! Begin PREBUILD_tm_YRANK Build"
go

use stats
set flushmessage on
set rowcount 0
go

print "::  Creating PREBUILD_tm_YRANK table"
go
while exists (select * from sysobjects where id = object_id('PREBUILD_tm_YRANK'))
	drop table PREBUILD_tm_YRANK
go
create table PREBUILD_tm_YRANK 
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
from RC5_64_Master

select
 M.team,
 @mdv as First,
 @mdv as Last,
 Sum(R.blocks) as Blocks
into #TYRANKa
from CACHE_tm_MEMBERS M, CACHE_em_YRANK R
where M.last=@mdv and M.id=R.id
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

print "::  Populating PREBUILD_tm_YRANK live table"
go
insert into PREBUILD_tm_YRANK 
  (team,name,first,last,blocks,days_working,rank,change,listmode)
select team, max(name),min(first),max(last),sum(blocks),1 as days_working,min(rank),min(change),max(listmode)
from #TYRANKb
where listmode < 10 or listmode = NULL
group by team
order by blocks desc, team desc
go

print "::  Setting # of Current, total and Active members"
go

update PREBUILD_tm_YRANK
set CurrentMembers = T.CurrentMembers,
 TotalMembers = T.TotalMembers,
 ActiveMembers = T.ActiveMembers
from PREBUILD_tm_YRANK C, CACHE_tm_RANK T
where T.team = C.team
go

print "::  Updating rank values to idx values (ranking step 1)"
go
update PREBUILD_tm_YRANK
  set rank = idx,
      overall_rate = convert(numeric(14,4),Blocks*268435.456/DateDiff(ss,First,DateAdd(dd,1,Last)))
go

print "::  Indexing on blocks for ranking acceleration"
go
create index tempindex on PREBUILD_tm_YRANK(blocks) with fillfactor = 100
go

print "::  Correcting rank for tied teams"
go
update PREBUILD_tm_YRANK
set rank = (select min(btb.rank) from PREBUILD_tm_YRANK btb where btb.blocks = PREBUILD_tm_YRANK.blocks)
where (select count(btb.blocks) from PREBUILD_tm_YRANK btb where btb.blocks = PREBUILD_tm_YRANK.blocks) > 1
go

drop index PREBUILD_tm_YRANK.tempindex

print "::  Creating team indexes"
go
create unique index team on PREBUILD_tm_YRANK(team) with fillfactor = 100
go

print "::  Calculating offset from previous ranking"
go
update PREBUILD_tm_YRANK
 set change = old.rank - PREBUILD_tm_YRANK.rank
 from CACHE_tm_YRANK old
 where PREBUILD_tm_YRANK.team = old.team
go

print ":: Creating clustered index"
go
create clustered index rank on PREBUILD_tm_YRANK(rank) with fillfactor = 100
go
grant select on PREBUILD_tm_YRANK  to public
go

while exists (select * from sysobjects where id = object_id('CACHE_tm_YRANK'))
	drop table CACHE_tm_YRANK
go
sp_rename PREBUILD_tm_YRANK, CACHE_tm_YRANK
go

while exists (select * from sysobjects where id = object_id('rc5_64_CACHE_tm_YRANK'))
	drop view rc5_64_CACHE_tm_YRANK
go
create view rc5_64_CACHE_tm_YRANK as select * from CACHE_tm_YRANK
go
grant select on rc5_64_CACHE_tm_YRANK to public
go

