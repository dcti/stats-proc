#!/usr/bin/sqsh -i
/*
#
# $Id: tm_rank.sql,v 1.23 2002/12/17 00:49:35 decibel Exp $
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
print '!! Begin team ranking'
print ' Drop indexes on Team_Rank'
go
--drop index Team_Rank.iDAY_RANK
--drop index Team_Rank.iOVERALL_RANK
--go

print ' Create rank table for today'
go
create table #rank_assign
(
	IDENT numeric(10, 0) identity,
	TEAM_ID int,
	WORK_UNITS numeric(20, 0)
)
go
insert #rank_assign (TEAM_ID, WORK_UNITS)
	select TEAM_ID, WORK_TODAY
	from Team_Rank
	where PROJECT_ID = ${1}
	order by WORK_TODAY desc, TEAM_ID desc
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
	TEAM_ID int,
	WORK_UNITS numeric(20, 0)
)
go
insert #rank_assign (TEAM_ID, WORK_UNITS)
	select TEAM_ID, WORK_TOTAL
	from Team_Rank
	where PROJECT_ID = ${1}
	order by WORK_TOTAL desc, TEAM_ID desc

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

print ' Update Team_Rank with new rankings'
update Team_Rank
	set OVERALL_RANK = o.rank, DAY_RANK = isnull(d.rank, Team_Rank.DAY_RANK)
	from #rank_tie_overall o, #rank_tie_today d
	where Team_Rank.WORK_TODAY *= d.WORK_UNITS
		and Team_Rank.WORK_TOTAL = o.WORK_UNITS
		and Team_Rank.PROJECT_ID = ${1}
go

print ' set previous rank = current rank for new participants'
go
declare @stats_date smalldatetime
select @stats_date = LAST_HOURLY_DATE
	from Project_statsrun
	where PROJECT_ID = ${1}

update	Team_Rank
	set DAY_RANK_PREVIOUS = DAY_RANK,
		OVERALL_RANK_PREVIOUS = OVERALL_RANK
	where PROJECT_ID = ${1}
		and FIRST_DATE = @stats_date

exec p_set_lastupdate_t ${1}, @stats_date
go

--print ' update statistics'
--go
--update statistics Team_Rank
--go
--print ' Rebuild indexes on Team_Rank'
--create index iDAY_RANK on Team_Rank(PROJECT_ID, DAY_RANK)
--create index iOVERALL_RANK on Team_Rank(PROJECT_ID, OVERALL_RANK)
--go
