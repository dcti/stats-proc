/*
#!/usr/bin/sqsh -i
#
# $Id: em_rank.sql,v 1.1 2000/04/11 14:25:02 bwilson Exp $
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
print ' Drop indexes on _Email_Rank'
go
drop index OGR_Email_Rank.iDAY_RANK
drop index OGR_Email_Rank.iOVERALL_RANK
go
print 'Remove retired or hidden participants'
delete OGR_Email_Rank
	from STATS_Participant
	where STATS_Participant.ID = OGR_Email_Rank.ID
		and (STATS_Participant.retire_to > 0
			or STATS_Participant.listmode >= 10)
go
print ' Remove or move "today" info '
update OGR_Email_Rank
	set DAY_RANK_PREVIOUS = DAY_RANK,
		DAY_RANK = 1000000,
		OVERALL_RANK_PREVIOUS = OVERALL_RANK,
		OVERALL_RANK = 1000000,
		WORK_TODAY = 0
	where 1 = 1
go
print ' Populate ID field in _Day_Master'
go
update OGR_Day_Master
	set ID = sp.ID
	from STATS_Participant sp
	where sp.EMAIL = OGR_Day_Master.EMAIL
		and OGR_Day_Master.ID = 0
go
create clustered index iID on OGR_Day_Master(ID)
go
print ' Now insert new participants '
go

declare @stats_date smalldatetime
select @stats_date = LAST_STATS_DATE
	from Projects
	where NAME = "OGR"
select @stats_date = isnull(@stats_date, getdate())

insert OGR_Email_Rank (ID, FIRST_DATE, LAST_DATE, WORK_TODAY, WORK_TOTAL, DAY_RANK, DAY_RANK_PREVIOUS,
		OVERALL_RANK, OVERALL_RANK_PREVIOUS)
	select sp.ID, @stats_date, @stats_date, 0, 0, 1000000, 1000000, 1000000, 1000000
	from OGR_Day_Master dm, STATS_Participant sp
	where dm.ID = sp.ID
		and sp.RETIRE_TO = 0
		and sp.LISTMODE < 10
		and dm.ID not in (select ID from OGR_Email_Rank)

/* TODO: Assign earlier date if others are retired into */
/* Will not attempt to do it here.  It should happen during a retire. */
go
print 'Populate direct work'
go
declare @stats_date smalldatetime
select @stats_date = LAST_STATS_DATE
	from Projects
	where NAME = "OGR"
select @stats_date = isnull(@stats_date, getdate())

update OGR_Email_Rank
	set WORK_TODAY = dm.SIZE,
		WORK_TOTAL = WORK_TOTAL + dm.SIZE,
		LAST_DATE = @stats_date
	from OGR_Day_Master dm, STATS_Participant sp
	where OGR_Email_Rank.ID = dm.ID
		and OGR_EMail_Rank.ID = sp.ID
		and dm.ID = sp.ID
		and sp.retire_to = 0

print 'Populate retired work'
go
create table #retired_work
(
	ID		int,
	WORK_TODAY	numeric(20, 0)
)
go
declare @stats_date smalldatetime
select @stats_date = LAST_STATS_DATE
	from Projects
	where NAME = 'OGR'

insert #retired_work
	select sp.RETIRE_TO, sum(dm.SIZE)
	from OGR_Day_Master dm, STATS_Participant sp
	where dm.EMAIL = sp.EMAIL
		and sp.RETIRE_TO > 0
	group by sp.RETIRE_TO

update OGR_Email_Rank
	set WORK_TODAY = OGR_Email_Rank.WORK_TODAY + rw.WORK_TODAY,
		WORK_TOTAL = WORK_TOTAL + rw.WORK_TODAY,
		LAST_DATE = @stats_date
	from #retired_work rw
	where rw.ID = OGR_Email_Rank.ID

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
insert #rank_assign (ID, WORK_UNITS)
	select ID, WORK_TODAY
	from OGR_Email_Rank
	order by WORK_TODAY desc, ID desc

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

update OGR_Email_Rank
	set DAY_RANK = #rank_tie.rank
	from #rank_tie, #rank_assign
	where #rank_tie.WORK_UNITS = #rank_assign.WORK_UNITS
		and OGR_Email_Rank.ID = #rank_assign.ID

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
	from OGR_Email_Rank
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

update OGR_Email_Rank
	set OVERALL_RANK = #rank_tie.rank
	from #rank_tie, #rank_assign
	where #rank_tie.WORK_UNITS = #rank_assign.WORK_UNITS
		and OGR_Email_Rank.ID = #rank_assign.ID

drop table #rank_assign
drop table #rank_tie

print ' update statistics'
go
update statistics OGR_Email_Rank
go
print ' Rebuild indexes on _Email_Rank'
drop index OGR_Email_Rank.iDAY_RANK
drop index OGR_Email_Rank.iOVERALL_RANK
go
