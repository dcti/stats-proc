/*
#!/usr/bin/sqsh -i
#
# $Id: em_rank.sql,v 1.2 2000/04/13 14:58:16 bwilson Exp $
#
# Does the participant ranking (overall)
#
# Arguments:
#       Project
*/

use stats
set rowcount 0
go
print '!! Begin e-mail ranking'
print ' Drop indexes on Email_Rank'
go
drop index Email_Rank.iDAY_RANK
drop index Email_Rank.iOVERALL_RANK
go
print 'Remove retired or hidden participants'
/* No project information because it's OK to remove them from all projects */
delete Email_Rank
	from STATS_Participant
	where STATS_Participant.ID = Email_Rank.ID
		and (STATS_Participant.retire_to > 0
			or STATS_Participant.listmode >= 10)
go
print ' Remove or move "today" info '
update Email_Rank
	set DAY_RANK_PREVIOUS = DAY_RANK,
		DAY_RANK = 1000000,
		OVERALL_RANK_PREVIOUS = OVERALL_RANK,
		OVERALL_RANK = 1000000,
		WORK_TODAY = 0
	from Projects
	where Email_Rank.PROJECT_ID = Projects.PROJECT_ID
		and Projects.NAME = "${1}"
go
print ' Populate ID field in Email_Contrib_Day'
go
update Email_Contrib_Day
	set ID = sp.ID
	from STATS_Participant sp, Projects p
	where sp.EMAIL = Email_Contrib_Day.EMAIL
		and Email_Contrib_Day.ID = 0
		and p.PROJECT_ID = Email_Contrib_Day.PROJECT_ID
		and p.NAME = "${1}"
go
create clustered index iID on Email_Contrib_Day(ID)
go
print ' Now insert new participants '
go

declare @stats_date smalldatetime,
	@proj_id tinyint
select @stats_date = LAST_STATS_DATE,
		@proj_id = PROJECT_ID
	from Projects
	where NAME = "${1}"
select @stats_date = isnull(@stats_date, getdate())

insert Email_Rank (PROJECT_ID, ID, FIRST_DATE, LAST_DATE, WORK_TODAY, WORK_TOTAL, DAY_RANK, DAY_RANK_PREVIOUS,
		OVERALL_RANK, OVERALL_RANK_PREVIOUS)
	select @proj_id, sp.ID, @stats_date, @stats_date, 0, 0, 1000000, 1000000, 1000000, 1000000
	from Email_Contrib_Day dm, STATS_Participant sp
	where dm.ID = sp.ID
		and sp.RETIRE_TO = 0
		and sp.LISTMODE < 10
		and dm.ID not in (select ID from Email_Rank)

/* TODO: Assign earlier date if others are retired into */
/* Will not attempt to do it here.  It should happen during a retire. */
go
print 'Populate direct work'
go
declare @stats_date smalldatetime,
	@proj_id tinyint
select @stats_date = LAST_STATS_DATE,
		@proj_id = PROJECT_ID
	from Projects
	where NAME = "${1}"
select @stats_date = isnull(@stats_date, getdate())

update Email_Rank
	set WORK_TODAY = dm.SIZE,
		WORK_TOTAL = WORK_TOTAL + dm.SIZE,
		LAST_DATE = @stats_date
	from Email_Contrib_Day dm, STATS_Participant sp
	where Email_Rank.ID = dm.ID
		and Email_Rank.ID = sp.ID
		and dm.ID = sp.ID
		and Email_Rank.PROJECT_ID = @proj_id
		and dm.PROJECT_ID = @proj_id
		and sp.retire_to = 0

print 'Populate retired work'
go
create table #retired_work
(
	ID		int,
	WORK_TODAY	numeric(20, 0)
)
go
declare @stats_date smalldatetime,
	@proj_id tinyint
select @stats_date = LAST_STATS_DATE,
		@proj_id = PROJECT_ID
	from Projects
	where NAME = 'OGR'

insert #retired_work
	select sp.RETIRE_TO, sum(dm.SIZE)
	from Email_Contrib_Day dm, STATS_Participant sp
	where dm.EMAIL = sp.EMAIL
		and sp.RETIRE_TO > 0
		and dm.PROJECT_ID = @proj_id
	group by sp.RETIRE_TO

update Email_Rank
	set WORK_TODAY = Email_Rank.WORK_TODAY + rw.WORK_TODAY,
		WORK_TOTAL = WORK_TOTAL + rw.WORK_TODAY,
		LAST_DATE = @stats_date
	from #retired_work rw
	where rw.ID = Email_Rank.ID
		and Email_Rank.PROJECT_ID = @proj_id

drop table #retired_work
go
print ' Rank all, today'
go
create table #rank_assign
(
	IDENT numeric(10, 0) identity,
	ID int,
	WORK_UNITS numeric(20, 0)
)
go
declare @proj_id tinyint
select @proj_id = PROJECT_ID
	from Projects
	where NAME = "${1}"

insert #rank_assign (ID, WORK_UNITS)
	select ID, WORK_TODAY
	from Email_Rank
	where PROJECT_ID = @proj_id
	order by WORK_TODAY desc, ID desc

create clustered index iWORK_UNITS on #rank_assign(WORK_UNITS)

create table #rank_tie
(
	WORK_UNITS numeric(20, 0),
	rank int
)
go
declare @proj_id tinyint
select @proj_id = PROJECT_ID
	from Projects
	where NAME = "${1}"

insert #rank_tie
	select WORK_UNITS, min(IDENT)
	from #rank_assign
	group by WORK_UNITS

update Email_Rank
	set DAY_RANK = #rank_tie.rank
	from #rank_tie, #rank_assign
	where #rank_tie.WORK_UNITS = #rank_assign.WORK_UNITS
		and Email_Rank.ID = #rank_assign.ID
		and Email_Rank.PROJECT_ID = @proj_id

drop table #rank_assign
drop table #rank_tie

print ' Rank all, overall'

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
	order by WORK_TOTAL desc, ID desc

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

update Email_Rank
	set OVERALL_RANK = #rank_tie.rank
	from #rank_tie, #rank_assign
	where #rank_tie.WORK_UNITS = #rank_assign.WORK_UNITS
		and Email_Rank.ID = #rank_assign.ID

drop table #rank_assign
drop table #rank_tie

print ' update statistics'
go
update statistics Email_Rank
go
print ' Rebuild indexes on _Email_Rank'
drop index Email_Rank.iDAY_RANK
drop index Email_Rank.iOVERALL_RANK
go
