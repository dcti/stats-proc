#!/usr/bin/sqsh -i
#
# $Id: audit.sql,v 1.2 2000/06/26 10:47:30 decibel Exp $

create table #audit (
	ECTsum		numeric(20),
	ECsumtoday	numeric(20),
	PCTsum		numeric(20),
	PCsumtoday	numeric(20),
	DSunits		numeric(20),
	DSusers		int,
	ECsum		numeric(20),
	PCsum		numeric(20),
	DSsum 		numeric(20),
	ECTignrsum	numeric(20),
	ECignrsumtdy	numeric(20),
	ERsumtoday	numeric(20),
	ERsum		numeric(20)
)
go -f -h
insert into #audit values(0,0,0,0,0,0,0,0,0,0,0,0,0)
go -f -h

print "Sum of work in Email_Contrib_Today for project id %1!", ${1}
go -f -h
update	#audit
	set ECTsum = (select sum(WORK_UNITS)
		from Email_Contrib_Today
		where PROJECT_ID = ${1})
select ECTsum from #audit
go -f -h

declare @proj_date smalldatetime
select @proj_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}

print "Sum of work in Email_Contrib for today (%1!)", @proj_date
go -f -h
declare @proj_date smalldatetime
select @proj_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}

update	#audit
	set ECsumtoday = (select sum(WORK_UNITS)
		from Email_Contrib
		where PROJECT_ID = ${1}
			and DATE = @proj_date)
select ECsumtoday from #audit
go -f -h

print "Sum of work in Platform_Contrib_Today for project id %1!", ${1}
go -f -h
update	#audit
	set PCTsum = (select sum(WORK_UNITS)
		from Platform_Contrib_Today
		where PROJECT_ID = ${1})
select PCTsum from #audit
go -f -h

declare @proj_date smalldatetime
select @proj_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}

print "Sum of work in Platform_Contrib for today (%1!)", @proj_date
go -f -h
declare @proj_date smalldatetime
select @proj_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}

update	#audit
	set PCsumtoday = (select sum(WORK_UNITS)
		from Platform_Contrib
		where PROJECT_ID = ${1}
			and DATE = @proj_date)
select PCsumtoday from #audit
go -f -h

declare @proj_date smalldatetime
select @proj_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}

print "Work Units, Participants in Daily_Summary for today (%1!)", @proj_date
go -f -h
declare @proj_date smalldatetime
declare @units numeric(20)
declare @participants int
select @proj_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}

select	@units = WORK_UNITS, @participants = PARTICIPANTS
	from Daily_Summary
	where DATE = @proj_date
		and PROJECT_ID = ${1}
update	#audit
	set DSunits = @units, DSusers = @participants
select @units, @participants
go -f -h

print "Total work units in Email_Contrib"
go -f -h
update	#audit
	set ECsum = (select sum(WORK_UNITS)
		from Email_Contrib
		where PROJECT_ID = ${1})
select ECsum from #audit
go -f -h

print "Total work units in Platform_Contrib"
go -f -h
update 	#audit
	set PCsum = (select sum(WORK_UNITS)
		from Platform_Contrib
		where PROJECT_ID = ${1})
select PCsum from #audit
go -f -h

print "Total work units in Daily_Summary"
go -f -h
update	#audit
	set DSsum = (select sum(WORK_UNITS)
		from Daily_Summary
		where PROJECT_ID = ${1})
select DSsum from #audit
go -f -h

print "Total work units ignored today (listmode >= 10)"
go -f -h
update	#audit
	set ECTignrsum = (select sum(d.WORK_UNITS)
		from Email_Contrib_Today d, STATS_Participant p
		where PROJECT_ID = ${1}
			and d.ID = p.ID
			and p.LISTMODE >= 10)
select ECTignrsum from #audit
go -f -h

print "Total work units ignored overall (listmode >= 10)"
go -f -h
update	#audit
	set ECignrsumtdy = (select sum(e.WORK_UNITS)
		from Email_Contrib e, STATS_Participant p
		where PROJECT_ID = ${1}
			and e.ID = p.ID
			and p.LISTMODE >= 10)
select ECignrsumtdy from #audit
go -f -h

print "Total work reported in Email_Rank for Today, Overall"
go -f -h
declare @ERsumtoday numeric(20)
declare @ERsum numeric(20)
select	@ERsumtoday = sum(WORK_TODAY), @ERsum = sum(WORK_TOTAL)
	from Email_Rank
	where PROJECT_ID = ${1}
update	#audit
	set ERsumtoday = @ERsumtoday, ERsum = @ERsum
select @ERsumtoday, @ERsum
go -f -h
