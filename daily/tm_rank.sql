/*
# $Id: tm_rank.sql,v 1.17 2000/09/22 02:41:37 decibel Exp $

Rank the teams

Parameters
	Project_ID

Flow: (M=members, T=teams)

M Build temp table of all contrib of all members of all teams (for this project)
M Remove members with listmode >= 10
M Clear yesterday member info
M Populate today contrib for existing members
M Flag existing members (in temp table)
M Insert nonflagged members and their contrib for today

T Build temp table of all contrib of each team (from member temp table)
T Remove (hide) teams with listmode >= 10
T Flag existing teams (in temp table)
T Insert nonflagged teams
T Clear yesterday team info
T Populate today info for existing teams

M TODO: Rank members within each team (cursor required)

T Populate team summary info (lifetime members, active members, listed members)
T Rank all teams

Notes:
	Do teams get credit for members with listmode >= 10?  Hopefully not.
	All members use retire_to if present
	Is Email_Contrib_Today.TEAM_ID useful in any other context?  It is superfluous here.
		Every reference to Email_Contrib_Today.TEAM_ID also requires a join
		to STATS_Participant, which is where Email_Contrib_Today got it from.
		OTOH, this may be necessary if/when team join is logged and date-driven
	It may be more efficient to rank members in all teams, even if the team didn't
		contribute today, because the work to detect non-contributing teams and
		avoid clearing the participant info may exceed the work to re-rank the team


*/

print '!! Begin team ranking'
go
print ' Rank all, today'
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

create clustered index iWORK_UNITS on #rank_assign(WORK_UNITS)

create table #rank_tie
(
	WORK_UNITS numeric(20, 0),
	RANK int
)
go
insert #rank_tie
	select WORK_UNITS, min(IDENT)
	from #rank_assign
	group by WORK_UNITS

update Team_Rank
	set DAY_RANK = #rank_tie.rank
	from #rank_tie, #rank_assign
	where #rank_tie.WORK_UNITS = #rank_assign.WORK_UNITS
		and Team_Rank.TEAM_ID = #rank_assign.TEAM_ID
		and Team_Rank.PROJECT_ID = ${1}

go
drop table #rank_assign
drop table #rank_tie
go


print ' Rank all, overall'
go

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

create clustered index iWORK_UNITS on #rank_assign(WORK_UNITS)

create table #rank_tie
(
	WORK_UNITS numeric(20, 0),
	RANK int
)
go
insert #rank_tie
	select WORK_UNITS, min(IDENT)
	from #rank_assign
	group by WORK_UNITS

update Team_Rank
	set OVERALL_RANK = #rank_tie.rank
	from #rank_tie, #rank_assign
	where #rank_tie.WORK_UNITS = #rank_assign.WORK_UNITS
		and Team_Rank.TEAM_ID = #rank_assign.TEAM_ID
		and Team_Rank.PROJECT_ID = ${1}

go
drop table #rank_assign
drop table #rank_tie
go

print ' set previous rank = current rank for new teams'
go
declare @stats_date smalldatetime
select @stats_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}

update	Team_Rank
	set DAY_RANK_PREVIOUS = DAY_RANK,
		OVERALL_RANK_PREVIOUS = OVERALL_RANK
	where PROJECT_ID = ${1}
		and FIRST_DATE = @stats_date
go
