# $Id: dy_fixemails.sql,v 1.2 2000/02/10 23:02:46 bwilson Exp $

/*
**	Make sure they don't have any leading spaces
*/
update RC5_64_daytable_master
	set email = ltrim(email)
	where email like ' %'

/*
**	Correct some common garbage combinations
**	It's going to table-scan anyway, so we might as well
**	do all the tests we can
*/
update RC5_64_daytable_master
	set email = 'rc5-bad@distributed.net'
	where email not like '%@%'	/* Must have @ */
		or email like '%[ <>]%'	/* Must not contain space, &gt or &lt */
		or email like '@%'	/* Must not begin with @ */
		or email like '%@'	/* Must not end with @ */

/*
**	Only one @.  Must test after we know they have at least one @
*/
update RC5_64_daytable_master
	set email = 'rc5-bad@distributed.net'
	where substring(email, charindex('@', email) + 1, 64) like '%@%'
go

