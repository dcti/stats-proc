print "!! Begin CACHE_em_RANK Build"
go

use stats
set rowcount 0
go

revoke select on CACHE_em_RANK to public
go

while exists (select * from sysobjects where id = object_id('CACHE_em_RANK_old'))
	drop table CACHE_em_RANK_old
go

while exists (select * from sysobjects where id = object_id('CACHE_em_RANK'))
	EXEC sp_rename 'CACHE_em_RANK', 'CACHE_em_RANK_old'
go

print "::  Creating CACHE_em_RANK table"
go
create table CACHE_em_RANK 
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
select distinct
 id,
 "                                                                " as email,
 min(date) as first,
 max(date) as last,
 Sum(blocks) as blocks,
 0 as listmode,
 0 as retire_to
into #RANKa
from RC5_64_master
group by id
go

print "::  Linking to participant data into cache table b (email,listmode,retire_to)"
go
update #RANKa
set email = S.email, listmode = S.listmode, retire_to = S.retire_to
from #RANKa, STATS_participant S
where S.id = #RANKa.id 
go

print "::  Honoring all retire_to requests"
go
update #RANKa
  set id = retire_to,
      email = "",
      listmode = 0
where retire_to <> id and retire_to <> NULL and retire_to <> 0
go

print "::  Populating CACHE_em_RANK table"
go
insert into CACHE_em_RANK 
  (id,email,first,last,blocks,days_working,rank,change,listmode)
select distinct id, max(email),min(first),max(last),sum(blocks),datediff(dd,min(first),max(last))+1 as days_working,0 as rank, 0 as change,max(listmode)
from #RANKa
where listmode < 10 or listmode = NULL
group by id
order by sum(blocks) desc
go

print "::  Updating rank values to idx values (ranking step 1)"
go
update CACHE_em_RANK
  set rank = idx,
      overall_rate = convert(numeric(14,4),blocks*268435.456/DateDiff(ss,first,DateAdd(dd,1,last)))
go

print "::  Indexing on blocks for ranking acceleration"
go
create index tempindex on CACHE_em_RANK(blocks)
go

print "::  Correcting rank for tied participants"
go
update CACHE_em_RANK
set rank = (select min(btb.rank) from CACHE_em_RANK btb where btb.blocks = CACHE_em_RANK.blocks)
where (select count(btb.blocks) from CACHE_em_RANK btb where btb.blocks = CACHE_em_RANK.blocks) > 1
go

drop index CACHE_em_RANK.tempindex
go

drop index CACHE_em_RANK_old.tempindex
go

print "::  Creating id indexes"
go
create index tempindex on CACHE_em_RANK_old(id)
go
create index tempindex on CACHE_em_RANK(id)
go

print "::  Calculating offset from previous ranking"
go
update CACHE_em_RANK
set change = (select CACHE_em_RANK_old.rank from CACHE_em_RANK_old
              where CACHE_em_RANK_old.id = CACHE_em_RANK.id)-CACHE_em_RANK.rank
go

drop index CACHE_em_RANK.tempindex
go

drop index CACHE_em_RANK_old.tempindex
go

grant select on CACHE_em_RANK to public
go

