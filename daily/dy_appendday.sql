#!/usr/bin/sqsh -i
#
# $Id: dy_appendday.sql,v 1.13 2000/11/07 18:52:30 decibel Exp $
#
# Appends the data from the daytables into the main tables
#
# Arguments:
#       PROJECT_ID

print "!! Appending day's activity to master tables"
go

print "::  Assigning CREDIT_ID and TEAM in Email_Contrib_Today"
go
/*
** When team-joins are handled as requests instead of live updates,
** the TEAM update will be handled from the requests table instead.
**
** CREDIT_ID holds RETIRE_TO or ID.  Not unique, but guaranteed to
** be the ID that should get credit for this work.
*/

declare @stats_date smalldatetime
select @stats_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}

update Email_Contrib_Today
	set CREDIT_ID = (abs(sign(sp.RETIRE_TO)) * sp.RETIRE_TO) + ((1 - abs(sign(sp.RETIRE_TO))) * sp.ID)
	from STATS_Participant sp
	where sp.ID = Email_Contrib_Today.ID
		and PROJECT_ID = ${1}

update Email_Contrib_Today
	set TEAM_ID = sp.TEAM_ID
	from Team_Joins tj
	where tj.ID = Email_Contrib_Today.CREDIT_ID
		and tj.join_date <= @stats_date
		and (tj.last_date = null or tj.last_date >= @stats_date)
		and PROJECT_ID = ${1}
--create unique clustered index iID on Email_Contrib_Today(PROJECT_ID,ID)
--create index iTEAM_ID on Email_Contrib_Today(PROJECT_ID,TEAM_ID)
--go

print "::  Appending into Email_Contrib"
go
declare @proj_date smalldatetime
select @proj_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}

insert into Email_Contrib (DATE, PROJECT_ID, ID, TEAM_ID, WORK_UNITS)
	select @proj_date, ${1}, ID, TEAM_ID, d.WORK_UNITS
	from Email_Contrib_Today d
	where d.PROJECT_ID = ${1}
	/* Group by is unnecessary, data is already summarized */
go

print ":: Appending into Platform_Contrib"
go
declare @proj_date smalldatetime
select @proj_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}

insert into Platform_Contrib (DATE, PROJECT_ID, CPU, OS, VER, WORK_UNITS)
	select @proj_date, ${1}, CPU, OS, VER, WORK_UNITS
	from Platform_Contrib_Today
	where PROJECT_ID = ${1}
	/* Group by is unnecessary, data is already summarized */
go

print ":: Assigning old work to current team"
go

-- This query will only get joins to teams (not to team 0) that have
-- taken place on the day that we're running stats for.
declare @proj_date smalldatetime
select @proj_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}

select id, team_id
	into #newjoins
	from Team_Joins
	where JOIN_DATE = @proj_date
		and (LAST_DATE = NULL or LAST_DATE >= @proj_date)
go

-- Dont forget to check for any retired emails that have blocks on team 0
declare ids cursor for
	select distinct sp.id, nj.team_id
	from STATS_Participant sp, #newjoins nj
	where sp.id = nj.id
		or (sp.retire_to = nj.id and sp.retire_to > 0)
go

declare @id int, @team_id int
declare @totalids int, @idrows int, @totalrows int
select @totalids = 0, @totalrows = 0
open ids
fetch ids into @id, @team_id

while (@@sqlstatus = 0)
begin
	update Email_Contrib set Email_Contrib.team = @team_id
		where Email_Contrib.ID = @id
			and Email_Contrib.PROJECT_ID = ${1}
			and Email_Contrib.TEAM_ID = 0

	select @totalids = @totalids + 1, @idrows = @@rowcount, @totalrows = @totalrows + @@rowcount
	print "  %1! rows processed for ID %2!, TEAM_ID %3!", @idrows, @id, @team_id

	fetch ids into @id, @team_id
end

if (@@sqlstatus = 1)
	print "ERROR! Cursor returned an error"

close ids
deallocate cursor ids
print "%1! IDs processed; %2! rows total", @totalids, @totalrows
go -f
