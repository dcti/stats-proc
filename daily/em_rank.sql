#!/usr/bin/sqsh -i
/*
#
# $Id: em_rank.sql,v 1.11 2000/10/04 21:54:28 decibel Exp $
#
# Does the participant ranking (overall)
#
# Arguments:
#       Project_id
*/

use stats
set rowcount 0
set flushmessage on
go
print '!! Begin e-mail ranking'
print ' Drop indexes on Email_Rank'
go
--drop index Email_Rank.iDAY_RANK
--drop index Email_Rank.iOVERALL_RANK
--go

print ' Create rank table for today'
go
create table #rank_assign
(
	IDENT numeric(10, 0) identity,
	ID int,
	WORK_UNITS numeric(20, 0)
)
go
insert #rank_assign (ID, WORK_UNITS)
	select ID, WORK_TODAY
	from Email_Rank
	where PROJECT_ID = ${1}
	order by WORK_TODAY desc, ID desc
go

create table #rank_tie_today
(
	WORK_UNITS numeric(20, 0),
	rank int
)
go
insert #rank_tie_today
	select WORK_UNITS, min(IDENT)
	from #rank_assign
	group by WORK_UNITS
go

drop table #rank_assign
create clustered index iWORK_UNITS on #rank_tie_today(WORK_UNITS)
go

print ' Create rank table for overall'
create table #rank_assign
(
	IDENT numeric(10, 0) identity,
	ID int,
	WORK_UNITS numeric(20, 0)
)
go
insert #rank_assign (ID, WORK_UNITS)
	select ID, WORK_TOTAL
	from Email_Rank
	where PROJECT_ID = ${1}
	order by WORK_TOTAL desc, ID desc

create table #rank_tie_overall
(
	WORK_UNITS numeric(20, 0),
	rank int
)
go
insert #rank_tie_overall
	select WORK_UNITS, min(IDENT)
	from #rank_assign
	group by WORK_UNITS
go

drop table #rank_assign
create clustered index iWORK_UNITS on #rank_tie_overall(WORK_UNITS)
go

print ' Update Email_Rank with new rankings'
update Email_Rank
	set OVERALL_RANK = o.rank, DAY_RANK = isnull(d.rank, Email_Rank.DAY_RANK)
	from #rank_tie_overall o, #rank_tie_today d
	where Email_Rank.WORK_TODAY *= d.WORK_UNITS
		and Email_Rank.WORK_TOTAL = o.WORK_UNITS
		and Email_Rank.PROJECT_ID = ${1}
go

print ' set previous rank = current rank for new participants'
go
declare @stats_date smalldatetime
select @stats_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}

update	Email_Rank
	set DAY_RANK_PREVIOUS = DAY_RANK,
		OVERALL_RANK_PREVIOUS = OVERALL_RANK
	where PROJECT_ID = ${1}
		and FIRST_DATE = @stats_date
go

--print ' update statistics'
--go
--update statistics Email_Rank
--go
--print ' Rebuild indexes on Email_Rank'
--create index iDAY_RANK on Email_Rank(PROJECT_ID, DAY_RANK)
--create index iOVERALL_RANK on Email_Rank(PROJECT_ID, OVERALL_RANK)
--go
