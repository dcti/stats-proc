
/*
TM_RANK

Parameters
	Project_ID
Reset TODAY fields to defaults
	Possibly in Members table as well as Team_Rank
Insert new teams
	Teams with work that do not exist in Team_Rank
Insert new team members
	Members who have work for a team for the first time
Delete hidden teams
	teams where listmode >= 10

Populate day's work, bump last_date for members (not em_rank table, multiple entries per ID)
	Day's work = copy of _Email_Rank, per project
	Last date = today if work submitted
	Must honor retire_to before this step
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


print '!! Begin team ranking'
go

use stats
set rowcount 0
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


print ' Now insert new teams'
go
declare @stats_date smalldatetime
select @stats_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}

insert Team_Rank (PROJECT_ID, TEAM_ID, FIRST_DATE, LAST_DATE, WORK_TODAY, WORK_TOTAL, DAY_RANK, DAY_RANK_PREVIOUS,
		OVERALL_RANK, OVERALL_RANK_PREVIOUS, MEMBERS_TODAY, MEMBERS_OVERALL, MEMBERS_LISTED)
	select distinct ${1}, dm.TEAM_ID, @stats_date, @stats_date, 0, 0, 1000000, 1000000, 1000000, 1000000, 0, 0, 0
	from Email_Contrib_Today ect, Stats_Team st
	where ect.TEAM_ID = st.TEAM
		and ect.TEAM_ID not in (select TEAM_ID from Team_Rank where PROJECT_ID = ${1})
		and st.LISTMODE < 10
		and ect.PROJECT_ID = ${1}
go

print " Update member tables"
go
/*
** TODO Update contents of Team_Members table with work done today, insert new team members
*/

print " Populate work"
go
print "::  Filling temp table"
go
create table #TeamWork
(
	TEAM_ID int not NULL,
	WORK_UNITS numeric(20, 0) not NULL
)
go
insert #TeamWork (TEAM_ID, WORK_UNITS)
	select TEAM_ID, sum(WORK_UNITS)
	from Email_Contrib_Today
	where PROJECT_ID = ${1}
	group by TEAM_ID
go
declare @stats_date smalldatetime
select @stats_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}

update Team_Rank
	set WORK_TODAY = tw.WORK_UNITS,
		WORK_TOTAL = WORK_TOTAL + tw.WORK_UNITS,
		LAST_DATE = @stats_date
	from #TeamWork tw
	where dm.TEAM_ID = tw.TEAM_ID
		and Team_Rank.PROJECT_ID = ${1}

/*
** TODO: team join should log, so this script can refer to team membership
** based on stats_date instead of the current value.  Without that fix,
** changes after midnight, before stats run will be mistakenly included.
** This also has an impact if stats have to be rerun.
*/
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

