/*
# vi: tw=100
# $Id: integrate.sql,v 1.28.2.13 2003/04/07 02:34:09 decibel Exp $
#
# Move data from the import_bcp table to the daytables
#
# Arguments:
#       ProjectType (OGR, RC5, etc.)
#       HourNumber
*/

\set ON_ERROR_STOP 1

/* Create a temp table that lets us know what project(s) we're working on here */
/* [BW] If this step wasn't here, it would be possible to run integrate without
**	importing any data, which could be useful if we can get data in
**	Email_Contrib_Today format but not import_bcp format.
*/
\echo Updating LAST_STATS_DATE for :ProjectType
select p.PROJECT_ID,  min(TIME_STAMP) as STATS_DATE, coalesce(sum(WORK_UNITS),0) as TOTAL_WORK,
        count(*) as TOTAL_ROWS
	into TEMP TEMP_Projects
	from import_bcp i RIGHT JOIN Projects p ON p.PROJECT_ID = i.PROJECT_ID
	where lower(p.PROJECT_TYPE) = lower(:ProjectType)
		and p.STATUS = 'O'
	group by p.PROJECT_ID
;
--go

update TEMP_Projects
	set STATS_DATE = (select min(STATS_DATE) from TEMP_Projects)
	where STATS_DATE is null
;
--go

/*
 Make sure we have rows in Project_statsrun for each project_id
 JCN: I'm not sure why we're doing this as a cursor... I'm guessing it's because of locking concerns

declare CSRprojects cursor for 
	select PROJECT_ID
	from #Projects
--go

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
--go

deallocate cursor CSRprojects
--go
*/

insert into Project_statsrun (PROJECT_ID)
    select PROJECT_ID
        from TEMP_Projects p
        where not exists (select 1 from Project_statsrun where PROJECT_ID = p.PROJECT_ID)
;

/* Store the stats date here, instead of in every row of Email_Contrib_Today and Platform_Contrib_Today */
update Project_statsrun
	set LAST_HOURLY_DATE = coalesce(p.STATS_DATE, LAST_HOURLY_DATE),
		LOGS_FOR_DAY = LOGS_FOR_DAY + 1,
		WORK_FOR_DAY = WORK_FOR_DAY + p.TOTAL_WORK
	from TEMP_Projects p
	where Project_statsrun.PROJECT_ID = p.PROJECT_ID
;
--go

\echo Rolling up data from import_bcp
create TEMP table TEMP_import
(
	PROJECT_ID	smallint		not NULL,
	EMAIL		varchar (64)	not NULL,
	WORK_UNITS	numeric(20, 0)	not NULL
);
--go
/* Subselect is probably better than multiply inside the sum, which is the only other alternative. You *don't*
   want to try and multiply outside the sum, it won't do what we want at all. */
insert into TEMP_import (PROJECT_ID, EMAIL, WORK_UNITS)
	select i.PROJECT_ID, i.EMAIL, sum(i.WORK_UNITS) * (select WORK_UNIT_IMPORT_MULTIPLIER
								from Projects p
								where p.PROJECT_ID = i.PROJECT_ID
								)
	from import_bcp i, Project_statsrun ps
	where i.PROJECT_ID = ps.PROJECT_ID
		and i.TIME_STAMP = ps.LAST_HOURLY_DATE
	group by i.PROJECT_ID, i.EMAIL
;
--go

/*
**	Moved e-mail cleanup here, to aggregate the data more quickly
*/
\echo Checking for bad emails
--go

/*
**	Make sure they don't have any leading spaces
*/
update TEMP_import
	set EMAIL = ltrim(EMAIL)
	where EMAIL <> ltrim(EMAIL)
;
/*
** TODO: Strip out any text in <brackets>, per the RFC for email addresses
*/

/*
**	Correct some common garbage combinations
**	It's --going to table-scan anyway, so we might as well
**	do all the tests we can
*/
update TEMP_import
	set EMAIL = 'rc5-bad@distributed.net'
	where EMAIL not like '%@%'	/* Must have @ */
		or EMAIL like '%[ <>]%'	/* Must not contain space, &gt or &lt */
		or EMAIL like '@%'	/* Must not begin with @ */
		or EMAIL like '%@'	/* Must not end with @ */
;
/*
**	Only one @.  Must test after we know they have at least one @
*/
update TEMP_import
	set EMAIL = 'rc5-bad@distributed.net'
	where EMAIL like '%@%@%'
;
--go
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
create TEMP table TEMP_Email_Contrib_Today
(
	PROJECT_ID	smallint		not NULL,
	EMAIL		varchar (64)	not NULL,
	ID		int		not NULL,
	WORK_UNITS	numeric(20, 0)	not NULL
)
;
create temporary sequence Email;
create TEMP table TEMP_dayemails
(
	ID		    int	        not NULL DEFAULT nextval('Email'),
	EMAIL		varchar(64)	not NULL
)
;
--go
/* Put EMAIL data into temp table */
\echo Final roll-up by email
/* First, put the latest set of logs in */
insert into TEMP_Email_Contrib_Today (PROJECT_ID, EMAIL, ID, WORK_UNITS)
	select PROJECT_ID, EMAIL, 0, sum(WORK_UNITS)
	from TEMP_import
	group by PROJECT_ID, EMAIL
;
--go

/* Assign ID's for everyone who has an ID */
\echo Assigning IDs
-- NOTE: At some point we might want to set TEAM_ID and CREDIT_ID here as well
-- [BW] No, because it shouldn't take effect until the end of day.  No sense
--	doing it 24 times when once will do.  The same would apply here, except
--	that it's really, really nice to be able to show new participants hourly
update TEMP_Email_Contrib_Today
	set ID = sp.ID
	from STATS_Participant sp
	where sp.EMAIL = TEMP_Email_Contrib_Today.EMAIL
;
--go

/* Add new participants to STATS_Participant */
\echo Adding new participants

/* First, copy all new participants to TEMP_dayemails to do the identity assignment */
insert into TEMP_dayemails (EMAIL)
	select distinct EMAIL
	from TEMP_Email_Contrib_Today
	where ID = 0
	order by EMAIL
;
--go

/* Figure out where to start assigning at */

-- [BW] If we switch to retire_to = id as the normal condition,
--	this insert should insert (id, EMAIL, retire_to)
--	from ID + @idoffset, EMAIL, ID + @idoffset
insert into STATS_participant (ID, EMAIL)
	select ID + (select max(id) from STATS_Participant), EMAIL
	from TEMP_dayemails
;

/* Assign the new IDs to the new participants */
-- JCN: where Email_Contrib_Today might be faster here...
update TEMP_Email_Contrib_Today
	set ID = sp.ID
	from STATS_Participant sp, TEMP_dayemails de
	where sp.EMAIL = TEMP_Email_Contrib_Today.EMAIL
		and sp.EMAIL = de.EMAIL
		and de.EMAIL = TEMP_Email_Contrib_Today.EMAIL
;

/* Now, add the stuff from the previous hourly runs */
\echo Copying Email_Contrib_Today into temptable

-- JCN: Removed sum() and group by.. data in Email_Contrib_Today should be summed already
insert into TEMP_Email_Contrib_Today (PROJECT_ID, EMAIL, ID, WORK_UNITS)
	select ect.PROJECT_ID, '', ect.ID, ect.WORK_UNITS
	from Email_Contrib_Today ect, TEMP_Projects p
	where ect.PROJECT_ID = p.PROJECT_ID
;
--go

/* Finally, remove the previous records from Email_Contrib_Today and insert the new
** data from the temp table. (It seems there should be a better way to do this...)
*/
\echo Moving data from temptable to Email_Contrib_Today
begin;
delete from Email_Contrib_Today
	where PROJECT_ID IN (SELECT project_id
                                                FROM TEMP_Projects p
                                            )
;

/*
** dy_appendday.sql depends on setting CREDIT_ID = ID
*/
insert into Email_Contrib_Today (PROJECT_ID, WORK_UNITS, ID, TEAM_ID, CREDIT_ID)
	select PROJECT_ID, sum(WORK_UNITS), ID, 0, ID
	from TEMP_Email_Contrib_Today
	group by PROJECT_ID, ID
;
commit;

drop table TEMP_Email_Contrib_Today
;
--go

/* Do the exact same stuff for Platform_Contrib_Today */
\echo Rolling up platform contributions
--go

/* First, make sure we don't have any crap in the logs */
update import_bcp set CPU = 0
	where CPU > (select max(CPU)+20 from STATS_cpu)
;
update import_bcp set OS = 0
	where OS > (select max(OS)+20 from STATS_os)
;
--go

create TEMP table TEMP_Platform_Contrib_Today
(
	PROJECT_ID	smallint		not NULL,
	CPU		smallint	not NULL,
	OS		smallint	not NULL,
	VER		smallint	not NULL,
	WORK_UNITS	numeric(20, 0)	not NULL
)
;
--go
/* Subselect is probably better than multiply inside the sum, which is the only other alternative. You *don't*
   want to try and multiply outside the sum, it won't do what we want at all. */
insert into TEMP_Platform_Contrib_Today (PROJECT_ID, CPU, OS, VER, WORK_UNITS)
	select i.PROJECT_ID, i.CPU, i.OS, i.VER, sum(i.WORK_UNITS) * (select WORK_UNIT_IMPORT_MULTIPLIER
										from Projects p
										where p.PROJECT_ID = i.PROJECT_ID
									)

	from import_bcp i, Project_statsrun p
	where i.PROJECT_ID = p.PROJECT_ID
		and i.TIME_STAMP = p.LAST_HOURLY_DATE
	group by i.PROJECT_ID, i.CPU, i.OS, i.VER
;

insert into TEMP_Platform_Contrib_Today (PROJECT_ID, CPU, OS, VER, WORK_UNITS)
	select pct.PROJECT_ID, pct.CPU, pct.OS, pct.VER, pct.WORK_UNITS
	from Platform_Contrib_Today pct, TEMP_Projects p
	where pct.PROJECT_ID = p.PROJECT_ID 
-- Removed by JN: the data in PCT should already be summed.
--	group by PROJECT_ID, CPU, OS, VER
;
--go

\echo Moving data from temptable to Platform_Contrib_Today
begin;
delete from Platform_Contrib_Today
	where PROJECT_ID IN (SELECT project_id
                                                FROM TEMP_Projects p
                                            )
;

insert into Platform_Contrib_Today (PROJECT_ID, CPU, OS, VER, WORK_UNITS)
	select PROJECT_ID, CPU, OS, VER, sum(WORK_UNITS)
	from TEMP_Platform_Contrib_Today
	group by PROJECT_ID, CPU, OS, VER
;
commit;

drop table TEMP_Platform_Contrib_Today
;
--go

/*
  Store info in Log_Info table
*/

\echo Adding data to Log_Info
insert into Log_Info(PROJECT_ID, LOG_TIMESTAMP, WORK_UNITS, LINES, ERROR)
    select PROJECT_ID, STATS_DATE + (text(:HourNumber) || ' hours')::interval, TOTAL_WORK, total_rows ,0::bit
    from TEMP_Projects
;

\echo Clearing import table

/*
 By doing the delete this way, we ensure that we'll throw an error if there are any rows in
 import_bcp from projects we didn't know about
*/

delete from import_bcp
	where (project_id, time_stamp) IN (SELECT project_id, last_hourly_date
                                                FROM TEMP_Projects p
                                            )
;
