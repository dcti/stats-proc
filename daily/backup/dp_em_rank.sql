#!/usr/bin/sqsh -i
#
# $Id: dp_em_rank.sql,v 1.1 2000/02/09 16:13:57 nugget Exp $
#
# Does the participant ranking (overall)
#
# Arguments:
#       Project

print "!! Begin ${1}_CACHE_em_RANK Build"
go

use stats
set rowcount 0
go

revoke select on ${1}_CACHE_em_RANK to public
go

while exists (select * from sysobjects where id = object_id(\\'${1}_CACHE_em_RANK_old\\'))
	drop table ${1}_CACHE_em_RANK_old
go

while exists (select * from sysobjects where id = object_id(\\'${1}_CACHE_em_RANK\\'))
	EXEC sp_rename \\'${1}_CACHE_em_RANK', '${1}_CACHE_em_RANK_old'
go

print "::  Creating ${1}_CACHE_em_RANK table"
go
create table ${1}_CACHE_em_RANK
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
select id, min(date) as first, max(date) as last, sum(blocks) as blocks
	into #RANKa
	from ${1}_master
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

print "::  Populating ${1}_CACHE_em_RANK table"
go
insert into ${1}_CACHE_em_RANK
	(id, email, first, last, blocks, days_working, rank, change, listmode, overall_rate)
	select p.id, max(p.email), min(r.first), max(r.last), sum(r.blocks),
		datediff(dd,min(r.first),max(r.last))+1 as days_working, 0 as rank, 0 as change, max(p.listmode),
		convert(numeric(14,4),sum(r.blocks)*268435.456/DateDiff(second,min(r.first),DateAdd(day,1,max(r.last)))) as overall_rate
	from #RANKa r, STATS_Participant p
	where r.id = p.id
		and listmode < 10
	group by p.id
	order by sum(r.blocks) desc, p.id
go

print "::  Calculating rank for participants"
go
select blocks, min(idx) as rank
	into #RANKb
	from ${1}_CACHE_em_RANK
	group by blocks
go
create unique clustered index blocks on #RANKb(blocks)
go
update ${1}_CACHE_em_RANK
	set rank = r.rank
	from #RANKb r
	where ${1}_CACHE_em_RANK.blocks = r.blocks
go

print "::  Calculating offset from previous ranking"
go
update ${1}_CACHE_em_RANK
	set change = old.rank - ${1}_CACHE_em_RANK.rank
	from ${1}_CACHE_em_RANK_old old
	where old.id = ${1}_CACHE_em_RANK.id
go

print "::  Creating indexes"
go
create clustered index rank on ${1}_CACHE_em_RANK(rank) with fillfactor = 100
create unique index id on ${1}_CACHE_em_RANK(id) with fillfactor = 100
-- create unique index email on ${1}_CACHE_em_RANK(email) with fillfactor = 100
go
grant select on ${1}_CACHE_em_RANK to public
go

