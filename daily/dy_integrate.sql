#!/usr/bin/sqsh -i
#
# $Id: dy_integrate.sql,v 1.8 2000/04/14 21:32:55 bwilson Exp $
#
# Move data from the ${1}_import table to the daytables
#
# Arguments:
#       PROJECT_ID

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

/* Store the stats date here, instead of in every row of Email_Contrib_Today and Platform_Contrib_Today */
declare @stats_date smalldatetime
select @stats_date = max(TIME_STAMP)
	from ${1}_import
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
insert #Email_Contrib_Today (EMAIL, WORK_UNITS)
	select EMAIL, sum(WORK_UNITS)
	from ${1}_import
	group by EMAIL

insert #Email_Contrib_Today (EMAIL, WORK_UNITS)
	select EMAIL, sum(WORK_UNITS)
	from Email_Contrib_Today
	where PROJECT_ID = ${1}

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
	from ${1}_import
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
delete ${1}_import
	where 1 = 1

/* This line produces the number of rows imported for logging */
select @@rowcount
go -f -h
