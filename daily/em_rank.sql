#!/usr/bin/sqsh -i
/*
#
# $Id: em_rank.sql,v 1.15 2002/03/28 18:28:48 bwilson Exp $
#
# Does the participant ranking (overall)
#
# Arguments:
#       Project_id
*/

use stats
set rowcount 0
set flushmessage on
go
print '!! Begin e-mail ranking'
--print ' Drop indexes on Email_Rank'
--go
--drop index Email_Rank.iDAY_RANK
--drop index Email_Rank.iOVERALL_RANK
go

print ' Create rank table for today'
go
create table #rank_today
(
	IDENT numeric(10, 0) identity,
	ID int,
	WORK_UNITS numeric(20, 0),
	RANK int
)
go
insert #rank_today (ID, WORK_UNITS, RANK)
	select ID, WORK_TODAY, -1
	from Email_Rank
	where PROJECT_ID = ${1}
	order by WORK_TODAY desc, ID desc

update #rank_today
	set RANK = (select min(IDENT) from #rank_today rt2 where rt2.WORK_UNITS = #rank_today.WORK_UNITS)
	where 1 = 1

create clustered index iID on #rank_today(ID)
go

print ' Create rank table for overall'
create table #rank_overall
(
	IDENT numeric(10, 0) identity,
	ID int,
	WORK_UNITS numeric(20, 0),
	RANK int
)
go
insert #rank_overall (ID, WORK_UNITS, RANK)
	select ID, WORK_TOTAL, -1
	from Email_Rank
	where PROJECT_ID = ${1}
	order by WORK_TOTAL desc, ID desc

update #rank_overall
	set RANK = (select min(IDENT) from #rank_overall ro2 where ro2.WORK_UNITS = #rank_overall.WORK_UNITS)
	where 1 = 1
	
create clustered index iID on #rank_overall(ID)
go

print ' Update Email_Rank with new rankings'
update Email_Rank
	set OVERALL_RANK = o.rank, 
/* TODO These two new fields need to be added to Email_Rank so we can fix the bug
	preventing access to any but the top 100 with a given rank.
		OVERALL_POS = o.IDENT,
		DAY_POS = isnull(d.IDENT, Email_Rank.DAY_POS),
*/
		DAY_RANK = isnull(d.rank, Email_Rank.DAY_RANK)
	from #rank_overall o, #rank_today d
	where Email_Rank.ID *= d.ID
		and Email_Rank.ID = o.ID
		and Email_Rank.PROJECT_ID = ${1}
go
drop table #rank_today
drop table #rank_overall
go

print ' set previous rank = current rank for new participants'
go
/* TODO This field should be in Project table, eliminate Project_statsrun */
/* TODO Error: this will only assign prev=curr for those who submitted their first block during the 00:00 hour */
declare @stats_date smalldatetime
select @stats_date = LAST_HOURLY_DATE
	from Project_statsrun
	where PROJECT_ID = ${1}

update Email_Rank
	set DAY_RANK_PREVIOUS = DAY_RANK,
		OVERALL_RANK_PREVIOUS = OVERALL_RANK
	where PROJECT_ID = ${1}
		and FIRST_DATE = @stats_date
go

--print ' update statistics'
--go
--update statistics Email_Rank
--go
--print ' Rebuild indexes on Email_Rank'
--create index iDAY_RANK on Email_Rank(PROJECT_ID, DAY_RANK)
--create index iOVERALL_RANK on Email_Rank(PROJECT_ID, OVERALL_RANK)
--go
