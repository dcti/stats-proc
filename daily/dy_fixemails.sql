#!/usr/bin/sqsh -i
#
# $Id: dy_fixemails.sql,v 1.2 2000/02/10 15:13:54 bwilson Exp $
#
# Sets invalid email addresses to 'rc5@distributed.net'
#
# Arguments:
#       Project

/*
**	Make sure they don't have any leading spaces
*/
update ${1}_daytable_master
	set email = ltrim(email)
	where email like ' %'

/*
**	Correct some common garbage combinations
*/
update ${1}_daytable_master
	set email = 'rc5@distributed.net'
	where email not like '%@%'	/* Must have @ */
		or email like '%[ <>]%'	/* Must not contain space, &gt or &lt */
		or email like '@%'	/* Must not begin with @ */
		or email like '%@'	/* Must not end with @ */

/*
**	Only one @.  Must test after we know they have at least one @
*/
update ${1}_daytable_master
	set email = 'rc5@distributed.net'
	where substring(email, charindex('@', email) + 1, 64) like '%@%'
go
