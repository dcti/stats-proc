#!/usr/bin/sqsh -i
#
# $Id: dp_em_rank.sql,v 1.2 2003/09/11 02:04:01 decibel Exp $
#
# Does the participant ranking (overall)
#
# Arguments:
#       Project

print "!! Begin CACHE_em_RANK Build"
go

use stats
set rowcount 0
set flushmessage on
go

print "::  Filling cache table a with data (id,first,last,blocks)"
go
create table #RANKa (
	id	numeric(10,0),
	first	smalldatetime,
	last	smalldatetime,
	blocks	numeric(10,0),
	yblocks	numeric(10,0)
)
go

declare @mdv smalldatetime
select @mdv = max(date)
from RC5_64_master

insert into #RANKa
	select id, min(date) as first, max(date) as last, sum(blocks) as blocks,
		isnull((select blocks from rc5_64_master m2 where m2.id = m1.id and m2.date = @mdv),0)
	from RC5_64_master m1
	group by id
go

print "::  Honoring all retire_to requests"
go
update #RANKa
	set id = retire_to
	from STATS_Participant
	where STATS_Participant.id = #RANKa.id
		and retire_to <> STATS_Participant.id
		and retire_to > 0
go

print "::  Creating PREBUILD_em_RANK table"
go
while exists (select * from sysobjects where id = object_id(\\'PREBUILD_em_RANK\\'))
	drop table PREBUILD_em_RANK
go
create table PREBUILD_em_RANK
(       idx numeric (10,0) IDENTITY NOT NULL,
        id numeric (10,0) NULL ,
	email varchar (64) NULL ,
	first smalldatetime NULL ,
	last smalldatetime NULL ,
	blocks numeric (10,0) NULL ,
	yblocks numeric (10,0) NULL ,
	days_working int NULL ,
	overall_rate numeric (14,4) NULL ,
	rank int NULL,
	change int NULL,
        listmode int NULL
)
go

print "::  Populating PREBUILD_em_RANK table"
go
insert into PREBUILD_em_RANK
	(id, email, first, last, blocks, yblocks, days_working, rank, change, listmode, overall_rate)
	select p.id, max(p.email), min(r.first), max(r.last), sum(r.blocks), sum(r.yblocks),
		datediff(dd,min(r.first),max(r.last))+1 as days_working, 0 as rank, 0 as change, max(p.listmode),
		convert(numeric(14,4),sum(r.blocks)*268435.456/DateDiff(second,min(r.first),DateAdd(day,1,max(r.last)))) as overall_rate
	from #RANKa r, STATS_Participant p
	where r.id = p.id
		and listmode < 10
	group by p.id
	order by sum(r.blocks) desc, p.id desc
go

print "::  Calculating rank for participants"
go
select blocks, min(idx) as rank
	into #RANKb
	from PREBUILD_em_RANK
	group by blocks
go
create unique clustered index blocks on #RANKb(blocks) with fillfactor = 100
go
update PREBUILD_em_RANK
	set rank = r.rank
	from #RANKb r
	where PREBUILD_em_RANK.blocks = r.blocks
go

print "::  Calculating offset from previous ranking"
go
update PREBUILD_em_RANK
	set change = old.rank - PREBUILD_em_RANK.rank
	from CACHE_em_RANK old
	where old.id = PREBUILD_em_RANK.id
go

print "::  Creating indexes"
go
create clustered index rank on PREBUILD_em_RANK(rank) with fillfactor = 100
create unique index email on PREBUILD_em_RANK(email) with fillfactor = 100
create unique index id on PREBUILD_em_RANK(id) with fillfactor = 100
go

grant select on PREBUILD_em_RANK to public
go
revoke select on CACHE_em_RANK to public
go

while exists (select * from sysobjects where id = object_id(\\'CACHE_em_RANK\\'))
	drop table CACHE_em_RANK
go
sp_rename PREBUILD_em_RANK, CACHE_em_RANK
go

drop view rc5_64_CACHE_em_RANK
go
create view rc5_64_CACHE_em_RANK as select * from CACHE_em_RANK
go
grant select on rc5_64_CACHE_em_RANK to public
go

