
/*
TM_RANK

Parameters
	Project_ID

Flow: (M=members, T=teams)

M Build temp table of all contrib of all members of all teams (for this project)
T Build temp table of all contrib of each team (from member temp table)
T Clear yesterday team info
T Populate today info for existing teams
T Flag existing teams (in temp table)
T Insert nonflagged teams
T Populate team summary info (lifetime members, active members, listed members)
T Remove (hide) teams with listmode >= 10
T Rank all teams

M Clear yesterday member info
M Populate today contrib for existing members
M Flag existing members (in temp table)
M Insert nonflagged members
M Remove members with listmode >= 10
M TODO: Rank members within each team (cursor required)


Populate day's work, bump last_date for members (not em_rank table, multiple entries per ID)
	Day's work = copy of _Email_Rank, per project
	Last date = today if work submitted
	Must use CREDIT_ID for this step
Populate day's work for team
	total = total + sum(work from members submitting today)
	Must populate member work before this step

Rank teams
	Same as EMAIL ranking script
Rank people within teams (cursor?)
Recalculate active members
	Work submitted today
Recalculate total members
	Old total + new members today
Recalculate listed members
	Old total + new members today - members who left
*/

print '!! Prepare for team ranking'
go

create table #TeamMemberWork
(
	ID			int		not NULL,
	TEAM_ID			int		not NULL,
	WORK_TODAY		numeric(20, 0)	not NULL,
	IS_NEW			bit		not NULL
)
go
create table #TeamWork
(
	TEAM_ID			int		not NULL,
	WORK_TODAY		numeric(20, 0)	not NULL,
	IS_NEW			bit		not NULL
)
go
insert #TeamMemberWork (ID, TEAM_ID, WORK_TODAY, IS_NEW)
	select ect.CREDIT_ID, odm.TEAM_ID, sum(ect.WORK_UNITS), 1
	from Email_Contrib_Today ect, STATS_Participant sp, STATS_Team st
	where ect.ID = sp.ID
		and ect.TEAM_ID = tm.TEAM_ID
		and ect.TEAM_ID > 0
		and sp.LISTMODE <= 9	/* Don't insert hidden people */
		and st.LISTMODE <= 9	/* Don't insert hidden teams */
		and ect.PROJECT_ID = ${1}
	group by ect.CREDIT_ID, ect.TEAM_ID

update #TeamMemberWork
	set IS_NEW = 0
	from Team_Members tm
	where tm.PROJECT_ID = ${1}
		and tm.TEAM_ID = #TeamMemberWork.TEAM_ID
		and tm.ID = #TeamMemberWork.ID

insert #TeamWork (TEAM_ID, WORK_TODAY, IS_NEW)
	select TEAM_ID, sum(WORK_TODAY), 1
	from #TeamMemberWork
	group by TEAM_ID
	
update #TeamWork
	set IS_NEW = 0
	from Team_Rank tr
	where tr.PROJECT_ID = ${1}
		and tr.TEAM_ID = #TeamWork.TEAM_ID
go

print '!! Process new teams, hidden teams'
go

print ' Remove hidden teams'
delete Team_Rank
	from STATS_Team
	where STATS_Team.TEAM = Team_Rank.TEAM_ID
		and STATS_Team.listmode >= 10
		and PROJECT_ID = ${1}
go

print ' Remove or move "today" info'
update Team_Rank
	set DAY_RANK_PREVIOUS = DAY_RANK,
		DAY_RANK = 1000000,
		OVERALL_RANK_PREVIOUS = OVERALL_RANK,
		OVERALL_RANK = 1000000,
		WORK_TODAY = 0,
		MEMBERS_TODAY = 0
	where PROJECT_ID = ${1}
go


print ' Insert new teams and update work for existing teams'
go
declare @stats_date smalldatetime
select @stats_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}

insert Team_Rank (PROJECT_ID, TEAM_ID, FIRST_DATE, LAST_DATE, WORK_TODAY, WORK_TOTAL, 
		DAY_RANK, DAY_RANK_PREVIOUS, OVERALL_RANK, OVERALL_RANK_PREVIOUS, 
		MEMBERS_TODAY, MEMBERS_OVERALL, MEMBERS_LISTED)
	select ${1}, dm.TEAM_ID, @stats_date, @stats_date, tw.WORK_TODAY, tw.WORK_TODAY, 
			1000000, 1000000, 1000000, 1000000, 0, 0, 0
	from #TeamWork tw
	where tw.IS_NEW = 1

update Team_Rank
	set WORK_TODAY = tw.WORK_UNITS,
		WORK_TOTAL = WORK_TOTAL + tw.WORK_UNITS,
		LAST_DATE = @stats_date
	from #TeamWork tw
	where Team_Rank.TEAM_ID = tw.TEAM_ID
		and Team_Rank.PROJECT_ID = ${1}
		and tw.IS_NEW = 0

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


/*
** Team_Members contains everyone who was or is on this team.
** Active members have WORK_TODAY > 0
** Total members = all listed in Team_Members
** Current members = people who are listed on this team today, active or not
*/
print "::  Setting # of Overall and Active members"
go
select tm.TEAM_ID, count(*) 'OVERALL', sum(sign(WORK_TODAY)) 'ACTIVE', sum(abs(sign(sp.TEAM_ID - tm.TEAM_ID))) 'CURR'
	into #CurrentMembers
	from Team_Members tm, STATS_Participant sp
	where tm.PROJECT_ID = ${1}
		and tm.WORK_TODAY > 0
		and sp.ID = tm.ID
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



print "::  Creating team indexes"
go
create index iTEAM_ID on Team_Rank(TEAM_ID)
go







/*
** Team member clear, insert, ranking
*/
print "!! Begin Team_Members Build"
go


update Team_Members
	set WORK_TODAY = 0,
		DAY_RANK = 1000000,
		DAY_RANK_PREVIOUS = DAY_RANK,
		OVERALL_RANK = 1000000,
		OVERALL_RANK_PREVIOUS = OVERALL_RANK
	where PROJECT_ID = ${1}		/* all records */

select PROJECT_ID, TEAM_ID

update Team_Members
	set WORK_TODAY = ect.WORK_UNITS,
		WORK_TOTAL = WORK_TOTAL + ect.WORK_UNITS
	from Email_Contrib_Today ect
	where Team_Members.PROJECT_ID = ${1}
		and ect.PROJECT_ID = ${1}
		and ect.TEAM_ID = Team_Members.TEAM_ID
		and ect.CREDIT_ID = Team_Members.ID

insert Team_Members (PROJECT_ID, ID, TEAM_ID, FIRST_DATE, LAST_DATE, WORK_TODAY, WORK_TOTAL, DAY_RANK, DAY_RANK_PREVIOUS,
  	OVERALL_RANK, OVERALL_RANK_PREVIOUS)
select PROJECT_ID, ID, TEAM_ID, min(FIRST_DATE), max(LAST_DATE), 0, sum(WORK_UNITS), 1000000, 1000000,
	1000000, 1000000

/*
** TODO Perform team member ranking within each team
*/



/*
** From dy_members.sql
*/


print "::  Removing members who have been retired or hidden"
go
delete Team_Members
	from STATS_Participant sp
	where sp.ID = Team_Members.ID
		and (sp.RETIRE_TO >= 1 or sp.listmode >= 10)
		and Team_Members.PROJECT_ID = ${1}
go

print "::  Inserting new members, and adding work for existing members"
go
declare @stats_date smalldatetime
select @stats_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}

update Team_Members
	set LAST_DATE = @stats_date,
		WORK_UNITS = Team_Members.WORK_UNITS + tmw.WORK_UNITS
	from #team_member_work tmw
	where tmw.ID = Team_Members.ID
		and tmw.TEAM_ID = Team_Members.TEAM_ID
		and Team_Members.PROJECT_ID = ${1}

delete #team_member_work
	from Team_Members otm
	where otm.ID = #team_member_work.ID
		and otm.TEAM_ID = #team_member_work.TEAM_ID
		and otm.PROJECT_ID = ${1}

insert Team_Members (PROJECT_ID, ID, TEAM_ID, FIRST_DATE, LAST_DATE, WORK_UNITS)
	select ${1}, ID, TEAM_ID, getdate(), getdate(), WORK_UNITS
	from #team_member_work

drop table #team_member_work
go
