/*
# $Id: tm_update.sql,v 1.29 2002/04/18 04:04:53 decibel Exp $

TM_RANK

Parameters
	Project_ID

Flow: (M=members, T=teams)

M Build temp table of all contrib of all members of all teams (for this project)
M Remove members with listmode >= 10
M Clear yesterday member info
M Populate today contrib for existing members
M Flag existing members (in temp table)
M Insert nonflagged members and their contrib for today and total (remember team '0' work)

T Build temp table of all contrib of each team (from member temp table)
T Remove (hide) teams with listmode >= 10
T Flag existing teams (in temp table)
T Insert nonflagged teams
T Clear yesterday team info
T Populate today info for existing teams
T Insert info for new teams *with a 0 for WORK_TOTAL, since that will be updated by the next step*
T Update all teams where new records for the team were inserted into Team_Members

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

set flushmessage on
print '!! Prepare for team member generation'
go

select ect.CREDIT_ID, ect.TEAM_ID, ect.WORK_UNITS
	into #TeamMembers
	from Email_Contrib_Today ect
	where ect.TEAM_ID >= 1
		and not exists (select *
					from STATS_Participant_Blocked spb
					where spb.ID = ect.CREDIT_ID
				)
		and not exists (select *
					from STATS_Team_Blocked stb
					where stb.TEAM_ID = ect.TEAM_ID
				)
		and ect.PROJECT_ID = ${1}
go
--delete from #TeamMembers
--	where TEAM_ID in (select TEAM_ID
--				from STATS_Participant_Blocked
--			)
--go

create table #TeamMemberWork
(
	ID			int		not NULL,
	TEAM_ID			int		not NULL,
	WORK_TODAY		numeric(20, 0)	not NULL,
	IS_NEW			bit		not NULL
)
go

-- WARNING! #TeamMemberWork must be unique by ID and TEAM_ID. See the note below for more info
insert #TeamMemberWork (ID, TEAM_ID, WORK_TODAY, IS_NEW)
	select CREDIT_ID, TEAM_ID, sum(WORK_UNITS) as WORK_UNITS, 1
	from #TeamMembers
	group by CREDIT_ID, TEAM_ID
go

print " Flag existing members as not-new"
go
update #TeamMemberWork
	set IS_NEW = 0
	from Team_Members tm
	where tm.PROJECT_ID = ${1}
		and tm.TEAM_ID = #TeamMemberWork.TEAM_ID
		and tm.ID = #TeamMemberWork.ID

go
print " Clear today info"
update Team_Members
	set WORK_TODAY = 0,
		DAY_RANK = 1000000,
		DAY_RANK_PREVIOUS = DAY_RANK,
		OVERALL_RANK = 1000000,
		OVERALL_RANK_PREVIOUS = OVERALL_RANK
	where PROJECT_ID = ${1}		/* all records */
go

print " Populate today's work"
declare @stats_date smalldatetime
select @stats_date = LAST_HOURLY_DATE
	from Project_statsrun
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
go

print " Insert records for members who have just joined a team"
/* Remember, Team_Members contains one record per ID for every team that ID has been on */
# Summarize work
create table #Work_Summary (
	ID int,
	TEAM_ID int,
	FIRST_DATE smalldatetime,
	WORK_UNITS numeric(20,0)
)
go
create table #NewTeamMembers (
	EC_ID int,
	PROJECT_ID tinyint,
	CREDIT_ID int,
	TEAM_ID int
)
go

-- Find the ficst date each new participant was on the team

-- First, build a list of just the new members, including everyone that's
-- retired to them
declare @stats_date smalldatetime
select @stats_date = LAST_HOURLY_DATE
	from Project_statsrun
	where PROJECT_ID = ${1}
insert into #NewTeamMembers(EC_ID, PROJECT_ID, CREDIT_ID, TEAM_ID)
	select sp.ID, ${1}, tmw.ID, tmw.TEAM_ID
	from #TeamMemberWork tmw, STATS_Participant sp
	where IS_NEW = 1
		and sp.RETIRE_TO = tmw.ID
		and (sp.RETIRE_DATE <= @stats_date or sp.RETIRE_DATE is NULL)
go
insert into #NewTeamMembers(EC_ID, PROJECT_ID, CREDIT_ID, TEAM_ID)
	select tmw.ID, ${1}, tmw.ID, tmw.TEAM_ID
	from #TeamMemberWork tmw
	where IS_NEW = 1
go
create clustered index id_project on #NewTeamMembers(EC_ID, PROJECT_ID)
go

-- Now, figure out the first date each one effectively joined the team
insert into #Work_Summary (ID, TEAM_ID, FIRST_DATE, WORK_UNITS)
	select ntm.CREDIT_ID, ntm.TEAM_ID, min(ec.DATE), sum(ec.WORK_UNITS)
	from #NewTeamMembers ntm, Email_Contrib ec
	where ec.ID = ntm.EC_ID
		and ec.TEAM_ID = ntm.TEAM_ID
		and ec.PROJECT_ID = ntm.PROJECT_ID
	group by ntm.CREDIT_ID, ntm.TEAM_ID

/*
# We're doing min(tmw.WORK_TODAY) because there can be more than one record in #Work_Summary. Any time
# there is, the row from tmw will be included multiple times. (tmw is already summarized)
*/
declare @stats_date smalldatetime
select @stats_date = LAST_HOURLY_DATE
	from Project_statsrun
	where PROJECT_ID = ${1}
insert Team_Members (PROJECT_ID, ID, TEAM_ID, FIRST_DATE, LAST_DATE, WORK_TODAY, WORK_TOTAL,
		DAY_RANK, DAY_RANK_PREVIOUS, OVERALL_RANK, OVERALL_RANK_PREVIOUS)
	select ${1}, ws.ID, ws.TEAM_ID, min(ws.FIRST_DATE), @stats_date, min(tmw.WORK_TODAY), sum(ws.WORK_UNITS),
		1000000, 1000000, 1000000, 1000000
	from #TeamMemberWork tmw, #Work_Summary ws
	where tmw.IS_NEW = 1
		and tmw.ID = ws.ID
		and tmw.TEAM_ID = ws.TEAM_ID
	group by ws.ID, ws.TEAM_ID
go

/*
** TODO: Perform team member ranking within each team
** but only after we eliminate hidden teams
*/



set flushmessage off
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
	from STATS_Team_Blocked
	where STATS_Team_Blocked.TEAM_ID = #TeamWork.TEAM_ID
delete Team_Rank
	from STATS_Team_Blocked
	where STATS_Team_Blocked.TEAM_ID = Team_Rank.TEAM_ID
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
go

print " Insert new teams and update work for existing teams"
go
declare @stats_date smalldatetime
select @stats_date = LAST_HOURLY_DATE
	from Project_statsrun
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
# TODO: Take a good hard look at whether any of these can be handled as
#	incremental changes.  If so, create temp table early and populate
#	as these facts become available.
#	"Count the needles before throwing them on the haystack"
#	ex: OVERALL = OVERALL + [inserted today]
#	ex: CURR calculated while summing the WORK_TODAY by team
#
# JCN
#	That will probably not be worth it, thanks to retire_to's.
*/

/* JCN
#	I removed the following, as I'm pretty sure it will totally screw up
#	the OVERALL count.
#
#	and tm.WORK_TODAY > 0
*/

declare @stats_date smalldatetime
select @stats_date = LAST_HOURLY_DATE
	from Project_statsrun
	where PROJECT_ID = ${1}

insert #CurrentMembers (TEAM_ID, OVERALL, ACTIVE, CURR)
	select tm.TEAM_ID, count(*), sum(sign(WORK_TODAY)), sum(1-abs(sign(tj.TEAM_ID - tm.TEAM_ID)))
	from Team_Members tm, Team_Joins tj
	where tj.ID = tm.ID
		and tj.JOIN_DATE <= @stats_date
		and (tj.LAST_DATE = null or tj.LAST_DATE >= @stats_date)
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

