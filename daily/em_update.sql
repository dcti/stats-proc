#!/usr/bin/sqsh -i
/*
#
# $Id: em_update.sql,v 1.4 2002/04/10 16:49:05 decibel Exp $
#
# Updates the info in the Email_Rank table
#
# Arguments:
#       Project_id
*/

use stats
set rowcount 0
set flushmessage on
go
print '!! Begin e-mail ranking'
print ' Drop indexes on Email_Rank'
go
--drop index Email_Rank.iDAY_RANK
--drop index Email_Rank.iOVERALL_RANK
--go

print ' Remove or move "today" info '
declare @max_rank int
select @max_rank = count(*)+1 from STATS_Participant
select @max_rank as max_rank into #maxrank
update Email_Rank
	set DAY_RANK_PREVIOUS = DAY_RANK,
		DAY_RANK = @max_rank,
		OVERALL_RANK_PREVIOUS = OVERALL_RANK,
		OVERALL_RANK = @max_rank,
		WORK_TODAY = 0
	where Email_Rank.PROJECT_ID = ${1}
go

print ' Now insert new participants'
go

declare @stats_date smalldatetime
select @stats_date = LAST_HOURLY_DATE
	from Project_statsrun
	where PROJECT_ID = ${1}
-- select @stats_date = isnull(@stats_date, getdate())

declare @max_rank int
select @max_rank = max_rank from #maxrank
insert Email_Rank (PROJECT_ID, ID, FIRST_DATE, LAST_DATE, WORK_TODAY, WORK_TOTAL, DAY_RANK, DAY_RANK_PREVIOUS,
		OVERALL_RANK, OVERALL_RANK_PREVIOUS)
	select distinct ${1}, ect.CREDIT_ID, @stats_date, @stats_date, 0, 0, @max_rank, @max_rank, @max_rank, @max_rank
	from Email_Contrib_Today ect, STATS_Participant sp
	where ect.CREDIT_ID = sp.ID
		and (sp.RETIRE_TO = 0 or sp.RETIRE_DATE > @stats_date)
		and ect.CREDIT_ID not in (select ID from Email_Rank where PROJECT_ID=${1})
		and not exists (select *
					from STATS_Participant_Blocked spb
					where spb.ID = ect.CREDIT_ID
						and spb.ID = sp.ID
				)
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
select @stats_date = LAST_HOURLY_DATE
	from Project_statsrun
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
