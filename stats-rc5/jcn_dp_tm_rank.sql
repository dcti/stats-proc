/* TM_RANK */

print "!! Begin CACHE_tm_RANK Build"
go

use stats
set rowcount 0
go

while exists (select * from sysobjects where id = object_id('CACHE_tm_RANK_old'))
	drop table CACHE_tm_RANK_old
go

while exists (select * from sysobjects where id = object_id('CACHE_tm_RANK'))
	EXEC sp_rename 'CACHE_tm_RANK', 'CACHE_tm_RANK_old'
go

print "::  Creating CACHE_tm_RANK table"
go
create table CACHE_tm_RANK 
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
from RC5_64_master
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

print "::  Populating CACHE_tm_RANK live table"
go
insert into CACHE_tm_RANK 
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

create unique clustered index team on #curmema(team) with fillfactor = 100
go

update CACHE_tm_RANK
set CurrentMembers = T.members
from CACHE_tm_RANK C, #curmema T
where T.team = C.team
go

print "::  Setting # of total members"
go

select distinct team, count(*) as members
into #curmemb
from RC5_64_master
group by team
go

create unique clustered index team on #curmemb(team) with fillfactor = 100
go

update CACHE_tm_RANK
set TotalMembers = T.members
from CACHE_tm_RANK C, #curmemb T
where T.team = C.team
go

print "::  Setting # of Active members"
go

declare @mdv smalldatetime
select @mdv = max(date)
from RC5_64_master

select distinct team, count(*) as members
into #curmemc
from RC5_64_master
where datediff(dd,date,@mdv)<7
group by team
go

create unique clustered index team on #curmemc(team) with fillfactor = 100
go

update CACHE_tm_RANK
set ActiveMembers = T.members
from CACHE_tm_RANK C, #curmemc T
where T.team = C.team
go



print "::  Updating rank values to idx values (ranking step 1)"
go
update CACHE_tm_RANK
  set rank = idx,
      overall_rate = convert(numeric(14,4),Blocks*268435.456/DateDiff(ss,First,DateAdd(dd,1,Last)))
go

print "::  Indexing on blocks for ranking acceleration"
go
create index tempindex on CACHE_tm_RANK(blocks)
go

print "::  Correcting rank for tied teams"
go
update CACHE_tm_RANK
set rank = (select min(btb.rank) from CACHE_tm_RANK btb where btb.blocks = CACHE_tm_RANK.blocks)
where (select count(btb.blocks) from CACHE_tm_RANK btb where btb.blocks = CACHE_tm_RANK.blocks) > 1
go

drop index CACHE_tm_RANK.tempindex

print "::  Creating team indexes"
go
create unique index team on CACHE_tm_RANK(team) with fillfactor = 100
go

print "::  Calculating offset from previous ranking"
go
update CACHE_tm_RANK
set Change = (select CACHE_tm_RANK_old.rank from CACHE_tm_RANK_old
              where CACHE_tm_RANK_old.team = CACHE_tm_RANK.team)-CACHE_tm_RANK.rank
go

print ":: Creating rank index"
create clustered index rank on CACHE_tm_RANK(rank) with fillfactor = 100
go

grant select on CACHE_tm_RANK  to public
go

