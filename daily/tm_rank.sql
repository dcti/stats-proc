/*
# $Id: tm_rank.sql,v 1.15 2000/07/15 08:18:18 decibel Exp $

TM_RANK

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

print '!! Prepare for team member generation'
go

select ect.CREDIT_ID, sp.TEAM, ect.WORK_UNITS
	into #TeamMembers
	from Email_Contrib_Today ect, STATS_Participant sp, STATS_Team st
	where ect.CREDIT_ID = sp.ID
		and ect.TEAM_ID = st.team
		and sp.TEAM = st.team
		and sp.TEAM = ect.TEAM_ID	-- Give the optimizer some more options
		and ect.TEAM_ID > 0
		and sp.LISTMODE <= 9	/* Don't insert hidden people */
		and st.LISTMODE <= 9	/* Don't insert hidden teams */
		and ect.PROJECT_ID = ${1}
go

create table #TeamMemberWork
(
	ID			int		not NULL,
	TEAM_ID			int		not NULL,
	WORK_TODAY		numeric(20, 0)	not NULL,
	IS_NEW			bit		not NULL
)
go

insert #TeamMemberWork (ID, TEAM_ID, WORK_TODAY, IS_NEW)
	select CREDIT_ID, TEAM, sum(WORK_UNITS) as WORK_UNITS, 1
	from #TeamMembers
	group by CREDIT_ID, TEAM
go

print " Remove hidden, retired members from work table and rank table"
go
delete #TeamMemberWork
	from STATS_Participant sp
	where sp.ID = #TeamMemberWork.ID
		and sp.LISTMODE >= 10

delete Team_Members
	from STATS_Participant sp
	where sp.ID = Team_Members.ID
		and sp.LISTMODE >= 10
		and Team_Members.PROJECT_ID = ${1}

delete Team_Members
	from STATS_Participant sp
	where sp.ID = Team_Members.ID
		and sp.RETIRE_TO >= 1
		and Team_Members.PROJECT_ID = ${1}
go

print " Flag existing members as not-new"
go
update #TeamMemberWork
	set IS_NEW = 0
	from Team_Members tm
	where tm.PROJECT_ID = ${1}
		and tm.TEAM_ID = #TeamMemberWork.TEAM_ID
		and tm.ID = #TeamMemberWork.ID

print " Clear today info"
go
update Team_Members
	set WORK_TODAY = 0,
		DAY_RANK = 1000000,
		DAY_RANK_PREVIOUS = DAY_RANK,
		OVERALL_RANK = 1000000,
		OVERALL_RANK_PREVIOUS = OVERALL_RANK
	where PROJECT_ID = ${1}		/* all records */

print " Populate today's work"
go

declare @stats_date smalldatetime
select @stats_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}
update Team_Members
	set WORK_TODAY = tmw.WORK_TODAY,
		WORK_TOTAL = WORK_TOTAL + tmw.WORK_TODAY,
		LAST_DATE = @stats_date
	from #TeamMemberWork tmw
	where Team_Members.PROJECT_ID = ${1}
		and tmw.TEAM_ID = Team_Members.TEAM_ID
		and tmw.ID = Team_Members.ID
		and tmw.IS_NEW = 0

print " Insert records for members who have just joined a team"
go
/* Remember, Team_Members contains one record per ID for every team that ID has been on */
declare @stats_date smalldatetime
select @stats_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}
insert Team_Members (PROJECT_ID, ID, TEAM_ID, FIRST_DATE, LAST_DATE, WORK_TODAY, WORK_TOTAL,
		DAY_RANK, DAY_RANK_PREVIOUS, OVERALL_RANK, OVERALL_RANK_PREVIOUS)
	select ${1}, ID, TEAM_ID, @stats_date, @stats_date, tmw.WORK_TODAY, tmw.WORK_TODAY,
		1000000, 1000000, 1000000, 1000000
	from #TeamMemberWork tmw
	where IS_NEW = 1
go

/*
** TODO: Perform team member ranking within each team
** but only after we eliminate hidden teams
*/




print '!! Process new teams, hidden teams'
go
create table #TeamWork
(
	TEAM_ID			int		not NULL,
	WORK_TODAY		numeric(20, 0)	not NULL,
	IS_NEW			bit		not NULL
)
go
print " Insert all teams with work today, assume new"
insert #TeamWork (TEAM_ID, WORK_TODAY, IS_NEW)
	select TEAM_ID, sum(WORK_TODAY), 1
	from #TeamMemberWork
	group by TEAM_ID

print " Remove hidden teams from work table and rank table"
delete #TeamWork
	from STATS_Team
	where STATS_Team.TEAM = #TeamWork.TEAM_ID
		and STATS_Team.listmode >= 10
delete Team_Rank
	from STATS_Team
	where STATS_Team.TEAM = Team_Rank.TEAM_ID
		and STATS_Team.listmode >= 10
		and PROJECT_ID = ${1}

print " Flag existing teams as not-new"
update #TeamWork
	set IS_NEW = 0
	from Team_Rank tr
	where tr.PROJECT_ID = ${1}
		and tr.TEAM_ID = #TeamWork.TEAM_ID

print " Remove or move ""today"" info"
declare @max_rank int
select @max_rank = count(*)+1 from STATS_Team
select @max_rank as max_rank into #maxrank
update Team_Rank
	set DAY_RANK_PREVIOUS = DAY_RANK,
		DAY_RANK = @max_rank,
		OVERALL_RANK_PREVIOUS = OVERALL_RANK,
		OVERALL_RANK = @max_rank,
		WORK_TODAY = 0,
		MEMBERS_TODAY = 0
	where PROJECT_ID = ${1}

print " Insert new teams and update work for existing teams"
go
declare @stats_date smalldatetime
select @stats_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}

update Team_Rank
	set WORK_TODAY = tw.WORK_TODAY,
		WORK_TOTAL = WORK_TOTAL + tw.WORK_TODAY,
		LAST_DATE = @stats_date
	from #TeamWork tw
	where Team_Rank.TEAM_ID = tw.TEAM_ID
		and Team_Rank.PROJECT_ID = ${1}
		and tw.IS_NEW = 0

declare @max_rank int
select @max_rank = max_rank from #maxrank
insert Team_Rank (PROJECT_ID, TEAM_ID, FIRST_DATE, LAST_DATE, WORK_TODAY, WORK_TOTAL,
		DAY_RANK, DAY_RANK_PREVIOUS, OVERALL_RANK, OVERALL_RANK_PREVIOUS,
		MEMBERS_TODAY, MEMBERS_OVERALL, MEMBERS_CURRENT)
	select ${1}, tw.TEAM_ID, @stats_date, @stats_date, tw.WORK_TODAY, tw.WORK_TODAY,
			@max_rank, @max_rank, @max_rank, @max_rank, 0, 0, 0
	from #TeamWork tw
	where tw.IS_NEW = 1

/*
** TODO: team join should log, so this script can refer to team membership
** based on stats_date instead of the current value.  Without that fix,
** changes after midnight, before stats run will be mistakenly included.
** This also has an impact if stats have to be rerun.
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


/*
** Team_Members contains everyone who was or is on this team.
** Active members have WORK_TODAY > 0
** Total members = all listed in Team_Members
** Current members = people who are listed on this team today, active or not
*/
print "::  Setting # of Overall and Active members"
go
create table #CurrentMembers
(
	TEAM_ID		int,
	OVERALL		int,
	ACTIVE		int,
	CURR		int
)
go
/*
** TODO: Take a good hard look at whether any of these can be handled as
**	incremental changes.  If so, create temp table early and populate
**	as these facts become available.
**	"Count the needles before throwing them on the haystack"
**	ex: OVERALL = OVERALL + [inserted today]
**	ex: CURR calculated while summing the WORK_TODAY by team
*/

/* JCN
#	I removed the following, as I'm pretty sure it will totally screw up
#	the OVERALL count.
#
#	and tm.WORK_TODAY > 0
*/

insert #CurrentMembers (TEAM_ID, OVERALL, ACTIVE, CURR)
	select tm.TEAM_ID, count(*), sum(sign(WORK_TODAY)), sum(1-abs(sign(sp.team - tm.TEAM_ID)))
	from Team_Members tm, STATS_Participant sp
	where sp.ID = tm.ID
		and tm.PROJECT_ID = ${1}
	group by tm.TEAM_ID
go
create index iTEAM_ID on #CurrentMembers(TEAM_ID)
go
update Team_Rank
	set MEMBERS_TODAY = ACTIVE,
		MEMBERS_OVERALL = OVERALL,
		MEMBERS_CURRENT = CURR
	from #CurrentMembers cm
	where Team_Rank.TEAM_ID = cm.TEAM_ID
		and Team_Rank.PROJECT_ID = ${1}

drop table #CurrentMembers
go

