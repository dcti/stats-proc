#!/usr/bin/sqsh -i
#
# $Id: dy_integrate.sql,v 1.3 2000/02/21 03:47:06 bwilson Exp $
#
# Move data from the import table to the daytables
#
# TODO: Resummarize on each pass so SQL can work with smaller chunks for the rest of the script
#	insert #temp select * from _import union select * from _daytable
#	delete daytable
#	insert daytable select * from #temp
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
	where email like ' %'

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

declare @proj_id tinyint

select @proj_id = PROJECT_ID
	from Projects
	where PROJECT = \\'${1}\\'

insert into ${1}_daytable_master (timestamp, PROJECT_ID, email, size)
select convert(varchar, timestamp, 112) as timestamp, @proj_id, email, sum(size) as size
from ${1}_import
group by convert(varchar, timestamp, 112), email

insert into ${1}_daytable_platform (timestamp, PROJECT_ID, cpu, os, ver, size)
select convert(varchar, timestamp, 112) as timestamp, @proj_id, cpu, os, ver, sum(size) as size
from ${1}_import
group by convert(varchar, timestamp, 112), cpu, os, ver
go

delete ${1}_import where 1 = 1
go
