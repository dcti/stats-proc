#!/usr/bin/sqsh -i
#
# $Id: dy_appendday.sql,v 1.21 2002/10/07 15:12:05 decibel Exp $
#
# Appends the data from the daytables into the main tables
#
# Arguments:
#       PROJECT_ID

set flushmessage on
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
select @stats_date = LAST_HOURLY_DATE
	from Project_statsrun
	where PROJECT_ID = ${1}

update Email_Contrib_Today
	set CREDIT_ID = sp.RETIRE_TO
	from STATS_Participant sp
	where sp.ID = Email_Contrib_Today.ID
		and sp.RETIRE_TO >= 1
		and (sp.RETIRE_DATE <= @stats_date or sp.RETIRE_DATE is NULL)
		and not exists (select *
					from STATS_Participant_Blocked spb
					where spb.ID = Email_Contrib_Today.ID
						and spb.ID = sp.ID
				)
		and PROJECT_ID = ${1}

update Email_Contrib_Today
	set TEAM_ID = tj.TEAM_ID
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
select @proj_date = LAST_HOURLY_DATE
	from Project_statsrun
	where PROJECT_ID = ${1}

insert into Email_Contrib (DATE, PROJECT_ID, ID, TEAM_ID, WORK_UNITS)
	select @proj_date, ${1}, ID, TEAM_ID, d.WORK_UNITS
	from Email_Contrib_Today d
	where d.PROJECT_ID = ${1}
	/* Group by is unnecessary, data is already summarized */

update Email_Contrib_Last_Update
	set LAST_DATE = @proj_date
	where PROJECT_ID = ${1}
go

print ":: Appending into Platform_Contrib"
go
declare @proj_date smalldatetime
select @proj_date = LAST_HOURLY_DATE
	from Project_statsrun
	where PROJECT_ID = ${1}

insert into Platform_Contrib (DATE, PROJECT_ID, CPU, OS, VER, WORK_UNITS)
	select @proj_date, ${1}, CPU, OS, VER, WORK_UNITS
	from Platform_Contrib_Today
	where PROJECT_ID = ${1}
	/* Group by is unnecessary, data is already summarized */

update Platform_Contrib_Last_Update
	set LAST_DATE = @proj_date
	where PROJECT_ID = ${1}
go
