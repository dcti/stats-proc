#!/usr/bin/sqsh -i
#
# $Id: integrate.sql,v 1.3 2000/06/25 22:01:10 decibel Exp $
#
# Move data from the import_bcp table to the daytables
#
# Arguments:
#       PROJECT_ID

/*
**	Moved e-mail cleanup here, to aggregate the data more quickly
*/

/*
**	Make sure they don't have any leading spaces
*/
update import_bcp
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
update import_bcp
	set EMAIL = 'rc5-bad@distributed.net'
	where EMAIL not like '%@%'	/* Must have @ */
		or EMAIL like '%[ <>]%'	/* Must not contain space, &gt or &lt */
		or EMAIL like '@%'	/* Must not begin with @ */
		or EMAIL like '%@'	/* Must not end with @ */

/*
**	Only one @.  Must test after we know they have at least one @
*/
update import_bcp
	set EMAIL = 'rc5-bad@distributed.net'
	where substring(EMAIL, charindex('@', EMAIL) + 1, 64) like '%@%'
go

/* Store the stats date here, instead of in every row of Email_Contrib_Today and Platform_Contrib_Today */
declare @stats_date smalldatetime
select @stats_date = max(TIME_STAMP)
	from import_bcp
update Projects
	set LAST_STATS_DATE = @stats_date
	where PROJECT_ID = ${1}
go

/*
Assign contest id
	Insert in holding table, or set bit or date field in STATS_Participant
	seqn, id, request_source, date_requested, date_sent
daytable contains id instead of EMAIL
password assign automatic
*/
create table #Email_Contrib_Today
(
	EMAIL varchar (64) NULL,
	WORK_UNITS numeric(20, 0) NULL
)
go
/* Put EMAIL data into temp table */
/* First, put the latest set of logs in */
insert #Email_Contrib_Today (EMAIL, WORK_UNITS)
	select EMAIL, sum(WORK_UNITS)
	from import_bcp
	group by EMAIL

/* Now, add the stuff from the previous hourly runs */
insert #Email_Contrib_Today (EMAIL, WORK_UNITS)
	select EMAIL, sum(WORK_UNITS)
	from Email_Contrib_Today
	where PROJECT_ID = ${1}

/* Finally, remove the previous records from Email_Contrib_Today and insert the new
** data from the temp table. (It seems there should be a better way to do this...)
*/
begin transaction
delete Email_Contrib_Today
	where PROJECT_ID = ${1}

insert into Email_Contrib_Today (PROJECT_ID, EMAIL, WORK_UNITS, ID, TEAM_ID, CREDIT_ID)
	select ${1}, EMAIL, sum(WORK_UNITS), 0, 0, 0
	from #Email_Contrib_Today
	group by EMAIL
commit transaction

drop table #Email_Contrib_Today
go

/* Do the exact same stuff for Platform_Contrib_Today */
create table #Platform_Contrib_Today
(
	CPU smallint not NULL,
	OS smallint not NULL,
	VER smallint not NULL,
	WORK_UNITS numeric(20, 0) not NULL
)
go
insert #Platform_Contrib_Today (CPU, OS, VER, WORK_UNITS)
	select CPU, OS, VER, sum(WORK_UNITS)
	from import_bcp
	group by CPU, OS, VER

insert #Platform_Contrib_Today (CPU, OS, VER, WORK_UNITS)
	select CPU, OS, VER, sum(WORK_UNITS)
	from Platform_Contrib_Today
	where PROJECT_ID = ${1}
	group by CPU, OS, VER

begin transaction
delete Platform_Contrib_Today
	where PROJECT_ID = ${1}

insert Platform_Contrib_Today (PROJECT_ID, CPU, OS, VER, WORK_UNITS)
	select ${1}, CPU, OS, VER, sum(WORK_UNITS)
	from #Platform_Contrib_Today
	group by CPU, OS, VER
commit transaction

drop table #Platform_Contrib_Today
go
delete import_bcp
	where 1 = 1

/* This line produces the number of rows imported for logging */
select @@rowcount
go -f -h
