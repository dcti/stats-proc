#!/usr/bin/sqsh -i
#
# $Id: dp_em_yrank.sql,v 1.2 2000/02/21 03:47:06 bwilson Exp $
#
# Rank the participants (yesterday)
#
# Arguments:
#       Project

print "!! Begin ${1}_CACHE_em_YRANK Build"
go

use stats
set rowcount 0
go

print "::  Creating PREBUILT_${1}_CACHE_em_YRANK table"
go

if object_id(\\'PREBUILT_${1}_CACHE_em_RANK\\') is not NULL
begin
	drop table PREBUILT_${1}_CACHE_em_RANK
end
go
create table PREBUILT_${1}_CACHE_em_YRANK
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
from ${1}_master

select distinct
 id,
 min(date) as first,
 max(date) as last,
 Sum(blocks) as blocks
into #YRANKa
from ${1}_master
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

print "::  Populating PREBUILT_${1}_CACHE_em_YRANK table"
go
insert into PREBUILT_${1}_CACHE_em_YRANK
  (id,email,first,last,blocks,days_working,rank,change,listmode)
select distinct id, max(email),min(first),max(last),sum(blocks),1 as days_working,0 as rank, 0 as change,max(listmode)
from #YRANKb
where listmode < 10 or listmode = NULL
group by id
order by sum(blocks) desc
go

print "::  Updating rank values to idx values (ranking step 1)"
go
update PREBUILT_${1}_CACHE_em_YRANK
  set rank = idx,
      overall_rate = convert(numeric(14,4),blocks*268435.456/DateDiff(ss,first,DateAdd(dd,1,last)))
go

print "::  Indexing on blocks for ranking acceleration"
go
create index tempindex on PREBUILT_${1}_CACHE_em_YRANK(blocks)
go

print "::  Correcting rank for tied participants"
go
update PREBUILT_${1}_CACHE_em_YRANK
set rank = (select min(btb.rank) from PREBUILT_${1}_CACHE_em_YRANK btb where btb.blocks = PREBUILT_${1}_CACHE_em_YRANK.blocks)
where (select count(btb.blocks) from PREBUILT_${1}_CACHE_em_YRANK btb where btb.blocks = PREBUILT_${1}_CACHE_em_YRANK.blocks) > 1
go

drop index PREBUILT_${1}_CACHE_em_YRANK.tempindex
go

print "::  Creating id indexes"
go
create unique index id on PREBUILT_${1}_CACHE_em_YRANK(id) with fillfactor = 100
go

print "::  Calculating offset from previous ranking"
go
update PREBUILT_${1}_CACHE_em_YRANK
set change = (select ${1}_CACHE_em_YRANK.rank from ${1}_CACHE_em_YRANK
              where ${1}_CACHE_em_YRANK.id = PREBUILT_${1}_CACHE_em_YRANK.id)-PREBUILT_${1}_CACHE_em_YRANK.rank
go

print ":: Indexing on email"
go

create clustered index rank on PREBUILT_${1}_CACHE_em_YRANK(rank) with fillfactor = 100
# create unique index email on PREBUILT_${1}_CACHE_em_YRANK(email) with fillfactor = 100
go

grant select on PREBUILT_${1}_CACHE_em_YRANK to public
go

print ":: Moving tables, backing up old data"
go

if (object_id(\\'${1}_CACHE_em_YRANK_backup\\') is not NULL
	and object_id(\\'PREBUILT_${1}_CACHE_em_YRANK\\') is not NULL)
begin
	if exists (select * from PREBUILT_${1}_CACHE_em_YRANK)
	begin
		drop table ${1}_CACHE_em_YRANK_backup
	end
end
go

if object_id(\\'PREBUILT_${1}_CACHE_em_YRANK\\') is not NULL
	if exists (select * from PREBUILT_${1}_CACHE_em_YRANK)
	begin
#		-- Do a select into instead of a rename so that the stored procs dont keep hitting
#		-- the old table
		select * into ${1}_CACHE_em_YRANK_backup from ${1}_CACHE_em_YRANK
		revoke select on ${1}_CACHE_em_YRANK to public
		drop table ${1}_CACHE_em_YRANK
		EXEC sp_rename \\'PREBUILT_${1}_CACHE_em_YRANK\\', \\'${1}_CACHE_em_YRANK\\'
	end
go
