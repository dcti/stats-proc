#!/usr/bin/sqsh -i
#
# $Id: audit.sql,v 1.1 2000/06/23 20:00:47 decibel Exp $

print "Sum of work in Email_Contrib_Today for project id %1!", ${1}
go
select	sum(WORK_UNITS)
	from Email_Contrib_Today
	where PROJECT_ID = ${1}
go

declare @proj_date smalldatetime
select @proj_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}

print "Sum of work in Email_Contrib for today (%1!)", @proj_date
go
declare @proj_date smalldatetime
select @proj_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}

select	sum(WORK_UNITS)
	from Email_Contrib
	where PROJECT_ID = ${1}
		and DATE = @proj_date
go

print "Sum of work in Platform_Contrib_Today for project id %1!", ${1}
go
select	sum(WORK_UNITS)
	from Platform_Contrib_Today
	where PROJECT_ID = ${1}
go

declare @proj_date smalldatetime
select @proj_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}

print "Sum of work in Platform_Contrib for today (%1!)", @proj_date
go
declare @proj_date smalldatetime
select @proj_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}

select	sum(WORK_UNITS)
	from Platform_Contrib
	where PROJECT_ID = ${1}
		and DATE = @proj_date
go

declare @proj_date smalldatetime
select @proj_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}

print "Work Units, Participants in Daily_Summary for today (%1!)", @proj_date
go
declare @proj_date smalldatetime
select @proj_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}

select	WORK_UNITS, PARTICIPANTS
	from Daily_Summary
	where DATE = @proj_date
		and PROJECT_ID = ${1}
go

print "Total work units in Email_Contrib"
go
select	sum(WORK_UNITS)
	from Email_Contrib
	where PROJECT_ID = ${1}
go

print "Total work units in Platform_Contrib"
go
select	sum(WORK_UNITS)
	from Platform_Contrib
	where PROJECT_ID = ${1}
go

print "Total work units in Daily_Summary"
go
select	sum(WORK_UNITS)
	from Daily_Summary
	where PROJECT_ID = ${1}
go

print "Total work units ignored today (listmode >= 10)"
go
select	sum(d.WORK_UNITS)
	from Email_Contrib_Today d, STATS_Participant p
	where PROJECT_ID = ${1}
		and d.ID = p.ID
		and p.LISTMODE >= 10
go

print "Total work units ignored overall (listmode >= 10)"
go
select	sum(e.WORK_UNITS)
	from Email_Contrib e, STATS_Participant p
	where PROJECT_ID = ${1}
		and e.ID = p.ID
		and p.LISTMODE >= 10
go

print "Total work reported in Email_Rank for Today, Overall"
go
select	sum(WORK_TODAY), sum(WORK_TOTAL)
	from Email_Rank
	where PROJECT_ID = ${1}
go
