#!/usr/bin/sqsh -i
#
# $Id: dy_integrate.sql,v 1.6 2000/04/11 14:25:02 bwilson Exp $
#
# Move data from the import table to the daytables
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
	set email = ltrim(email)
	where email <> ltrim(email)

/*
**	Correct some common garbage combinations
**	It's going to table-scan anyway, so we might as well
**	do all the tests we can
*/
update ${1}_import
	set email = 'rc5-bad@distributed.net'
	where email not like '%@%'	/* Must have @ */
		or email like '%[ <>]%'	/* Must not contain space, &gt or &lt */
		or email like '@%'	/* Must not begin with @ */
		or email like '%@'	/* Must not end with @ */

/*
**	Only one @.  Must test after we know they have at least one @
*/
update ${1}_import
	set email = 'rc5-bad@distributed.net'
	where substring(email, charindex('@', email) + 1, 64) like '%@%'
go

/* Store the stats date here, instead of in every row of _Day_Master and _Day_Platform */
declare @stats_date smalldatetime
select @stats_date = max(timestamp)
	from ${1}_import
update Projects
	set LAST_STATS_DATE = @stats_date
	where NAME = '${1}'
go

/*
Assign contest id
	Insert in holding table, or set bit or date field in STATS_Participant
	seqn, id, request_source, date_requested, date_sent
daytable contains id instead of email
password assign automatic
*/
create table #Day_Master
(
	email varchar (64) NULL,
	size numeric(20, 0) NULL
)
go
declare @proj_id tinyint

select @proj_id = PROJECT_ID
	from Projects
	where NAME = '${1}'

/* Put email data into temp table */
insert #Day_Master (email, size)
	select email, sum(size)
	from ${1}_import
	group by email

insert #Day_Master (email, size)
	select email, sum(size)
	from ${1}_Day_Master
	where PROJECT_ID = @proj_id

begin transaction
delete ${1}_Day_Master
	where PROJECT_ID = @proj_id

insert into ${1}_Day_Master (PROJECT_ID, EMAIL, SIZE, TEAM)
	select @proj_id, email, sum(size), 0
	from #Day_Master
	group by email
commit transaction

drop table #Day_Master
go

create table #Day_Platform
(
	CPU smallint not NULL,
	OS smallint not NULL,
	VER smallint not NULL,
	SIZE numeric(20, 0) not NULL
)
go
declare @proj_id tinyint

select @proj_id = PROJECT_ID
	from Projects
	where NAME = '${1}'

insert #Day_Platform (cpu, os, ver, size)
	select cpu, os, ver, sum(size)
	from ${1}_import
	group by cpu, os, ver

insert #Day_Platform (cpu, os, ver, size)
	select cpu, os, ver, sum(size)
	from ${1}_Day_Platform
	where PROJECT_ID = @proj_id
	group by cpu, os, ver

begin transaction
delete ${1}_Day_Platform
	where PROJECT_ID = @proj_id

insert ${1}_Day_Platform (PROJECT_ID, CPU, OS, VER, SIZE)
	select @proj_id, CPU, OS, VER, sum(size)
	from #Day_Platform
	group by CPU, OS, VER
commit transaction

drop table #Day_Platform
go

delete ${1}_import
	where 1 = 1
go
