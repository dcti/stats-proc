#!/usr/bin/sqsh -i
#
# $Id: dy_integrate.sql,v 1.7 2000/04/13 14:58:16 bwilson Exp $
#
# Move data from the ${1}_import table to the daytables
#
# Arguments:
#       Project

/*
**	Moved e-mail cleanup here, to aggregate the data more quickly
*/

/*
**	Make sure they don't have any leading spaces
*/
update ${1}_import
	set EMAIL = ltrim(EMAIL)
	where EMAIL <> ltrim(EMAIL)

/*
**	Correct some common garbage combinations
**	It's going to table-scan anyway, so we might as well
**	do all the tests we can
*/
update ${1}_import
	set EMAIL = 'rc5-bad@distributed.net'
	where EMAIL not like '%@%'	/* Must have @ */
		or EMAIL like '%[ <>]%'	/* Must not contain space, &gt or &lt */
		or EMAIL like '@%'	/* Must not begin with @ */
		or EMAIL like '%@'	/* Must not end with @ */

/*
**	Only one @.  Must test after we know they have at least one @
*/
update ${1}_import
	set EMAIL = 'rc5-bad@distributed.net'
	where substring(EMAIL, charindex('@', EMAIL) + 1, 64) like '%@%'
go

/* Store the stats date here, instead of in every row of Email_Contrib_Day and Platform_Contrib_Day */
declare @stats_date smalldatetime
select @stats_date = max(timestamp)
	from ${1}_import
update Projects
	set LAST_STATS_DATE = @stats_date
	where NAME = "${1}"
go

/*
Assign contest id
	Insert in holding table, or set bit or date field in STATS_Participant
	seqn, id, request_source, date_requested, date_sent
daytable contains id instead of EMAIL
password assign automatic
*/
create table #Email_Contrib_Day
(
	EMAIL varchar (64) NULL,
	WORK_UNITS numeric(20, 0) NULL
)
go
declare @proj_id tinyint

select @proj_id = PROJECT_ID
	from Projects
	where NAME = "${1}"

/* Put EMAIL data into temp table */
insert #Email_Contrib_Day (EMAIL, WORK_UNITS)
	select EMAIL, sum(WORK_UNITS)
	from ${1}_import
	group by EMAIL

insert #Email_Contrib_Day (EMAIL, WORK_UNITS)
	select EMAIL, sum(WORK_UNITS)
	from Email_Contrib_Day
	where PROJECT_ID = @proj_id

begin transaction
delete Email_Contrib_Day
	where PROJECT_ID = @proj_id

insert into Email_Contrib_Day (PROJECT_ID, EMAIL, WORK_UNITS, ID, TEAM)
	select @proj_id, EMAIL, sum(WORK_UNITS), 0, 0
	from #Email_Contrib_Day
	group by EMAIL
commit transaction

drop table #Email_Contrib_Day
go

create table #Platform_Contrib_Day
(
	CPU smallint not NULL,
	OS smallint not NULL,
	VER smallint not NULL,
	WORK_UNITS numeric(20, 0) not NULL
)
go
declare @proj_id tinyint

select @proj_id = PROJECT_ID
	from Projects
	where NAME = "${1}"

insert #Platform_Contrib_Day (CPU, os, ver, WORK_UNITS)
	select CPU, os, ver, sum(WORK_UNITS)
	from ${1}_import
	group by CPU, os, ver

insert #Platform_Contrib_Day (CPU, os, ver, WORK_UNITS)
	select CPU, os, ver, sum(WORK_UNITS)
	from Platform_Contrib_Day
	where PROJECT_ID = @proj_id
	group by CPU, os, ver

begin transaction
delete Platform_Contrib_Day
	where PROJECT_ID = @proj_id

insert Platform_Contrib_Day (PROJECT_ID, CPU, OS, VER, WORK_UNITS)
	select @proj_id, CPU, OS, VER, sum(WORK_UNITS)
	from #Platform_Contrib_Day
	group by CPU, OS, VER
commit transaction

drop table #Platform_Contrib_Day
go
delete ${1}_import
	where 1 = 1

/* This line produces the number of rows imported for logging */
select @@rowcount
go -f -h
