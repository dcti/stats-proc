print "!! Begin CACHE_em_YRANK Build"
go

use stats
set flushmessage on
set rowcount 0
go

print "::  Creating PREBUILD_em_YRANK table"
go
while exists (select * from sysobjects where id = object_id('PREBUILD_em_YRANK'))
	drop table PREBUILD_em_YRANK
go
create table PREBUILD_em_YRANK 
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

print "::  Populating PREBUILD_em_YRANK table"
go
declare @mdv smalldatetime
select @mdv = max(date)
from RC5_64_master

insert into PREBUILD_em_YRANK 
  (id,email,first,last,blocks,days_working,rank,change,listmode)
select id, email,last,last,yblocks,1 as days_working,0 as rank, 0 as change,listmode
from CACHE_em_RANK
where last = @mdv
order by yblocks desc, id desc
go

print "::  Updating rank values to idx values (ranking step 1)"
go
update PREBUILD_em_YRANK
  set rank = idx,
      overall_rate = convert(numeric(14,4),blocks*268435.456/DateDiff(ss,first,DateAdd(dd,1,last)))
go

print "::  Indexing on blocks for ranking acceleration"
go
create index tempindex on PREBUILD_em_YRANK(blocks) with fillfactor = 100
go

print "::  Correcting rank for tied participants"
go
update PREBUILD_em_YRANK
set rank = (select min(btb.rank) from PREBUILD_em_YRANK btb where btb.blocks = PREBUILD_em_YRANK.blocks)
where (select count(*) from PREBUILD_em_YRANK btb where btb.blocks = PREBUILD_em_YRANK.blocks) > 1
go

drop index PREBUILD_em_YRANK.tempindex
go

print "::  Creating id indexes"
go
create unique index id on PREBUILD_em_YRANK(id) with fillfactor = 100
go

print "::  Calculating offset from previous ranking"
go
update PREBUILD_em_YRANK
 set change = old.rank - PREBUILD_em_YRANK.rank
 from CACHE_em_YRANK old
 where old.id = PREBUILD_em_YRANK.id
go

print ":: Indexing on rank and email"
go

create clustered index rank on PREBUILD_em_YRANK(rank) with fillfactor = 100
create index email on PREBUILD_em_YRANK(email) with fillfactor = 100
go
print ":: updating statistics"
go

grant select on PREBUILD_em_YRANK to public
go

drop view rc5_64_CACHE_em_YRANK
go
create view rc5_64_CACHE_em_YRANK as select * from CACHE_em_YRANK
go
grant select on rc5_64_CACHE_em_YRANK to public
go
revoke select on CACHE_em_YRANK to public
go

while exists (select * from sysobjects where id = object_id('CACHE_em_YRANK'))
	drop table CACHE_em_YRANK
go
sp_rename PREBUILD_em_YRANK, CACHE_em_YRANK
go
