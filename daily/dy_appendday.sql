#!/usr/bin/sqsh -i
#
# $Id: dy_appendday.sql,v 1.5 2000/04/13 14:58:16 bwilson Exp $
#
# Appends the data from the daytables into the main tables
#
# Arguments:
#       Project

print "!! Appending day's activity to master tables"
go

print "::  Appending into Email_Contrib"
go
declare @proj_id tinyint,
	@proj_date smalldatetime
select @proj_id = PROJECT_ID,
		@proj_date = LAST_STATS_DATE
	from Projects
	where NAME = "${1}"

insert into Email_Contrib (DATE, PROJECT_ID, ID, TEAM_ID, WORK_UNITS)
	select @proj_date, @proj_id, ID, TEAM, sum(d.WORK_UNITS)
	from Email_Contrib_Day d
	where d.PROJECT_ID = @proj_id
	/* Group by is unnecessary, data is already summarized */
go

print ":: Appending into Platform_Contrib"
go
declare @proj_id tinyint,
	@proj_date smalldatetime
select @proj_id = PROJECT_ID,
		@proj_date = LAST_STATS_DATE
	from Projects
	where NAME = "${1}"

insert into Platform_Contrib (DATE, PROJECT_ID, CPU, OS, VER, WORK_UNITS)
	select @proj_date, @proj_id, CPU, OS, VER, sum(WORK_UNITS)
	from Platform_Contrib_Day
	where PROJECT_ID = @proj_id
	/* Group by is unnecessary, data is already summarized */
go

