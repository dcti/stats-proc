
/*
TM_RANK

Reset TODAY fields to defaults
	Possibly in Members table as well as ${1}_Team_Rank
Insert new teams
	Teams with work that do not exist in ${1}_Team_Rank
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
	Same as email ranking script
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
delete ${1}_Team_Rank
	from STATS_Team
	where STATS_Team.TEAM = ${1}_Team_Rank.TEAM
		and STATS_Team.listmode >= 10
go

print ' Remove or move "today" info'
update ${1}_Team_Rank
	set DAY_RANK_PREVIOUS = DAY_RANK,
		DAY_RANK = 1000000,
		OVERALL_RANK_PREVIOUS = OVERALL_RANK,
		OVERALL_RANK = 1000000,
		WORK_TODAY = 0,
		MEMBERS_TODAY = 0
go


print ' Now insert new teams'
go
declare @stats_date smalldatetime
select @stats_date = LAST_STATS_DATE
	from Projects
	where NAME = "${1}"

insert ${1}_Team_Rank (TEAM, FIRST_DATE, LAST_DATE, WORK_TODAY, WORK_TOTAL, DAY_RANK, DAY_RANK_PREVIOUS,
		OVERALL_RANK, OVERALL_RANK_PREVIOUS, MEMBERS_TODAY, MEMBERS_OVERALL, MEMBERS_LISTED)
	select dm.TEAM, @stats_date, @stats_date, 0, 0, 1000000, 1000000, 1000000, 1000000, 0, 0, 0
	from ${1}_Day_Master dm, Stats_Team st
	where dm.TEAM = st.TEAM
		and dm.TEAM not in (select TEAM from ${1}_Team_Rank)
		and dm.LISTMODE < 10
go

print ' Update member tables'
go


update ${1}_Team_Rank
	set WORK_UNITS = tws.WORK_UNITS
	from ${1}_Email_Rank er, STATS_Participant s
	where er.PROJECT_ID = ${1}_Team_Rank.PROJECT_ID
		and tws.ID = ${1}_Team_Rank.ID
		and tws.TEAM = ${1}_Team_Rank.TEAM

insert ${1}_Team_Rank

go
print ' Populate work'
go
print "::  Filling temp table with data (team,first,last,blocks)"
go
create table #TeamWork
(
	TEAM int not NULL,
	WORK_UNITS numeric(20, 0) not NULL
)
go
insert #TeamWork (TEAM, WORK_UNITS)
	select TEAM, sum(WORK_UNITS)
	from ${1}_Day_Master
	group by TEAM
go
declare @stats_date smalldatetime
select @stats_date = LAST_STATS_DATE
	from Projects
	where NAME = "${1}"

update ${1}_Team_Rank
	set WORK_TODAY = tw.WORK_UNITS,
		WORK_TOTAL = WORK_TOTAL + tw.WORK_UNITS,
		LAST_DATE = @stats_date
	from #TeamWork tw
	where dm.TEAM = tw.TEAM

/* TODO: team join should log, so this script can refer to team membership on stats_date */
go
print ' Rank all, today'
go

create table #rank_assign
(
	IDENT numeric(10, 0) identity,
	TEAM int,
	WORK_UNITS numeric(20, 0)
)
go
insert #rank_assign (TEAM, WORK_UNITS)
	select TEAM, WORK_TODAY
	from ${1}_Team_Rank
	order by WORK_TODAY desc, TEAM desc

create clustered index iWORK_UNITS on #rank_assign(WORK_UNITS)

create table #rank_tie
(
	WORK_UNITS numeric(20, 0),
	rank int
)
go
insert #rank_tie
	select WORK_UNITS, min(IDENT)
	from #rank_assign
	group by WORK_UNITS

update ${1}_Team_Rank
	set DAY_RANK = #rank_tie.rank
	from #rank_tie, #rank_assign
	where #rank_tie.WORK_UNITS = #rank_assign.WORK_UNITS
		and ${1}_Team_Rank.TEAM = #rank_assign.TEAM

go
drop table #rank_assign
drop table #rank_tie
go


-- Old script


print "::  Setting # of Current members"
go

select distinct team, count(*) as members
into #curmema
from STATS_participant
where retire_to = 0 or retire_to = NULL
group by team
go

create index team on #curmema(team)
go

update ${1}_CACHE_tm_RANK
set CurrentMembers = T.members
from ${1}_CACHE_tm_RANK C, #curmema T
where T.team = C.team
go

print "::  Setting # of total members"
go

select distinct team, count(*) as members
into #curmemb
from ${1}_master
group by team
go

create index team on #curmemb(team)
go

update ${1}_CACHE_tm_RANK
set TotalMembers = T.members
from ${1}_CACHE_tm_RANK C, #curmemb T
where T.team = C.team
go

print "::  Setting # of Active members"
go

declare @mdv smalldatetime
select @mdv = max(date)
from ${1}_master

select distinct team, count(*) as members
into #curmemc
from ${1}_master
where datediff(dd,date,@mdv)<7
group by team
go

create index team on #curmemc(team)
go

update ${1}_CACHE_tm_RANK
set ActiveMembers = T.members
from ${1}_CACHE_tm_RANK C, #curmemc T
where T.team = C.team
go



print "::  Updating rank values to idx values (ranking step 1)"
go
update ${1}_CACHE_tm_RANK
  set rank = idx,
      overall_rate = convert(numeric(14,4),Blocks*268435.456/DateDiff(ss,First,DateAdd(dd,1,Last)))
go

print "::  Indexing on blocks for ranking acceleration"
go
create index tempindex on ${1}_CACHE_tm_RANK(blocks)
go

print "::  Correcting rank for tied teams"
go
update ${1}_CACHE_tm_RANK
set rank = (select min(btb.rank) from ${1}_CACHE_tm_RANK btb where btb.blocks = ${1}_CACHE_tm_RANK.blocks)
where (select count(btb.blocks) from ${1}_CACHE_tm_RANK btb where btb.blocks = ${1}_CACHE_tm_RANK.blocks) > 1
go

drop index ${1}_CACHE_tm_RANK.tempindex

print "::  Creating team indexes"
go
create index team on ${1}_CACHE_tm_RANK(team)
go

print "::  Calculating offset from previous ranking"
go
update ${1}_CACHE_tm_RANK
set Change = (select ${1}_CACHE_tm_RANK_old.rank from ${1}_CACHE_tm_RANK_old
              where ${1}_CACHE_tm_RANK_old.team = ${1}_CACHE_tm_RANK.team)-${1}_CACHE_tm_RANK.rank
go

grant select on ${1}_CACHE_tm_RANK  to public
go

