print "!! Begin CACHE_em_YRANK Build"
go

use stats
set rowcount 0
go

revoke select on CACHE_em_YRANK to public
go

while exists (select * from sysobjects where id = object_id('CACHE_em_YRANK_old'))
	drop table CACHE_em_YRANK_old
go

while exists (select * from sysobjects where id = object_id('CACHE_em_YRANK'))
	EXEC sp_rename 'CACHE_em_YRANK', 'CACHE_em_YRANK_old'
go

print "::  Creating CACHE_em_YRANK table"
go
create table CACHE_em_YRANK 
(       idx numeric (10,0) IDENTITY NOT NULL,
        id numeric (10,0) NULL ,
	email varchar (64) NULL ,
	first smalldatetime NULL ,
	last smalldatetime NULL ,
	blocks numeric (10,0) NULL ,
	days_working int NULL ,
	overall_rate numeric (14,4) NULL ,
	rank int NULL,
	change int NULL,
        listmode int NULL
)
go

print "::  Filling cache table a with data (id,first,last,blocks)"
go

declare @mdv smalldatetime
select @mdv = max(date)
from RC5_64_master

select distinct
 id,
 min(date) as first,
 max(date) as last,
 Sum(blocks) as blocks
into #YRANKa
from RC5_64_master
where datediff(dd,date,@mdv)=0
group by id
go

print "::  Linking to participant data into cache table b (listmode,retire_to)"
go

select C.id, S.email, C.first, C.last, C.blocks,
  S.listmode, S.retire_to 
into #YRANKb
from #YRANKa C, STATS_participant S
where C.id = S.id
go 

print "::  Honoring all retire_to requests"
go
update #YRANKb
  set id = retire_to,
      email = "",
      listmode = 0
where retire_to <> id and retire_to <> NULL and retire_to <> 0
go

print "::  Populating CACHE_em_YRANK table"
go
insert into CACHE_em_YRANK 
  (id,email,first,last,blocks,days_working,rank,change,listmode)
select distinct id, max(email),min(first),max(last),sum(blocks),1 as days_working,0 as rank, 0 as change,max(listmode)
from #YRANKb
where listmode < 10 or listmode = NULL
group by id
order by sum(blocks) desc
go

print "::  Updating rank values to idx values (ranking step 1)"
go
update CACHE_em_YRANK
  set rank = idx,
      overall_rate = convert(numeric(14,4),blocks*268435.456/DateDiff(ss,first,DateAdd(dd,1,last)))
go

print "::  Indexing on blocks for ranking acceleration"
go
create index tempindex on CACHE_em_YRANK(blocks)
go

print "::  Correcting rank for tied participants"
go
update CACHE_em_YRANK
set rank = (select min(btb.rank) from CACHE_em_YRANK btb where btb.blocks = CACHE_em_YRANK.blocks)
where (select count(btb.blocks) from CACHE_em_YRANK btb where btb.blocks = CACHE_em_YRANK.blocks) > 1
go

drop index CACHE_em_YRANK.tempindex
go

print "::  Creating id indexes"
go
create unique index id on CACHE_em_YRANK(id)
go

print "::  Calculating offset from previous ranking"
go
update CACHE_em_YRANK
set change = (select CACHE_em_YRANK_old.rank from CACHE_em_YRANK_old
              where CACHE_em_YRANK_old.id = CACHE_em_YRANK.id)-CACHE_em_YRANK.rank
go

print ":: Indexing on rank and email"
go

create clustered index rank on CACHE_em_YRANK(email)
create index email on CACHE_em_YRANK(email)
go
print ":: updating statistics"
go
update statistics on CACHE_em_YRANK
go

grant select on CACHE_em_YRANK to public
go

