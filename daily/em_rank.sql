/*
#!/usr/bin/sqsh -i
#
# $Id: em_rank.sql,v 1.4 2000/04/20 13:11:37 bwilson Exp $
#
# Does the participant ranking (overall)
#
# Arguments:
#       Project_id
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
go
delete Email_Rank
	from STATS_Participant
	where STATS_Participant.ID = Email_Rank.ID
		and (STATS_Participant.RETIRE_TO >= 1
			or STATS_Participant.listmode >= 10)
		and PROJECT_ID = ${1}
go
print ' Remove or move "today" info '
update Email_Rank
	set DAY_RANK_PREVIOUS = DAY_RANK,
		DAY_RANK = 1000000,
		OVERALL_RANK_PREVIOUS = OVERALL_RANK,
		OVERALL_RANK = 1000000,
		WORK_TODAY = 0
	where Email_Rank.PROJECT_ID = ${1}
go

print ' Now insert new participants'
go

declare @stats_date smalldatetime
select @stats_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}
select @stats_date = isnull(@stats_date, getdate())

insert Email_Rank (PROJECT_ID, ID, FIRST_DATE, LAST_DATE, WORK_TODAY, WORK_TOTAL, DAY_RANK, DAY_RANK_PREVIOUS,
		OVERALL_RANK, OVERALL_RANK_PREVIOUS)
	select distinct ${1}, ect.CREDIT_ID, @stats_date, @stats_date, 0, 0, 1000000, 1000000, 1000000, 1000000
	from Email_Contrib_Today ect, STATS_Participant sp
	where ect.CREDIT_ID = sp.ID
		and sp.RETIRE_TO = 0
		and sp.LISTMODE < 10
		and ect.CREDIT_ID not in (select ID from Email_Rank)
		and ect.PROJECT_ID = ${1}

/*
** TODO: Assign earlier date if others are retired into
** Should not attempt to do it here.  It should happen one-up during a retire.
*/

go
print 'Populate work'
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
	where PROJECT_ID = ${1}

insert #retired_work
	select CREDIT_ID, sum(ect.WORK_UNITS)
	from Email_Contrib_Today ect
	where ect.PROJECT_ID = ${1}
	group by ect.CREDIT_ID

update Email_Rank
	set WORK_TODAY = rw.WORK_TODAY,
		WORK_TOTAL = WORK_TOTAL + rw.WORK_TODAY,
		LAST_DATE = @stats_date
	from #retired_work rw
	where rw.ID = Email_Rank.ID
		and Email_Rank.PROJECT_ID = ${1}
go
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
	from Email_Rank
	where PROJECT_ID = ${1}
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

update Email_Rank
	set DAY_RANK = #rank_tie.rank
	from #rank_tie, #rank_assign
	where #rank_tie.WORK_UNITS = #rank_assign.WORK_UNITS
		and Email_Rank.ID = #rank_assign.ID
		and Email_Rank.PROJECT_ID = ${1}

drop table #rank_assign
drop table #rank_tie
go
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
	where PROJECT_ID = ${1}
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
		and Email_Rank.PROJECT_ID = ${1}
go
drop table #rank_assign
drop table #rank_tie

print ' update statistics'
go
update statistics Email_Rank
go
print ' Rebuild indexes on _Email_Rank'
create index iDAY_RANK on Email_Rank(PROJECT_ID, DAY_RANK)
create index iOVERALL_RANK on Email_Rank(PROJECT_ID, OVERALL_RANK)
go