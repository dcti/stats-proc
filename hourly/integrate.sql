#!/usr/bin/sqsh -i
# vi: tw=100
# $Id: integrate.sql,v 1.21 2002/05/10 13:47:43 decibel Exp $
#
# Move data from the import_bcp table to the daytables
#
# Arguments:
#       Project Type (OGR, RC5, etc.)

set flushmessage on
go

/* Create a temp table that lets us know what project(s) we're working on here */
/* [BW] If this step wasn't here, it would be possible to run integrate without
**	importing any data, which could be useful if we can get data in
**	Email_Contrib_Today format but not import_bcp format.
*/
print "Updating LAST_STATS_DATE for all projects"
select p.PROJECT_ID,  min(TIME_STAMP) as STATS_DATE, isnull(sum(WORK_UNITS),0) as TOTAL_WORK
	into #Projects
	from import_bcp i, Projects p
	where p.PROJECT_ID *= i.PROJECT_ID
		and p.PROJECT_TYPE = ${1}
		and p.PROJECT_STATUS = 'O'
	group by p.PROJECT_ID
go

update #Projects
	set STATS_DATE = (select min(STATS_DATE) from #Projects)
	where STATS_DATE is null
go

/*
 Make sure we have rows in Project_statsrun for each project_id
 JCN: I'm not sure why we're doing this as a cursor... I'm guessing it's because of locking concerns
*/

declare CSRprojects cursor for 
	select PROJECT_ID
	from #Projects
go

declare @project_id tinyint
open CSRprojects

fetch CSRprojects into @project_id
while (@@sqlstatus = 0)
begin
	if not exists (select * from Project_statsrun where PROJECT_ID = @project_id)
	begin
		insert into Project_statsrun (PROJECT_ID) select @project_id
	end

	fetch CSRprojects into @project_id
end
go

deallocate cursor CSRprojects
go

/* Store the stats date here, instead of in every row of Email_Contrib_Today and Platform_Contrib_Today */
declare @stats_date smalldatetime
update Project_statsrun
	set LAST_HOURLY_DATE = p.STATS_DATE,
		LOGS_FOR_DAY = LOGS_FOR_DAY + 1,
		WORK_FOR_DAY = WORK_FOR_DAY + p.TOTAL_WORK
	from #Projects p
	where Project_statsrun.PROJECT_ID = p.PROJECT_ID
go

print "Rolling up data from import_bcp"
create table #import
(
	PROJECT_ID	tinyint		not NULL,
	EMAIL		varchar (64)	not NULL,
	WORK_UNITS	numeric(20, 0)	not NULL
)
go
insert #import (PROJECT_ID, EMAIL, WORK_UNITS)
	select i.PROJECT_ID, i.EMAIL, sum(i.WORK_UNITS)
	from import_bcp i, Project_statsrun p
	where i.PROJECT_ID = p.PROJECT_ID
		and i.TIME_STAMP = p.LAST_HOURLY_DATE
	group by i.PROJECT_ID, i.EMAIL
go

/*
**	Moved e-mail cleanup here, to aggregate the data more quickly
*/
print "Checking for bad emails"
go

/*
**	Make sure they don't have any leading spaces
*/
update #import
	set EMAIL = ltrim(EMAIL)
	where EMAIL <> ltrim(EMAIL)
/*
** TODO: Strip out any text in <brackets>, per the RFC for email addresses
*/

/*
**	Correct some common garbage combinations
**	It's going to table-scan anyway, so we might as well
**	do all the tests we can
*/
update #import
	set EMAIL = 'rc5-bad@distributed.net'
	where EMAIL not like '%@%'	/* Must have @ */
		or EMAIL like '%[ <>]%'	/* Must not contain space, &gt or &lt */
		or EMAIL like '@%'	/* Must not begin with @ */
		or EMAIL like '%@'	/* Must not end with @ */
/*
**	Only one @.  Must test after we know they have at least one @
*/
update #import
	set EMAIL = 'rc5-bad@distributed.net'
	where substring(EMAIL, charindex('@', EMAIL) + 1, 64) like '%@%'
go
/* [BW] Processing all projects at once is a Bad Thing (TM) because we may not have
**	the same number of logs for all projects, and even if that doesn't cause a
**	problem, it would make it harder to run hourly for one the same time as
**	daily for another, if we need to.  I need to think about this more, but
**	even if we do it all in one fell swoop, there might be performance benefits
**	to stepping through each project in a cursor.
*/


/*
Assign project id
	Insert in holding table, or set bit or date field in STATS_Participant
	seqn, id, request_source, date_requested, date_sent
daytable contains id instead of EMAIL
password assign automatic
*/
create table #Email_Contrib_Today
(
	PROJECT_ID	tinyint		not NULL,
	EMAIL		varchar (64)	not NULL,
	ID		int		not NULL,
	WORK_UNITS	numeric(20, 0)	not NULL
)
create table #dayemails
(
	ID		numeric(10, 0)	identity,
	EMAIL		varchar(64)	not NULL
)
go
/* Put EMAIL data into temp table */
print "Final roll-up by email"
/* First, put the latest set of logs in */
insert #Email_Contrib_Today (PROJECT_ID, EMAIL, ID, WORK_UNITS)
	select PROJECT_ID, EMAIL, 0, sum(WORK_UNITS)
	from #import
	group by PROJECT_ID, EMAIL
go

/* Assign ID's for everyone who has an ID */
print "Assigning IDs"
-- NOTE: At some point we might want to set TEAM_ID and CREDIT_ID here as well
-- [BW] No, because it shouldn't take effect until the end of day.  No sense
--	doing it 24 times when once will do.  The same would apply here, except
--	that it's really, really nice to be able to show new participants hourly
update #Email_Contrib_Today
	set ID = sp.ID
	from STATS_Participant sp
	where sp.EMAIL = #Email_Contrib_Today.EMAIL
go

/* Add new participants to STATS_Participant */
print "Adding new participants"

/* First, copy all new participants to #dayemails to do the identity assignment */
insert #dayemails (EMAIL)
	select distinct EMAIL
	from #Email_Contrib_Today
	where ID = 0
	order by EMAIL
go

/* Figure out where to start assigning at */
declare @idoffset int
select @idoffset = max(id)
	from STATS_Participant
-- select @idoffset as current_max_ID

-- [BW] If we switch to retire_to = id as the normal condition,
--	this insert should insert (id, EMAIL, retire_to)
--	from ID + @idoffset, EMAIL, ID + @idoffset
insert into STATS_participant (ID, EMAIL)
	select ID + @idoffset, EMAIL
	from #dayemails

/* Assign the new IDs to the new participants */
-- JCN: where Email_Contrib_Today might be faster here...
update #Email_Contrib_Today
	set ID = sp.ID
	from STATS_Participant sp, #dayemails de
	where sp.EMAIL = #Email_Contrib_Today.EMAIL
		and sp.EMAIL = de.EMAIL
		and de.EMAIL = #Email_Contrib_Today.EMAIL

/* Now, add the stuff from the previous hourly runs */
print "Copying Email_Contrib_Today into temptable"

-- JCN: Removed sum() and group by.. data in Email_Contrib_Today should be summed already
insert #Email_Contrib_Today (PROJECT_ID, EMAIL, ID, WORK_UNITS)
	select ect.PROJECT_ID, "", ect.ID, ect.WORK_UNITS
	from Email_Contrib_Today ect, #Projects p
	where ect.PROJECT_ID = p.PROJECT_ID
go

/* Finally, remove the previous records from Email_Contrib_Today and insert the new
** data from the temp table. (It seems there should be a better way to do this...)
*/
print "Moving data from temptable to Email_Contrib_Today"
begin transaction
delete Email_Contrib_Today
	from #Projects p
	where Email_Contrib_Today.PROJECT_ID = p.PROJECT_ID

/*
** dy_appendday.sql depends on setting CREDIT_ID = ID
*/
insert into Email_Contrib_Today (PROJECT_ID, WORK_UNITS, ID, TEAM_ID, CREDIT_ID)
	select PROJECT_ID, sum(WORK_UNITS), ID, 0, ID
	from #Email_Contrib_Today
	group by PROJECT_ID, ID
commit transaction

drop table #Email_Contrib_Today
go

/* Do the exact same stuff for Platform_Contrib_Today */
print "Rolling up platform contributions"
go
create table #Platform_Contrib_Today
(
	PROJECT_ID	tinyint		not NULL,
	CPU		smallint	not NULL,
	OS		smallint	not NULL,
	VER		smallint	not NULL,
	WORK_UNITS	numeric(20, 0)	not NULL
)
go
insert #Platform_Contrib_Today (PROJECT_ID, CPU, OS, VER, WORK_UNITS)
	select i.PROJECT_ID, i.CPU, i.OS, i.VER, sum(i.WORK_UNITS)
	from import_bcp i, Project_statsrun p
	where i.PROJECT_ID = p.PROJECT_ID
		and i.TIME_STAMP = p.LAST_HOURLY_DATE
	group by i.PROJECT_ID, i.CPU, i.OS, i.VER

insert #Platform_Contrib_Today (PROJECT_ID, CPU, OS, VER, WORK_UNITS)
	select pct.PROJECT_ID, pct.CPU, pct.OS, pct.VER, pct.WORK_UNITS
	from Platform_Contrib_Today pct, #Projects p
	where pct.PROJECT_ID = p.PROJECT_ID 
-- Removed by JN: the data in PCT should already be summed.
--	group by PROJECT_ID, CPU, OS, VER
go

print "Moving data from temptable to Platform_Contrib_Today"
begin transaction
delete Platform_Contrib_Today
	from #Projects p
	where Platform_Contrib_Today.PROJECT_ID = p.PROJECT_ID

insert Platform_Contrib_Today (PROJECT_ID, CPU, OS, VER, WORK_UNITS)
	select PROJECT_ID, CPU, OS, VER, sum(WORK_UNITS)
	from #Platform_Contrib_Today
	group by PROJECT_ID, CPU, OS, VER
commit transaction

drop table #Platform_Contrib_Today
go

print "Clearing import table"

/*
 By doing the delete this way, we ensure that we'll throw an error if there are any rows in
 import_bcp from projects we didn't know about
*/
print "Total rows in import table:"
delete import_bcp
	from Project_statsrun p
	where import_bcp.PROJECT_ID = p.PROJECT_ID
		and import_bcp.TIME_STAMP = p.LAST_HOURLY_DATE

/* This line produces the number of rows imported for logging. The print is for the benefit of hourly.pl */
select @@rowcount
go -f -h
